//
//  RNPushConfig+ML.swift
//  Pods-RNPush_Example
//
//  Created by wangcong on 2018/9/26.
//

import Foundation

/// MARK: ML拆包配置
extension RNPushConfig {
    class func ml_config(_ module: String) -> RNPushConfig {
        let config = RNPushConfig(module)
        #if DEBUG
            config.serverUrl = "http://pm.qa.medlinker.com/api/"
            config.deploymentKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoibWVkLXJuLWlvcyIsImVudiI6ImRldmVsb3BtZW50IiwiaWF0IjoxNTMwNjk3MzAyfQ.43XEuT6zm8l9OSiwGoPzDYNl6ULHzBgwCs5U9yNo6r0"
        #else
            config.serverUrl = "https://pm.medlinker.com/api/"
            config.deploymentKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoibWVkLXJuLWlvcyIsImVudiI6InByb2R1Y3Rpb24iLCJpYXQiOjE1MzA2OTczMDJ9.JTtq93c1a-ysiS_kUCZhuvgtRK0_rVJkIvn_968LJPI"
        #endif
        return config
    }
}

extension RNPushConfig {
    func ml_params() -> [String: Any] {
        return [
            "deployKey": deploymentKey,
            "appVersion": appVersion,
            "buildVersion": buildVersion,
            "buildHash": "vXGV4CUB6otO4BIBlmVvf2U8sz9Ez8tX7G_V1amzZ9E=", // MLHotUpdateManifestManager.share.buildHashKey(moduleName),
            "deviceId": clientUniqueId,
            "publicKey": publicKey,
            "module": module
        ]
    }
}
