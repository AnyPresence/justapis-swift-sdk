//
//  ObjC.h
//  JustApisSwiftSDK
//
//  Created by Taha Samad on 12/14/16.
//  Copyright © 2016 AnyPresence. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ObjC : NSObject

+ (BOOL)catchException:(void(^)())tryBlock error:(__autoreleasing NSError **)error;

@end
