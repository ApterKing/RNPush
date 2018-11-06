//
//  RCTBridge+RNPush.m
//  Pods-RNPush_Example
//
//  Created by wangcong on 2018/9/25.
//

#import "RCTBridge+RNPush.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <React/RCTJavaScriptLoader.h>

static NSString *kAutomaticReferenceCount = @"kAutomaticReferenceCount";
static NSString *kShouldReloadAfterAutomaticReferenceCountEqualZero = @"kShouldReloadAfterAutomaticReferenceCountEqualZero";
static NSString *kExtraModule = @"kExtraModule";

@interface RCTBridgeEnqueueError: NSError

+ (instancetype)errorWithMessage:(NSString *)message;

@end

@implementation RCTBridgeEnqueueError

+ (instancetype)errorWithMessage:(NSString *)message {
    return [RCTBridgeEnqueueError errorWithDomain:@"RNPushManagerErrorDomain" code:-1 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:message, @"RNPushManagerErrorKey", nil]];
}

- (NSString *)localizedDescription {
    return [NSString stringWithFormat:@"errorDomain: %@;  code: %lu;  errorMsg: %@", self.domain, self.code, self.userInfo[@"RNPushManagerErrorKey"]];
}

@end

@interface RCTBridge (RNExtraModule)

// 记录额外加载的module
@property(nonatomic, strong) NSDictionary *extraModule;

// 记录当前被多少个RCTRootView引用
@property (nonatomic, assign) NSInteger automaticReferenceCount;

@end

@implementation RCTBridge (RNPush)

#pragma mark getter setter
- (NSInteger)automaticReferenceCount {
    id object = objc_getAssociatedObject(self, &kAutomaticReferenceCount);
    if (object != nil) {
        return [object integerValue];
    } else {
        return 0;
    }
}

- (void)setAutomaticReferenceCount:(NSInteger)automaticReferenceCount {
    if (self.shouldReloadAfterAutomaticReferenceCountEqualZero && automaticReferenceCount == 0) {
        self.extraModule = [NSDictionary dictionary];
        objc_setAssociatedObject(self, &kShouldReloadAfterAutomaticReferenceCountEqualZero, nil, OBJC_ASSOCIATION_ASSIGN);
        [self reload];
    }
    objc_setAssociatedObject(self, &kAutomaticReferenceCount, [NSNumber numberWithInteger:automaticReferenceCount], OBJC_ASSOCIATION_ASSIGN);
}

- (BOOL)shouldReloadAfterAutomaticReferenceCountEqualZero {
    id object = objc_getAssociatedObject(self, &kShouldReloadAfterAutomaticReferenceCountEqualZero);
    if (object != nil) {
        return [object boolValue];
    } else {
        return false;
    }
}

- (void)setShouldReloadAfterAutomaticReferenceCountEqualZero:(BOOL)shouldReloadAfterAutomaticReferenceCountEqualZero {
    objc_setAssociatedObject(self, &kShouldReloadAfterAutomaticReferenceCountEqualZero, [NSNumber numberWithBool:shouldReloadAfterAutomaticReferenceCountEqualZero], OBJC_ASSOCIATION_ASSIGN);
}

- (NSArray<NSString *> *)modules {
    return self.extraModule.allKeys;
}

- (NSDictionary *)extraModule {
    NSDictionary *extra = objc_getAssociatedObject(self, &kExtraModule);
    if (!extra) {
        extra = [NSDictionary dictionary];
    }
    return extra;
}

