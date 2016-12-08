//
//  CompositedGateway.swift
//  JustApisSwiftSDK
//
//  Created by Andrew Palumbo on 12/9/15.
//  Copyright © 2015 AnyPresence. All rights reserved.
//

import Foundation

///
/// Invoked by the CompositedGateway to prepare a request before sending.
///
/// Common use cases of a RequestPreparer might be to:
///  - add default headers
///  - add default query parameters
///  - rewrite a path
///  - serialize data as JSON or XML
///
public protocol RequestPreparer
{
    func prepareRequest(_ request:Request) -> Request
}

///
/// Invoked by the CompositedGateway to process a request after its received
///
/// Common use cases of a ResponseProcessor might be to:
///  - validate the type of a response
///  - interpret application-level error messages
///  - deserialize JSON or XML responses
///
public protocol ResponseProcessor
{
    func processResponse(_ response:Response, callback: @escaping ResponseProcessorCallback)
}

public typealias ResponseProcessorCallback = ((_ response:Response, _ error:Error?) -> Void)

///
/// Invoked by the CompositedGateway to send the request along the wire
///
/// Common use cases of a NetworkAdapter might be to:
///  - Use a specific network library (Foundation, AFNetworking, etc)
///  - Mock responses
///  - Reference a cache before using network resources
///
public protocol NetworkAdapter
{
    func submitRequest(_ request:Request, gateway:CompositedGateway)
}

///
/// Invoked by the CompositedGateway to save and retrieve responses locally cached responses
///
public protocol CacheProvider
{
    /// Called to retrieve a Response from the cache. Should call the callback with nil or the retrieved response
    func cachedResponseForIdentifier(_ identifier:String, callback:CacheProviderCallback)

    /// Called to save a Response to the cache. The expiration should be considered a preference, not a guarantee.
    func setCachedResponseForIdentifier(_ identifier:String, response:ResponseProperties, expirationSeconds:UInt)
}

public typealias CacheProviderCallback = ((ResponseProperties?) -> Void)

///
/// A Cache Provider implementation that does nothing. Useful to disable caching without changing your request logic
///
open class NullCacheProvider : CacheProvider
{
    open func cachedResponseForIdentifier(_ identifier: String, callback: CacheProviderCallback) {
        return callback(nil)
    }
    
    open func setCachedResponseForIdentifier(_ identifier: String, response: ResponseProperties, expirationSeconds: UInt) {
        return
    }
}

///
/// Convenience object for configuring a composited gateway. Can be passed into Gateway initializer
///
public struct CompositedGatewayConfiguration
{
    var baseUrl:URL
    var sslCertificate:SSLCertificate? = nil
    var defaultRequestProperties:DefaultRequestPropertySet? = nil
    var networkAdapter:NetworkAdapter? = nil
    var cacheProvider:CacheProvider? = nil
    var requestPreparer:RequestPreparer? = nil
    var responseProcessor:ResponseProcessor? = nil
    var pushNotificationsProvider:PushNotificationsProvider? = nil
    
    public init(baseUrl:URL,
        sslCertificate:SSLCertificate? = nil,
        defaultRequestProperties:DefaultRequestPropertySet? = nil,
        requestPreparer:RequestPreparer? = nil,
        responseProcessor:ResponseProcessor? = nil,
        cacheProvider:CacheProvider? = nil,
        networkAdapter:NetworkAdapter? = nil,
        pushNotificationsProvider:PushNotificationsProvider? = nil)
    {
        self.baseUrl = baseUrl
        self.sslCertificate = sslCertificate
        self.defaultRequestProperties = defaultRequestProperties
        self.requestPreparer = requestPreparer
        self.responseProcessor = responseProcessor
        self.cacheProvider = cacheProvider
        self.networkAdapter = networkAdapter
        self.pushNotificationsProvider = pushNotificationsProvider
    }
}

///
/// Implementation of Gateway protocol that dispatches most details to
/// helper classes.
///
open class CompositedGateway : Gateway, PushNotificationSupportingGateway
{
    open let baseUrl:URL
    open let sslCertificate:SSLCertificate?
    open let defaultRequestProperties:DefaultRequestPropertySet
    
    // Public method groups
    public var pushNotifications:PushNotificationMethods { return self.pushNotificationsDispatcher }

    // Internal Providers, Adapters, and Dispatches
    private let networkAdapter:NetworkAdapter
    private let cacheProvider:CacheProvider
    private let requestPreparer:RequestPreparer?
    private let responseProcessor:ResponseProcessor?
    private let contentTypeParser:ContentTypeParser
    private var pushNotificationsDispatcher:PushNotificationMethodDispatcher!

    // Internal state
    private var requests:InternalRequestQueue = InternalRequestQueue()
    open var pendingRequests:[Request] { return self.requests.pendingRequests }
    open var isPaused:Bool { return _isPaused }
    private var _isPaused:Bool = true
    
    /// TODO: Make this configurable?
    open var maxActiveRequests:Int = 2
    
