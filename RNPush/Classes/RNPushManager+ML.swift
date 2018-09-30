//
//  RNPushManager+ML.swift
//  Pods-RNPush_Example
//
//  Created by wangcong on 2018/9/21.
//

import Foundation

private var _checkSuccess: [Bool] = []
private var _shouldReload = false

/// MARK: ML拆包管理（公用方法-可供外部调用）
public extension RNPushManager {
    
    /// MARK: 检查文件是否需要下载，注意每次调用下载某个某个模块之前一定要检查所依赖的模块是否已经被下载，如果未被下载则需下载
    class public func ml_updateIfNeeded(_ module: String, _ completion: @escaping ((_ shouldReload: Bool) -> Void)) {
        
        // 这里的module 应当包含依赖的相关模块
        var modules = [module]
        modules.append(contentsOf: MLManifestModel.model(for: module)?.dependency ?? [])
        
        var statisticsSuccess: [Bool] = []
        var statisticsReload = false
        for tmpModule in modules {
            RNPushManager.ml_check(tmpModule) { (success, reload) in
                
                // 所有模块完整加载成功才判定是否需要刷新界面，如果存在其中一个出现错误则不能够刷新
                objc_sync_enter(statisticsSuccess)
                statisticsSuccess.append(success)
                if reload == true {
                    statisticsReload = reload
                }
                
                if statisticsSuccess.count == modules.count {
                    let neededReload = statisticsSuccess.filter({ $0 }).count == module.count && statisticsReload
                    completion(neededReload)
                    RNPushLog("RNPushManager  ml_updateIfNeeded  shouldReload: \(neededReload)")
                    
                    if neededReload == true {
                        RNPushManager.ml_success(module)
                    }
                }
                objc_sync_exit(statisticsSuccess)
            }
        }
    }
}

/// MARK: 网络相关处理
extension RNPushManager {
    
    // 检测是否需要重新reload，checkSuccess 标识检测成功，shouldReload标识是否需要重新加载（检测成功不一定代表需要重新加载，只有模块所依赖的所有checkSuccess才能够去判定是否需要reload）
    class fileprivate func ml_check(_ module: String, completion: @escaping ((_ checkSuccess: Bool, _ shouldReload: Bool) -> Void)) {
        let config = RNPushConfig(module)
        RNPushManager.request(config.serverUrl.appending(MLRNPushManagerApi.check), config.ml_params(), "POST") { (data, response, error) in
            if let err = error {
                RNPushLog("RNPushManager ml_check error: \(module)  \(String(describing: err))")
                completion(false, false)
            } else {
                do {
                    if let json = (try JSONSerialization.jsonObject(with: data ?? Data(), options: .allowFragments)) as? [String: Any] {
                        let jsonCode = json["code"] as? Int64 ?? 0
                        let jsonData = json["data"] as? [String: Any] ?? [:]
                        if jsonCode != 0 {
                            completion(true, false)
                        } else {
                            let model = MLCheckModel.model(from: jsonData)
                            if model.shouldUpdate {
                                RNPushManager.ml_pending(module)
                                RNPushManager.download(urlPath: model.url, save: RNPushManager.zipPath(for: module), progress: nil, completion: { (path, downloadError) in
                                    if downloadError != nil {
                                        completion(false, false)
                                    } else {
                                        RNPushManager.unzip(path, RNPushManager.unzipedPath(for: module), nil, completion: { (zipPath, successed, zipError) in
                                            if zipError == nil {    // 仅当能够解压成功，才标识整个模块更新完成
                                                completion(true, true)
                                            } else {
                                                completion(false, false)
                                            }
                                        })
                                    }
                                })
                            } else {
                                RNPushLog("RNPushManager ml_check success: \(module)  已经是最新版本")
                                completion(true, false)
                            }
                        }
                    }
                } catch let error {
                    RNPushLog("RNPushManager ml_check error catch: \(module)  \(String(describing: error))")
                    completion(false, false)
                }
            }
        }
    }
    
    // 请求所有模块，暂时未使用到
    class fileprivate func ml_all() {
        let config = RNPushConfig("")
        RNPushManager.request(config.serverUrl.appending(MLRNPushManagerApi.all), config.ml_params(), "POST") { (data, response, error) in
            
        }
    }
    
    class fileprivate func ml_success(_ module: String) {
        RNPushLog("RNPushManager ml_success : \(module)")
        let config = RNPushConfig(module)
        RNPushManager.request(config.serverUrl.appending(MLRNPushManagerApi.success), config.ml_params(), "POST", nil)
    }
    
    class fileprivate func ml_pending(_ module: String) {
        RNPushLog("RNPushManager ml_pending : \(module)")
        let config = RNPushConfig(module)
        RNPushManager.request(config.serverUrl.appending(MLRNPushManagerApi.pending), config.ml_params(), "POST", nil)
    }
    
    class fileprivate func ml_fail(_ module: String) {
        RNPushLog("RNPushManager ml_fail : \(module)")
        let config = RNPushConfig(module)
        RNPushManager.request(config.serverUrl.appending(MLRNPushManagerApi.fail), config.ml_params(), "POST", nil)
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
        var updated: Bool = true    // 是否为最新版本
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
