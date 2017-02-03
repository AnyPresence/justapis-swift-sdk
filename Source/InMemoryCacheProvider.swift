//
//  InMemoryCacheProvider.swift
//  JustApisSwiftSDK
//
//  Created by Andrew Palumbo on 1/4/16.
//  Copyright © 2016 AnyPresence. All rights reserved.
//

import Foundation

open class InMemoryCacheProvider : CacheProvider
{
    var cache = NSCache<AnyObject, AnyObject>()

    internal class CacheObject : NSObject
    {
        var response:ResponseProperties
        var expiresAt:Date
        
        init(response:ResponseProperties, expiresAt:Date)
        {
            self.response = response
            self.expiresAt = expiresAt
        }
    }
    
    open func cachedResponseForIdentifier(_ identifier:String, callback:CacheProviderCallback)
    {
        // See if a response was stored for this identifier at all
        guard let object:CacheObject = self.cache.object(forKey: identifier as AnyObject) as? CacheObject else
        {
            // Respond that there was no cache entry for this identifier
            callback(nil)
            return
        }
        
        // See if the response is actually valid, and make sure it expires in the future
        let response = object.response
        guard object.expiresAt.timeIntervalSinceNow > 0 else
        {
            // clean out this cache object if it already expired or is invalid
            cache.removeObject(forKey: identifier as AnyObject)

            // Respond that there was no cache entry for this identifier
            callback(nil)
            return
        }

        callback(response)
    }
    
    open func setCachedResponseForIdentifier(_ identifier:String, response:ResponseProperties, expirationSeconds:UInt)
    {
        // Wrap the response in a cache object, including the preferred expiration date
        let cacheObject:CacheObject = CacheObject(response:response, expiresAt: Date(timeIntervalSinceNow: TimeInterval(expirationSeconds)))

        // Insert the response into the cache
        cache.setObject(cacheObject, forKey: identifier as AnyObject)
    }
}
