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
            "deviceId": clientUniqueId,
            "publicKey": publicKey,
            "module": module
        ]
    }
    
    func ml_encode(string: String) -> String? {
        let generalDelimitersToEncode = ":#[]@"
        let subDelimitersToEncode = "!$&'()*+,;="
        
        var allowedCharacterSet = CharacterSet.urlHostAllowed
        allowedCharacterSet.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        return string.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)
    }
}
