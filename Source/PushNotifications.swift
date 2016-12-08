//
//  PushNotifications.swift
//  JustApisSwiftSDK
//
//  Created by Andrew Palumbo on 5/13/16.
//  Copyright © 2016 AnyPresence. All rights reserved.
//

import Foundation

///
/// A protocol that exposes Push Notification methods on a Gateway
///
public protocol PushNotificationSupportingGateway : Gateway
{
    /// Methods for managing push notifications subscriptions and publishing
    var pushNotifications:PushNotificationMethods { get }
}

///
/// The set of methods available for managing Push Notification subscriptions and publishing
///
public protocol PushNotificationMethods {
    func subscribe(endpointCodename:String, platform:String, channel:String, period:Int, name:String, token:String, callback:RequestCallback?)
    
    func unsubscribe(endpointCodename:String, platform: String, channel: String, name:String, callback:RequestCallback?)
    func unsubscribe(endpointCodename:String, platform: String, channel: String, token:String, callback:RequestCallback?)
    
    ///
    /// Sends a payload to a channel, in a provided environment.
    ///
    /// Payload is a hash of push platform specific payloads; 
    /// "default" is sent if a matching push platform isn't found
    ///
    /// Example payload:
    ///   {
    ///      "apple": {"aps":{"alert":{"body":"A test Message"},"url-args":[]}},
    ///      "default": {"message": "A test Message"}
    ///   }
    ///
    ///
    /// May throw a JSON Encoding error if payload cannot be serialized to JSON
    ///
    func publish(endpointCodename:String, channel:String, environment:String, payload:NSDictionary, callback:RequestCallback?) throws
}

///
/// Implements the PushNotificationMethods protocol by dispatching to a PushNotificationsProvider, using Gateway
///
internal class PushNotificationMethodDispatcher : PushNotificationMethods {
    unowned let gateway:Gateway
    let pushNotifcationsProvider:PushNotificationsProvider
    
    init(gateway:Gateway, pushNotificationsProvider:PushNotificationsProvider)
    {
        self.gateway = gateway
        self.pushNotifcationsProvider = pushNotificationsProvider
    }

    func subscribe(endpointCodename:String, platform:String, channel:String, period:Int, name:String, token:String, callback:RequestCallback?)
    {
        self.pushNotifcationsProvider.subscribe(gateway: self.gateway, endpointCodename: endpointCodename, platform: platform, channel: channel, period: period, name: name, token: token, callback: callback)
    }
    
    func unsubscribe(endpointCodename:String, platform: String, channel: String, name:String, callback:RequestCallback?)
    {
        self.pushNotifcationsProvider.unsubscribe(gateway: self.gateway, endpointCodename: endpointCodename, platform: platform, channel: channel, name: name, callback: callback)
    }
    
    func unsubscribe(endpointCodename:String, platform: String, channel: String, token:String, callback:RequestCallback?)
    {
        self.pushNotifcationsProvider.unsubscribe(gateway: self.gateway, endpointCodename: endpointCodename, platform: platform, channel: channel, token: token, callback: callback)
    }
    
    func publish(endpointCodename:String, channel:String, environment:String, payload:NSDictionary, callback:RequestCallback?) throws
    {
        try self.pushNotifcationsProvider.publish(gateway: self.gateway, endpointCodename: endpointCodename, channel: channel, environment: environment, payload: payload, callback: callback)
    }
}

///
/// Protocol that provides Gateway-agnostic push notification methods
///
public protocol PushNotificationsProvider
{
    func subscribe(gateway:Gateway, endpointCodename:String, platform:String, channel:String, period:Int, name:String, token:String, callback:RequestCallback?)
    
    func unsubscribe(gateway:Gateway, endpointCodename:String, platform: String, channel: String, name:String, callback:RequestCallback?)
    func unsubscribe(gateway:Gateway, endpointCodename:String, platform: String, channel: String, token:String, callback:RequestCallback?)
    
    func publish(gateway:Gateway, endpointCodename:String, channel:String, environment:String, payload:NSDictionary, callback:RequestCallback?) throws
}

///
/// Implementation of the default Push Notification subscription/publishing protocol
///
public class DefaultPushNotificationsProvider : PushNotificationsProvider
{
    private func resolvePath(endpointCodename:String, method:String) -> String
    {
        return "/push/\(endpointCodename)/\(method)"
    }
    
    public func subscribe(gateway:Gateway, endpointCodename:String, platform:String, channel:String, period:Int, name:String, token:String, callback:RequestCallback?)
    {
        let path:String = self.resolvePath(endpointCodename: endpointCodename, method: "subscribe")
        let bodyPayload:[String:Any] = [
            "platform": platform,
            "channel": channel,
            "period": period,
            "name": name,
            "token": token
        ]
        
        // We know all parameters are JSON-friendly, so we mute the possible encoding exception
        let body = try! JSONSerialization.data(withJSONObject: bodyPayload, options: JSONSerialization.WritingOptions(rawValue: 0))
        gateway.post(path, params: nil, headers: nil, body: body, callback: callback)
    }

    public func unsubscribe(gateway:Gateway, endpointCodename:String, platform: String, channel: String, name:String, callback:RequestCallback?)
    {
        let path:String = self.resolvePath(endpointCodename: endpointCodename, method: "unsubscribe")
        let bodyPayload:[String:Any] = [
            "platform":platform,
            "channel":channel,
            "name":name
        ]
        let body = try! JSONSerialization.data(withJSONObject: bodyPayload, options: JSONSerialization.WritingOptions(rawValue: 0))
        gateway.post(path, params: nil, headers:nil, body:body, callback: callback)
    }

    public func unsubscribe(gateway:Gateway, endpointCodename:String, platform: String, channel: String, token:String, callback:RequestCallback?)
    {
        let path:String = self.resolvePath(endpointCodename: endpointCodename, method: "unsubscribe")
        let bodyPayload:[String:Any] = [
            "platform":platform,
            "channel":channel,
            "token":token
        ]
        let body = try! JSONSerialization.data(withJSONObject: bodyPayload, options: JSONSerialization.WritingOptions(rawValue: 0))
        gateway.post(path, params: nil, headers:nil, body: body, callback: callback)
    }

    public func publish(gateway:Gateway, endpointCodename:String, channel:String, environment:String, payload:NSDictionary, callback:RequestCallback?) throws
    {
        let path:String = self.resolvePath(endpointCodename: endpointCodename, method: "publish")
        let bodyPayload:[String:Any] = [
            "channel":channel,
            "environment":environment,
            "payload":payload
        ]
        let body = try JSONSerialization.data(withJSONObject: bodyPayload, options: JSONSerialization.WritingOptions(rawValue: 0))
        gateway.post(path, params: nil, headers:nil, body:body, callback: callback)
    }
}



