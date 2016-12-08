//
//  ContentTypeParsingTests.swift
//  JustApisSwiftSDK
//
//  Created by Andrew Palumbo on 1/5/16.
//  Copyright © 2016 AnyPresence. All rights reserved.
//

import XCTest
import JustApisSwiftSDK

class ContentTypeParsingTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testMatchedContentType() {
        let baseUrl = "http://localhost"
        let requestPath = "test/request/path"
        let expectation = self.expectation(description: self.name!)
        
        stub(condition: isHost("localhost"), response: {
            (request:URLRequest) in
            
            return OHHTTPStubsResponse(jsonObject: ["a":123], statusCode: 200, headers: ["Content-Type":"test/data"])
        })

        let parser = ResponseProcessorClosureAdapter(closure: { (response:Response) in
            return (request:response.request, response:response.copyWith(parsedBody: "test"), error:nil)
        })
        
        let gateway:CompositedGateway = CompositedGateway(baseUrl: URL(string:baseUrl)!)
        gateway.setParser(parser, contentType: "test/data")
        
        gateway.get(requestPath, callback: { (result) in
            XCTAssertEqual(result.response?.parsedBody as? String, "test")
            expectation.fulfill()
        })
        self.waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testMatchedContentTypeWithDisabledAutoparse() {
        let baseUrl = "http://localhost"
        let expectation = self.expectation(description: self.name!)
        
        stub(condition: isHost("localhost"), response: {
            (request:URLRequest) in
            
            return OHHTTPStubsResponse(jsonObject: ["a":123], statusCode: 200, headers: ["Content-Type":"test/data"])
        })
        
        let parser = ResponseProcessorClosureAdapter(closure: { (response:Response) in
            return (request:response.request, response:response.copyWith(parsedBody: "test"), error:nil)
        })
        
        let gateway:CompositedGateway = CompositedGateway(baseUrl: URL(string:baseUrl)!)
        gateway.setParser(parser, contentType: "test/data")
        
        var request = gateway.defaultRequestProperties.get
        request.applyContentTypeParsing = false
        
        gateway.submitRequest(request, callback:{ (result) in
            XCTAssertTrue(result.response?.parsedBody == nil)
            expectation.fulfill()
        })
        self.waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testUnmatchedContentType() {
        let baseUrl = "http://localhost"
        let requestPath = "test/request/path"
        let expectation = self.expectation(description: self.name!)
        
        stub(condition: isHost("localhost"), response: {
            (request:URLRequest) in
            
            return OHHTTPStubsResponse(jsonObject: ["a":123], statusCode: 200, headers: ["Content-Type":"nothing/familiar"])
        })
        
        let parser = ResponseProcessorClosureAdapter(closure: { (response:Response) in
            return (request:response.request, response:response.copyWith(parsedBody: "test"), error:nil)
        })
        
        let gateway:CompositedGateway = CompositedGateway(baseUrl: URL(string:baseUrl)!)
        gateway.setParser(parser, contentType: "test/data")
        
        gateway.get(requestPath, callback: { (result) in
            XCTAssertTrue(result.response?.parsedBody == nil)
            expectation.fulfill()
        })
        self.waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testMatchedContentTypeOverride() {
        let baseUrl = "http://localhost"
        let expectation = self.expectation(description: self.name!)
        
        stub(condition: isHost("localhost"), response: {
            (request:URLRequest) in
            
            return OHHTTPStubsResponse(jsonObject: ["a":123], statusCode: 200, headers: ["Content-Type":"nothing/familiar"])
        })
        
        let parser = ResponseProcessorClosureAdapter(closure: { (response:Response) in
            return (request:response.request, response:response.copyWith(parsedBody: "test"), error:nil)
        })
        
        let gateway:CompositedGateway = CompositedGateway(baseUrl: URL(string:baseUrl)!)
        gateway.setParser(parser, contentType: "test/data")
        
        var request = gateway.defaultRequestProperties.get
        request.contentTypeOverride = "test/data"
        
        gateway.submitRequest(request, callback:{ (result) in
            XCTAssertEqual(result.response?.parsedBody as? String, "test")
            expectation.fulfill()
        })
        self.waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testUnmatchedContentTypeOverride() {
        let baseUrl = "http://localhost"
        let expectation = self.expectation(description: self.name!)
        
        stub(condition: isHost("localhost"), response: {
            (request:URLRequest) in
            
            return OHHTTPStubsResponse(jsonObject: ["a":123], statusCode: 200, headers: ["Content-Type":"test/data"])
        })
        
        let parser = ResponseProcessorClosureAdapter(closure: { (response:Response) in
            return (request:response.request, response:response.copyWith(parsedBody: "test"), error:nil)
        })
        
        let gateway:CompositedGateway = CompositedGateway(baseUrl: URL(string:baseUrl)!)
        gateway.setParser(parser, contentType: "test/data")
        
        var request = gateway.defaultRequestProperties.get
        request.contentTypeOverride = "nothing/familiar"
        
        gateway.submitRequest(request, callback:{ (result) in
            XCTAssertTrue(result.response?.parsedBody == nil)
            expectation.fulfill()
        })
        self.waitForExpectations(timeout: 5, handler: nil)
    }
    
    ///
    /// Tests that the JsonResponseProcessor can parse a JSON object in body
    ///
    func testJsonObjectResponse()
    {
        let baseUrl = "http://localhost"
        let requestPath = "test/request/path"
        let expectation = self.expectation(description: self.name!)
        
        stub(condition: isHost("localhost"), response: {
            (request:URLRequest) in
            
            return OHHTTPStubsResponse(jsonObject: ["a":123], statusCode: 200, headers: ["Content-Type":"application/json"])
        })
        
        let gateway:Gateway = JsonGateway(baseUrl: URL(string: baseUrl)!)
        gateway.get(requestPath, callback: { (result) in
            XCTAssertNil(result.error)
            XCTAssert(result.response != nil)
            XCTAssertEqual(result.response!.statusCode, 200)
            XCTAssertNotNil(result.response!.parsedBody as? [String: Any])
            let content = (result.response!.parsedBody as! [String: Any])
            XCTAssertEqual(content["a"] as? Int, 123)
            expectation.fulfill()
        })
        
        self.waitForExpectations(timeout: 5, handler: nil)
    }
    
    ///
    /// Tests that the JsonResponseProcessor can parse a JSON array in body
    ///
    func testJsonArrayResponse()
    {
        let baseUrl = "http://localhost"
        let requestPath = "test/request/path"
        let expectation = self.expectation(description: self.name!)
        
        stub(condition: isHost("localhost"), response: {
            (request:URLRequest) in
            
            return OHHTTPStubsResponse(jsonObject: [123, 456], statusCode: 200, headers: ["Content-Type":"application/json"])
        })
        
        let gateway:Gateway = JsonGateway(baseUrl: URL(string: baseUrl)!)
        gateway.get(requestPath, callback: { (result) in
            XCTAssertNil(result.error)
            XCTAssert(result.response != nil)
            XCTAssertEqual(result.response!.statusCode, 200)
            XCTAssertNotNil(result.response!.parsedBody as? [Any])
            let content = (result.response!.parsedBody as! [Any])
            XCTAssertEqual(content[0] as? Int, 123)
            XCTAssertEqual(content[1] as? Int, 456)
            expectation.fulfill()
        })
        
        self.waitForExpectations(timeout: 5, handler: nil)
    }
    
    ///
    /// Tests that the JsonResponseProcessor produces an error for non-RFC JSON data
    ///
    func testJsonError()
    {
        let baseUrl = "http://localhost"
        let requestPath = "test/request/path"
        let expectation = self.expectation(description: self.name!)
        
        stub(condition: isHost("localhost"), response: {
            (request:URLRequest) in
            
            return OHHTTPStubsResponse(data: "2".data(using: String.Encoding.utf8)! , statusCode: 200, headers: ["Content-Type":"application/json"])
        })
        
        let gateway:Gateway = JsonGateway(baseUrl: URL(string: baseUrl)!)
        gateway.get(requestPath, callback: { (result) in
            XCTAssertNotNil(result.error)
            expectation.fulfill()
        })
        
        self.waitForExpectations(timeout: 5, handler: nil)
    }
}
