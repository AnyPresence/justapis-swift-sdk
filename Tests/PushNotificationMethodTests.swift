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
        
        let expectedURL = URL(string:"http://localhost/push/\(endpointCodename)/subscribe")!
        
        let expectation = self.expectation(description: self.name!)
        
        stub(condition: isHost("localhost"), response: {
            (request:URLRequest) in
            
            // NSURLSession has a known bug where it strips HTTPBody from the request, making testing
            // more difficult. (5/17/2016) Until this is fixed, we stash the body using NSURLProtocol
            // so we can expect it there in tests.
            // https://github.com/AliSoftware/OHHTTPStubs/wiki/Testing-for-the-request-body-in-your-stubs
            let bodyData = URLProtocol.property(forKey: "HTTPBody", in: request) as? Data

            let body = bodyData != nil ? (try? JSONSerialization.jsonObject(with: bodyData!, options: JSONSerialization.ReadingOptions(rawValue:0))) as? [String : Any] : nil

            XCTAssertEqual(body?["platform"] as? String, platform)
            XCTAssertEqual(body?["channel"] as? String, channel)
            XCTAssertEqual(body?["period"] as? Int, period)
            XCTAssertEqual(body?["name"] as? String, name)
            XCTAssertEqual(body?["token"] as? String, token)
            
            XCTAssertEqual(request.url, expectedURL)
            expectation.fulfill()
            return OHHTTPStubsResponse()
        })
        
        let gateway:PushNotificationSupportingGateway = CompositedGateway(baseUrl: URL(string: baseUrl)!)
        gateway.pushNotifications.subscribe(endpointCodename: endpointCodename, platform: platform, channel: channel, period: period, name: name, token: token, callback: nil)
        
        self.waitForExpectations(timeout: 5, handler: nil)
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
        
        let expectedURL = URL(string:"http://localhost/push/\(endpointCodename)/unsubscribe")!
        
        let expectation = self.expectation(description: self.name!)
        
        stub(condition: isHost("localhost"), response: {
            (request:URLRequest) in
            
            // NSURLSession has a known bug where it strips HTTPBody from the request, making testing
            // more difficult. (5/17/2016) Until this is fixed, we stash the body using NSURLProtocol
            // so we can expect it there in tests.
            // https://github.com/AliSoftware/OHHTTPStubs/wiki/Testing-for-the-request-body-in-your-stubs
            let bodyData = URLProtocol.property(forKey: "HTTPBody", in: request) as? Data
            
            let body = bodyData != nil ? (try? JSONSerialization.jsonObject(with: bodyData!, options: JSONSerialization.ReadingOptions(rawValue:0))) as? [String : Any] : nil
            
            XCTAssertEqual(body?["platform"] as? String, platform)
            XCTAssertEqual(body?["channel"] as? String, channel)
            XCTAssertEqual(body?["name"] as? String, name)
            
            XCTAssertEqual(request.url, expectedURL)
            expectation.fulfill()
            return OHHTTPStubsResponse()
        })
        
        let gateway:PushNotificationSupportingGateway = CompositedGateway(baseUrl: URL(string: baseUrl)!)
        gateway.pushNotifications.unsubscribe(endpointCodename: endpointCodename, platform: platform, channel: channel, name: name, callback: nil)
        
        self.waitForExpectations(timeout: 5, handler: nil)
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
        
        let expectedURL = URL(string:"http://localhost/push/\(endpointCodename)/unsubscribe")!
        
        let expectation = self.expectation(description: self.name!)
        
        stub(condition: isHost("localhost"), response: {
            (request:URLRequest) in
            
            // NSURLSession has a known bug where it strips HTTPBody from the request, making testing
            // more difficult. (5/17/2016) Until this is fixed, we stash the body using NSURLProtocol
            // so we can expect it there in tests.
            // https://github.com/AliSoftware/OHHTTPStubs/wiki/Testing-for-the-request-body-in-your-stubs
            let bodyData = URLProtocol.property(forKey: "HTTPBody", in: request) as? Data
            
            let body = bodyData != nil ? (try? JSONSerialization.jsonObject(with: bodyData!, options: JSONSerialization.ReadingOptions(rawValue:0))) as? [String : Any]: nil
            
            XCTAssertEqual(body?["platform"] as? String, platform)
            XCTAssertEqual(body?["channel"] as? String, channel)
            XCTAssertEqual(body?["token"] as? String, token)
            
            XCTAssertEqual(request.url, expectedURL)
            expectation.fulfill()
            return OHHTTPStubsResponse()
        })
        
        let gateway:PushNotificationSupportingGateway = CompositedGateway(baseUrl: URL(string: baseUrl)!)
        gateway.pushNotifications.unsubscribe(endpointCodename: endpointCodename, platform: platform, channel: channel, token: token, callback: nil)
        
        self.waitForExpectations(timeout: 5, handler: nil)
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
        let payload: NSDictionary = [
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
        
        let expectedURL = URL(string:"http://localhost/push/\(endpointCodename)/publish")!
        
        let expectation = self.expectation(description: self.name!)
        
        stub(condition: isHost("localhost"), response: {
            (request:URLRequest) in
            
            // NSURLSession has a known bug where it strips HTTPBody from the request, making testing
            // more difficult. (5/17/2016) Until this is fixed, we stash the body using NSURLProtocol
            // so we can expect it there in tests.
            // https://github.com/AliSoftware/OHHTTPStubs/wiki/Testing-for-the-request-body-in-your-stubs
            let bodyData = URLProtocol.property(forKey: "HTTPBody", in: request) as? Data
            
            let body = bodyData != nil ? (try? JSONSerialization.jsonObject(with: bodyData!, options: JSONSerialization.ReadingOptions(rawValue:0))) as? NSDictionary : nil
            
            XCTAssertEqual(body?["channel"] as? String, channel)
            XCTAssertEqual(body?["environment"] as? String, environment)
            if  let body = body,
                let bodyPayload = body["payload"] as? NSDictionary,
                let bodyDefault = bodyPayload["default"] as? NSDictionary,
                let bodyDefaultMessage = bodyDefault["message"] as? String,
                let bodyApple = bodyPayload["apple"] as? NSDictionary,
                let bodyAps = bodyApple["aps"] as? NSDictionary,
                let bodyAlert = bodyAps["alert"] as? NSDictionary,
                let bodyAlertMessageBody = bodyAlert["body"] as? String,
                let bodyAlertUrlArgs = bodyAps["url-args"] as? NSArray
            {
                XCTAssertEqual(bodyAlertMessageBody, "A test message")
                XCTAssertEqual(bodyDefaultMessage, "A test message")
                XCTAssertEqual(bodyAlertUrlArgs.count, 0)
            }
            else
            {
                XCTAssert(false, "JSON Body payload was incorrect")
            }
            
            XCTAssertEqual(request.url, expectedURL)
            expectation.fulfill()
            return OHHTTPStubsResponse()
        })
        
        let gateway:PushNotificationSupportingGateway = CompositedGateway(baseUrl: URL(string: baseUrl)!)
        try! gateway.pushNotifications.publish(endpointCodename: endpointCodename, channel: channel, environment: environment, payload: payload, callback: nil)
        
        self.waitForExpectations(timeout: 5, handler: nil)
    }

}
