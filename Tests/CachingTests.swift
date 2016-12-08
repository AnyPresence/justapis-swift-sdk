//
//  CachingTests.swift
//  JustApisSwiftSDK
//
//  Created by Andrew Palumbo on 1/5/16.
//  Copyright © 2016 AnyPresence. All rights reserved.
//

import XCTest
@testable import JustApisSwiftSDK

class CachingTests: XCTestCase {

    private let mockRequestDefaults:MutableRequestProperties = MutableRequestProperties(
        method: "GET",
        path: "/",
        params: ["foo":"bar"],
        headers: ["foo-header":"bar-value"],
        body: nil,
        followRedirects: true,
        applyContentTypeParsing: true,
        contentTypeOverride: "test/content-type",
        allowCachedResponse: false,
        cacheResponseWithExpiration: 0,
        customCacheIdentifier: nil)
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    private func getDefaultMockResponse() -> InternalResponse
    {
        let gateway:CompositedGateway = CompositedGateway(baseUrl: URL(string:"http://localhost")!)
        let mockRequestDefaults:MutableRequestProperties = MutableRequestProperties(
            method: "GET",
            path: "/",
            params: ["foo":"bar"],
            headers: ["foo-header":"bar-value"],
            body: nil,
            followRedirects: true,
            applyContentTypeParsing: true,
            contentTypeOverride: "test/content-type",
            allowCachedResponse: false,
            cacheResponseWithExpiration: 0,
            customCacheIdentifier: nil)
        let mockRequest = gateway.internalizeRequest(mockRequestDefaults)
        
        let mockResponseDefaults:MutableResponseProperties = MutableResponseProperties(
            gateway: gateway,
            request: mockRequest,
            requestedURL: gateway.baseUrl.appendingPathComponent("/?foo=bar"),
            resolvedURL: gateway.baseUrl,
            statusCode: 400,
            headers: ["test-response-header":"foo bar"],
            body: "test".data(using: String.Encoding.utf8),
            parsedBody: "test",
            retreivedFromCache: false)
        
        return gateway.internalizeResponse(mockResponseDefaults)
    }
    
    func testInMemoryCacheProviderDirectAccess() {
        let expectation = self.expectation(description: self.name!)
        let cache = InMemoryCacheProvider()
        
        let response = self.getDefaultMockResponse()
        cache.setCachedResponseForIdentifier("a", response: response, expirationSeconds: 5)
        cache.cachedResponseForIdentifier("a", callback: { (cachedResponse:ResponseProperties?) in
            XCTAssertNotNil(cachedResponse ?? nil)
            XCTAssertEqual(response.request.path, cachedResponse?.request.path)
            XCTAssertEqual(response.request.method, cachedResponse?.request.method)
            expectation.fulfill()
        })
        self.waitForExpectations(timeout: 5, handler: nil)

    }
    
