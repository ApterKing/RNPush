//
//  NSObject+Objc.m
//  RNPush_Example
//
//  Created by wangcong on 2018/10/12.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//

#import "NSObject+Objc.h"
#import <objc/message.h>

@implementation NSObject (Objc)

- (void)enqueueApplicationModule:(NSString *)module at:(NSURL *)bundleURL complection:(typeof(void (^)(NSError *)))complection {
    
}

- (void)fuck:(SEL)selector withObjects:(id)object, ... {
    id eachObject;
    va_list args;
    if (object) {
        va_start(args, object);
        while ((eachObject = va_arg(args, id))) {}
        va_end(args);
    }
    ((void(*)(id, SEL, va_list))objc_msgSend)(self, selector, args);
}

- (void)fuck {
    NSLog(@"fuck");
}

@end
