//
//  Gateway.swift
//  JustApisSwiftSDK
//
//  Created by Andrew Palumbo on 12/29/15.
//  Copyright © 2015 AnyPresence. All rights reserved.
//

import Foundation

let kGatewayDefaultCacheExpiration:UInt = 300

///
/// A client-side representation of a JustAPIs Gateway server
///
public protocol Gateway : class
{
    /// The Base URL to which requests will be sent
    var baseUrl:URL { get }
    var defaultRequestProperties:DefaultRequestPropertySet { get }
    
    /// Sends a request to the gateway
    func submitRequest(_ request:RequestProperties, callback:RequestCallback?)

    
    ///
    /// Request Queue
    /// ---
    /// Requests submitted to this gateway enter a queue.
    ///
    /// Features:
    /// * The queue can be rate-limited so that only a certain number of
    ///   requests are active at any time.
    /// * The queue can be paused to prevent any requests from being processed
    /// * You can retrieve the list of unstarted requests the queue for persistence
    
    /// Requests that have been submitted to the gateway but not yet executed
    var pendingRequests:[Request] { get }
    
    /// The number of requests that may execute simultaneously on this gateway
    var maxActiveRequests:Int { get set }
    
    /// Indicated whether this gateway is currently paused
    var isPaused:Bool { get }
    
    /// Stops request processing on this Gateay
    func pause()
    
    /// Resumes request processing on this Gateway
    func resume()
    
    /// Removes a request from the queue, if it hasn't yet been started. The request must
    /// be from this gateway's pendingRequests queue
    func cancelRequest(_ request:Request) -> Bool
}

///
/// A protocol extension to Gateway that adds convenience methods for preparing GET requests
///
public extension Gateway
{
    /// A convenience method for sending a GET request
    func get(_ path:String, params:QueryParameters?, headers:Headers?, body:Data?, followRedirects:Bool, callback:RequestCallback?)
    {
        var request = self.defaultRequestProperties.get
        request.path = path
        request.params = params ?? request.params
        request.headers = headers ?? request.headers
        request.body = body
        request.followRedirects = followRedirects

        self.submitRequest(request, callback: callback)
    }
    
    /// A convenience method for sending a GET request
    func get(_ path:String, params:QueryParameters?, headers:Headers?, body:Data?, callback:RequestCallback?)
    {
        return self.get(path, params: params, headers: headers, body: nil, followRedirects: true, callback: callback)
    }
    
    /// A convenience method for sending a GET request
    func get(_ path:String, params:QueryParameters?, headers:Headers?, callback:RequestCallback?)
    {
        return self.get(path, params: params, headers: headers, body: nil, followRedirects: true, callback: callback)
    }
    
    /// A convenience method for sending a GET request
    func get(_ path:String, params:QueryParameters?, callback:RequestCallback?)
    {
        return self.get(path, params: params, headers: nil, body: nil, followRedirects: true, callback: callback)
    }
    
    /// A convenience method for sending a GET request
    func get(_ path:String, callback:RequestCallback?)
    {
        return self.get(path, params: nil, headers: nil, body: nil, followRedirects: true, callback: callback)
    }
}

///
/// A protocol extension to Gateway that adds convenience methods for preparing POST requests
///
public extension Gateway
{
    /// A convenience method for sending a POST request
    func post(_ path:String, params:QueryParameters?, headers:Headers?, body:Data?, followRedirects:Bool, callback:RequestCallback?)
    {
        var request = self.defaultRequestProperties.post
        request.path = path
        request.params = params ?? request.params
        request.headers = headers ?? request.headers
        request.body = body
        request.followRedirects = followRedirects
        
        self.submitRequest(request, callback: callback)
    }
    
    /// A convenience method for sending a POST request
    func post(_ path:String, params:QueryParameters?, headers:Headers?, body:Data?, callback:RequestCallback?)
    {
        return self.post(path, params: params, headers: headers, body: nil, followRedirects: true, callback: callback)
    }
    
