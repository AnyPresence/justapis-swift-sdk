//
//  RequestQueueTests.swift
//  JustApisSwiftSDK
//
//  Created by Andrew Palumbo on 1/11/16.
//  Copyright © 2016 AnyPresence. All rights reserved.
//

import XCTest
@testable import JustApisSwiftSDK

class RequestQueueTests: XCTestCase {

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

    func testQueueOperations()
    {
        let queue = InternalRequestQueue()
        let gateway:CompositedGateway = CompositedGateway(baseUrl: URL(string:"http://localhost")!)
        
        let request1 = gateway.internalizeRequest(self.mockRequestDefaults).copyWith(path: "/1")
        let request2 = gateway.internalizeRequest(self.mockRequestDefaults).copyWith(path: "/2")
        let request3 = gateway.internalizeRequest(self.mockRequestDefaults).copyWith(path: "/3")
        let request4 = gateway.internalizeRequest(self.mockRequestDefaults).copyWith(path: "/4")

        queue.appendRequest(request1, callback: nil)
        queue.appendRequest(request2, callback: nil)
        queue.appendRequest(request3, callback: nil)
        queue.appendRequest(request4, callback: nil)
        
        XCTAssertEqual(queue.nextRequest()?.path, "/1")
        XCTAssertEqual(queue.nextRequest()?.path, "/2")
        XCTAssertEqual(queue.nextRequest()?.path, "/3")
        XCTAssertEqual(queue.nextRequest()?.path, "/4")
    }
    
    func testDefaultQueueProcessing()
    {
        let expectation = self.expectation(description: self.name!)
        let gateway:CompositedGateway = CompositedGateway(baseUrl: URL(string:"http://localhost")!)
        gateway.pause()

        stub(condition: isHost("localhost"), response: {
            (request:URLRequest) in
            
            return OHHTTPStubsResponse()
        })

        var numberProcessedRequests = 0
        let callback:RequestCallback = { (result:RequestResult) in
            numberProcessedRequests += 1

            XCTAssert(Thread.isMainThread, "Request Callback should always run on main thread")
            
            if (numberProcessedRequests == 4)
            {
                expectation.fulfill()
            }
        }

        gateway.get("/1", callback: callback)
        gateway.get("/2", callback: callback)
        gateway.get("/3", callback: callback)
        gateway.get("/4", callback: callback)

        XCTAssertEqual(gateway.pendingRequests.count, 4)

        gateway.resume()
        
        self.waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testCancelFirstQueuedRequest()
    {
        let expectation = self.expectation(description: self.name!)
        let gateway:CompositedGateway = CompositedGateway(baseUrl: URL(string:"http://localhost")!)
        gateway.pause()
        
        stub(condition: isHost("localhost"), response: {
            (request:URLRequest) in
            
            return OHHTTPStubsResponse()
        })
        
        var numberProcessedRequests = 0
        let callback:RequestCallback = { (result:RequestResult) in
            numberProcessedRequests += 1
            
            XCTAssertNotEqual(result.request.path, "/1", "A cancelled request should never execute")
            XCTAssert(Thread.isMainThread, "Request Callback should always run on main thread")
            
            if (numberProcessedRequests == 3)
            {
                expectation.fulfill()
            }
        }
        
        gateway.get("/1", callback: callback)
        gateway.get("/2", callback: callback)
        gateway.get("/3", callback: callback)
        gateway.get("/4", callback: callback)
        
        let _ = gateway.cancelRequest(gateway.pendingRequests[0])

        XCTAssertEqual(gateway.pendingRequests.count, 3)
        
        gateway.resume()
        
        self.waitForExpectations(timeout: 5, handler: nil)
    }

    func testCancelMiddleQueuedRequest()
    {
        let expectation = self.expectation(description: self.name!)
        let gateway:CompositedGateway = CompositedGateway(baseUrl: URL(string:"http://localhost")!)
        gateway.pause()
        
        stub(condition: isHost("localhost"), response: {
            (request:URLRequest) in
            
            return OHHTTPStubsResponse()
        })
        
        var numberProcessedRequests = 0
        let callback:RequestCallback = { (result:RequestResult) in
            numberProcessedRequests += 1
            
            XCTAssertNotEqual(result.request.path, "/2", "A cancelled request should never execute")
            XCTAssertNotEqual(result.request.path, "/3", "A cancelled request should never execute")
            XCTAssert(Thread.isMainThread, "Request Callback should always run on main thread")
            
            if (numberProcessedRequests == 2)
            {
                expectation.fulfill()
            }
        }
        
        gateway.get("/1", callback: callback)
        gateway.get("/2", callback: callback)
        gateway.get("/3", callback: callback)
        gateway.get("/4", callback: callback)
        
        let pendingRequests = gateway.pendingRequests
        let _ = gateway.cancelRequest(pendingRequests[1])
        let _ = gateway.cancelRequest(pendingRequests[2])
        
        XCTAssertEqual(gateway.pendingRequests.count, 2)
        
        gateway.resume()
        
        self.waitForExpectations(timeout: 5, handler: nil)
    }

    func testCancelLastQueuedRequest()
    {
        let expectation = self.expectation(description: self.name!)
        let gateway:CompositedGateway = CompositedGateway(baseUrl: URL(string:"http://localhost")!)
        gateway.pause()
        
        stub(condition: isHost("localhost"), response: {
            (request:URLRequest) in
            
            return OHHTTPStubsResponse()
        })
        
        var numberProcessedRequests = 0
        let callback:RequestCallback = { (result:RequestResult) in
            numberProcessedRequests += 1
            
            XCTAssertNotEqual(result.request.path, "/4", "A cancelled request should never execute")
            XCTAssert(Thread.isMainThread, "Request Callback should always run on main thread")
            
            if (numberProcessedRequests == 2)
            {
                expectation.fulfill()
            }
        }
        
        gateway.get("/1", callback: callback)
        gateway.get("/2", callback: callback)
        gateway.get("/3", callback: callback)
        gateway.get("/4", callback: callback)
        
        let pendingRequests = gateway.pendingRequests
        let _ = gateway.cancelRequest(pendingRequests[3])
        
        XCTAssertEqual(gateway.pendingRequests.count, 3)
        
        gateway.resume()
        
        self.waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testJsonCompatibleDictionarySerialization()
    {
        var request = mockRequestDefaults
        
        let json = request.toJsonCompatibleDictionary()
        XCTAssertEqual(json["method"] as? String, request.method)
        XCTAssertEqual(json["path"] as? String, request.path)
        XCTAssertEqual((json["params"] as? QueryParameters)?["foo"] as? String, (request.params!["foo"] as! String))
        XCTAssertEqual((json["headers"] as? Headers)?["foo-header"], request.headers!["foo-header"]!)
        XCTAssertEqual(json["followRedirects"] as? Bool, request.followRedirects)
        XCTAssertEqual(json["applyContentTypeParsing"] as? Bool, request.applyContentTypeParsing)
        XCTAssertEqual(json["contentTypeOverride"] as? String, request.contentTypeOverride)
        XCTAssertEqual(json["allowCachedResponse"] as? Bool, request.allowCachedResponse)
        XCTAssertEqual(json["cacheResponseWithExpiration"] as? UInt, request.cacheResponseWithExpiration)
    }

}
