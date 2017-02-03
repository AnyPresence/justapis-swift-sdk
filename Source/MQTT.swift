//
//  MQTT.swift
//  JustApisSwiftSDK
//
//  Created by Taha Samad on 11/28/16.
//  Copyright © 2016 AnyPresence. All rights reserved.
//

import Foundation
import CocoaMQTT
import CocoaAsyncSocket

public enum MQTTQoS: UInt8 {
    case qos0 = 0
    case qos1 = 1
    case qos2 = 2
    
    internal init(cocoaMQTTQoS: CocoaMQTTQOS) {
        switch cocoaMQTTQoS {
        case .qos0:
            self = .qos0
        case .qos1:
            self = .qos1
        case .qos2:
            self = .qos2
        }
    }
    
    internal var cocoaMQTTQos: CocoaMQTTQOS {
        get {
            switch self {
            case .qos0:
                return .qos0
            case .qos1:
                return .qos1
            case .qos2:
                return .qos2
            }
        }
    }
}

/// MQTT Error Codes
public enum MQTTError: Error {
    case notConnected
    case unexpected
    //Conn Ack:
    case unacceptableProtocolVersion
    case identifierRejected
    case serverUnavailable
    case badUsernameOrPassword
    case notAuthorized
    case reserved
    
    internal static func errorForConnAck(_ connAck: CocoaMQTTConnAck) -> Error? {
        switch connAck {
        case .accept:
            return nil
        case .unacceptableProtocolVersion:
            return MQTTError.unacceptableProtocolVersion
        case .identifierRejected:
            return MQTTError.identifierRejected
        case .serverUnavailable:
            return MQTTError.serverUnavailable
        case .badUsernameOrPassword:
            return MQTTError.badUsernameOrPassword
        case .notAuthorized:
            return MQTTError.notAuthorized
        case .reserved:
            return MQTTError.reserved
        }
    }
}

///
/// A MQTT Message
///
public struct MQTTMessage {
    public var topic: String
    public var payload: Data
    public var string: String? {
        get {
            return String(data: payload, encoding: .utf8)
        }
    }
    public var retained: Bool
    
    var qos: MQTTQoS!
    var dup: Bool!
    
    var cocoaMQTTMessage: CocoaMQTTMessage {
        get {
            return CocoaMQTTMessage(topic: topic, payload: [UInt8](payload), qos: qos.cocoaMQTTQos, retained: retained, dup: dup)
        }
    }
    
    public init(topic: String, payload: Data, qos: MQTTQoS = .qos2, retained: Bool = false, dup: Bool = false) {
        self.topic = topic
        self.payload = payload
        self.qos = qos
        self.retained = retained
        self.dup = dup
    }
    
    public init(topic: String, string: String, qos: MQTTQoS = .qos2, retained: Bool = false, dup: Bool = false) {
        self.topic = topic
        self.payload = string.data(using: .utf8)!
        self.qos = qos
        self.retained = retained
        self.dup = dup
    }
    
    init(cocoaMQTTMessage: CocoaMQTTMessage) {
        topic = cocoaMQTTMessage.topic
        payload = Data(bytes: cocoaMQTTMessage.payload)
        retained = cocoaMQTTMessage.retained
    }
}

///
/// A delegate for receiving event on MQTT message receive.
///
public protocol MQTTDelegate: class {
    func mqtt(_ mqtt: MQTTMethods, didFinishConnectingWithError error: Error?)
    func mqtt(_ mqtt: MQTTMethods, didDisconnectWithError error: Error?)
    func mqtt(_ mqtt: MQTTMethods, didSubscribeToTopic topic: String)
    func mqtt(_ mqtt: MQTTMethods, didUnsubscribeFromTopic topic: String)
    func mqtt(_ mqtt: MQTTMethods, didPublishMessageWithId id: UInt16)
    func mqtt(_ mqtt: MQTTMethods, didReceiveMessage message: MQTTMessage)
}

///
/// A struct for specifying config for MQTT
///
public struct MQTTConfiguration {
    public var host: String
    public var port: UInt16
    public var clientId: String
    public var username: String
    public var password: String
    public var keepAlive: UInt16
    public var cleanSession: Bool
    public var willMesage: (topic: String, message: String)?
    public weak var delegator: MQTTMethods?
    public weak var delegate: MQTTDelegate?
    
    public static func defaultConfigurationWith(host: String, username: String, password: String) -> MQTTConfiguration {
        return MQTTConfiguration(host: host,
                                 port: 1883,
                                 clientId: "",
                                 username: username,
                                 password: password,
                                 keepAlive: 60,//seconds
                                 cleanSession: true,
                                 willMesage: nil,
                                 delegator: nil,
                                 delegate: nil)
    }
}