    /// A convenience method for sending a POST request
    func post(_ path:String, params:QueryParameters?, headers:Headers?, callback:RequestCallback?)
    {
        return self.post(path, params: params, headers: headers, body: nil, followRedirects: true, callback: callback)
    }
    
    /// A convenience method for sending a POST request
    func post(_ path:String, params:QueryParameters?, callback:RequestCallback?)
    {
        return self.post(path, params: params, headers: nil, body: nil, followRedirects: true, callback: callback)
    }
    
    /// A convenience method for sending a POST request
    func post(_ path:String, callback:RequestCallback?)
    {
        return self.post(path, params: nil, headers: nil, body: nil, followRedirects: true, callback: callback)
    }
}

///
/// A protocol extension to Gateway that adds convenience methods for preparing PUT requests
///
public extension Gateway
{
    /// A convenience method for sending a PUT request
    func put(_ path:String, params:QueryParameters?, headers:Headers?, body:Data?, followRedirects:Bool, callback:RequestCallback?)
    {
        var request = self.defaultRequestProperties.put
        request.path = path
        request.params = params ?? request.params
        request.headers = headers ?? request.headers
        request.body = body
        request.followRedirects = followRedirects
        
        self.submitRequest(request, callback: callback)
    }
    
    /// A convenience method for sending a PUT request
    func put(_ path:String, params:QueryParameters?, headers:Headers?, body:Data?, callback:RequestCallback?)
    {
        return self.put(path, params: params, headers: headers, body: nil, followRedirects: true, callback: callback)
    }
    
    /// A convenience method for sending a PUT request
    func put(_ path:String, params:QueryParameters?, headers:Headers?, callback:RequestCallback?)
    {
        return self.put(path, params: params, headers: headers, body: nil, followRedirects: true, callback: callback)
    }
    
    /// A convenience method for sending a PUT request
    func put(_ path:String, params:QueryParameters?, callback:RequestCallback?)
    {
        return self.put(path, params: params, headers: nil, body: nil, followRedirects: true, callback: callback)
    }
    
    /// A convenience method for sending a PUT request
    func put(_ path:String, callback:RequestCallback?)
    {
        return self.put(path, params: nil, headers: nil, body: nil, followRedirects: true, callback: callback)
    }
}

///
/// A protocol extension to Gateway that adds convenience methods for preparing DELETE requests
///
public extension Gateway
{
    /// A convenience method for sending a DELETE request
    func delete(_ path:String, params:QueryParameters?, headers:Headers?, body:Data?, followRedirects:Bool, callback:RequestCallback?)
    {
        var request = self.defaultRequestProperties.delete
        request.path = path
        request.params = params ?? request.params
        request.headers = headers ?? request.headers
        request.body = body
        request.followRedirects = followRedirects
        
        self.submitRequest(request, callback: callback)
    }
    
    /// A convenience method for sending a DELETE request
    func delete(_ path:String, params:QueryParameters?, headers:Headers?, body:Data?, callback:RequestCallback?)
    {
        return self.delete(path, params: params, headers: headers, body: nil, followRedirects: true, callback: callback)
    }
    
    /// A convenience method for sending a DELETE request
    func delete(_ path:String, params:QueryParameters?, headers:Headers?, callback:RequestCallback?)
    {
        return self.delete(path, params: params, headers: headers, body: nil, followRedirects: true, callback: callback)
    }
    
    /// A convenience method for sending a DELETE request
    func delete(_ path:String, params:QueryParameters?, callback:RequestCallback?)
    {
        return self.delete(path, params: params, headers: nil, body: nil, followRedirects: true, callback: callback)
    }
    
    /// A convenience method for sending a DELETE request
    func delete(_ path:String, callback:RequestCallback?)
    {
        return self.delete(path, params: nil, headers: nil, body: nil, followRedirects: true, callback: callback)
    }
}
