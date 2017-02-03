//
//  Helpers.swift
//  JustApisSwiftSDK
//
//  Created by Andrew Palumbo on 1/7/16.
//  Copyright © 2016 AnyPresence. All rights reserved.
//

import Foundation

/// Approximates Objective-C's @synchronized locking behavior and syntax.
internal func synchronized<T>(lock: AnyObject, closure: () throws -> T) rethrows -> T {
    objc_sync_enter(lock)
    defer {
        objc_sync_exit(lock)
    }
    return try closure()
}

/// Converts a Dictionary with Optional values to a dictionary with NSNull values in place of nils
internal func dictionaryWithNilsConvertedToNSNulls<Key,Value>(_ dictionary:Dictionary<Key, Value?>) -> Dictionary<Key,Value>
{
    var out = Dictionary<Key, Value>()
    for (key, value) in dictionary
    {
        if let value = value
        {
            out[key] = value
        }
        else
        {
            out[key] = NSNull() as? Value
        }
    }
    return out
}

/// Converts an Array with Optional values to an array with NSNull values in place of nils
internal func arrayWithNilsConvertedToNSNulls<Value>(_ array:Array<Value?>) -> Array<Value>
{
    var out = Array<Value>()
    for value in array
    {
        if let value = value
        {
            out.append(value)
        }
        else
        {
            out.append(NSNull() as! Value)
        }
    }
    return out
}