    ///
    /// Designated initializer
    ///
    public init(
        baseUrl:URL,
        sslCertificate:SSLCertificate? = nil,
        defaultRequestProperties:DefaultRequestPropertySet? = nil,
        requestPreparer:RequestPreparer? = nil,
        responseProcessor:ResponseProcessor? = nil,
        cacheProvider:CacheProvider? = nil,
        networkAdapter:NetworkAdapter? = nil,
        pushNotificationsProvider:PushNotificationsProvider? = nil
        )
    {
        self.baseUrl = baseUrl
        self.sslCertificate = sslCertificate

        // Use the GatewayDefaultRequestProperties if none were provided
        self.defaultRequestProperties = defaultRequestProperties ?? GatewayDefaultRequestProperties()
        self.requestPreparer = requestPreparer
        self.responseProcessor = responseProcessor
        self.contentTypeParser = ContentTypeParser()

        // Use the InMemory Cache Provider if none was provided
        self.cacheProvider = cacheProvider ?? InMemoryCacheProvider()
        
        // Use the Foundation Network Adapter if none was provided
        self.networkAdapter = networkAdapter ?? FoundationNetworkAdapter(sslCertificate: sslCertificate)
        
        // Use the Default Push Notifications Provider if none was provided
        self.pushNotificationsDispatcher = PushNotificationMethodDispatcher(gateway: self, pushNotificationsProvider: pushNotificationsProvider ?? DefaultPushNotificationsProvider())

        self.resume()
    }
    
    ///
    /// Convenience initializer for use with CompositedGatewayConfiguration
    ///
    public convenience init(configuration:CompositedGatewayConfiguration)
    {
        self.init(
            baseUrl:configuration.baseUrl,
            sslCertificate:configuration.sslCertificate,
            defaultRequestProperties:configuration.defaultRequestProperties,
            requestPreparer:configuration.requestPreparer,
            responseProcessor:configuration.responseProcessor,
            cacheProvider:configuration.cacheProvider,
            networkAdapter:configuration.networkAdapter,
            pushNotificationsProvider: configuration.pushNotificationsProvider
                  )
    }
    
    ///
    /// Pauses the gateway. No more pending requests will be processed until resume() is called.
    ///
    open func pause()
    {
        self._isPaused = true
    }
    
    ///
    /// Unpauses the gateway. Pending requests will continue being processed.
    ///
    open func resume()
    {
        self._isPaused = false
        self.conditionallyProcessRequestQueue()
    }
    
    ///
    /// Removes a request from this gateway's pending request queue
    ///
    open func cancelRequest(_ request: Request) -> Bool {
        guard let internalRequest = request as? InternalRequest, internalRequest.gateway === self else
        {
            /// Do nothing. This request wasn't associated with this gateway.
            return false
        }
        return self.requests.cancelPendingRequest(internalRequest)
    }
    
    ///
    /// Takes a Request from the queue and begins processing it if conditions are met
    //
    private func conditionallyProcessRequestQueue()
    {
        // If not paused, not already at max active requests, and if there are requests pending
        if (false == self._isPaused
            && self.requests.numberActive < self.maxActiveRequests
            && self.requests.numberPending > 0)
        {
            self.processNextInternalRequest()
        }
    }
    
    ///
    /// Sets a ResponseProcessor to run when the given contentType is encountered in a response
    ///
    open func setParser(_ parser:ResponseProcessor?, contentType:String)
    {
        if (parser != nil)
        {
            self.contentTypeParser.contentTypes[contentType] = parser
        }
        else
        {
            self.contentTypeParser.contentTypes.removeValue(forKey: contentType)
        }
    }
    
    open func submitRequest(_ request:RequestProperties, callback:RequestCallback?)
    {
        let request = self.internalizeRequest(request)
        self.submitInternalRequest(request, callback: callback)
    }
    
