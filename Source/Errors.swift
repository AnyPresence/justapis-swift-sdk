//
//  Errors.swift
//  JustApisSwiftSDK
//
//  Created by Andrew Palumbo on 12/29/15.
//  Copyright © 2015 AnyPresence. All rights reserved.
//

import Foundation

public let kJustApisSdkErrorDomain = "com.anypresence.justapis-sdk"
public let kJustApisSdkErrorUserInfoContextKey = "justapis-sdk-error-context"
public let kJustApisSdkErrorUserInfoDescriptionKey = NSLocalizedDescriptionKey

internal func createError(_ code:Int, context:AnyObject? = nil, description:String? = nil) -> Error
{
    var userInfo = [AnyHashable: Any]()
    if let context = context
    {
        userInfo[kJustApisSdkErrorUserInfoContextKey] = context
    }
    if let description = description
    {
        userInfo[kJustApisSdkErrorUserInfoDescriptionKey] = description
    }
    
    let error = NSError(domain: kJustApisSdkErrorDomain, code: code, userInfo: (userInfo.count > 0) ? userInfo : nil)
    return error
}
