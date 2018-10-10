//
//  RNPushManager+ML.swift
//  Pods-RNPush_Example
//
//  Created by wangcong on 2018/9/21.
//

import Foundation

let check_lock = "check_lock"

/// MARK: ML拆包管理（公用方法-可供外部调用）
public extension RNPushManager {
    
    /// MARK: 检查文件是否需要下载，注意每次调用下载某个某个模块之前一定要检查所依赖的模块是否已经被下载，如果未被下载则需下载
    class public func ml_updateIfNeeded(_ module: String, _ completion: ((_ shouldReload: Bool) -> Void)? = nil) {
        
        // 这里的modules 应当包含依赖的相关模块
        var modules = [module]
        modules.append(contentsOf: MLManifestModel.model(for: module)?.dependency ?? [])
        RNPushManager.ml_checks(modules) { (checkSuccess, needReload) in
            if checkSuccess {
                if needReload {
                    RNPushManager.addRollbackIfNeeded(for: module)
                }
                completion?(needReload)
                RNPushManager.removeRollbackIfNeeded(for: module)
            } else {
                completion?(false)
            }
        }
    }
    
    // 此方法需要在用户登录状态为成功时调用一次，上传数据如下
    /*
     "name": MLLoginUser.shared.user?.name ?? "" ,
     "sectionName": MLLoginUser.shared.user?.sectionName ?? "",
     "titleName": MLLoginUser.shared.user?.titleName ?? "",
     "hospital": MLLoginUser.shared.user?.hospital ?? "",
     "sex": MLLoginUser.shared.user?.sex.rawValue ?? 0,
     "type": MLLoginUser.shared.user?.type?.rawValue ?? 0,
     "avatar": MLLoginUser.shared.user?.avatar ?? "",
     "id": MLLoginUser.shared.user?.userId ?? 0,
     "phoneNum": MLLoginUser.shared.user?.cellphone ?? ""
     */
    class public func ml_bind(userInfo: [String: Any]) {
        let config = RNPushConfig()
        RNPushManager.request(config.serverUrl.appending(MLRNPushManagerApi.bind), userInfo, "POST", nil)
    }
}

extension RNPushManager {
    
    // 保证同时检测、下载、解压、合并成功
    class fileprivate func ml_checks(_ modules: [String], _ completion: @escaping ((_ checkSuccess: Bool, _ needReload: Bool) -> Void)) {
        var _successes: [Bool] = []
        var _needReload = false
        for module in modules {
            RNPushManager.ml_check_pre(module) { (success, reload) in
                objc_sync_enter(check_lock)
                _successes.append(success)
                
                if reload == true {
                    _needReload = true
                }
                
                if _successes.count == modules.count {
                    let _checkSuccess = _successes.filter({ $0 }).count == modules.count
                    completion(_checkSuccess, _needReload)
                }
                objc_sync_exit(check_lock)
            }
        }
    }
    
    class fileprivate func ml_merge(_ module: String, _ completion: ((_ mergeSuccess: Bool) -> Void)? = nil) {
        let unpatchedTmpPath = RNPushManager.unpatchedTmpPath(for: module)
        let unpatchedPath = RNPushManager.unpatchedPath(for: module)
        let rollbackPath = RNPushManager.rollbackPath(for: module)
        
        // 如果当前的更新存在bug则无需merge
        let url = URL(fileURLWithPath: RNPushManager.unpatchedTmpPath(for: module)).appendingPathComponent("manifest.json")
        let buildHash = RNPushManager.ml_buildHash(for: url)
        guard !RNPushManager.isBugBuildHash(for: buildHash) else {
            RNPushManager.ml_clearInvalidate(module)
            completion?(true)
            return
        }
        