    ///
    /// Called by CacheProvider or NetworkAdapter once a response is ready
    ///
    open func fulfillRequest(_ request:Request, response:ResponseProperties?, error:Error?, fromCache:Bool = false)
    {
        guard let request = request as? InternalRequest else
        {
            // TODO: THROW serious error. The Request was corrupted!
            return
        }

        // Build the result object
        let response:InternalResponse? = (response != nil) ? self.internalizeResponse(response!) : nil
        var result:RequestResult = (request:request,
                                    response:response?.copyWith(retreivedFromCache: fromCache),
                                    error:error)

        // Check if there was an error
        guard error == nil else
        {
            self.requests.fulfillRequest(request, result: result)
            return
        }
        
        // Check if there was no response; that's an error itself!
        guard response != nil else
        {
            // TODO: create meaningful error
            result.error = createError(0, context:nil, description:"")
            self.requests.fulfillRequest(request, result: result)
            return
        }
        
        // Compound 0+ response processors for this response
        let compoundResponseProcessor = CompoundResponseProcessor()
        
        // Add the content type parser
        if request.applyContentTypeParsing
        {
            compoundResponseProcessor.responseProcessors.append(contentTypeParser)
        }

        // Add any all-response processor
        if let responseProcessor = self.responseProcessor
        {
            compoundResponseProcessor.responseProcessors.append(responseProcessor)
        }
        
        // Run the compound processor in a dispatch group
        let responseProcessingDispatchGroup = DispatchGroup()
        responseProcessingDispatchGroup.enter()
        compoundResponseProcessor.processResponse(result.response!,
            callback:
            {
                (response:Response, error:Error?) in
                
                result = (request:request, response:response, error:error)
                responseProcessingDispatchGroup.leave()
            }
        )

        // When the dispatch group is emptied, cache the response and run the callback
        responseProcessingDispatchGroup.notify(queue: DispatchQueue.main, execute: {
            
            
            if result.error == nil // There's no error
                && result.response != nil // And there is a response
                && !fromCache // And the response isn't already from the cache
                && request.cacheResponseWithExpiration > 0 // And we're supposed to cache it
            {
                // Cache the response
                self.cacheProvider.setCachedResponseForIdentifier(request.cacheIdentifier, response: result.response!, expirationSeconds:request.cacheResponseWithExpiration)
            }
            
            // Pass result back to caller
            self.requests.fulfillRequest(request, result: result)
            
            // Keep the processor running, if appropriate
            self.conditionallyProcessRequestQueue()
        })
    }
    
    ///
    /// Wraps raw ResponseProperties as an InternalResponse
    ///
    internal func internalizeResponse(_ response:ResponseProperties) -> InternalResponse
    {
        // Downcast to an InternalResponse, or wrap externally prepared properties
        var internalResponse:InternalResponse = (response as? InternalResponse) ?? InternalResponse(self, response:response)
        
        if (internalResponse.gateway !== self)
        {
            // response was prepared for another gateway. Associate it with this one!
            internalResponse = internalResponse.copyWith(gateway: self)
        }
        
        return internalResponse
    }

    ///
    /// Prepares RequestProperties as an InteralRequest and performs preflight prep
    ///
    internal func internalizeRequest(_ request:RequestProperties) -> InternalRequest
    {
        // Downcast to an InternalRequest, or wrap externally prepared properties
        var internalRequest:InternalRequest = (request as? InternalRequest) ?? InternalRequest(self, request:request)

        if (internalRequest.gateway !== self)
        {
            // request was prepared for another gateway. Associate it with this one!
            internalRequest = internalRequest.copyWith(gateway: self)
        }
        
        return internalRequest
    }
    
    ///
    /// Checks CacheProvider for matching Response or submits InternalRequest to NetworkAdapter
    ///
    private func submitInternalRequest(_ request:InternalRequest, callback:RequestCallback?)
    {
        var request = request
        
        // Prepare the request if a preparer is available
        if let requestPreparer = self.requestPreparer
        {
            // TODO?: change interface to something async; may need to do something complex
            request = requestPreparer.prepareRequest(request) as! InternalRequest
        }

        // Add the request to the queue
        self.requests.appendRequest(request, callback: callback)
        
        // Keep the queue moving, if appropriate
        self.conditionallyProcessRequestQueue()
    }
    
    ///
    /// [Background] Starts processing the next request from the queue
    ///
    private func processNextInternalRequest()
    {
        guard let request = self.requests.nextRequest() else
        {
            // No request to process
            return
        }
        
        DispatchQueue.global(qos: .default).async {
            
            if request.allowCachedResponse
            {
                // Check the cache
                self.cacheProvider.cachedResponseForIdentifier(request.cacheIdentifier, callback: {
                    (response:ResponseProperties?) in
                    
                    if let response = response
                    {
                        // There was a subitably fresh response in the cache. Use it
                        self.fulfillRequest(request, response: response, error: nil, fromCache:true)
                    }
                    else
                    {
                        // Otherwise, send the request to the network adapter
                        self.networkAdapter.submitRequest(request, gateway:self)
                    }
                })
            }
            else
            {
                // Ignore anything in the cache, and send the request to the network adapter immediately
                self.networkAdapter.submitRequest(request, gateway:self)
            }
            
        }
    }
}

///
/// Convenience subclass of CompositedGateway that uses the JsonResponseProcessor.
///
open class JsonGateway : CompositedGateway
{
    public override init(baseUrl: URL, sslCertificate:SSLCertificate? = nil, defaultRequestProperties:DefaultRequestPropertySet? = nil, requestPreparer: RequestPreparer? = nil, responseProcessor:ResponseProcessor? = nil, cacheProvider:CacheProvider? = nil, networkAdapter: NetworkAdapter? = nil, pushNotificationsProvider:PushNotificationsProvider? = nil)
    {
        super.init(baseUrl: baseUrl, defaultRequestProperties: defaultRequestProperties, requestPreparer:requestPreparer, responseProcessor:responseProcessor, networkAdapter:networkAdapter)
        super.setParser(JsonResponseProcessor(), contentType: "application/json")
    }
}
