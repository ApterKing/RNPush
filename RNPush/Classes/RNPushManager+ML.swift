//
//  RNPushManager+ML.swift
//  Pods-RNPush_Example
//
//  Created by wangcong on 2018/9/21.
//

import Foundation

/// MARK: ML拆包管理
public extension RNPushManager {
    
    /// MARK: 检查文件是否需要下载，注意每次调用下载某个某个模块之前一定要检查所依赖的模块是否已经被下载，如果未被下载则需要优先下载
    public func ml_downloadIfNeeded(_ module: String, _ completion: @escaping ((_ success: Bool) -> Void)) {
        ml_check(module) { [weak self] (checkModel, error) in    // 检查是否需要更新
            if error != nil {
                completion(false)
            } else {
                guard let model = checkModel else { return }
                if model.force || !model.updated {
                    self?.download(urlPath: model.url, save: nil, progress: nil, completion: { (path, error) in  // 下载更新
                        if error != nil {
                            completion(false)
                        } else {
                            self?.unzip(path, "/Users/wangcong/Library/Developer/CoreSimulator/Devices/2AB84DD7-3830-40EB-A520-BA4EF210A1F8/data/Containers/Data/Application/DFA28337-FF32-4D36-A32F-13010546CE87/tmp/", nil, completion: { (zipPath, successed, zipError) in   // 解压文件
                                completion(true)
                            })
                        }
                    })
                }
                completion(true)
            }
        }
    }
    
}

/// MARK: 网络相关处理
extension RNPushManager {
    
    fileprivate func ml_check(_ module: String, completion: @escaping ((_ model: CheckModel?, _ error: Error?) -> Void)) {
        let config = RNPushConfig.ml_config(module)
        request(config.serverUrl.appending(RNPushManagerApi.check), config.ml_params(), "POST") { (data, response, error) in
            if let err = error {
                completion(nil, err)
            } else {
                if let json = (try? JSONSerialization.jsonObject(with: data ?? Data(), options: .allowFragments)) as? Dictionary<String, Any> {
                    let jsonCode = json["code"] as? Int64 ?? 0
                    let jsonMsg = json["message"] as? String ?? ""
                    let jsonData = json["data"] as? [String: Any] ?? [:]
                    if jsonCode != 0 {
                        completion(nil, nil)
                    } else {
                        completion(CheckModel.model(from: jsonData), nil)
                    }
                } else {
                    completion(nil, nil)
                }
            }
        }
    }
    
    fileprivate func ml_all() {
        let config = RNPushConfig.ml_config("")
        request(config.serverUrl.appending(RNPushManagerApi.all), config.ml_params(), "POST") { (data, response, error) in
            
        }
    }
    
    fileprivate func ml_success(_ module: String) {
        let config = RNPushConfig.ml_config(module)
        request(config.serverUrl.appending(RNPushManagerApi.success), config.ml_params(), "POST", nil)
    }
    
    fileprivate func ml_pending(_ module: String) {
        let config = RNPushConfig.ml_config(module)
        request(config.serverUrl.appending(RNPushManagerApi.pending), config.ml_params(), "POST", nil)
    }
    
    fileprivate func ml_fail(_ module: String) {
        let config = RNPushConfig.ml_config(module)
        request(config.serverUrl.appending(RNPushManagerApi.fail), config.ml_params(), "POST", nil)
    }
    
    fileprivate struct RNPushManagerApi {
        static let all = "releases/buildhash/lastest/all"
        static let check = "releases/checkUpdate"
        static let success = "releases/update/success"
        static let pending = "releases/update/pending"
        static let fail = "releases/update/fail"
        static let bind = "projects/bindDevice"
    }
    
    fileprivate class CheckModel: NSObject {
        var updated: Bool = false   // 是否为最新版本
        var force: Bool = false     // 是否需要强制更新
        var full: Bool = false      // 是否全量更新
        var url: String = ""        // 文件url
        var buildHash: String = ""  // hash值
        var module: String = ""     // 模块名称
        
        static func model(from data: [String: Any]) -> CheckModel {
            let model = CheckModel()
            model.updated = data["updated"] as? Bool ?? false
            model.force = data["force"] as? Bool ?? false
            model.full = data["full"] as? Bool ?? false
            if let meta = data["meta"] as? Dictionary<String, Any> {
                model.url = meta["url"] as? String ?? ""
                model.buildHash = meta["buildHash"] as? String ?? ""
            }
            return model
        }
    }
}

/// MARK: 读取manifest配置文件
extension RNPushManager {
    
    

    fileprivate class ManifestModel: NSObject {
        var appVersion: String = ""        // 当前发布的版本号
        var minAppVersion: String = ""     // 最小可使用的应用版本
        var buildHash: String = ""         // 模块构建后的hash值
        var routes: [String] = []          // 模块路由，用于跳转，暂时未使用
        var dependency: [String] = []      // 当前模块所依赖的其他模块
    }
}
