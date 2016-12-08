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

    func testBuilderMethods() {
        let response = self.getDefaultMockResponse()
        let altGateway:CompositedGateway = CompositedGateway(baseUrl: URL(string:"http://foo")!)

        XCTAssertEqual(response.copyWith(gateway: altGateway).gateway.baseUrl.absoluteString, "http://foo")
        XCTAssertEqual(response.copyWith(request: response.request.copyWith(method: "POST")).request.method, "POST")
        XCTAssertEqual(response.copyWith(requestedURL: URL(string:"http://test/")!).requestedURL.absoluteString, "http://test/")
        XCTAssertEqual(response.copyWith(resolvedURL: URL(string:"http://test/alt")!).resolvedURL?.absoluteString, "http://test/alt")
        XCTAssertEqual(response.copyWith(statusCode: 200).statusCode, 200)
        XCTAssertEqual(response.copyWith(headers: ["foo":"value"]).headers["foo"], "value")
        XCTAssertEqual(response.copyWith(body: "foobar".data(using: String.Encoding.utf8)).body, "foobar".data(using: String.Encoding.utf8))
        XCTAssertEqual(response.copyWith(parsedBody: "foo").parsedBody as? String, "foo")
        XCTAssertEqual(response.copyWith(retreivedFromCache: false).retreivedFromCache, false)
        XCTAssertEqual(response.copyWith(retreivedFromCache: true).retreivedFromCache, true)
    }
    
    func testInitFromMutableResponseProperties() {
        let response = self.getDefaultMockResponse()
        
        XCTAssertEqual(response.gateway.baseUrl.absoluteString, "http://localhost")
        XCTAssertEqual(response.request.method, "GET")
        XCTAssertEqual(response.request.path, "/")
        XCTAssertEqual(response.request.params?["foo"] as? String, "bar")
        XCTAssertEqual(response.statusCode, 400)
        XCTAssertEqual(response.headers["test-response-header"], "foo bar")
        XCTAssertEqual(response.body, "test".data(using: String.Encoding.utf8))
        XCTAssertEqual(response.parsedBody as? String, "test")
        XCTAssertEqual(response.retreivedFromCache, false)
    }

}
