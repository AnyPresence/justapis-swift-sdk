//
//  MQTTTests.swift
//  JustApisSwiftSDK
//
//  Created by Taha Samad on 12/2/16.
//  Copyright © 2016 AnyPresence. All rights reserved.
//

import Foundation

import XCTest
import HKLSocketStubServer
@testable import JustApisSwiftSDK
@testable import CocoaMQTT

class MQTTDelegateState {
    var didConnectCalled: Bool = false
    var connectError: Error? = nil
    var didDisconnectCalled = false
    var disconnectError: Error? = nil
    var didSubscribeCalled = false
    var subscribedTopic: String?
    var didUnsubscribeCalled = false
    var unsubscribedTopic: String? = nil
    var didPublishCalled = false
    var publishedMessageIdentifier: UInt16? = nil
    var didReceiveMessageCalled = false
    var receivedMessage: MQTTMessage? = nil
    
    func reset() {
        didConnectCalled = false
        connectError = nil
        didDisconnectCalled = false
        disconnectError = nil
        didSubscribeCalled = false
        subscribedTopic = nil
        didUnsubscribeCalled = false
        unsubscribedTopic = nil
        didPublishCalled = false
        publishedMessageIdentifier = nil
        didReceiveMessageCalled = false
        receivedMessage = nil
    }
}

extension MQTTDelegateState {//For Testing
    func noneCalled() -> Bool {
        return !didConnectCalled && !didDisconnectCalled && !didSubscribeCalled && !didUnsubscribeCalled && !didPublishCalled && !didReceiveMessageCalled
    }
}

typealias InternalTestCallback = (_ canContinue: Bool) -> Void//canContinue, if some persistent change that had to be made has been made.

class MQTTTests: XCTestCase, MQTTDelegate {
    
    let baseUrlString = "https://www.somehost.com"
    let stubBaseUrlString = "https://localhost"
    let port: UInt16 = kHKLDefaultListenPort
    let username = "someusername"
    let password = "somepassword"
    let clientId = "someclientid"
    let keepAlive = UInt16(2000)
    let willTopic = "/somewilltopic"
    let willMessage = "Some will message."
    let topic = "/sometopic"
    var serverPublishedMessage = "Some Received Message."
    var triggerMessageForServerPublish = "Send me something."
    
    let server = HKLSocketStubServer.shared()!
    let delegateState = MQTTDelegateState()
    var gateway: CompositedGateway! = nil
    
    override func setUp() {
        super.setUp()
        do {
            try ObjC.catchException {
                self.server.start()
            }
        }
        catch {
            //Do nothing
        }
    }
    
    override func tearDown() {
        super.tearDown()
        server.clear()
        server.stop()
        delegateState.reset()
        gateway = nil
    }
    
    func testMQTTDefaultConfigurationMethod() {
        let host = URL(string: baseUrlString)!.host!
        let mqttConfiguration = MQTTConfiguration.defaultConfigurationWith(host: host, username: username, password: password)
        XCTAssertEqual(mqttConfiguration.host, host)
        XCTAssertEqual(mqttConfiguration.username, username)
        XCTAssertEqual(mqttConfiguration.password, password)
    }
    
    func testMQTTError() {
        XCTAssertNil(MQTTError.errorForConnAck(.accept))
        XCTAssertEqual(MQTTError.errorForConnAck(.badUsernameOrPassword) as? MQTTError, MQTTError.badUsernameOrPassword)
        XCTAssertEqual(MQTTError.errorForConnAck(.identifierRejected) as? MQTTError, MQTTError.identifierRejected)
        XCTAssertEqual(MQTTError.errorForConnAck(.notAuthorized) as? MQTTError, MQTTError.notAuthorized)
        XCTAssertEqual(MQTTError.errorForConnAck(.reserved) as? MQTTError, MQTTError.reserved)
        XCTAssertEqual(MQTTError.errorForConnAck(.serverUnavailable) as? MQTTError, MQTTError.serverUnavailable)
        XCTAssertEqual(MQTTError.errorForConnAck(.unacceptableProtocolVersion) as? MQTTError, MQTTError.unacceptableProtocolVersion)
    }
    
    func testMQTTQoS() {
        XCTAssertEqual(MQTTQoS.init(cocoaMQTTQoS: .qos0), .qos0)
        XCTAssertEqual(MQTTQoS.init(cocoaMQTTQoS: .qos1), .qos1)
        XCTAssertEqual(MQTTQoS.init(cocoaMQTTQoS: .qos2), .qos2)
        XCTAssertEqual(MQTTQoS.qos0.cocoaMQTTQos, .qos0)
        XCTAssertEqual(MQTTQoS.qos1.cocoaMQTTQos, .qos1)
        XCTAssertEqual(MQTTQoS.qos2.cocoaMQTTQos, .qos2)
    }
    