    func testInMemoryCachingDisabled() {
        let gateway:CompositedGateway = CompositedGateway(baseUrl: URL(string:"http://localhost")!)
        let expectation = self.expectation(description: self.name!)

        var numberOfRequestsReceivedByStub = 0
        stub(condition: isHost("localhost"), response: {
            (request:URLRequest) in
            
            numberOfRequestsReceivedByStub += 1
            return OHHTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        })

        var request1 = mockRequestDefaults
        request1.allowCachedResponse = false
        
        let request2 = request1
        
        gateway.submitRequest(request1, callback: { _ in
            XCTAssertEqual(numberOfRequestsReceivedByStub, 1)

            gateway.submitRequest(request2, callback: { _ in
                XCTAssertEqual(numberOfRequestsReceivedByStub, 2)
                expectation.fulfill()
            })
        })

        
        self.waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testInMemoryCachingEnabled() {
        let gateway:CompositedGateway = CompositedGateway(baseUrl: URL(string:"http://localhost")!)
        let expectation = self.expectation(description: self.name!)
        
        var request1 = mockRequestDefaults
        request1.allowCachedResponse = true
        request1.cacheResponseWithExpiration = 10
        
        let request2 = request1
        
        XCTAssertEqual(request1.cacheIdentifier, request2.cacheIdentifier)

        var numberOfRequestsReceivedByStub = 0
        stub(condition: isHost("localhost"), response: {
            (request:URLRequest) in
            
            numberOfRequestsReceivedByStub += 1
            return OHHTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        })
        
        gateway.submitRequest(request1, callback: { (result:RequestResult) in
            XCTAssertEqual(result.response?.retreivedFromCache, false)
            XCTAssertEqual(numberOfRequestsReceivedByStub, 1)

            gateway.submitRequest(request2, callback: { (result:RequestResult) in
                XCTAssertEqual(result.response?.retreivedFromCache, true)
                XCTAssertEqual(numberOfRequestsReceivedByStub, 1)
                expectation.fulfill()
            })
        })
        
        self.waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testInMemoryCachingExpiration() {
        let gateway:CompositedGateway = CompositedGateway(baseUrl: URL(string:"http://localhost")!)
        let expectation = self.expectation(description: self.name!)
        
        var request1 = mockRequestDefaults
        request1.allowCachedResponse = true
        request1.cacheResponseWithExpiration = 1
        
        let request2 = request1
        
        XCTAssertEqual(request1.cacheIdentifier, request2.cacheIdentifier)
        
        var numberOfRequestsReceivedByStub = 0
        stub(condition: isHost("localhost"), response: {
            (request:URLRequest) in
            
            numberOfRequestsReceivedByStub += 1
            return OHHTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        })
        
        gateway.submitRequest(request1, callback: { (result:RequestResult) in
            XCTAssertEqual(result.response?.retreivedFromCache, false)
            XCTAssertEqual(numberOfRequestsReceivedByStub, 1)
            
            Thread.sleep(forTimeInterval: 2)
            gateway.submitRequest(request2, callback: { (result:RequestResult) in
                XCTAssertEqual(numberOfRequestsReceivedByStub, 2)
                XCTAssertEqual(result.response?.retreivedFromCache, false)
                expectation.fulfill()
            })
        })
        
        self.waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testInMemoryCachingDoNotStore() {
        let gateway:CompositedGateway = CompositedGateway(baseUrl: URL(string:"http://localhost")!)
        let expectation = self.expectation(description: self.name!)
        
        var request1 = mockRequestDefaults
        request1.allowCachedResponse = true
        request1.cacheResponseWithExpiration = 0
        
        let request2 = request1
        
        XCTAssertEqual(request1.cacheIdentifier, request2.cacheIdentifier)
        
        var numberOfRequestsReceivedByStub = 0
        stub(condition: isHost("localhost"), response: {
            (request:URLRequest) in
            
            numberOfRequestsReceivedByStub += 1
            return OHHTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        })
        
        gateway.submitRequest(request1, callback: { (result:RequestResult) in
            XCTAssertEqual(result.response?.retreivedFromCache, false)
            XCTAssertEqual(numberOfRequestsReceivedByStub, 1)
            
            Thread.sleep(forTimeInterval: 2)
            gateway.submitRequest(request2, callback: { (result:RequestResult) in
                XCTAssertEqual(numberOfRequestsReceivedByStub, 2)
                XCTAssertEqual(result.response?.retreivedFromCache, false)
                expectation.fulfill()
            })
        })
        
        self.waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testCustomCacheIdentifier() {
        let gateway:CompositedGateway = CompositedGateway(baseUrl: URL(string:"http://localhost")!)
        let expectation = self.expectation(description: self.name!)
        
        var request1 = mockRequestDefaults
        request1.path = "/some/unique/path"
        request1.allowCachedResponse = true
        request1.cacheResponseWithExpiration = 10
        
        var request2 = request1
        request2.path = "/some/different/path/entirely"
        request2.allowCachedResponse = true
        request2.cacheResponseWithExpiration = 10
        
        XCTAssertNotEqual(request1.cacheIdentifier, request2.cacheIdentifier)
        
        request1.customCacheIdentifier = "Some.App.Determined.Identifier"
        request2.customCacheIdentifier = "Some.App.Determined.Identifier"
        XCTAssertEqual(request1.cacheIdentifier, request2.cacheIdentifier)
        
        var numberOfRequestsReceivedByStub = 0
        stub(condition: isHost("localhost"), response: {
            (request:URLRequest) in
            
            numberOfRequestsReceivedByStub += 1
            return OHHTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        })
        
        gateway.submitRequest(request1, callback: { (result:RequestResult) in
            XCTAssertEqual(result.response?.retreivedFromCache, false)
            XCTAssertEqual(numberOfRequestsReceivedByStub, 1)
            
            gateway.submitRequest(request2, callback: { (result:RequestResult) in
                XCTAssertEqual(result.response?.retreivedFromCache, true)
                XCTAssertEqual(numberOfRequestsReceivedByStub, 1)
                expectation.fulfill()
            })
        })
        
        self.waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testNullCacheProvider() {
        let gateway:CompositedGateway = CompositedGateway(baseUrl: URL(string:"http://localhost")!, defaultRequestProperties:nil, cacheProvider:NullCacheProvider())
        let expectation = self.expectation(description: self.name!)
        
        var request1 = mockRequestDefaults
        request1.allowCachedResponse = true
        request1.cacheResponseWithExpiration = 10
        
        let request2 = request1
        
        XCTAssertEqual(request1.cacheIdentifier, request2.cacheIdentifier)
        
        var numberOfRequestsReceivedByStub = 0
        stub(condition: isHost("localhost"), response: {
            (request:URLRequest) in
            
            numberOfRequestsReceivedByStub += 1
            return OHHTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        })
        
        gateway.submitRequest(request1, callback: { (result:RequestResult) in
            XCTAssertEqual(result.response?.retreivedFromCache, false)
            XCTAssertEqual(numberOfRequestsReceivedByStub, 1)
            
            Thread.sleep(forTimeInterval: 2)
            gateway.submitRequest(request2, callback: { (result:RequestResult) in
                XCTAssertEqual(numberOfRequestsReceivedByStub, 2)
                XCTAssertEqual(result.response?.retreivedFromCache, false)
                expectation.fulfill()
            })
        })
        
        self.waitForExpectations(timeout: 5, handler: nil)
    }
}