///
/// The set of methods available for MQTT Provider
///
public protocol MQTTProvider: class {
    var connected: Bool { get }
    func connect(usingConfig config: MQTTConfiguration, callback: MQTTCallbackWithError?) -> Error?
    func disconnect(_ callback: MQTTCallbackWithError?) -> Error?
    func subscribeTo(topic: String, qos: MQTTQoS, callback: MQTTCallback?) -> Error?
    func unsubscribeFrom(topic: String, callback: MQTTCallback?) -> Error?
    func publish(topic: String, string: String, qos: MQTTQoS, callback: MQTTCallback?) -> MQTTMethodResult
    func publish(message: MQTTMessage, callback: MQTTCallback?) -> MQTTMethodResult
}


//A tuple for representing result of a MQTT Method
public typealias MQTTMethodResult = (identifier: UInt16?, error: Error?)

///
/// The set of methods available for managing MQTT subscriptions and publishing
///
public protocol MQTTMethods: class {
    var connected: Bool { get }
    func defaultConfigurationWith(username: String, password: String, delegate: MQTTDelegate?) -> MQTTConfiguration
    //Same as provider
    func connect(usingConfig config: MQTTConfiguration, callback: MQTTCallbackWithError?) -> Error?
    func disconnect(_ callback: MQTTCallbackWithError?) -> Error?
    func subscribeTo(topic: String, qos: MQTTQoS, callback: MQTTCallback?) -> Error?
    func unsubscribeFrom(topic: String, callback: MQTTCallback?) -> Error?
    func publish(topic: String, string: String, qos: MQTTQoS, callback: MQTTCallback?) -> MQTTMethodResult
    func publish(message: MQTTMessage, callback: MQTTCallback?) -> MQTTMethodResult
}


public class MQTTMethodDispatcher: MQTTMethods {
    
    unowned let gateway: Gateway
    let mqttProvider: MQTTProvider
    
    public var connected: Bool {
        get {
            return mqttProvider.connected
        }
    }

    init(gateway: Gateway, mqttProvider: MQTTProvider) {
        self.gateway = gateway
        self.mqttProvider = mqttProvider
    }
    
    public func defaultConfigurationWith(username: String, password: String, delegate: MQTTDelegate?) -> MQTTConfiguration {
        var config = MQTTConfiguration.defaultConfigurationWith(host: gateway.baseUrl.host!, username: username, password: password)
        config.delegator = self
        config.delegate = delegate
        return config
    }

    public func connect(usingConfig config: MQTTConfiguration, callback: MQTTCallbackWithError?) -> Error? {
        return mqttProvider.connect(usingConfig: config, callback: callback)
    }
    
    public func disconnect(_ callback: MQTTCallbackWithError?) -> Error? {
        return mqttProvider.disconnect(callback)
    }
    
    public func subscribeTo(topic: String, qos: MQTTQoS = .qos2, callback: MQTTCallback?) -> Error? {
        return mqttProvider.subscribeTo(topic: topic, qos: qos, callback: callback)
    }
    
    public func unsubscribeFrom(topic: String, callback: MQTTCallback?) -> Error? {
        return mqttProvider.unsubscribeFrom(topic: topic, callback: callback)
    }
    
    public func publish(topic: String, string: String, qos: MQTTQoS = .qos2, callback: MQTTCallback?) -> MQTTMethodResult {
        return mqttProvider.publish(topic: topic, string: string, qos: qos, callback: callback)
    }
    
    public func publish(message: MQTTMessage, callback: MQTTCallback?) -> MQTTMethodResult {
        return mqttProvider.publish(message: message, callback: callback)
    }
}

///
/// A protocol that exposes MQTT methods on a Gateway
///
public protocol MQTTSupportingGateway : Gateway
{
    /// Methods for managing mqtt subscriptions and publishing
    var mqtt: MQTTMethods { get }
}

///
/// Implementation of the default MQTT subscription/publishing protocol
///
public class DefaultMQTTProvider : MQTTProvider, CocoaMQTTDelegate
{
    private var client: CocoaMQTT!
    private var currentClientConfig: MQTTConfiguration!
    private var callbacks: [String : MQTTCallback] = [:]
    private var connectCallback: MQTTCallbackWithError? = nil
    private var disconnectCallback: MQTTCallbackWithError? = nil
    
    public var connected: Bool {
        get {
            return client?.connState == .connected
        }
    }
    
