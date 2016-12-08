//
//  InternalResponse.swift
//  JustApisSwiftSDK
//
//  Created by Andrew Palumbo on 12/30/15.
//  Copyright © 2015 AnyPresence. All rights reserved.
//

import Foundation

internal protocol InternalResponseProperties : ResponseProperties
{
    var internalRequest:InternalRequest? { get }
}

internal struct MutableInternalResponseProperties : InternalResponseProperties
{
    var gateway:Gateway
    var request:Request
    var requestedURL:URL
    var resolvedURL:URL?
    var statusCode:Int
    var headers:Headers
    var body:Data?
    var parsedBody:Any?
    var retreivedFromCache:Bool
    var internalRequest:InternalRequest? { get { return request as? InternalRequest } }

    init(_ response:InternalResponseProperties)
    {
        self.gateway = response.gateway
        self.request = response.request
        self.requestedURL = response.requestedURL as URL
        self.resolvedURL = response.resolvedURL as URL?
        self.statusCode = response.statusCode
        self.headers = response.headers
        self.body = response.body as Data?
        self.parsedBody = response.parsedBody
        self.retreivedFromCache = response.retreivedFromCache
    }
    
}

///
/// Internal immutable implementation of Response Protocol
///
internal struct InternalResponse: Response, InternalResponseProperties
{
    typealias ResponseType = InternalResponse

    let gateway:Gateway
    let request:Request
    let requestedURL:URL
    let resolvedURL:URL?
    let statusCode:Int
    let headers:Headers
    let body:Data?
    let parsedBody:Any?
    let retreivedFromCache:Bool
    var internalRequest:InternalRequest? { get { return request as? InternalRequest } }
    
    init(_ response:InternalResponseProperties)
    {
        self.gateway = response.gateway
        self.request = response.request
        self.requestedURL = response.requestedURL as URL
        self.resolvedURL = response.resolvedURL as URL?
        self.statusCode = response.statusCode
        self.headers = response.headers
        self.body = response.body as Data?
        self.parsedBody = response.parsedBody
        self.retreivedFromCache = response.retreivedFromCache
    }
    
    init(_ gateway:CompositedGateway, response:ResponseProperties)
    {
        self.gateway = gateway
        self.request = response.request
        self.requestedURL = response.requestedURL as URL
        self.resolvedURL = response.resolvedURL as URL?
        self.statusCode = response.statusCode
        self.headers = response.headers
        self.body = response.body as Data?
        self.parsedBody = response.parsedBody
        self.retreivedFromCache = response.retreivedFromCache
    }

    func getMutableProperties() -> MutableInternalResponseProperties
    {
        return MutableInternalResponseProperties(self)
    }
}

extension InternalResponse : ResponseBuilderMethods
{
    func copyWith(gateway value: Gateway) -> InternalResponse {
        var properties = self.getMutableProperties()
        properties.gateway = value
        return InternalResponse(properties)
    }
    
    func copyWith(request value: Request) -> InternalResponse {
        var properties = self.getMutableProperties()
        properties.request = value
        return InternalResponse(properties)
    }
        
    func copyWith(requestedURL value: URL) -> InternalResponse {
        var properties = self.getMutableProperties()
        properties.requestedURL = value
        return InternalResponse(properties)
    }
    
    func copyWith(resolvedURL value: URL) -> InternalResponse {
        var properties = self.getMutableProperties()
        properties.resolvedURL = value
        return InternalResponse(properties)
    }
    
    func copyWith(statusCode value: Int) -> InternalResponse {
        var properties = self.getMutableProperties()
        properties.statusCode = value
        return InternalResponse(properties)
    }
    
    func copyWith(headers value: Headers) -> InternalResponse {
        var properties = self.getMutableProperties()
        properties.headers = value
        return InternalResponse(properties)
    }
    
    func copyWith(headerKey key: String, headerValue value: String?) -> InternalResponse {
        var properties = self.getMutableProperties()
        
        if let value = value
        {
            properties.headers[key] = value
        }
        else
        {
            properties.headers.removeValue(forKey: key)
        }
        return InternalResponse(properties)
    }
    
    func copyWith(body value: Data?) -> InternalResponse {
        var properties = self.getMutableProperties()
        properties.body = value
        return InternalResponse(properties)
    }
    
    func copyWith(parsedBody value: Any?) -> InternalResponse {
        var properties = self.getMutableProperties()
        properties.parsedBody = value
        return InternalResponse(properties)
    }
    
    func copyWith(retreivedFromCache value: Bool) -> InternalResponse {
        var properties = self.getMutableProperties()
        properties.retreivedFromCache = value
        return InternalResponse(properties)
    }
}
