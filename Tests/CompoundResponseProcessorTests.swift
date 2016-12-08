//
//  CompoundResponseProcessorTests.swift
//  JustApisSwiftSDK
//
//  Created by Andrew Palumbo on 1/5/16.
//  Copyright © 2016 AnyPresence. All rights reserved.
//

import XCTest
@testable import JustApisSwiftSDK

class CompoundResponseProcessorTests: XCTestCase {

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
    

    func testNoProcessors() {
        let processor = CompoundResponseProcessor()
        let response = getDefaultMockResponse()
        let expectation = self.expectation(description: self.name!)

        XCTAssertEqual(processor.responseProcessors.count, 0)

        processor.processResponse(response, callback: {
            (response:Response, error:Error?) in
            
            XCTAssertTrue(true)
            expectation.fulfill()
        })
        
        self.waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testOneProcessor() {
        let processor = CompoundResponseProcessor()
        let response = getDefaultMockResponse().copyWith(statusCode: 0)
        let expectation = self.expectation(description: self.name!)
        
        XCTAssertEqual(processor.responseProcessors.count, 0)
        
        let statusIncrementingProcessor = ResponseProcessorClosureAdapter(closure: {
            (response:Response) in
            return (request:response.request, response:response.copyWith(statusCode: response.statusCode + 1), error:nil)
        })
        
        processor.responseProcessors.append(statusIncrementingProcessor)
        XCTAssertEqual(processor.responseProcessors.count, 1)

        processor.processResponse(response, callback: {
            (response:Response, error:Error?) in
            
            XCTAssertEqual(response.statusCode, 1)
            expectation.fulfill()
        })
        
        self.waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testManySuccessfulProcessors() {
        let processor = CompoundResponseProcessor()
        let response = getDefaultMockResponse().copyWith(statusCode: 0)
        let expectation = self.expectation(description: self.name!)
        
        XCTAssertEqual(processor.responseProcessors.count, 0)
        
        let statusIncrementingProcessor = ResponseProcessorClosureAdapter(closure: {
            (response:Response) in
            return (request:response.request, response:response.copyWith(statusCode: response.statusCode + 1), error:nil)
        })
        processor.responseProcessors.append(statusIncrementingProcessor)
        processor.responseProcessors.append(statusIncrementingProcessor)
        processor.responseProcessors.append(statusIncrementingProcessor)
        processor.responseProcessors.append(statusIncrementingProcessor)
        processor.responseProcessors.append(statusIncrementingProcessor)
        XCTAssertEqual(processor.responseProcessors.count, 5)

        processor.processResponse(response, callback: {
            (response:Response, error:Error?) in
            
            XCTAssertEqual(response.statusCode, 5)
            expectation.fulfill()
        })
        
        self.waitForExpectations(timeout: 5, handler: nil)
    }

    func testErrorInFirstOfManyProcessors() {
        let processor = CompoundResponseProcessor()
        let response = getDefaultMockResponse().copyWith(statusCode: 0)
        let expectation = self.expectation(description: self.name!)
        
        XCTAssertEqual(processor.responseProcessors.count, 0)
        
        let failingProcessor = ResponseProcessorClosureAdapter(closure: {
            (response:Response) in
            return (request:response.request, response:response, error:createError(1))
        })

        let statusIncrementingProcessor = ResponseProcessorClosureAdapter(closure: {
            (response:Response) in
            return (request:response.request, response:response.copyWith(statusCode: response.statusCode + 1), error:nil)
        })
        processor.responseProcessors.append(failingProcessor)
        processor.responseProcessors.append(statusIncrementingProcessor)
        processor.responseProcessors.append(statusIncrementingProcessor)
        processor.responseProcessors.append(statusIncrementingProcessor)
        processor.responseProcessors.append(statusIncrementingProcessor)
        processor.responseProcessors.append(statusIncrementingProcessor)
        XCTAssertEqual(processor.responseProcessors.count, 6)
        
        processor.processResponse(response, callback: {
            (response:Response, error:Error?) in
            
            XCTAssertEqual(response.statusCode, 0)
            XCTAssertNotNil(error ?? nil)
            expectation.fulfill()
        })
        
        self.waitForExpectations(timeout: 5, handler: nil)
    }
}
