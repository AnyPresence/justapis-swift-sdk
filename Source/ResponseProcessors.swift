//
//  ResponsePreparers.swift
//  JustApisSwiftSDK
//
//  Created by Andrew Palumbo on 12/9/15.
//  Copyright © 2015 AnyPresence. All rights reserved.
//

import Foundation

///
/// A Response Processor implementation that does nothing
///
open class NullResponseProcessor : ResponseProcessor
{
    open func processResponse(_ response: Response, callback: @escaping ResponseProcessorCallback) {
        callback(response, nil)
    }
}

///
/// A ResponseProcessor that dispatches its functionality to
/// a closure provided at initialization
///
open class ResponseProcessorClosureAdapter : ResponseProcessor
{
    public typealias ResponseProcessorClosure = (Response) -> (RequestResult)
    
    private let closure:ResponseProcessorClosure
    
    open func processResponse(_ response: Response, callback: @escaping ResponseProcessorCallback) {
        let result = self.closure(response)
        callback(result.response!, result.error)
    }
    
    public init(closure: @escaping ResponseProcessorClosure)
    {
        self.closure = closure
    }
}

///
/// A ResponseProcessor that executes multiple other processors in series
///
open class CompoundResponseProcessor : ResponseProcessor
{
    open var responseProcessors = [ResponseProcessor]()
    
    open func processResponse(_ response: Response, callback: @escaping ResponseProcessorCallback) {

        let dispatchGroup = DispatchGroup()

        var response = response
        var error:Error? = nil

        for responseProcessor in responseProcessors
        {
            dispatchGroup.notify(queue: DispatchQueue.main, execute: {
                guard error == nil else
                {
                    // If there's an error, do no more processing
                    return
                }

                dispatchGroup.enter()
                
                responseProcessor.processResponse(response,
                    callback:
                    {
                        (immediateResponse:Response, immediateError:Error?) in
                        
                        response = immediateResponse
                        error = immediateError
                        dispatchGroup.leave()
                    }
                )
            })
        }
        
        dispatchGroup.notify(queue: DispatchQueue.main, execute: {
            callback(response, error)
        })
    }
    
    public init()
    {
        
    }
}

///
/// Dispatches a ResponseProcessor for a matched Content-Type header (or overriden Content-Type)
///
open class ContentTypeParser : ResponseProcessor
{
    /// Map of "Content-Type" value to ResponseProcessor
    open var contentTypes = [String:ResponseProcessor]()
    
    open func processResponse(_ response: Response, callback: @escaping ResponseProcessorCallback) {

        if let contentType = response.request.contentTypeOverride ?? response.headers["Content-Type"]
        {
            if let processor:ResponseProcessor = contentTypes[contentType]
            {
                processor.processResponse(response, callback: callback)
                return
            }
        }
        
        // There was either no contentType or no ResponseProcess. Just pass along our input:
        callback(response, nil)
    }
}

///
/// Implementation of a ResponseProcessor that decodes body data as a JSON object
///
open class JsonResponseProcessor : ResponseProcessor
{
    open func processResponse(_ response: Response, callback: @escaping ResponseProcessorCallback)
    {
        // Make sure the body is an NSData object, as expected
        guard let body = response.body else
        {
            // TODO create an error to indicate no body data and return
            let error:Error? = nil
            callback(response, error)
            return
        }

        var response:Response = response
        var error:Error? = nil

        // Unpack the body data as a JSON object
        do
        {
            let jsonData = try JSONSerialization.jsonObject(with: body as Data, options: [])

            // TODO: Parsing should use different properties! Not overwrite body!
            // Build a new Response with the parsed data replacing the original NSData
            response = response.copyWith(parsedBody: jsonData)
        }
        catch let jsonError
        {
            error = jsonError
        }
        
        // TODO if successful, replace the response with an ImmutableJsonResponse
        callback(response, error)
    }
}
