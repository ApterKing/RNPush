//
//  RNPushManager+RCT.swift
//  Pods-RNPush_Example
//
//  Created by wangcong on 2018/09/26.
//

import Foundation

/// MARK: 预加载
public extension RNPushManager {
    
    static fileprivate var kPreloadedBridgeKey = "kPreloadedBridgeKey"
    
    class public var preloadedBridge: RCTBridge? {
        get {
            return objc_getAssociatedObject(self, &kPreloadedBridgeKey) as? RCTBridge
        }
        set {
            objc_setAssociatedObject(self, &kPreloadedBridgeKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // 创建一个新的bridge
    class public func bridge(for module: String, extras: [String]? = nil) -> RCTBridge? {
        return RCTBridge(delegate: RNPushRCTBridgeDelegate(module, extras), launchOptions: nil)
    }
    
    class public func preloadBridge(module: String = "Base") {
//        var extras: [String] = []
//        if let preloadedModules = preloadedBridge?.modules {
//            modules.append(contentsOf: preloadedModules)
//        }
        preloadedBridge?.invalidate()
        preloadedBridge = nil
        preloadedBridge = bridge(for: module, extras: nil)
    }
    
}

fileprivate class RNPushRCTBridgeDelegate: NSObject, RCTBridgeDelegate {
    
    var module = ""
    var extras: [String]? = nil
    init(_ module: String, _ extras: [String]? = nil) {
        self.module = module
        self.extras = extras
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
    
    func loadSource(for bridge: RCTBridge!, with loadCallback: RCTSourceLoadBlock!) {
        var modules: [String] = []
        var bundleURLs: [URL] = []
        if extras != nil {
            for module in extras! {
                if let url = RNPushManager.bridgeBundleURL(for: module) {
                    modules.append(module)
                    bundleURLs.append(url)
                }
            }
        }
        bridge.loadSource(with: modules, at: bundleURLs, onSourceLoad: loadCallback)
    }
    
}

