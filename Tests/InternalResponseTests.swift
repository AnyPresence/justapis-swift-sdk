//
//  InternalResponseTests.swift
//  JustApisSwiftSDK
//
//  Created by Andrew Palumbo on 1/5/16.
//  Copyright © 2016 AnyPresence. All rights reserved.
//

import XCTest
@testable import JustApisSwiftSDK

class InternalResponseTests: XCTestCase {

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
        let gateway:CompositedGateway = CompositedGateway(baseUrl: NSURL(string:"http://localhost")!)
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
            requestedURL: gateway.baseUrl.URLByAppendingPathComponent("/?foo=bar"),
            resolvedURL: gateway.baseUrl,
            statusCode: 400,
            headers: ["test-response-header":"foo bar"],
            body: "test".dataUsingEncoding(NSUTF8StringEncoding),
            parsedBody: "test",
            retreivedFromCache: false)

        return gateway.internalizeResponse(mockResponseDefaults)
    }

    func testBuilderMethods() {
        let response = self.getDefaultMockResponse()
        let altGateway:CompositedGateway = CompositedGateway(baseUrl: NSURL(string:"http://foo")!)

        XCTAssertEqual(response.gateway(altGateway).gateway.baseUrl.absoluteString, "http://foo")
        XCTAssertEqual(response.request(response.request.method("POST")).request.method, "POST")
        XCTAssertEqual(response.requestedURL(NSURL(string:"http://test/")!).requestedURL.absoluteString, "http://test/")
        XCTAssertEqual(response.resolvedURL(NSURL(string:"http://test/alt")!).resolvedURL?.absoluteString, "http://test/alt")
        XCTAssertEqual(response.statusCode(200).statusCode, 200)
        XCTAssertEqual(response.headers(["foo":"value"]).headers["foo"], "value")
        XCTAssertEqual(response.body("foobar".dataUsingEncoding(NSUTF8StringEncoding)).body, "foobar".dataUsingEncoding(NSUTF8StringEncoding))
        XCTAssertEqual(response.parsedBody("foo").parsedBody as? String, "foo")
        XCTAssertEqual(response.retreivedFromCache(false).retreivedFromCache, false)
        XCTAssertEqual(response.retreivedFromCache(true).retreivedFromCache, true)
    }
    
    func testInitFromMutableResponseProperties() {
        let response = self.getDefaultMockResponse()
        
        XCTAssertEqual(response.gateway.baseUrl.absoluteString, "http://localhost")
        XCTAssertEqual(response.request.method, "GET")
        XCTAssertEqual(response.request.path, "/")
        XCTAssertEqual(response.request.params?["foo"] as? String, "bar")
        XCTAssertEqual(response.statusCode, 400)
        XCTAssertEqual(response.headers["test-response-header"], "foo bar")
        XCTAssertEqual(response.body, "test".dataUsingEncoding(NSUTF8StringEncoding))
        XCTAssertEqual(response.parsedBody as? String, "test")
        XCTAssertEqual(response.retreivedFromCache, false)
    }

}
