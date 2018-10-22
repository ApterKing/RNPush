//
//  RNPushManager+RCT.swift
//  Pods-RNPush_Example
//
//  Created by wangcong on 2018/09/26.
//

import Foundation

/// MARK: 预加载
public extension RNPushManager {
    
    // 获取已经准备好的bridge
    class public func preloadedBridge(for module: String = "Base", potentialPreload: Bool = true) -> RCTBridge? {
        var pool = bridgePool
        var bridge = pool.removeValue(forKey: module)
        if bridge == nil {
            bridge = RNPushManager.bridge(for: module)
        }
        if potentialPreload {  // 为下次可能需要使用到该模块预加载一个bridge
            let potentialBridge = RNPushManager.bridge(for: module)
            pool[module] = potentialBridge
        }
        bridgePool = pool
        return bridge
    }
    
    class func preloadBridge(module: String = "Base") {
        // 预加载前获取当前池中如果存在bridge，则需要invalidate
        for (_, bridge) in bridgePool {
            bridge.invalidate()
        }
        bridgePool.removeAll()
        
        var pool : [String: RCTBridge] = [:]
        let bridge = RCTBridge(delegate: RNPushRCTBridgeDelegate(module), launchOptions: nil)
        pool["Base"] = bridge
        bridgePool = pool
    }
    
    // 创建一个新的bridge
    class func bridge(for module: String) -> RCTBridge? {
        return RCTBridge(delegate: RNPushRCTBridgeDelegate(module), launchOptions: nil)
    }
    
    static fileprivate var kBridgePoolKey = "kBridgePoolKey"
    static fileprivate var bridgePool: [String: RCTBridge] {
        get {
            let pool = objc_getAssociatedObject(self, &kBridgePoolKey) as? [String: RCTBridge]
            return pool ?? [:]
        }
        set {
            objc_setAssociatedObject(self, &kBridgePoolKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

fileprivate class RNPushRCTBridgeDelegate: NSObject, RCTBridgeDelegate {
    
    var module = ""

    init(_ module: String) {
        self.module = module
    }

    func sourceURL(for bridge: RCTBridge!) -> URL! {
//        #if DEBUG
//        return  RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: "index", fallbackResource: nil, fallbackExtension: "js")
//        #else
        return RNPushManager.bridgeBundleURL(for: module)
//        #endif
    }

    func shouldBridgeUseCxxBridge(_ bridge: RCTBridge!) -> Bool {
        return true
    }
    
    /// MARK: 自定义加载方式 ，当bridge.reload()时无需重新添加其他module
    func loadSource(for bridge: RCTBridge!, with loadCallback: RCTSourceLoadBlock!) {
        var modules: [String] = []
        var bundleURLs: [URL] = []
        for module in bridge.modules {
            if let url = RNPushManager.bridgeBundleURL(for: module) {
                modules.append(module)
                bundleURLs.append(url)
            }
        }
        bridge.loadSource(with: modules, at: bundleURLs, onSourceLoad: loadCallback)
    }

}

