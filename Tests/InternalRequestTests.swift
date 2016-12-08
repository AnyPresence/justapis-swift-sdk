//
//  InternalRequestTests.swift
//  JustApisSwiftSDK
//
//  Created by Andrew Palumbo on 1/5/16.
//  Copyright © 2016 AnyPresence. All rights reserved.
//

import XCTest
@testable import JustApisSwiftSDK

class InternalRequestTests: XCTestCase {

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

    func testHashableProtocolSupport()
    {
        let gateway:CompositedGateway = CompositedGateway(baseUrl: URL(string:"http://localhost")!)

        let request = gateway.internalizeRequest(self.mockRequestDefaults)
            .copyWith(path: "/abc")
            .copyWith(params: ["a":1,"b":2])
        
        let requestWithDifferentMethod = request.copyWith(method: "POST")
        let requestWithBarelyDifferentPath = request.copyWith(path: "/abc/")
        let requestWithVeryDifferentPath = request.copyWith(path: "/foo/bar/test")
        let requestWithBarelyDifferentParams = request.copyWith(params: ["a":1,"b":3])
        let requestWithOtherReorderedParams = request.copyWith(params: ["b":2,"a":1])
        let requestWithVeryDifferentParams = request.copyWith(params: ["sessionID":"adakjlasdlkjsadljkaffa="])
        let requestWithDifferentBody = request.copyWith(body: "test".data(using: String.Encoding.utf8))
        
        // These requests should be equal!
        XCTAssertEqual(request, request)
        XCTAssertEqual(request, requestWithOtherReorderedParams)
        XCTAssertEqual(request, requestWithDifferentBody)

        // These requests should be unequal!
        XCTAssertNotEqual(request, requestWithDifferentMethod)
        XCTAssertNotEqual(request, requestWithBarelyDifferentPath)
        XCTAssertNotEqual(request, requestWithVeryDifferentPath)
        XCTAssertNotEqual(request, requestWithBarelyDifferentParams)
        XCTAssertNotEqual(request, requestWithVeryDifferentParams)
    }
    
    func testBuilderMethods()
    {
        let gateway:CompositedGateway = CompositedGateway(baseUrl: URL(string:"http://localhost")!)
        
        let request = gateway.internalizeRequest(self.mockRequestDefaults)

        XCTAssertEqual(request.copyWith(method: "TEST").method, "TEST")
        XCTAssertEqual(request.copyWith(path: "/abc").path, "/abc")
        XCTAssertEqual(request.copyWith(params: ["a":"test"]).params?["a"] as? String, "test")
        XCTAssertEqual(request.copyWith(headers: ["b":"test"]).headers?["b"], "test")
        XCTAssertEqual(request.copyWith(body: "test".data(using: String.Encoding.utf8)).body, "test".data(using: String.Encoding.utf8))
        XCTAssertEqual(request.copyWith(body: "test".data(using: String.Encoding.utf8)).body, "test".data(using: String.Encoding.utf8))
        XCTAssertEqual(request.copyWith(followRedirects: false).followRedirects, false)
        XCTAssertEqual(request.copyWith(followRedirects: true).followRedirects, true)

        XCTAssertEqual(request.copyWith(applyContentTypeParsing: false).applyContentTypeParsing, false)
        XCTAssertEqual(request.copyWith(applyContentTypeParsing: true).applyContentTypeParsing, true)
        XCTAssertEqual(request.copyWith(contentTypeOverride: "test/test").contentTypeOverride, "test/test")

        XCTAssertEqual(request.copyWith(allowCachedResponse: false).allowCachedResponse, false)
        XCTAssertEqual(request.copyWith(allowCachedResponse: true).allowCachedResponse, true)

        XCTAssertEqual(request.copyWith(cacheResponseWithExpiration: 10).cacheResponseWithExpiration, 10)
        XCTAssertEqual(request.copyWith(cacheResponseWithExpiration: 100).cacheResponseWithExpiration, 100)
        
        XCTAssertEqual(request.copyWith(customCacheIdentifier: "testCacheIdentifier").customCacheIdentifier, "testCacheIdentifier")
    }
    
    func testInitFromMutableRequestProperties()
    {
        func XCTAssertEqualDictionaries<S, T: Equatable>(_ first: [S:T], _ second: [S:T]) {
            XCTAssert(first == second)
        }
        
        let gateway:CompositedGateway = CompositedGateway(baseUrl: URL(string:"http://localhost")!)
        let props = self.mockRequestDefaults
        let request = gateway.internalizeRequest(self.mockRequestDefaults)

        XCTAssertEqual(request.method, props.method)
        XCTAssertEqual(request.path, props.path)
        XCTAssertEqual(request.body, props.body)
        XCTAssertEqual(request.params?["foo"] as? String, "bar")
        if (request.headers != nil || props.headers != nil)
        {
            XCTAssertEqualDictionaries(request.headers!, props.headers!)
        }
        XCTAssertEqual(request.followRedirects, props.followRedirects)
        XCTAssertEqual(request.applyContentTypeParsing, props.applyContentTypeParsing)
        XCTAssertEqual(request.contentTypeOverride, props.contentTypeOverride)
        XCTAssertEqual(request.allowCachedResponse, props.allowCachedResponse)
        XCTAssertEqual(request.cacheResponseWithExpiration, props.cacheResponseWithExpiration)
        XCTAssertEqual(request.customCacheIdentifier, props.customCacheIdentifier)
    }
}
