//
//  PushNotificationMethodTests.swift
//  JustApisSwiftSDK
//
//  Created by Andrew Palumbo on 5/17/16.
//  Copyright © 2016 AnyPresence. All rights reserved.
//

import XCTest
import JustApisSwiftSDK

class PushNotificationMethodTests: XCTestCase {

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
    /// Tests that calls to subscribe(...) generate and submit appropriate-looking requests
    ///
    func testSubscribeRequestGeneration()
    {
        let baseUrl = "http://localhost"

        let endpointCodename = "--endpoint_codename--"
        let platform = "apple"
        let channel = "test"
        let period = 31536000
        let name = "test_name"
        let token = "B9CE9E973D135E429338D733A4142E1E8DCCA829475565025214823AB12CCD3C"
        
        let expectedURL = NSURL(string:"http://localhost/push/\(endpointCodename)/subscribe")!
        
        let expectation = self.expectationWithDescription(self.name!)
        
        stub(isHost("localhost"), response: {
            (request:NSURLRequest) in
            
            // NSURLSession has a known bug where it strips HTTPBody from the request, making testing
            // more difficult. (5/17/2016) Until this is fixed, we stash the body using NSURLProtocol
            // so we can expect it there in tests.
            // https://github.com/AliSoftware/OHHTTPStubs/wiki/Testing-for-the-request-body-in-your-stubs
            let bodyData = NSURLProtocol.propertyForKey("HTTPBody", inRequest: request) as? NSData

            let body:AnyObject? = bodyData != nil ? try? NSJSONSerialization.JSONObjectWithData(bodyData!, options: NSJSONReadingOptions(rawValue:0)) : nil

            XCTAssertEqual(body?["platform"], platform)
            XCTAssertEqual(body?["channel"], channel)
            XCTAssertEqual(body?["period"], period)
            XCTAssertEqual(body?["name"], name)
            XCTAssertEqual(body?["token"], token)
            
            XCTAssertEqual(request.URL, expectedURL)
            expectation.fulfill()
            return OHHTTPStubsResponse()
        })
        
        let gateway:PushNotificationSupportingGateway = CompositedGateway(baseUrl: NSURL(string: baseUrl)!)
        gateway.pushNotifications.subscribe(endpointCodename, platform: platform, channel: channel, period: period, name: name, token: token, callback: nil)
        
        self.waitForExpectationsWithTimeout(5, handler: nil)
    }

    ///
    /// Tests that calls to unsubscribe(...token:) generate and submit appropriate-looking requests
    ///
    func testUnsubscribeTokenRequestGeneration()
    {
        let baseUrl = "http://localhost"
        
        let endpointCodename = "--endpoint_codename--"
        let platform = "test_platform"
        let channel = "test_channel"
        let name = "test_name"
        
        let expectedURL = NSURL(string:"http://localhost/push/\(endpointCodename)/unsubscribe")!
        
        let expectation = self.expectationWithDescription(self.name!)
        
        stub(isHost("localhost"), response: {
            (request:NSURLRequest) in
            
            // NSURLSession has a known bug where it strips HTTPBody from the request, making testing
            // more difficult. (5/17/2016) Until this is fixed, we stash the body using NSURLProtocol
            // so we can expect it there in tests.
            // https://github.com/AliSoftware/OHHTTPStubs/wiki/Testing-for-the-request-body-in-your-stubs
            let bodyData = NSURLProtocol.propertyForKey("HTTPBody", inRequest: request) as? NSData
            
            let body:AnyObject? = bodyData != nil ? try? NSJSONSerialization.JSONObjectWithData(bodyData!, options: NSJSONReadingOptions(rawValue:0)) : nil
            
            XCTAssertEqual(body?["platform"], platform)
            XCTAssertEqual(body?["channel"], channel)
            XCTAssertEqual(body?["name"], name)
            
            XCTAssertEqual(request.URL, expectedURL)
            expectation.fulfill()
            return OHHTTPStubsResponse()
        })
        
        let gateway:PushNotificationSupportingGateway = CompositedGateway(baseUrl: NSURL(string: baseUrl)!)
        gateway.pushNotifications.unsubscribe(endpointCodename, platform: platform, channel: channel, name: name, callback: nil)
        
        self.waitForExpectationsWithTimeout(5, handler: nil)
    }