- (void)setExtraModule:(NSDictionary *)extraModule {
    if (extraModule) {
        objc_setAssociatedObject(self, &kExtraModule, extraModule, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

#pragma mark 加载额外的module
- (void)enqueueApplicationModule:(NSString *)module at:(NSURL *)bundleURL onSourceLoad:(RCTSourceLoadBlock)onSourceLoad {
    // 已经加载过的module，则不需要重新加载
    if ([self.modules containsObject:module]) {
        onSourceLoad(nil, nil);
        NSLog(@"RNPushManager  enqueueApplicationModule  yes");
        return;
    }
    NSLog(@"RNPushManager  enqueueApplicationModule  no");
    __weak typeof(self) weakSelf = self;
    [RCTJavaScriptLoader loadBundleAtURL:bundleURL onProgress:^(RCTLoadingProgress *progressData) {

    } onComplete:^(NSError *error, RCTSource *source) {
        if (error == nil) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            Class selfClazz = object_getClass(strongSelf);
            NSString *propertyName = @"batchedBridge";
            NSString *selectorName = @"enqueueApplicationScript:url:onComplete:";
            
            // 检测是否存在batchedBridge属性
            if (class_getProperty(selfClazz, propertyName.UTF8String) != nil) {
                RCTBridge *batchedBridge = [strongSelf valueForKey:propertyName];
                Class batchedClazz = object_getClass(batchedBridge);
                SEL selector = NSSelectorFromString(selectorName);
                dispatch_block_t onComplete = ^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSMutableDictionary* extraModule = [NSMutableDictionary dictionaryWithDictionary:strongSelf.extraModule];
                        [extraModule setObject:bundleURL forKey:module];
                        strongSelf.extraModule = extraModule;
                        onSourceLoad(nil, source);
                    });
                };
                
                // 检测是否响应enqueueApplicationScript:url:onComplete:方法
                if (class_respondsToSelector(batchedClazz, selector)) {
                    ((void(*)(id, SEL, NSData*, NSURL*, dispatch_block_t))objc_msgSend)(batchedBridge, selector, source.data, source.url, onComplete);
                } else {
                    onSourceLoad([RCTBridgeEnqueueError errorWithMessage:[NSString stringWithFormat:@"couldn't not response %@", selectorName]], source);
                }
            } else {
                onSourceLoad([RCTBridgeEnqueueError errorWithMessage:[NSString stringWithFormat:@"couldn't not find property %@", propertyName]], source);
            }
        } else {
            onSourceLoad(error, nil);
        }
    }];
}

#pragma 加载资源，此方法如果在RCTBridgeDelete 代理loadSourceForBridge:withBlock:中调用，那么reload将会自动重新加载
- (void)loadSourceWith:(NSArray<NSString *> *)modules at:(NSArray<NSURL *> *)bundleURLs onSourceLoad:(RCTSourceLoadBlock)onSourceLoad {
    NSLog(@"RNPushManager  enqueueApplicationModules  loadSourceWith: %@", modules);
    __weak typeof(self) weakSelf = self;
    
    // 优先加载自身的bundleURL，成功后加载其他extraModule
    [RCTJavaScriptLoader loadBundleAtURL:self.bundleURL onProgress:^(RCTLoadingProgress *progressData) {
        
    } onComplete:^(NSError *error, RCTSource *source) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        // 在reload时还需要将extraModule重新加载，并且将extraModule置空
        if (modules.count != 0) {
            strongSelf.extraModule = [NSDictionary dictionary];
            [self enqueueApplicationModules:modules at:bundleURLs onSourceLoad:onSourceLoad];
        } else {
            onSourceLoad(error, source);
        }
    }];
}

#pragma 同时加载更多module
- (void)enqueueApplicationModules:(NSArray<NSString *> *)modules at:(NSArray<NSURL *> *)bundleURLs onSourceLoad:(RCTSourceLoadBlock)onSourceLoad {
    
    if (modules.count != bundleURLs.count) { return; }

    NSLog(@"RNPushManager  enqueueApplicationModules: %@", modules);
    
    // 需要同步加载完成所有模块，才能够回调
    __block NSLock *sync_lock = [[NSLock alloc] init];
    __block NSInteger index = 0;
    for (int i = 0; i < modules.count; i++) {
        [self enqueueApplicationModule:modules[i] at:bundleURLs[i] onSourceLoad:^(NSError *error, RCTSource *source) {
            [sync_lock lock];
            index += 1;
            if (error) {
                onSourceLoad(error, source);
            } else {
                if (index == modules.count) {
                    onSourceLoad(nil, source);
                }
            }
            [sync_lock unlock];
        }];
    }
}

#pragma mark 移除指定的模块包
- (void)deleteModuleIfNeeded:(NSString *)module {
    if ([self.modules containsObject:module]) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:self.extraModule];
        [dict removeObjectForKey:module];
        self.extraModule = dict;
    }
}

@end