    public func connect(usingConfig config: MQTTConfiguration, callback: MQTTCallbackWithError?) -> Error? {
        removeClientIfNeeded()
        setupClientFromConfig(config)
        if !client.connect() {
            removeClientIfNeeded()
            return MQTTError.unexpected
        }
        else {
            connectCallback = callback
            return nil
        }
    }
    
    public func disconnect(_ callback: MQTTCallbackWithError?) -> Error? {
        if connected {
            client.disconnect()
            disconnectCallback = callback
            return nil
        }
        else {
            return MQTTError.notConnected
        }
        
    }
    
    public func subscribeTo(topic: String, qos: MQTTQoS, callback: MQTTCallback?) -> Error? {
        if connected {
            let _ = client.subscribe(topic, qos:  qos.cocoaMQTTQos)
            storeIfNeededWithIdentifier(stringIdentifierForSubscribeToTopic(topic), callback: callback)
            return nil
        }
        else {
            return MQTTError.notConnected
        }
    }
    
    public func unsubscribeFrom(topic: String, callback: MQTTCallback?) -> Error? {
        if connected {
            let _ = client.unsubscribe(topic)
            storeIfNeededWithIdentifier(stringIdentifierForUnsubscribeFromTopic(topic), callback: callback)
            return nil
        }
        else {
            return MQTTError.notConnected
        }
    }
    
    public func publish(topic: String, string: String, qos: MQTTQoS, callback: MQTTCallback?) -> MQTTMethodResult {
        if connected {
            let identifier = client.publish(topic, withString: string, qos: qos.cocoaMQTTQos)
            if qos != .qos0 {
                storeIfNeededWithIdentifier(identifier, callback: callback)
            }
            else {
                dispatchDidPublishCallWithIdentifier(identifier, callback: callback)
            }
            return MQTTMethodResult(identifier: identifier, error: nil)
        }
        else {
            return MQTTMethodResult(identifier: nil, error: MQTTError.notConnected)
        }
    }
    
    public func publish(message: MQTTMessage, callback: MQTTCallback?) -> MQTTMethodResult {
        if connected {
            let identifier = client.publish(message.cocoaMQTTMessage)
            if message.qos != .qos0 {
                storeIfNeededWithIdentifier(identifier, callback: callback)
            }
            else {
                dispatchDidPublishCallWithIdentifier(identifier, callback: callback)
            }
            return MQTTMethodResult(identifier: identifier, error: nil)
        }
        else {
            return MQTTMethodResult(identifier: nil, error: MQTTError.notConnected)
        }
    }
    
    //MARK: Publish Callback/Delegate for QoS0
    
    private func dispatchDidPublishCallWithIdentifier(_ identifier: UInt16, callback: MQTTCallback?) {
        let delegate = currentClientConfig.delegate
        let delegator = currentClientConfig.delegator
        if callback != nil || (delegate != nil && delegator != nil) {
            DispatchQueue.main.async {
                callback?()
                if let delegate = delegate, let delegator = delegator {
                    delegate.mqtt(delegator, didPublishMessageWithId: identifier)
                }
            }
        }
    }
    
    //MARK: Client Management
    
    private func removeClientIfNeeded() {
        if connected {
            let _ = disconnect(nil)
        }
        if client != nil {
            client.delegate = nil
            client = nil
            currentClientConfig = nil
            callbacks = [:]
            connectCallback = nil
            disconnectCallback = nil
        }
    }
    
    private func setupClientFromConfig(_ config: MQTTConfiguration) {
        currentClientConfig = config
        client = CocoaMQTT(clientID: config.clientId, host: config.host, port: config.port)
        client.username = config.username
        client.password = config.password
        client.keepAlive = config.keepAlive
        client.cleanSession = config.cleanSession
        if let willMessage = config.willMesage {
            client.willMessage = CocoaMQTTWill(topic: willMessage.topic, message: willMessage.message)
        }
        client.delegate = self
    }
    
    //MARK: Callback Identifiers
    
    private func stringIdentifierForUnsignedInteger(_ identifier: UInt16) -> String {
        return "uint16_\(identifier)"
    }
    
    private func stringIdentifierForSubscribeToTopic(_ topic: String) -> String {
        return "subscribe_\(topic)"
    }
    
    private func stringIdentifierForUnsubscribeFromTopic(_ topic: String) -> String {
        return "unsubscribe_\(topic)"
    }
    
    //MARK: Callback Handling
    
