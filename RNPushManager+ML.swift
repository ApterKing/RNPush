//
//  RNPushManager+ML.swift
//  Pods-RNPush_Example
//
//  Created by wangcong on 2018/9/21.
//

import UIKit

public extension RNPushManager {
    
    public func ml_downloadIfNeeded(module: String, _ completion: ((_ success: Bool) -> Void)) {
        
    }

}

/// MARK: 检查更新
extension RNPushManager {
    
    fileprivate func ml_check(_ module: String, completion: @escaping ((_ model: CheckModel?, _ error: Error?) -> Void)) {
        request(RNPushManagerApi.check, nil, "POST") { (data, response, error) in
            if let err = error {
                completion(nil, err)
            } else {
                completion(CheckModel.model(from: data), nil)
            }
        }
    }
    
    fileprivate class CheckModel: NSObject {
        var updated: Bool = false   // 是否为最新版本
        var force: Bool = false     // 是否需要强制更新
        var full: Bool = false      // 是否全量更新
        var url: String = ""        // 文件url
        var buildHash: String = ""  // hash
        var module: String = ""     // 模块名称
        
        static func model(from data: Data?) -> CheckModel {
            let model = CheckModel()
            
            return model
        }
    }
}

/// MARK: 与更新有关的状态回执
extension RNPushManager {
    
    fileprivate func ml_success(_ module: String) {
        request(RNPushManagerApi.success, nil, "POST", nil)
    }
    
    fileprivate func ml_pending(_ module: String) {
        request(RNPushManagerApi.pending, nil, "POST", nil)
    }
    
    fileprivate func ml_fail(_ module: String) {
        request(RNPushManagerApi.fail, nil, "POST", nil)
    }

}


/// MARK: API
extension RNPushManager {
    
    fileprivate struct RNPushManagerApi {
        static let check = "/releases/checkUpdate"
        static let success = "/releases/update/success"
        static let pending = "/releases/update/pending"
        static let fail = "/releases/update/fail"
        static let bind = "/projects/bindDevice"
    }
    
}