    ///
    /// Tests that calls to unsubscribe(...name:) generate and submit appropriate-looking requests
    ///
    func testUnsubscribeNameRequestGeneration()
    {
        let baseUrl = "http://localhost"
        
        let endpointCodename = "--endpoint_codename--"
        let platform = "test_platform"
        let channel = "test_channel"
        let token = "B9CE9E973D135E429338D733A4142E1E8DCCA829475565025214823AB12CCD3C"
        
        let expectedURL = NSURL(string:"http://localhost/push/\(endpointCodename)/unsubscribe")!
        
        let expectation = self.expectationWithDescription(self.name!)
        
        stub(isHost("localhost"), response: {
            (request:NSURLRequest) in
            
            // NSURLSession has a known bug where it strips HTTPBody from the request, making testing
            // more difficult. (5/17/2016) Until this is fixed, we stash the body using NSURLProtocol
            // so we can expect it there in tests.
            // https://github.com/AliSoftware/OHHTTPStubs/wiki/Testing-for-the-request-body-in-your-stubs
            let bodyData = NSURLProtocol.propertyForKey("HTTPBody", inRequest: request) as? NSData
            
            let body:AnyObject? = bodyData != nil ? try? NSJSONSerialization.JSONObjectWithData(bodyData!, options: NSJSONReadingOptions(rawValue:0)) : nil
            
            XCTAssertEqual(body?["platform"], platform)
            XCTAssertEqual(body?["channel"], channel)
            XCTAssertEqual(body?["token"], token)
            
            XCTAssertEqual(request.URL, expectedURL)
            expectation.fulfill()
            return OHHTTPStubsResponse()
        })
        
        let gateway:PushNotificationSupportingGateway = CompositedGateway(baseUrl: NSURL(string: baseUrl)!)
        gateway.pushNotifications.unsubscribe(endpointCodename, platform: platform, channel: channel, token: token, callback: nil)
        
        self.waitForExpectationsWithTimeout(5, handler: nil)
    }

    ///
    /// Tests that calls to publish(...) generate and submit appropriate-looking requests
    ///
    func testPublishNameRequestGeneration()
    {
        let baseUrl = "http://localhost"
        
        let endpointCodename = "--endpoint_codename--"
        let channel = "test"
        let environment = "development"
        let payload = [
            "apple": [
                "aps":[
                    "alert":[
                        "body":"A test message"
                    ],
                    "url-args":[]
                ]
            ],
            "default":[
                "message":"A test message"
            ]
        ]
        
        let expectedURL = NSURL(string:"http://localhost/push/\(endpointCodename)/publish")!
        
        let expectation = self.expectationWithDescription(self.name!)
        
        stub(isHost("localhost"), response: {
            (request:NSURLRequest) in
            
            // NSURLSession has a known bug where it strips HTTPBody from the request, making testing
            // more difficult. (5/17/2016) Until this is fixed, we stash the body using NSURLProtocol
            // so we can expect it there in tests.
            // https://github.com/AliSoftware/OHHTTPStubs/wiki/Testing-for-the-request-body-in-your-stubs
            let bodyData = NSURLProtocol.propertyForKey("HTTPBody", inRequest: request) as? NSData
            
            let body:AnyObject? = bodyData != nil ? try? NSJSONSerialization.JSONObjectWithData(bodyData!, options: NSJSONReadingOptions(rawValue:0)) : nil
            
            XCTAssertEqual(body?["channel"], channel)
            XCTAssertEqual(body?["environment"], environment)
            if let body = body as? NSDictionary,
                bodyPayload = body["payload"] as? NSDictionary,
                bodyDefault = bodyPayload["default"] as? NSDictionary,
                bodyDefaultMessage = bodyDefault["message"] as? String,
                bodyApple = bodyPayload["apple"] as? NSDictionary,
                bodyAps = bodyApple["aps"] as? NSDictionary,
                bodyAlert = bodyAps["alert"] as? NSDictionary,
                bodyAlertMessageBody = bodyAlert["body"] as? String,
                bodyAlertUrlArgs = bodyAps["url-args"] as? NSArray
            {
                XCTAssertEqual(bodyAlertMessageBody, "A test message")
                XCTAssertEqual(bodyDefaultMessage, "A test message")
                XCTAssertEqual(bodyAlertUrlArgs.count, 0)
            }
            else
            {
                XCTAssert(false, "JSON Body payload was incorrect")
            }
            
            XCTAssertEqual(request.URL, expectedURL)
            expectation.fulfill()
            return OHHTTPStubsResponse()
        })
        
        let gateway:PushNotificationSupportingGateway = CompositedGateway(baseUrl: NSURL(string: baseUrl)!)
        try! gateway.pushNotifications.publish(endpointCodename, channel: channel, environment: environment, payload: payload as NSDictionary, callback: nil)
        
        self.waitForExpectationsWithTimeout(5, handler: nil)
    }

}
