//
//  RequestPreparers.swift
//  JustApisSwiftSDK
//
//  Created by Andrew Palumbo on 12/9/15.
//  Copyright © 2015 AnyPresence. All rights reserved.
//

import Foundation

///
/// A Request Preparer implementation that does nothing
///
open class NullRequestPreparer : RequestPreparer
{
    open func prepareRequest(_ request:Request) -> Request {
        return request
    }
}

///
/// Implementation of RequestPreparer that infills default values
/// for headers and query parameters
///
open class DefaultFieldsRequestPreparer : RequestPreparer
{
    open var defaultHeaders:Headers!
    open var defaultQueryParameters:QueryParameters!
    
    open func prepareRequest(_ request: Request) -> Request
    {
        if (self.defaultHeaders.count == 0 && self.defaultQueryParameters.count == 0)
        {
            // Nothing to do. Don't even make our working copy
            return request;
        }
        var request:Request = request

        // Infill defaultHeaders into request.headers if they're missing
        for (key, value) in self.defaultHeaders
        {
            if (request.headers?[key] == nil)
            {
                request = request.copyWith(headerKey: key, headerValue: value)
            }
        }
        
        // Infill defaultQueryParameters into request.queryParameters
        for (key, value) in self.defaultQueryParameters
        {
            if (request.params?[key] == nil)
            {
                request = request.copyWith(paramKey: key, paramValue: value)
            }
        }
        return request
    }
    
    public init(headers:Headers? = nil, params:QueryParameters? = nil)
    {
        self.defaultHeaders = headers ?? Headers();
        self.defaultQueryParameters = params ?? QueryParameters()
    }
}

///
/// Implementation of RequestPreparer that dispatches its functionality
//  to a closure provided at initialization
///
open class RequestPreparerClosureAdapter : RequestPreparer
{
    public typealias RequestPreparerClosure = (Request) -> (Request)
    
    private let closure:RequestPreparerClosure
    
    open func prepareRequest(_ request: Request) -> Request
    {
        // Call the closure
        return self.closure(request)
    }
    
    public init(closure: @escaping RequestPreparerClosure)
    {
        self.closure = closure
    }
}