    private func storeIfNeededWithIdentifier(_ identifier: UInt16, callback: MQTTCallback?) {
        storeIfNeededWithIdentifier(stringIdentifierForUnsignedInteger(identifier), callback: callback)
    }
    
    private func storeIfNeededWithIdentifier(_ identifier: String, callback: MQTTCallback?) {
        if let callback = callback {
            callbacks[identifier] = callback
        }
    }
    
    private func dispatchCallbackForIdentifier(_ identifier: UInt16, andRemove remove: Bool) {
        dispatchCallbackForIdentifier(stringIdentifierForUnsignedInteger(identifier), andRemove: remove)
    }
    
    private func dispatchCallbackForIdentifier(_ identifier: String, andRemove remove: Bool) {
        if let callback = callbacks[identifier] {
            if remove {
                callbacks[identifier] = nil
            }
            callback()
        }
    }
    
    //MARK: Sec Trust Evaluation
    
    private class func trustIsValid(_ trust: SecTrust) -> Bool {
        var isValid = false
        
        var result = SecTrustResultType.invalid
        let status = SecTrustEvaluate(trust, &result)
        
        if status == errSecSuccess {
            let unspecified = SecTrustResultType.unspecified
            let proceed = SecTrustResultType.proceed
            isValid = result == unspecified || result == proceed
        }
        
        return isValid
    }
    
    //MARK: CocoaMQTTDelegate
    
    public func mqtt(_ mqtt: CocoaMQTT, didConnect host: String, port: Int) {
        //Do Nothing
    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        let error = MQTTError.errorForConnAck(ack)
        let connectCallback = self.connectCallback
        self.connectCallback = nil
        let delegate = currentClientConfig.delegate
        let delegator = currentClientConfig.delegator
        //Callback & Delegate Call
        if let connectCallback = connectCallback {
            connectCallback(error)
        }
        if let delegate = delegate, let delegator = delegator {
            delegate.mqtt(delegator, didFinishConnectingWithError: error)
        }
    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        //Do Nothing
    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didPublishComplete id: UInt16) {
        let delegate = currentClientConfig.delegate
        let delegator = currentClientConfig.delegator
        //Callback & Delegate Call
        dispatchCallbackForIdentifier(id, andRemove: true)
        if let delegate = delegate, let delegator = delegator {
            delegate.mqtt(delegator, didPublishMessageWithId: id)
        }
    }
    
    
    public func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        let delegate = currentClientConfig.delegate
        let delegator = currentClientConfig.delegator
        //Callback & Delegate Call
        dispatchCallbackForIdentifier(id, andRemove: true)
        if let delegate = delegate, let delegator = delegator {
            delegate.mqtt(delegator, didPublishMessageWithId: id)
        }
    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16 ) {
        let delegate = currentClientConfig.delegate
        let delegator = currentClientConfig.delegator
        //Delegate Call
        if let delegate = delegate, let delegator = delegator {
            delegate.mqtt(delegator, didReceiveMessage: MQTTMessage(cocoaMQTTMessage: message))
        }
    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topic: String) {
        let delegate = currentClientConfig.delegate
        let delegator = currentClientConfig.delegator
        //Callback & Delegate Call
        dispatchCallbackForIdentifier(stringIdentifierForSubscribeToTopic(topic), andRemove: true)
        if let delegate = delegate, let delegator = delegator {
            delegate.mqtt(delegator, didSubscribeToTopic: topic)
        }
    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
        let delegate = currentClientConfig.delegate
        let delegator = currentClientConfig.delegator
        //Callback & Delegate Call
        dispatchCallbackForIdentifier(stringIdentifierForUnsubscribeFromTopic(topic), andRemove: true)
        if let delegate = delegate, let delegator = delegator {
            delegate.mqtt(delegator, didUnsubscribeFromTopic: topic)
        }
    }
    
    public func mqttDidPing(_ mqtt: CocoaMQTT) {
        //Do Nothing
    }
    
    public func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        //Do Nothing
    }
    
    public func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        let connectCallback = self.connectCallback
        self.connectCallback = nil
        let disconnectCallback = self.disconnectCallback
        self.disconnectCallback = nil
        let delegate = currentClientConfig.delegate
        let delegator = currentClientConfig.delegator
        removeClientIfNeeded()
        
        if let connectCallback = connectCallback {
            connectCallback(err ?? MQTTError.unexpected)
        }
        if let disconnectCallback = disconnectCallback {
            disconnectCallback(err)
        }
        if let delegate = delegate, let delegator = delegator {
            delegate.mqtt(delegator, didDisconnectWithError: err)
        }
    }    
}