    func testMQTTMessage() {
        let someTestMessage = "some test message"
        let someTestMessageData = someTestMessage.data(using: .utf8)!
        
        var message = MQTTMessage(topic: topic, payload: someTestMessageData)
        XCTAssertEqual(message.dup, false)
        XCTAssertEqual(message.retained, false)
        XCTAssertEqual(message.qos, .qos2)
        XCTAssertEqual(message.string, someTestMessage)
        XCTAssertEqual(message.payload, someTestMessageData)
        XCTAssertEqual(message.topic, topic)
        
        message = MQTTMessage(topic: topic, string: someTestMessage)
        XCTAssertEqual(message.dup, false)
        XCTAssertEqual(message.retained, false)
        XCTAssertEqual(message.qos, .qos2)
        XCTAssertEqual(message.string, someTestMessage)
        XCTAssertEqual(message.payload, someTestMessageData)
        XCTAssertEqual(message.topic, topic)
        
        message = MQTTMessage(topic: topic, payload: someTestMessageData, qos: .qos1, retained: true, dup: false)
        XCTAssertEqual(message.dup, false)
        XCTAssertEqual(message.retained, true)
        XCTAssertEqual(message.qos, .qos1)
        XCTAssertEqual(message.string, someTestMessage)
        XCTAssertEqual(message.payload, someTestMessageData)
        XCTAssertEqual(message.topic, topic)
        
        message = MQTTMessage(topic: topic, payload: someTestMessageData, qos: .qos0, retained: false, dup: true)
        XCTAssertEqual(message.dup, true)
        XCTAssertEqual(message.retained, false)
        XCTAssertEqual(message.qos, .qos0)
        XCTAssertEqual(message.string, someTestMessage)
        XCTAssertEqual(message.payload, someTestMessageData)
        XCTAssertEqual(message.topic, topic)

        message = MQTTMessage(topic: topic, string: someTestMessage, qos: .qos2, retained: true, dup: true)
        XCTAssertEqual(message.dup, true)
        XCTAssertEqual(message.retained, true)
        XCTAssertEqual(message.qos, .qos2)
        XCTAssertEqual(message.string, someTestMessage)
        XCTAssertEqual(message.payload, someTestMessageData)
        XCTAssertEqual(message.topic, topic)
        
        var cocoaMessage = message.cocoaMQTTMessage
        XCTAssertEqual(cocoaMessage.qos, .qos2)
        XCTAssertEqual(cocoaMessage.dup, true)
        message = MQTTMessage(cocoaMQTTMessage: cocoaMessage)
        XCTAssertNil(message.dup)
        XCTAssertEqual(message.retained, true)
        XCTAssertNil(message.qos)
        XCTAssertEqual(message.string, someTestMessage)
        XCTAssertEqual(message.payload, someTestMessageData)
        XCTAssertEqual(message.topic, topic)

        message = MQTTMessage(topic: topic, string: someTestMessage, qos: .qos1, retained: true, dup: false)
        XCTAssertEqual(message.dup, false)
        XCTAssertEqual(message.retained, true)
        XCTAssertEqual(message.qos, .qos1)
        XCTAssertEqual(message.string, someTestMessage)
        XCTAssertEqual(message.payload, someTestMessageData)
        XCTAssertEqual(message.topic, topic)
        
        cocoaMessage = message.cocoaMQTTMessage
        XCTAssertEqual(cocoaMessage.qos, .qos1)
        XCTAssertEqual(cocoaMessage.dup, false)
        message = MQTTMessage(cocoaMQTTMessage: cocoaMessage)
        XCTAssertNil(message.dup)
        XCTAssertEqual(message.retained, true)
        XCTAssertNil(message.qos)
        XCTAssertEqual(message.string, someTestMessage)
        XCTAssertEqual(message.payload, someTestMessageData)
        XCTAssertEqual(message.topic, topic)
        
        message = MQTTMessage(topic: topic, string: someTestMessage, qos: .qos0, retained: false, dup: true)
        XCTAssertEqual(message.dup, true)
        XCTAssertEqual(message.retained, false)
        XCTAssertEqual(message.qos, .qos0)
        XCTAssertEqual(message.string, someTestMessage)
        XCTAssertEqual(message.payload, someTestMessageData)
        XCTAssertEqual(message.topic, topic)
        
        cocoaMessage = message.cocoaMQTTMessage
        XCTAssertEqual(cocoaMessage.qos, .qos0)
        XCTAssertEqual(cocoaMessage.dup, true)
        message = MQTTMessage(cocoaMQTTMessage: cocoaMessage)
        XCTAssertNil(message.dup)
        XCTAssertEqual(message.retained, false)
        XCTAssertNil(message.qos)
        XCTAssertEqual(message.string, someTestMessage)
        XCTAssertEqual(message.payload, someTestMessageData)
        XCTAssertEqual(message.topic, topic)
    }
    
    func testCompositeGatewayInit() {
        let myMQTTProvider = DefaultMQTTProvider()
        gateway = CompositedGateway(baseUrl: URL(string: baseUrlString)!, mqttProvider: myMQTTProvider)
        
        let dispatcher = gateway.mqtt as! MQTTMethodDispatcher
        
        XCTAssert(dispatcher.gateway === gateway)
        XCTAssert(dispatcher.mqttProvider === myMQTTProvider)
    }
    
