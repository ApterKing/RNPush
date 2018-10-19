//
//  RCTBridge+RNPush.h
//  Pods-RNPush_Example
//
//  Created by wangcong on 2018/9/25.
//

#import <Foundation/Foundation.h>
#import <React/RCTBridge.h>

@interface RCTBridge (RNPush)

@property (nonatomic, strong, readonly) NSArray<NSString *> *modules;

/// MARK: 额外添加其他业务模块
- (void)enqueueApplicationModule:(NSString *)module at:(NSURL *)bundleURL onSourceLoad:(RCTSourceLoadBlock)onSourceLoad;

/// MARK: 此方法用于存在了其他模块，reload使用，最佳使用方式是在实现RCTBridgeDelegate中loadSourceForBridge:withBlock:调用
- (void)loadSourceWith:(NSArray<NSString *> *)modules at:(NSArray<NSURL *> *)bundleURLs onSourceLoad:(RCTSourceLoadBlock)onSourceLoad;

@end
