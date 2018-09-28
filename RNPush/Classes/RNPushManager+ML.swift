//
//  RNPushManager+ML.swift
//  Pods-RNPush_Example
//
//  Created by wangcong on 2018/9/21.
//

import Foundation

/// MARK: ML拆包管理（公用方法-可供外部调用）
public extension RNPushManager {
    
    /// MARK: 检查文件是否需要下载，注意每次调用下载某个某个模块之前一定要检查所依赖的模块是否已经被下载，如果未被下载则需要优先下载
    public func ml_downloadIfNeeded(_ module: String, _ completion: @escaping ((_ success: Bool) -> Void)) {
//        let groupQueue = DispatchGroup
        ml_check(module) { [weak self] (MLCheckModel, error) in    // 检查是否需要更新
            if error != nil {
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
}

/// MARK: 网络相关处理
extension RNPushManager {
    
    fileprivate func ml_check(_ module: String, completion: @escaping ((_ model: MLCheckModel?, _ error: Error?) -> Void)) {
        let config = RNPushConfig(module)
        request(config.serverUrl.appending(MLRNPushManagerApi.check), config.ml_params(), "POST") { [weak self] (data, response, error) in
            guard let weakSelf = self else { return }
            if let err = error {
                RNPushLog("RNPushManager ml_check error: \(module)  \(String(describing: err))")
                completion(nil, err)
            } else {
                do {
                    if let json = (try JSONSerialization.jsonObject(with: data ?? Data(), options: .allowFragments)) as? [String: Any] {
                        let jsonCode = json["code"] as? Int64 ?? 0
                        let jsonData = json["data"] as? [String: Any] ?? [:]
                        if jsonCode != 0 {
                            completion(nil, nil)
                        } else {
                            let model = MLCheckModel.model(from: jsonData)
                            if !model.shouldUpdate {
                                RNPushLog("RNPushManager ml_check success: \(module)  已经是最新版本")
                                //                    weakSelf.ml_pending(module)
                                weakSelf.download(urlPath: model.url, save: RNPushManager.zipPath(for: module), progress: nil, completion: { (path, error) in  // 下载更新
                                    if error != nil {
                                        completion(model, error)
                                        //                            weakSelf.ml_fail(module)
                                    } else {
                                        weakSelf.unzip(path, RNPushManager.unzipedPath(for: module), nil, completion: { (zipPath, successed, zipError) in   // 解压文件
                                            completion(model, nil)
                                            //                                weakSelf.ml_success(module)
                                        })
                                    }
                                })
                            } else {
                                completion(model, nil)
                            }
                        }
                    }
                } catch let error {
                    RNPushLog("RNPushManager ml_check error catch: \(module)  \(String(describing: error))")
                    completion(nil, error)
                }
            }
        }
    }
    
    fileprivate func ml_all() {
        let config = RNPushConfig("")
        request(config.serverUrl.appending(MLRNPushManagerApi.all), config.ml_params(), "POST") { (data, response, error) in
            
        }
    }
    
    fileprivate func ml_success(_ module: String) {
        RNPushLog("RNPushManager ml_success : \(module)")
        let config = RNPushConfig(module)
        request(config.serverUrl.appending(MLRNPushManagerApi.success), config.ml_params(), "POST", nil)
    }
    
    fileprivate func ml_pending(_ module: String) {
        RNPushLog("RNPushManager ml_pending : \(module)")
        let config = RNPushConfig(module)
        request(config.serverUrl.appending(MLRNPushManagerApi.pending), config.ml_params(), "POST", nil)
    }
    
    fileprivate func ml_fail(_ module: String) {
        RNPushLog("RNPushManager ml_fail : \(module)")
        let config = RNPushConfig(module)
        request(config.serverUrl.appending(MLRNPushManagerApi.fail), config.ml_params(), "POST", nil)
    }
    
    fileprivate struct MLRNPushManagerApi {
        static let all = "/releases/buildhash/lastest/all"
        static let check = "/releases/checkUpdate"
        static let success = "/releases/update/success"
        static let pending = "/releases/update/pending"
        static let fail = "/releases/update/fail"
        static let bind = "/projects/bindDevice"
    }
    
    fileprivate class MLCheckModel: NSObject {
        var updated: Bool = false   // 是否为最新版本
        var force: Bool = false     // 是否需要强制更新
        var full: Bool = false      // 是否全量更新
        var url: String = ""        // 文件url
        var buildHash: String = ""  // hash值
        var module: String = ""     // 模块名称
        
        var shouldUpdate: Bool {
            get {
                return (force || !updated)
            }
        }
        
        static func model(from data: [String: Any]) -> MLCheckModel {
            let model = MLCheckModel()
            model.updated = data["updated"] as? Bool ?? false
            model.force = data["force"] as? Bool ?? false
            model.full = data["full"] as? Bool ?? false
            if let meta = data["meta"] as? [String: Any] {
                model.url = meta["url"] as? String ?? ""
                model.buildHash = meta["buildHash"] as? String ?? ""
            }
            return model
        }
    }
}

/// MARK: 读取manifest配置文件
extension RNPushManager {
    
    // 检测路由是否有效
    class public func ml_validate(module: String = "", route: String) -> Bool {
        guard let model = MLManifestModel.model(for: module) else { return false }
        return model.routes.contains(route)
    }
    
    // 获取buildHash
    class func ml_buildHash(for module: String = "") -> String {
        return MLManifestModel.model(for: module)?.buildHash ?? ""
    }
    
    // 获取manifest.json URL
    class fileprivate func ml_manifestBundleURL(for module: String = "") -> URL? {
        return RNPushManager.bundleURL(for: module)?.appendingPathComponent("manifest.json")
    }
    
    /// 配置文件
    fileprivate class MLManifestModel: NSObject {
        var appVersion: String = ""        // 当前发布的版本号
        var minAppVersion: String = ""     // 最小可使用的应用版本
        var buildHash: String = ""         // 模块构建后的hash值
        var routes: [String] = []          // 模块路由，用于检测路由是否可跳转
        var dependency: [String] = []      // 当前模块所依赖的其他模块
        
        static func model(for module: String) -> MLManifestModel? {
            guard let url = RNPushManager.ml_manifestBundleURL(for: module) else { return nil }
            if let data = try? Data(contentsOf: url), let json = (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)) as? [String: Any] {
                let model = MLManifestModel()
                model.appVersion = json["appVersion"] as? String ?? ""
                model.minAppVersion = json["minAppVersion"] as? String ?? ""
                model.buildHash = json["buildHash"] as? String ?? ""
                model.routes = json["routes"] as? [String] ?? []
                model.dependency = json["dependency"] as? [String] ?? []
                return model
            }
            return nil
        }
    }
}