    func testMethodsReturnError() {
        gateway = CompositedGateway(baseUrl: URL(string: baseUrlString)!)
        var config = gateway.mqtt.defaultConfigurationWith(username: username, password: password, delegate: nil)
        
        var error: Error? = nil
        var methodResult: MQTTMethodResult! = nil
        
        let oldHost = config.host
        config.host = ""
        error = gateway.mqtt.connect(usingConfig: config, callback: nil)
        XCTAssertEqual(error as? MQTTError, .unexpected)
        config.host = oldHost
        
        error = gateway.mqtt.disconnect(nil)
        XCTAssertEqual(error as? MQTTError, .notConnected)
        
        error = gateway.mqtt.subscribeTo(topic: topic, qos: .qos2, callback: nil)
        XCTAssertEqual(error as? MQTTError, .notConnected)
        
        let message = MQTTMessage(topic: topic, string: "some test message")
        methodResult = gateway.mqtt.publish(message: message, callback: nil)
        XCTAssertNil(methodResult.identifier)
        XCTAssertNotNil(methodResult.error as? MQTTError)
        XCTAssertEqual(methodResult.error as? MQTTError, .notConnected)
        
        methodResult = gateway.mqtt.publish(topic: topic, string: "some test message", qos: .qos2, callback: nil)
        XCTAssertNil(methodResult.identifier)
        XCTAssertNotNil(methodResult.error as? MQTTError)
        XCTAssertEqual(methodResult.error as? MQTTError, .notConnected)
        
        error = gateway.mqtt.unsubscribeFrom(topic: topic, callback: nil)
        XCTAssertEqual(error as? MQTTError, .notConnected)
    }
    
    //MARK: Tests with Stub Server
    
    func testConnectDisconnect() {
        //Setup:
        let expect = expectation(description: "MQTTTests Connect Disconnect")
        gateway = CompositedGateway(baseUrl: URL(string: stubBaseUrlString)!)
        let config = _configForStubbedGatedway(gateway)
        
        //Test:
        _testConnectCleanFalse(withConfig: config) { (canContinue) in
            guard canContinue else {
                XCTFail("Can not continue")
                expect.fulfill()
                return
            }
            self._testDisconnect { (canContinue) in
                guard canContinue else {
                    XCTFail("Can not continue")
                    expect.fulfill()
                    return
                }
                self._testConnectCleanFalseWithIdentifierError(withConfig: config) { (canContinue) in
                    guard canContinue else {
                        XCTFail("Can not continue")
                        expect.fulfill()
                        return
                    }
                    self._testConnectingToStoppedServer(withConfig: config) { (canContinue) in
                        guard canContinue else {
                            XCTFail("Can not continue")
                            expect.fulfill()
                            return
                        }//No need for guard currently, but incase we need to extend
                        expect.fulfill()
                    }
                }
            }
        }
        
        //Wait:
        waitForExpectations(timeout: 5) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }
    
