//
//  CoreTypes.swift
//  JustApisSwiftSDK
//
//  Created by Andrew Palumbo on 12/9/15.
//  Copyright © 2015 AnyPresence. All rights reserved.
//

import Foundation

//
//
// Types used for semantic clarity
//
//

/// The tuple that represents a response or error associated with an attempted request
public typealias RequestResult = (request:Request, response:Response?, error:Error?)

/// A callback which is invoked when a request completes
public typealias RequestCallback = ((RequestResult) -> Void)

/// A semantic alias for Key-Value hashes used as Query Parameters
public typealias QueryParameters = Dictionary<String, Any>

/// A semantic alias for Key-Value hashes used as HTTP Headers
public typealias Headers = Dictionary<String, String>


