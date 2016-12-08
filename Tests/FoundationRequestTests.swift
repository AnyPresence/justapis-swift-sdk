//
//  FoundationRequestTests.swift
//  JustApisSwiftSDK
//
//  Created by Andrew Palumbo on 12/15/15.
//  Copyright © 2015 AnyPresence. All rights reserved.
//

import XCTest
import JustApisSwiftSDK

///
/// Tests request building when using the FoundationNetworkAdapter
///
class FoundationRequestTests: XCTestCase {

    let anyRequest:OHHTTPStubsTestBlock = { _ in return true }

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        OHHTTPStubs.removeAllStubs()
        super.tearDown()
    }

    ///
    /// Tests basic combination of a scheme:host:port baseURL and a Request path
    ///
    func testSimplePathAppend()
    {
        let baseUrl = "http://localhost"
        let requestPath = "test/request/path"
        let expectedURL = URL(string:"http://localhost/test/request/path")!
        let expectation = self.expectation(description: self.name!)
        
        stub(condition: isHost("localhost"), response: {
            (request:URLRequest) in
            
            XCTAssertEqual(request.url, expectedURL)
            expectation.fulfill()
            return OHHTTPStubsResponse()
        })
        
        let gateway:Gateway = CompositedGateway(baseUrl: URL(string: baseUrl)!)
        gateway.get(requestPath, callback: { _ in
            // No action. The test was performed in the stub.
        })
        
        self.waitForExpectations(timeout: 5, handler: nil)
    }

    ///
    /// Tests basic combination of a scheme:host:port/path baseURL and a Request path
    ///
    func testRelativePathAppend()
    {
        let baseUrl = "http://localhost/api/v1/"
        let requestPath = "test/request/path"
        let expectedURL = URL(string:"http://localhost/api/v1/test/request/path")!
        let expectation = self.expectation(description: self.name!)
        
        stub(condition: isHost("localhost"), response: {
            (request:URLRequest) in
            
            XCTAssertEqual(request.url, expectedURL)
            expectation.fulfill()
            return OHHTTPStubsResponse()
        })
        
        let gateway:Gateway = CompositedGateway(baseUrl: URL(string: baseUrl)!)
        gateway.get(requestPath, callback: { _ in
            // No action. The test was performed in the stub.
        })
        
        self.waitForExpectations(timeout: 5, handler: nil)
    }
    
    ///
    /// Tests that simple query parameters are appended to URL properly
    ///
    func testQueryParameterEncoding()
    {
        let baseUrl = "http://localhost/"
        let requestPath = "test/request/path"
        let queryParams:QueryParameters = ["a":"test", "b":2]
        let expectedURL = URL(string:"http://localhost/test/request/path?a=test&b=2")!
        let alternateExpectedURL = URL(string:"http://localhost/test/request/path?b=2&a=test")!
        let expectation = self.expectation(description: self.name!)
        
        
        stub(condition: isHost("localhost"), response: {
            (request:URLRequest) in
            
            // QueryParamters is a Dictionary and the order of members is not guaranteed.
            // We'll allow that the URL is valid if either order is given here.
            XCTAssert((request.url == expectedURL) || (request.url == alternateExpectedURL))
            expectation.fulfill()
            return OHHTTPStubsResponse()
        })
        
        let gateway:Gateway = CompositedGateway(baseUrl: URL(string: baseUrl)!)
        gateway.get(requestPath, params: queryParams, callback: { _ in
            // No action. The test was performed in the stub.
        })
        
        self.waitForExpectations(timeout: 5, handler: nil)
    }
    
    ///
    /// Tests that array query parameters are appended to URL in traditional style
    ///
    func testArrayQueryParameterEncoding()
    {
        let baseUrl = "http://localhost/"
        let requestPath = "test/request/path"
        let queryParams:QueryParameters = ["a":[1,2]]
        let expectedURL = URL(string:"http://localhost/test/request/path?a%5B%5D=1&a%5B%5D=2")!
        let expectation = self.expectation(description: self.name!)
        
        
        stub(condition: isHost("localhost"), response: {
            (request:URLRequest) in
            
            XCTAssertEqual(request.url, expectedURL)
            expectation.fulfill()
            return OHHTTPStubsResponse()
        })
        
        let gateway:Gateway = CompositedGateway(baseUrl: URL(string: baseUrl)!)
        gateway.get(requestPath, params: queryParams, callback: { _ in
            // No action. The test was performed in the stub.
        })
        
        self.waitForExpectations(timeout: 5, handler: nil)
    }
    
    ///
    /// Tests that array query parameters are appended to URL in traditional style
    ///
    func testEmptyKeyQueryParameterEncoding()
    {
        let baseUrl = "http://localhost/"
        let requestPath = "test/request/path"
        let queryParams:QueryParameters = ["":"test"]
        let expectedURL = URL(string:"http://localhost/test/request/path?=test")!
        let expectation = self.expectation(description: self.name!)
        
        
        stub(condition: isHost("localhost"), response: {
            (request:URLRequest) in
            
            XCTAssertEqual(request.url, expectedURL)
            expectation.fulfill()
            return OHHTTPStubsResponse()
        })
        
        let gateway:Gateway = CompositedGateway(baseUrl: URL(string: baseUrl)!)
        gateway.get(requestPath, params: queryParams, callback: { _ in
            // No action. The test was performed in the stub.
        })
        
        self.waitForExpectations(timeout: 5, handler: nil)
    }

    ///
    /// Tests that array query parameters are appended to URL in traditional style
    ///
    func testEmptyValueQueryParameterEncoding()
    {
        let baseUrl = "http://localhost/"
        let requestPath = "test/request/path"
        let queryParams:QueryParameters = ["a":""]
        let expectedURL = URL(string:"http://localhost/test/request/path?a=")!
        let expectation = self.expectation(description: self.name!)
        
        
        stub(condition: isHost("localhost"), response: {
            (request:URLRequest) in
            
            XCTAssertEqual(request.url, expectedURL)
            expectation.fulfill()
            return OHHTTPStubsResponse()
        })
        
        let gateway:Gateway = CompositedGateway(baseUrl: URL(string: baseUrl)!)
        gateway.get(requestPath, params: queryParams, callback: { _ in
            // No action. The test was performed in the stub.
        })
        
        self.waitForExpectations(timeout: 5, handler: nil)
    }

    ///
    /// Tests that array query parameters are appended to URL in traditional style
    ///
    func testNilValueQueryParameterEncoding()
    {
        let baseUrl = "http://localhost/"
        let requestPath = "test/request/path"
        let queryParams:QueryParameters = ["a":NSNull()]
        let expectedURL = URL(string:"http://localhost/test/request/path?a")!
        let expectation = self.expectation(description: self.name!)
        
        
        stub(condition: isHost("localhost"), response: {
            (request:URLRequest) in
            
            XCTAssertEqual(request.url, expectedURL)
            expectation.fulfill()
            return OHHTTPStubsResponse()
        })
        
        let gateway:Gateway = CompositedGateway(baseUrl: URL(string: baseUrl)!)
        gateway.get(requestPath, params: queryParams, callback: { _ in
            // No action. The test was performed in the stub.
        })
        
        self.waitForExpectations(timeout: 5, handler: nil)
    }
    
    ///
    /// Tests that headers are encoded as expected
    ///
    func testHeaderEncoding()
    {
        let baseUrl = "http://localhost/"
        let requestPath = "test/request/path"
        let expectedURL = URL(string:"http://localhost/test/request/path")!
        let headers:Headers = ["X-Test-Header":"TestValue", "X-Another-Test-Header":"AnotherTestValue"]
        let expectation = self.expectation(description: self.name!)
        
        stub(condition: isHost("localhost"), response: {
            (request:URLRequest) in
            
            XCTAssertEqual(request.url, expectedURL)
            XCTAssertEqual(request.value(forHTTPHeaderField: "X-Test-Header"), "TestValue")
            XCTAssertEqual(request.value(forHTTPHeaderField: "X-Another-Test-Header"), "AnotherTestValue")
            expectation.fulfill()
            return OHHTTPStubsResponse()
        })
        
        let gateway:Gateway = CompositedGateway(baseUrl: URL(string: baseUrl)!)
        gateway.get(requestPath, params: nil, headers: headers, callback: { _ in
            // No action. The test was performed in the stub.
        })
        
        self.waitForExpectations(timeout: 5, handler: nil)
    }
    
    ///
    /// Tests that default headers are applied when using DefaultFieldsRequestPreparer
    ///
    func testDefaultHeaders()
    {
        let baseUrl = "http://localhost"
        let requestPath = "test/request/path"
        let expectedURL = URL(string:"http://localhost/test/request/path")!
        let expectation = self.expectation(description: self.name!)
        
        stub(condition: isHost("localhost"), response: {
            (request:URLRequest) in
            
            XCTAssertEqual(request.url, expectedURL)
            XCTAssertEqual(request.value(forHTTPHeaderField: "X-Test-Header"), "TestValue")
            XCTAssertEqual(request.value(forHTTPHeaderField: "X-Another-Test-Header"), "AnotherTestValue")
            expectation.fulfill()
            return OHHTTPStubsResponse()
        })
        
        let requestPreparer = DefaultFieldsRequestPreparer()
        requestPreparer.defaultHeaders["X-Test-Header"] = "TestValue"
        requestPreparer.defaultHeaders["X-Another-Test-Header"] = "AnotherTestValue"
        let gateway:Gateway = CompositedGateway(baseUrl: URL(string: baseUrl)!, requestPreparer: requestPreparer)
        gateway.get(requestPath, callback: { _ in
            // No action. The test was performed in the stub.
        })
        
        self.waitForExpectations(timeout: 5, handler: nil)
    }
    
    ///
    /// Tests that default query parameters are applied when using a DefaultFieldsRequestPreparer
    ///
    func testDefaultQueryParameters()
    {
        let baseUrl = "http://localhost"
        let requestPath = "test/request/path"
        let expectedURL = URL(string:"http://localhost/test/request/path?a=test&b=2")!
        let alternateExpectedURL = URL(string:"http://localhost/test/request/path?b=2&a=test")!
        let expectation = self.expectation(description: self.name!)
        
        stub(condition: isHost("localhost"), response: {
            (request:URLRequest) in
            
            // QueryParamters is a Dictionary and the order of members is not guaranteed.
            // We'll allow that the URL is valid if either order is given here.
            XCTAssert((request.url == expectedURL) || (request.url == alternateExpectedURL))
            expectation.fulfill()
            return OHHTTPStubsResponse()
        })
        
        let requestPreparer = DefaultFieldsRequestPreparer()
        requestPreparer.defaultQueryParameters["a"] = "test"
        requestPreparer.defaultQueryParameters["b"] = 2
        
        let gateway:Gateway = CompositedGateway(baseUrl: URL(string: baseUrl)!, requestPreparer: requestPreparer)
        gateway.get(requestPath, callback: { _ in
            // No action. The test was performed in the stub.
        })
        
        self.waitForExpectations(timeout: 5, handler: nil)
    }
    
    ///
    /// Tests that the RequestPreparerClosureAdapter can modify requests
    ///
    func testRequestClosureAdapterModification()
    {
        let baseUrl = "http://localhost"
        let requestPath = "test/request/path"
        let expectedURL = URL(string:"http://localhost/alternate/request/path")!
        let expectation = self.expectation(description: self.name!)
        
        stub(condition: isHost("localhost"), response: {
            (request:URLRequest) in
            
            XCTAssertEqual(request.url, expectedURL)
            expectation.fulfill()
            return OHHTTPStubsResponse()
        })
        
        let requestPreparer = RequestPreparerClosureAdapter(closure: {
            (request) in
            return request.copyWith(path: "alternate/request/path")
        })
        let gateway:Gateway = CompositedGateway(baseUrl: URL(string: baseUrl)!, requestPreparer: requestPreparer)
        gateway.get(requestPath, callback: { _ in
            // No action. The test was performed in the stub.
        })
        
        self.waitForExpectations(timeout: 5, handler: nil)
    }
}