    func testFullFlow() {
        //Setup:
        let expect = expectation(description: "MQTTTests Full Flow")
        gateway = CompositedGateway(baseUrl: URL(string: stubBaseUrlString)!)
        let config = _configForStubbedGatedway(gateway)
        
        //Test:
        _testConnectCleanTrue(withConfig: config) { (canContinue) in
            guard canContinue else {
                XCTFail("Can not continue")
                expect.fulfill()
                return
            }
            self._testSubscribeQoS0AssumingMessageId2 { (canContinue) in
                guard canContinue else {
                    XCTFail("Can not continue")
                    expect.fulfill()
                    return
                }
                self._testUnsubscribeAssumingMessageId(3) { (canContinue) in
                    guard canContinue else {
                        XCTFail("Can not continue")
                        expect.fulfill()
                        return
                    }
                    self._testSubscribeQoS1AssumingMessageId4 { (canContinue) in
                        guard canContinue else {
                            XCTFail("Can not continue")
                            expect.fulfill()
                            return
                        }
                        self._testUnsubscribeAssumingMessageId(5) { (canContinue) in
                            guard canContinue else {
                                XCTFail("Can not continue")
                                expect.fulfill()
                                return
                            }
                            self._testSubscribeQoS2AssumingMessageId6 { (canContinue) in
                                guard canContinue else {
                                    XCTFail("Can not continue")
                                    expect.fulfill()
                                    return
                                }
                                self._testPublish(0) { (canContinue) in
                                    guard canContinue else {
                                        XCTFail("Can not continue")
                                        expect.fulfill()
                                        return
                                    }
                                    self._testPublish(1) { (canContinue) in
                                        guard canContinue else {
                                            XCTFail("Can not continue")
                                            expect.fulfill()
                                            return
                                        }
                                        self._testPublish(2) { (canContinue) in
                                            guard canContinue else {
                                                XCTFail("Can not continue")
                                                expect.fulfill()
                                                return
                                            }
                                            self._testServerPublish { (canContinue) in
                                                guard canContinue else {
                                                    XCTFail("Can not continue")
                                                    expect.fulfill()
                                                    return
                                                }
                                                self._testUnsubscribeAssumingMessageId(11) { (canContinue) in
                                                    guard canContinue else {
                                                        XCTFail("Can not continue")
                                                        expect.fulfill()
                                                        return
                                                    }
                                                    expect.fulfill()
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        //Wait:
        waitForExpectations(timeout: 5) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }

    //MARK: Internal Test Funcs
    
    //Persistent Change: Connects the Client
    func _testConnectCleanFalse(withConfig config: MQTTConfiguration, completionCallback: @escaping InternalTestCallback) {
        //Set
        var config = config
        config.cleanSession = false
        //Set Stubs
        server.clear()
        _setupConnectCleanFalseStub()
        _setupLogStub()
        //Test
        _testConnect(withConfig: config, completionCallback: completionCallback)
    }
    
    //Persistent Change: Connects the Client
    func _testConnectCleanTrue(withConfig config: MQTTConfiguration, completionCallback: @escaping InternalTestCallback) {
        //Set
        var config = config
        config.cleanSession = true
        //Set Stubs
        server.clear()
        _setupConnectCleanTrueStub()
        _setupLogStub()
        //Test
        _testConnect(withConfig: config, completionCallback: completionCallback)
    }
    
    //Persistent Change: Connects the Client
    func _testConnect(withConfig config: MQTTConfiguration, completionCallback: @escaping InternalTestCallback) {
        //Reset State
        delegateState.reset()
        //Connect successfully with clean = false
        let error = gateway.mqtt.connect(usingConfig: config) { (error) in
            XCTAssertNil(error)
            DispatchQueue.main.async {//Delay for delegate
                //Check Delegate State
                XCTAssertTrue(self.delegateState.didConnectCalled)
                XCTAssertNil(self.delegateState.connectError)
                //Set this to false & check that only this was called
                self.delegateState.didConnectCalled = false
                XCTAssertTrue(self.delegateState.noneCalled())
                //Reset State
                self.delegateState.reset()
                //Done
                completionCallback(error == nil)
            }
        }
        if error != nil {
            XCTFail("Error should have been nil")
            DispatchQueue.main.async {
                completionCallback(false)
            }
        }
    }
    
    //Persistent Change: nil
    func _testConnectCleanFalseWithIdentifierError(withConfig config: MQTTConfiguration, completionCallback: @escaping InternalTestCallback) {
        //Set
        var config = config
        config.cleanSession = false
        config.clientId += "_"
        //Set Stubs
        server.clear()
        _setupConnectCleanFalseWithIdentifierRejectedErrorStub()
        _setupDisconnectStub()
        _setupLogStub()
        //Reset State
        delegateState.reset()
        //Connect fail with clean = false & identfier rejected
        let error = gateway.mqtt.connect(usingConfig: config) { (error) in
            XCTAssertEqual((error as? MQTTError), .identifierRejected)
            DispatchQueue.main.async {//Delay for delegate
                //Check Delegate State
                XCTAssertTrue(self.delegateState.didConnectCalled)
                XCTAssertEqual((self.delegateState.connectError as? MQTTError), .identifierRejected)
                //Set this to false & check that only this was called
                self.delegateState.didConnectCalled = false
                self.delegateState.didDisconnectCalled = false
                XCTAssertTrue(self.delegateState.noneCalled())
                //Done
                completionCallback(true)
            }
        }
        if error != nil {
            XCTFail("Error should have been nil")
            DispatchQueue.main.async {
                completionCallback(true)
            }
        }
    }
    
    //Persistent Change: nil
    func _testConnectingToStoppedServer(withConfig config: MQTTConfiguration, completionCallback: @escaping InternalTestCallback) {
        //Set
        server.clear()
        server.stop()
        //Reset State
        delegateState.reset()
        //Connect fail since server is stopped.
        let error = gateway.mqtt.connect(usingConfig: config) { (error) in
            XCTAssertNotNil(error)
            let errDesc = error?.localizedDescription ?? ""
            DispatchQueue.main.async {//Delay for delegate
                //Check Delegate State
                XCTAssertTrue(self.delegateState.didDisconnectCalled)
                XCTAssertNotNil(self.delegateState.disconnectError)
                let delegateErrDesc = self.delegateState.disconnectError?.localizedDescription ?? ""
                XCTAssertTrue(delegateErrDesc.characters.count > 0)
                XCTAssertEqual(delegateErrDesc, errDesc)
                //Set this to false & check that only this was called
                self.delegateState.didDisconnectCalled = false
                XCTAssertTrue(self.delegateState.noneCalled())
                //Done
                completionCallback(true)
            }
        }
        if error != nil {
            XCTFail("Error should have been nil")
            DispatchQueue.main.async {
                completionCallback(true)
            }
        }
    }

    //Persistent Change: Disconnects Client
    func _testDisconnect(_ completionCallback: @escaping InternalTestCallback) {
        //Set Stub
        server.clear()
        _setupDisconnectStub()
        _setupLogStub()
        //Reset State
        delegateState.reset()
        //Disconnect successfully with clean = false
        let error = gateway.mqtt.disconnect { (error) in
            XCTAssertNil(error)
            DispatchQueue.main.async {//Delay for delegate
                //Check Delegate State
                XCTAssertTrue(self.delegateState.didDisconnectCalled)
                XCTAssertNil(self.delegateState.disconnectError)
                //Set this to false & check that only this was called
                self.delegateState.didDisconnectCalled = false
                XCTAssertTrue(self.delegateState.noneCalled())
                //Done
                completionCallback(error == nil)
            }
        }
        if error != nil {
            XCTFail("Error should have been nil")
            DispatchQueue.main.async {
                completionCallback(false)
            }
        }
    }
    
    //Persistent Change: Subscribes Client to `topic` with qos0. 
    //NOTE: Message Sequence should be such that MessageId == 2
    func _testSubscribeQoS0AssumingMessageId2(_ completionCallback: @escaping InternalTestCallback) {
        //Set Stubs
        server.clear()
        _setupSubscribeQoS0ForMessageId2Stub()
        _setupLogStub()
        //Test
        _testSubscribe(withQoS: .qos0, completionCallback: completionCallback)
    }
    
    //Persistent Change: Subscribes Client to `topic` with qos01
    //NOTE: Message Sequence should be such that MessageId == 4
    func _testSubscribeQoS1AssumingMessageId4(_ completionCallback: @escaping InternalTestCallback) {
        //Set Stubs
        server.clear()
        _setupSubscribeQoS1ForMessageId4Stub()
        _setupLogStub()
        //Test
        _testSubscribe(withQoS: .qos1, completionCallback: completionCallback)
    }
    
    //Persistent Change: Subscribes Client to `topic` with qos2.
    //NOTE: Message Sequence should be such that MessageId == 6
    func _testSubscribeQoS2AssumingMessageId6(_ completionCallback: @escaping InternalTestCallback) {
        //Set Stubs
        server.clear()
        _setupSubscribeQoS2ForMessageId6Stub()
        _setupLogStub()
        //Test
        _testSubscribe(withQoS: .qos2, completionCallback: completionCallback)
    }
    
    //Persistent Change: Subscribes Client to `topic` with qos.
    func _testSubscribe(withQoS qos: MQTTQoS, completionCallback: @escaping InternalTestCallback) {
        //Reset State
        delegateState.reset()
        //Test
        let error = gateway.mqtt.subscribeTo(topic: topic, qos: qos) {
            DispatchQueue.main.async {
                //Check Delegate State
                XCTAssertTrue(self.delegateState.didSubscribeCalled)
                XCTAssertEqual(self.delegateState.subscribedTopic, self.topic)
                //Set this to false & check that only this was called
                self.delegateState.didSubscribeCalled = false
                XCTAssertTrue(self.delegateState.noneCalled())
                //Done
                completionCallback(true)
            }
        }
        if error != nil {
            XCTFail("Error should have been nil")
            DispatchQueue.main.async {
                completionCallback(false)
            }
        }
    }
    
    func _testUnsubscribeAssumingMessageId(_ messageId: Int, completionCallback: @escaping InternalTestCallback) {
        assert(messageId == 3 || messageId == 5 || messageId == 11)
        //Set Stubs
        server.clear()
        switch messageId {
        case 3:
            _setupUnsubscribeForMessageId3Stub()
        case 5:
            _setupUnsubscribeForMessageId5Stub()
        default: //11
            _setupUnsubscribeForMessageId11Stub()
        }
        _setupLogStub()
        //Test
        _testUnsubscribe(completionCallback)
    }
    
    //Persistent Change: Unsubscribes Client from `topic`
    func _testUnsubscribe(_ completionCallback: @escaping InternalTestCallback) {
        //Reset State
        delegateState.reset()
        //Test
        let error = gateway.mqtt.unsubscribeFrom(topic: topic) {
            DispatchQueue.main.async {
                //Check Delegate State
                XCTAssertTrue(self.delegateState.didUnsubscribeCalled)
                XCTAssertEqual(self.delegateState.unsubscribedTopic, self.topic)
                //Set this to false & check that only this was called
                self.delegateState.didUnsubscribeCalled = false
                XCTAssertTrue(self.delegateState.noneCalled())
                //Done
                completionCallback(true)
            }
        }
        if error != nil {
            XCTFail("Error should have been nil")
            DispatchQueue.main.async {
                completionCallback(false)
            }
        }
    }
    
    //Persistent Change: Publishes Message increasing message id.
    func _testPublish(_ index: Int, completionCallback: @escaping InternalTestCallback) {
        assert(index >= 0 && index <= 2)
        //Reset
        delegateState.reset()
        //Set Stubs & Test
        server.clear()
        var identifier: UInt16 = 0
        var methodResult: MQTTMethodResult! = nil
        
        switch index {
        case 0:
            //Set Stubs
            _setupPublish0Stub()
            _setupLogStub()
            //Test
            let message = "Some Message (0) with QoS0, dup: true, retain: false."
            let mqttMessage = MQTTMessage(topic: topic, payload: message.data(using: .utf8)!, qos: .qos0, retained: false, dup: true)
            methodResult = gateway.mqtt.publish(message: mqttMessage) {
                self._validateDidPublish(messageIdentifier: identifier, completionCallback)
            }
        case 1:
            //Set Stubs
            _setupPublish1Stub()
            _setupLogStub()
            //Test
            let message = "Some Message (1) with QoS1, dup: false, retain: true."
            let mqttMessage = MQTTMessage(topic: topic, payload: message.data(using: .utf8)!, qos: .qos1, retained: true, dup: false)
            methodResult = gateway.mqtt.publish(message: mqttMessage) {
                self._validateDidPublish(messageIdentifier: identifier, completionCallback)
            }
        default: //2
            //Set Stubs
            _setupPublish2Stub()
            _setupLogStub()
            //Test
            let message = "Some Message (2) with QoS2, dup: false, retain: false."
            methodResult = gateway.mqtt.publish(topic: topic, string: message, qos: .qos2) {
                self._validateDidPublish(messageIdentifier: identifier, completionCallback)
            }
        }
        if methodResult.identifier == nil || methodResult.error != nil {
            XCTFail("Identifier should have been non-nil. Error should have been nil.")
            DispatchQueue.main.async {
                completionCallback(false)
            }
        }
        else {
            identifier = methodResult.identifier!
        }
    }
    
    func _validateDidPublish(messageIdentifier: UInt16, _ complettionCallback: @escaping InternalTestCallback) {
        DispatchQueue.main.async {
            XCTAssertTrue(self.delegateState.didPublishCalled)
            XCTAssertEqual(messageIdentifier, self.delegateState.publishedMessageIdentifier)
            complettionCallback(true)
        }
    }
    
    //Persistent Change: Publishes Trigger Message increasing message id.
    func _testServerPublish(_ completionCallback: @escaping InternalTestCallback) {
        //Set Stub
        server.clear()
        _setupServerPublishStub()
        _setupLogStub()
        //Reset State
        delegateState.reset()
        //Test
        let methodResult = gateway.mqtt.publish(topic: topic, string: triggerMessageForServerPublish, qos: .qos0, callback: nil)
        if methodResult.identifier == nil || methodResult.error != nil {
            XCTFail("Identifier should have been non-nil. Error should have been nil.")
            DispatchQueue.main.async {
                completionCallback(false)
            }
        }
        else {
            //Wait for message
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                XCTAssertTrue(self.delegateState.didReceiveMessageCalled)
                XCTAssertNotNil(self.delegateState.receivedMessage)
                if let receivedMessage = self.delegateState.receivedMessage {
                    XCTAssertNil(receivedMessage.dup)
                    XCTAssertEqual(receivedMessage.retained, true)
                    XCTAssertNil(receivedMessage.qos)
                    XCTAssertEqual(receivedMessage.string, self.serverPublishedMessage)
                    XCTAssertEqual(receivedMessage.topic, self.topic)
                }
                completionCallback(true)
            }
        }
    }

    //MARK: MQTT Delegate
    
    func mqtt(_ mqtt: MQTTMethods, didFinishConnectingWithError error: Error?) {
        XCTAssertTrue(mqtt === gateway?.mqtt)
        delegateState.didConnectCalled = true
        delegateState.connectError = error
    }
    
    func mqtt(_ mqtt: MQTTMethods, didDisconnectWithError error: Error?) {
        XCTAssertTrue(mqtt === gateway?.mqtt)
        delegateState.didDisconnectCalled = true
        delegateState.disconnectError = error
    }
    
    func mqtt(_ mqtt: MQTTMethods, didSubscribeToTopic topic: String) {
        XCTAssertTrue(mqtt === gateway?.mqtt)
        delegateState.didSubscribeCalled = true
        delegateState.subscribedTopic = topic
    }
    
    func mqtt(_ mqtt: MQTTMethods, didUnsubscribeFromTopic topic: String) {
        XCTAssertTrue(mqtt === gateway?.mqtt)
        delegateState.didUnsubscribeCalled = true
        delegateState.unsubscribedTopic = topic
    }
    
    func mqtt(_ mqtt: MQTTMethods, didPublishMessageWithId id: UInt16) {
        XCTAssertTrue(mqtt === gateway?.mqtt)
        delegateState.didPublishCalled = true
        delegateState.publishedMessageIdentifier = id
    }
    
    func mqtt(_ mqtt: MQTTMethods, didReceiveMessage message: MQTTMessage) {
        XCTAssertTrue(mqtt === gateway?.mqtt)
        delegateState.didReceiveMessageCalled = true
        delegateState.receivedMessage = message
    }
    
    //MARK: Private
    
    private func _configForStubbedGatedway(_ gateway: CompositedGateway) -> MQTTConfiguration {
        var config = gateway.mqtt.defaultConfigurationWith(username: username, password: password, delegate: self)
        config.port = port
        config.clientId = clientId
        config.keepAlive = keepAlive
        config.willMesage = (topic: willTopic, message: willMessage)
        return config
    }
    
    private func _setupLogStub() {
        //Log Stub. This shold be last.
        let logStub = server.tcpStub() as! HKLSocketStubResponse
        (logStub.forData(Data()) as! HKLSocketStubResponse).andCheckData { (data) in
            NSLog("Stub Server Received Data: \(data?.base64EncodedString() ?? "")")
            XCTFail("Stub should not have reached here")
        }
    }
    
    private func _setupConnectCleanFalseStub() {
        //Connect Clean False & Connect Clean False Ack Data
        let connectCleanFalseData = Data(base64Encoded: "EFgABE1RVFQEzAfQAAxzb21lY2xpZW50aWQADi9zb21ld2lsbHRvcGljABJTb21lIHdpbGwgbWVzc2FnZS4ADHNvbWV1c2VybmFtZQAMc29tZXBhc3N3b3Jk")
        let connectCleanFalseAckData = Data(base64Encoded: "IAIAAA==")
        
        //Connect Clean False Stub
        let connectCleanFalseStub = server.tcpStub() as! HKLSocketStubResponse
        (connectCleanFalseStub.forData(connectCleanFalseData) as! HKLSocketStubResponse).responds(connectCleanFalseAckData)
    }
    
    private func _setupConnectCleanFalseWithIdentifierRejectedErrorStub() {
        // Connect Clean False With Error Ack Data
        let connectCleanFalseWithError = Data(base64Encoded: "EFkABE1RVFQEzAfQAA1zb21lY2xpZW50aWRfAA4vc29tZXdpbGx0b3BpYwASU29tZSB3aWxsIG1lc3NhZ2UuAAxzb21ldXNlcm5hbWUADHNvbWVwYXNzd29yZA==")
        let connectCleanFalseWithErrorAck = Data(base64Encoded: "IAIAAg==")
        
        //Connect Clean False With Error Stub
        let connectCleanFalseWithErrorStub = server.tcpStub() as! HKLSocketStubResponse
        (connectCleanFalseWithErrorStub.forData(connectCleanFalseWithError) as! HKLSocketStubResponse).responds(connectCleanFalseWithErrorAck)
    }
    
    private func _setupConnectCleanTrueStub() {
        //Connect Clean True & Connect Clean True Ack Data
        let connectCleanTrueData = Data(base64Encoded: "EFgABE1RVFQEzgfQAAxzb21lY2xpZW50aWQADi9zb21ld2lsbHRvcGljABJTb21lIHdpbGwgbWVzc2FnZS4ADHNvbWV1c2VybmFtZQAMc29tZXBhc3N3b3Jk")
        let connectCleanTrueAckData = Data(base64Encoded: "IAIAAA==")
        
        //Connect Clean True Stub
        let connectCleanTrueStub = server.tcpStub() as! HKLSocketStubResponse
        (connectCleanTrueStub.forData(connectCleanTrueData) as! HKLSocketStubResponse).responds(connectCleanTrueAckData)
    }
    
    private func _setupDisconnectStub() {
        //Disconnect Data
        let disconnectData = Data(base64Encoded: "4AA=")
        
        //Disconnect Stub
        let disconnectStub = server.tcpStub() as! HKLSocketStubResponse
        (disconnectStub.forData(disconnectData) as! HKLSocketStubResponse).andCheckData { (_) in
            NSLog("Disconnect Called")
        }
    }
    
    private func _setupSubscribeQoS0ForMessageId2Stub() {
        //Subscribe QoS0 MessageId 2 Data
        let subscribeQoS0ForMessageId2Data = Data(base64Encoded: "gg8AAgAKL3NvbWV0b3BpYwA=")
        let subackQoS0ForMessageId2Data = Data(base64Encoded: "kAUAAgABAg==")
        
        //Subscribe QoS0 MessageId 2 Stub
        let subscribeQoS0ForMessageId2Stub = server.tcpStub() as! HKLSocketStubResponse
        (subscribeQoS0ForMessageId2Stub.forData(subscribeQoS0ForMessageId2Data) as! HKLSocketStubResponse).responds(subackQoS0ForMessageId2Data)
    }
    
    private func _setupUnsubscribeForMessageId3Stub() {
        //Unsubscribe MessageId 3 Data
        let unsubscribeForMessageId3Data = Data(base64Encoded: "og4AAwAKL3NvbWV0b3BpYw==")
        let unsubackForMessageId3Data = Data(base64Encoded: "sAIAAw==")
        
        //Unsubscribe MessageId 3 Stub
        let subscribeForMessageId3Stub = server.tcpStub() as! HKLSocketStubResponse
        (subscribeForMessageId3Stub.forData(unsubscribeForMessageId3Data) as! HKLSocketStubResponse).responds(unsubackForMessageId3Data)
    }
    
    private func _setupSubscribeQoS1ForMessageId4Stub() {
        //Subscribe QoS1 MessageId 4 Data
        let subscribeQoS1ForMessageId4Data = Data(base64Encoded: "gg8ABAAKL3NvbWV0b3BpYwE=")
        let subackQoS1ForMessageId4Data = Data(base64Encoded: "kAUABAABAg==")
        
        //Subscribe QoS1 MessageId 4 Stub
        let subscribeQoS1ForMessageId4Stub = server.tcpStub() as! HKLSocketStubResponse
        (subscribeQoS1ForMessageId4Stub.forData(subscribeQoS1ForMessageId4Data) as! HKLSocketStubResponse).responds(subackQoS1ForMessageId4Data)
    }
    
    private func _setupUnsubscribeForMessageId5Stub() {
        //Unsubscribe MessageId 5 Data
        let unsubscribeForMessageId5Data = Data(base64Encoded: "og4ABQAKL3NvbWV0b3BpYw==")
        let unsubackForMessageId5Data = Data(base64Encoded: "sAIABQ==")
        
        //Unsubscribe MessageId 5 Stub
        let subscribeForMessageId5Stub = server.tcpStub() as! HKLSocketStubResponse
        (subscribeForMessageId5Stub.forData(unsubscribeForMessageId5Data) as! HKLSocketStubResponse).responds(unsubackForMessageId5Data)
    }
    
    private func _setupSubscribeQoS2ForMessageId6Stub() {
        //Subscribe QoS2 MessageId 6 Data
        let subscribeQoS2ForMessageId6Data = Data(base64Encoded: "gg8ABgAKL3NvbWV0b3BpYwI=")
        let subackQoS2ForMessageId6Data = Data(base64Encoded: "kAUABgABAg==")
        
        //Subscribe QoS2 MessageId 6 Stub
        let subscribeQoS2ForMessageId6Stub = server.tcpStub() as! HKLSocketStubResponse
        (subscribeQoS2ForMessageId6Stub.forData(subscribeQoS2ForMessageId6Data) as! HKLSocketStubResponse).responds(subackQoS2ForMessageId6Data)
    }
    
    //Message: Some Message (0) with QoS0, dup: true, retain: false.
    private func _setupPublish0Stub() {
        //Publish 0 Data
        let publish0Data = Data(base64Encoded: "OEEACi9zb21ldG9waWNTb21lIE1lc3NhZ2UgKDApIHdpdGggUW9TMCwgZHVwOiB0cnVlLCByZXRhaW46IGZhbHNlLg==")!
        
        //Publish 0 Stub
        let publish0Stub = server.tcpStub() as! HKLSocketStubResponse
        (publish0Stub.forData(publish0Data) as! HKLSocketStubResponse).andCheckData { (data) in
            NSLog("Publish 0 Received")
        }
    }
    
    //Message: Some Message (1) with QoS1, dup: false, retain: true.
    private func _setupPublish1Stub() {
        //Publish 1 Data
        let publish1Data = Data(base64Encoded: "M0MACi9zb21ldG9waWMACFNvbWUgTWVzc2FnZSAoMSkgd2l0aCBRb1MxLCBkdXA6IGZhbHNlLCByZXRhaW46IHRydWUu")!
        let publish1AckData = Data(base64Encoded: "QAIACA==")!
        
        //Publish 1 Stub
        let publish1Stub = server.tcpStub() as! HKLSocketStubResponse
        (publish1Stub.forData(publish1Data) as! HKLSocketStubResponse).responds(publish1AckData)
    }
    
    //Message: Some Message (2) with QoS2, dup: false, retain: false.
    private func _setupPublish2Stub() {
        //Publish 2 Data
        let publish2Data = Data(base64Encoded: "NEQACi9zb21ldG9waWMACVNvbWUgTWVzc2FnZSAoMikgd2l0aCBRb1MyLCBkdXA6IGZhbHNlLCByZXRhaW46IGZhbHNlLg==")!
        let publish2RecData = Data(base64Encoded: "UAIACQ==")!
        let publish2RelData = Data(base64Encoded: "YgIACQ==")!
        let publish2CompData = Data(base64Encoded: "cAIACQ==")!
        
        //Publish 2 Stub
        let publish2Stub1 = server.tcpStub() as! HKLSocketStubResponse
        (publish2Stub1.forData(publish2Data) as! HKLSocketStubResponse).responds(publish2RecData)
        let publish2Stub2 = server.tcpStub() as! HKLSocketStubResponse
        (publish2Stub2.forData(publish2RelData) as! HKLSocketStubResponse).responds(publish2CompData)
    }
    
    //Sends`triggerMessageForServerPublish`
    private func _setupServerPublishStub() {
        //Server Publish Stub Data
        let triggerMessageForServerPublishData = Data(base64Encoded: "MB4ACi9zb21ldG9waWNTZW5kIG1lIHNvbWV0aGluZy4=")!
        let serverPublishedData = Data(base64Encoded: "OSIACi9zb21ldG9waWNTb21lIFJlY2VpdmVkIE1lc3NhZ2Uu")!
        
        //Publish 3 Stub
        let serverPublishStub = server.tcpStub() as! HKLSocketStubResponse
        (serverPublishStub.forData(triggerMessageForServerPublishData) as! HKLSocketStubResponse).responds(serverPublishedData)
    }
    
    private func _setupUnsubscribeForMessageId11Stub() {
        //Unsubscribe MessageId 11 Data
        let unsubscribeForMessageId11Data = Data(base64Encoded: "og4ACwAKL3NvbWV0b3BpYw==")
        let unsubackForMessageId11Data = Data(base64Encoded: "sAIACw==")
        
        //Unsubscribe MessageId 11 Stub
        let subscribeForMessageId11Stub = server.tcpStub() as! HKLSocketStubResponse
        (subscribeForMessageId11Stub.forData(unsubscribeForMessageId11Data) as! HKLSocketStubResponse).responds(unsubackForMessageId11Data)
    }
}
