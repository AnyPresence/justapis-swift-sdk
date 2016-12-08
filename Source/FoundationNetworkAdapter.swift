//
//  FoundationNetworkAdapter.swift
//  JustApisSwiftSDK
//
//  Created by Andrew Palumbo on 12/9/15.
//  Copyright © 2015 AnyPresence. All rights reserved.
//

import Foundation

open class FoundationNetworkAdapter : NSObject, NetworkAdapter, URLSessionDataDelegate, URLSessionDelegate
{
    typealias TaskCompletionHandler =  (_ data:Data?, _ response:URLResponse?, _ error:NSError?) -> Void;
    
    public init(sslCertificate:SSLCertificate? = nil)
    {
        self.sslCertificate = sslCertificate
        super.init()
        
        self.session = Foundation.URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
    }
    
    private let sslCertificate:SSLCertificate?
    private var session:Foundation.URLSession!
    private var taskToRequestMap = [Int: (request:Request, handler:TaskCompletionHandler)]()
    
    @objc open func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response:
        HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {

            if let taskRequest = self.taskToRequestMap[task.taskIdentifier]
            {
                if (taskRequest.request.followRedirects)
                {
                    // Allow redirect
                    completionHandler(request)
                }
                else
                {
                    // Reject redirect
                    completionHandler(nil)
                    
                    // HACK: For a currently unclear reason, the data task's completion handler doesn't
                    // get called by the NSURLSession framework if we reject the redirect here. 
                    // So we call it here explicitly.
                    taskRequest.handler(nil, response, nil)
                }
            }
            else
            {
                completionHandler(request)
            }
    }
    
    @objc open func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

        // If we have a SSL certificate for certificate pinning, verify it

        guard let serverTrust = challenge.protectionSpace.serverTrust else
        {
            // APPROVE: This isn't the challenge we're looking for
            completionHandler(Foundation.URLSession.AuthChallengeDisposition.useCredential, nil)
            return
        }
     
        let credential = URLCredential(trust: serverTrust)

        guard let sslCertificate = self.sslCertificate else
        {
            // APPROVE: We're not worried about trusting the server as we have no certificate pinned
            challenge.sender?.use(credential, for: challenge)
            completionHandler(Foundation.URLSession.AuthChallengeDisposition.useCredential, credential)
            return
        }
        
        guard let remoteCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0) else
        {
            // FAIL: We want to verify the server ceritifate, but it didn't give us one!
            challenge.sender?.cancel(challenge)
            completionHandler(Foundation.URLSession.AuthChallengeDisposition.cancelAuthenticationChallenge, nil)
            return
        }
        
        guard let remoteCertificateData:Data = SecCertificateCopyData(remoteCertificate) as Data?, remoteCertificateData == sslCertificate.data else
        {
            // FAIL: The certificates didn't match!
            challenge.sender?.cancel(challenge)
            completionHandler(Foundation.URLSession.AuthChallengeDisposition.cancelAuthenticationChallenge, nil)
            return
        }
        
        // APPROVE: We checked for a certificate and it was valid!
        challenge.sender?.use(credential, for: challenge)
        completionHandler(Foundation.URLSession.AuthChallengeDisposition.useCredential, credential)
        return
    }
    
    open func submitRequest(_ request: Request, gateway:CompositedGateway)
    {
        // Build the request
        guard let urlRequest:URLRequest = request.toURLRequest(gateway) else
        {
            // TODO: construct error indicating invalid request and invoke callback
            return
        }
        
        var taskIdentifier:Int!
        let taskCompletionHandler = { [weak self]
            (data:Data?, response:URLResponse?, error:Error?) -> Void in
            
            var gatewayResponse:MutableResponseProperties? = nil
            
            // Generate a Gateway Response, if there's
            if let foundationResponse = response as? HTTPURLResponse
            {
                gatewayResponse = MutableResponseProperties(foundationResponse, data:data, requestedURL:urlRequest.url!, gateway: gateway, request: request)
            }
            
            let _ = self?.taskToRequestMap.removeValue(forKey: taskIdentifier)
            
            // Let the gateway finish processing the response (on main thread)
            DispatchQueue.main.async(execute: {
                gateway.fulfillRequest(request, response:gatewayResponse, error:error);
            })
        }
        
        // Submit the request on the session
        let task = self.session.dataTask(with: urlRequest, completionHandler: taskCompletionHandler)
        
        taskIdentifier = task.taskIdentifier
        self.taskToRequestMap[taskIdentifier] = (request, taskCompletionHandler)
        task.resume()
    }
}

internal extension MutableResponseProperties
{
    // Internal initializer method to populate an Immutable Response
    internal init(_ response:HTTPURLResponse, data:Data?, requestedURL:URL, gateway:Gateway, request:Request)
    {
        self.gateway = gateway
        self.request = request
        self.statusCode = response.statusCode
        
        var headers = Headers()
        for (key, value) in response.allHeaderFields
        {
            if let keyString = key as? String, let valueString = value as? String
            {
                headers[keyString] = valueString
            }
        }
        self.headers = headers
        self.requestedURL = requestedURL
        self.resolvedURL = response.url ?? nil
        self.body = data
        self.parsedBody = nil
        self.retreivedFromCache = false
    }
}

internal extension Request
{
    /// Internal method to convert any type of Request to a NSURLRequest for Foundation networking
    internal func toURLRequest(_ gateway:Gateway) -> URLRequest?
    {
        // Identify the absolute URL endpoint
        let endpointUrl:URL = gateway.baseUrl.appendingPathComponent(self.path)
        
        var url:URL = endpointUrl
        
        // If params are assigned, apply them
        if nil != self.params && self.params!.count > 0
        {
            let params = self.params!
            
            // Create a components object
            guard var urlComponents:URLComponents = URLComponents(url: endpointUrl, resolvingAgainstBaseURL: false) else
            {
                // Could not parse NSURL through this technique
                return nil
            }
            
            // Build query list
            var queryItems = Array<URLQueryItem>()
            for (key,value) in params
            {
                if let arrayValue = value as? Array<Any>
                {
                    for (innerValue) in arrayValue
                    {
                        let queryItem:URLQueryItem = URLQueryItem(name: key + "[]", value:String(describing: innerValue))
                        queryItems.append(queryItem)
                    }
                }
                else if let _ = value as? NSNull
                {
                    let queryItem:URLQueryItem = URLQueryItem(name: key, value: nil);
                    queryItems.append(queryItem)
                }
                else if let stringValue = value as? CustomStringConvertible
                {
                    let queryItem:URLQueryItem = URLQueryItem(name: key, value: String(describing: stringValue));
                    queryItems.append(queryItem)
                }
                else
                {
                    assert(false, "Unsupported query item value. Must be array, NSNull, or a CustomStringConvertible type")
                }
            }
            urlComponents.queryItems = queryItems
            
            // Try to resolve the URLComponents
            guard let completeUrl = urlComponents.url else
            {
                // Could not resolve to URL once we included query parameters
                return nil
            }
            url = completeUrl
        }
        
        // Create the request object
        let urlRequest:NSMutableURLRequest = NSMutableURLRequest(url: url);
        
        // Set the method
        urlRequest.httpMethod = self.method;
        
        // If headers were assigned, apply them
        if nil != self.headers && self.headers!.count > 0
        {
            let headers = self.headers!
            for (field,value) in headers
            {
                urlRequest.addValue(value, forHTTPHeaderField: field);
            }
        }
        
        // If a body was assigned, apply it
        if let body = self.body
        {
            urlRequest.httpBody = body as Data
        }
        
        return urlRequest as URLRequest
    }
}
