//
//  RNPushConfig+ML.swift
//  Pods-RNPush_Example
//
//  Created by wangcong on 2018/9/26.
//

import Foundation

/// MARK: ML拆包配置
extension RNPushConfig {
    func ml_params() -> [String: Any] {
        return [
            "deployKey": deploymentKey,
            "appVersion": appVersion,
            "buildVersion": buildVersion,
            "buildHash": "Kw1ZEDakWJRJywqo5_92eqRysXwWMulwC0fikMmPNaU=", // MLHotUpdateManifestManager.share.buildHashKey(moduleName),
            "deviceId": clientUniqueId,
            "publicKey": publicKey,
            "module": module
        ]
    }
}
