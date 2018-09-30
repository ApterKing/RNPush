//
//  RNPushConfig.swift
//  Pods-RNPush_Example
//
//  Created by wangcong on 2018/9/20.
//

import Foundation

class RNPushConfig: NSObject {
   
    fileprivate struct RNPushConfigKey {
        static let deploymentKeyConfigKey = "deploymentKey"
        static let appVersionConfigKey = "appVersion"
        static let buildVersionConfigKey = "buildVersion"
        static let clientUniqueIDConfigKey = "clientUniqueId"
        static let serverURLConfigKey = "serverUrl"
        static let publicKeyConfigKey = "publicKey"
        static let moduleConfigKey = "module"
    }
    
    fileprivate var configInfo: [String: Any] = [:]
    init(_ module: String = "") {
        super.init()
        self.module = module
        
        if let infoDictionary = Bundle.main.infoDictionary {
            deploymentKey = infoDictionary["RNPushDeploymentKey"] as? String ?? ""
            appVersion = infoDictionary["CFBundleShortVersionString"] as? String ?? "1.0.0"
            buildVersion = infoDictionary["CFBundleVersion"] as? String ?? "1"
            serverUrl = infoDictionary["RNPushServerURL"] as? String ?? ""
            publicKey = infoDictionary["RNPushPublicKey"] as? String ?? ""
            
            let userDefaults = UserDefaults(suiteName: "RNPush") ?? UserDefaults.standard
            if deploymentKey == "" {
                deploymentKey = userDefaults.string(forKey: RNPushConfigKey.deploymentKeyConfigKey) ?? ""
            }
            
            if serverUrl == "" {
                serverUrl = userDefaults.string(forKey: RNPushConfigKey.serverURLConfigKey) ?? ""
            }
            
            var clientUniqueID = userDefaults.string(forKey: RNPushConfigKey.clientUniqueIDConfigKey)
            if clientUniqueID == nil {
                clientUniqueID = UIDevice.current.identifierForVendor?.uuidString
                userDefaults.setValue(clientUniqueID!, forKey: RNPushConfigKey.clientUniqueIDConfigKey)
            }
            clientUniqueId = clientUniqueID ?? ""
        }
    }
    
    var deploymentKey: String {
        get {
            return configInfo[RNPushConfigKey.deploymentKeyConfigKey] as? String ?? ""
        }
        set {
            configInfo[RNPushConfigKey.deploymentKeyConfigKey] = newValue
        }
    }
    
    var appVersion: String {
        get {
            return configInfo[RNPushConfigKey.appVersionConfigKey] as? String ?? ""
        }
        set {
            configInfo[RNPushConfigKey.appVersionConfigKey] = newValue
        }
    }
    
    var buildVersion: String {
        get {
            return configInfo[RNPushConfigKey.buildVersionConfigKey] as? String ?? ""
        }
        set {
            configInfo[RNPushConfigKey.buildVersionConfigKey] = newValue
        }
    }
    
    var clientUniqueId: String {
        get {
            return configInfo[RNPushConfigKey.clientUniqueIDConfigKey] as? String ?? ""
        }
        set {
            configInfo[RNPushConfigKey.clientUniqueIDConfigKey] = newValue
        }
    }
    
    var serverUrl: String {
        get {
            return configInfo[RNPushConfigKey.serverURLConfigKey] as? String ?? ""
        }
        set {
            configInfo[RNPushConfigKey.serverURLConfigKey] = newValue
        }
    }
    
    var publicKey: String {
        get {
            return configInfo[RNPushConfigKey.publicKeyConfigKey] as? String ?? ""
        }
        set {
            configInfo[RNPushConfigKey.publicKeyConfigKey] = newValue
        }
    }
    
    var module: String {
        get {
            return configInfo[RNPushConfigKey.moduleConfigKey] as? String ?? ""
        }
        set {
            configInfo[RNPushConfigKey.moduleConfigKey] = newValue
        }
    }
    
}

extension RNPushConfig {
    
    static func register(serverUrl: String, deploymentKey: String) {
        let userDefaults = UserDefaults(suiteName: kSuitNameKey) ?? UserDefaults.standard
        userDefaults.setValue(serverUrl, forKey: RNPushConfigKey.serverURLConfigKey)
        userDefaults.setValue(deploymentKey, forKey: RNPushConfigKey.deploymentKeyConfigKey)
    }
    
}