        // 在merge之前备份正常使用的module，用于后续merge或者热更出现错误回滚
        RNPushManager.copy(unpatchedPath, rollbackPath, true) { (_) in
            RNPushManager.merge(unpatchedTmpPath, unpatchedPath, [], { (error) in
                let _mergeSuccess = error == nil
                if _mergeSuccess { // 合并成功清除不必要的文件
                    RNPushManager.ml_clearInvalidate(module)
                } else { // 否则则需要回滚该模块
                    try? RNPushManager.rollback(for: module)
                }
                completion?(_mergeSuccess)
            })
        }
    }
    
    // 清除无用文件
    class fileprivate func ml_clearInvalidate(_ module: String) {
        DispatchQueue(label: "com.RNPush.ml_clearInvalidate").async {
            let unpatchedTmpPath = RNPushManager.unpatchedTmpPath(for: module)
            if FileManager.default.fileExists(atPath: unpatchedTmpPath) {
                try? FileManager.default.removeItem(atPath: unpatchedTmpPath)
            }
            
            let patchPath = RNPushManager.patchPath(for: module)
            if FileManager.default.fileExists(atPath: patchPath) {
                try? FileManager.default.removeItem(atPath: patchPath)
            }
        }
    }
}

/// MARK: 网络相关处理
extension RNPushManager {
    
    // 检测单个module是否需要重新reload;
    // parameter: checkSuccess 标识检测成功
    // parameter: shouldReload 标识是否需要重新加载
    class fileprivate func ml_check_pre(_ module: String, _ completion: @escaping ((_ checkSuccess: Bool, _ shouldReload: Bool) -> Void)) {
        // 如果当前的模块是最新版本，并且在sanbox中没有包含模块，那么将打包中的文件拷贝至外部（用于merge）
        let destDir = RNPushManager.unpatchedPath(for: module)
        if !FileManager.default.fileExists(atPath: destDir) {
            let sourceDir = RNPushManager.binaryBundleURL(for: module)?.path ?? ""
            RNPushManager.copy(sourceDir, destDir, true, { (_) in
                ml_check(module, completion)
            })
        } else {
            ml_check(module, completion)
        }
    }
    
    class fileprivate func ml_check(_ module: String, _ completion: @escaping ((_ checkSuccess: Bool, _ shouldReload: Bool) -> Void)) {
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
                            completion(false, false)
                        } else {
                            let model = MLCheckModel.model(from: jsonData)
                            if model.shouldUpdate {
                                RNPushManager.ml_pending(module)
                                // 下载
                                RNPushManager.download(urlPath: model.url, save: RNPushManager.patchPath(for: module), progress: nil, completion: { (path, downloadError) in
                                    if downloadError != nil {
                                        completion(false, false)
                                    } else {
                                        // 解压
                                        RNPushManager.unzip(RNPushManager.patchPath(for: module), RNPushManager.unpatchedTmpPath(for: module), nil, completion: { (zipPath, success, zipError) in
                                            if success {
                                                // 合并
                                                RNPushManager.ml_merge(module, { (mergeSuccess) in
                                                    completion(mergeSuccess, mergeSuccess)
                                                })
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
        RNPushManager.success(for: module)
        let config = RNPushConfig(module)
        RNPushManager.request(config.serverUrl.appending(MLRNPushManagerApi.success), config.ml_params(), "POST", nil)
    }
    
    class fileprivate func ml_pending(_ module: String) {
        RNPushLog("RNPushManager ml_pending : \(module)")
        RNPushManager.pending(for: module)
        let config = RNPushConfig(module)
        RNPushManager.request(config.serverUrl.appending(MLRNPushManagerApi.pending), config.ml_params(), "POST", nil)
    }
    
    class fileprivate func ml_fail(_ module: String) {
        RNPushLog("RNPushManager ml_fail : \(module)")
        RNPushManager.fail(for: module)
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
    
    class func ml_buildHash(for url: URL) -> String {
        return MLManifestModel.model(for: url)?.buildHash ?? ""
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
            return MLManifestModel.model(for: url)
        }
        
        static func model(for url: URL) -> MLManifestModel? {
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
