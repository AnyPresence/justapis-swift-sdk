//
//  Response.swift
//  JustApisSwiftSDK
//
//  Created by Andrew Palumbo on 12/29/15.
//  Copyright © 2015 AnyPresence. All rights reserved.
//

import Foundation

///
/// Properties that define a Response.
///
public protocol ResponseProperties
{
    /// The Gateway from which this response was generated
    var gateway:Gateway { get }
    
    /// The Request that was ultimately submitted to the gateway
    var request:Request { get }
    
    /// The final URL that was sent to the gateway (prior to redirection)
    var requestedURL:URL { get }
    
    /// The final URL of the request (after any redirection)
    var resolvedURL:URL? { get }
    
    /// The HTTP status code returned by the server
    var statusCode:Int { get }
    
    /// HTTP headers returned by the server
    var headers:Headers { get }
    
    /// Any body data returned by the server
    var body:Data? { get }

    /// Any parsed body data
    var parsedBody:Any? { get }
    
    /// Indicates that this response was retrieved from a local cache
    var retreivedFromCache:Bool { get }
}

public protocol ResponseBuilderMethods
{
    /// Returns a new Response with gateway set to the provided value
    func copyWith(gateway value:Gateway) -> Self
    
    /// Returns a new Response with request set to the provided value
    func copyWith(request value:Request) -> Self
    
    /// Returns a new Response with requestedURL set to the provided value
    func copyWith(requestedURL value:URL) -> Self
    
    /// Returns a new Response with resolvedURL set to the provided value
    func copyWith(resolvedURL value:URL) -> Self
    
    /// Returns a new Response with statusCode set to the provided value
    func copyWith(statusCode value:Int) -> Self
    
    /// Returns a new Response with all headers set to the provided value
    func copyWith(headers value:Headers) -> Self
    
    /// Returns a new Response with a header with the provided key set to the provided value
    func copyWith(headerKey key:String, headerValue value:String?) -> Self
    
    /// Returns a new Response with body set to the provided value
    func copyWith(body value:Data?) -> Self
    
    /// Returns a new Response with parsedBody set to the provided value
    func copyWith(parsedBody value:Any?) -> Self
    
    // Returns a new Response with retreivedFromCache set to the provided value
    func copyWith(retreivedFromCache value:Bool) -> Self
}

public protocol Response : ResponseProperties, ResponseBuilderMethods
{
    
}

///
/// Basic mutable representation of public Response properties
///
public struct MutableResponseProperties : ResponseProperties
{
    public var gateway:Gateway
    public var request:Request
    public var requestedURL:URL
    public var resolvedURL:URL?
    public var statusCode:Int
    public var headers:Headers
    public var body:Data?
    public var parsedBody:Any?
    public var retreivedFromCache:Bool

    public init(gateway:Gateway, request:Request, requestedURL:URL, resolvedURL:URL, statusCode:Int, headers:Headers, body:Data?, parsedBody:Any?, retreivedFromCache:Bool) {
        self.gateway = gateway
        self.request = request
        self.requestedURL = requestedURL
        self.resolvedURL = resolvedURL
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
        self.parsedBody = parsedBody
        self.retreivedFromCache = retreivedFromCache
    }
}
