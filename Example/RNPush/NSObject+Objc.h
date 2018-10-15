//
//  NSObject+Objc.h
//  RNPush_Example
//
//  Created by wangcong on 2018/10/12.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (Objc)

- (void)enqueueApplicationModule:(NSString *)module at:(NSURL *)bundleURL complection:(typeof(void(^)(NSError *)))complection;

- (void)fuck:(SEL)selector withObjects:(id)object,...;
- (void)fuck;

@end
