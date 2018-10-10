//
//  RNPushManager.swift
//  Pods-RNPush_Example
//
//  Created by wangcong on 2018/9/21.
//

import Foundation
import SSZipArchive


/// MARK: global
let RNPushNotificationName = Notification.Name("kRNPushNotificationName")
let kSuitNameKey = "RNPush"
func RNPushLog(_ format: String, _ args: CVarArg...) {
    #if DEBUG
    NSLog(format, args)
    #endif
}

public class RNPushManager: NSObject {
    
    static let kBundleResourceKey = "com.RNPush.kBundleResourceKey"
    static let kRollbackKey = "com.RNPush.kRollbackKey"
    static let kRollbackBugBuildhashKey = "com.RNPush.kRollbackBugBuildhashKey"
    static let kPatchSuffixKey = ".zip"
    static let kRollBackSuffixKey = "_rollback"
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    static let buildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
}

public extension RNPushManager {
    
    /// 注册相关配置，此方法在willFinishLaunchingWithOptions/didFinishLaunchingWithOptions中需要调用
    class public func register(serverUrl: String, deploymentKey: String, bundleResource: String? = nil) {
        RNPushConfig.register(serverUrl: serverUrl, deploymentKey: deploymentKey)
        let userDefaults = UserDefaults(suiteName: kSuitNameKey) ?? UserDefaults.standard
        userDefaults.set(bundleResource, forKey: kBundleResourceKey)
        
        rollbackIfNeeded { (error) in
            if error != nil {  // 再次尝试移除
                rollbackIfNeeded()
            }
        }
    }

    /// 模块所在的位置
    class public func bundleURL(for module: String = "") -> URL? {
        // 从sanbox中获取bundleURL
        let bundlePath = RNPushManager.unpatchedPath(for: module)
        if FileManager.default.fileExists(atPath: bundlePath) {
            return URL(fileURLWithPath: bundlePath)
        }
        
        // 从应用包中获取bundleURL
        return binaryBundleURL(for: module)
    }
    
    class public func binaryBundleURL(for module: String = "") -> URL? {
        let userDefaults = UserDefaults(suiteName: kSuitNameKey) ?? UserDefaults.standard
        let bundleResource = userDefaults.string(forKey: kBundleResourceKey) ?? "main.jsbundle"
        let bundleURL = Bundle.main.url(forResource: bundleResource, withExtension: nil)
        return module == "" ? bundleURL : bundleURL?.appendingPathComponent(module)
    }
    
    class public func bridgeBundleURL(for module: String = "") -> URL? {
        return bundleURL(for: module)?.appendingPathComponent(module == "" ? "main.js" : "index.js")
    }
    
    class public func success(for module: String = "") {
        
    }
    
    class public func pending(for module: String = "") {
        
    }
    
    class public func fail(for module: String = "") {
        
    }
}


/// MARK: 回滚
extension RNPushManager {
    
    // 添加某个模块到待回滚队列
    class public func addRollbackIfNeeded(for module: String) {
        let userDefaults = UserDefaults(suiteName: kSuitNameKey) ?? UserDefaults.standard
        var rollbackModules = userDefaults.array(forKey: kRollbackKey) as? [String] ?? []
        if !rollbackModules.contains(module) {
            rollbackModules.append(module)
        }
        userDefaults.set(rollbackModules, forKey: kRollbackKey)
    }
    
    // 将某个模块移除回滚队列
    class public func removeRollbackIfNeeded(for module: String) {
        let userDefaults = UserDefaults(suiteName: kSuitNameKey) ?? UserDefaults.standard
        var rollbackModules = userDefaults.array(forKey: kRollbackKey) as? [String] ?? []
        if let index = rollbackModules.index(of: module) {
            rollbackModules.remove(at: index)
        }
        userDefaults.set(rollbackModules, forKey: kRollbackKey)
    }
    
    // 检测某个构建版本是否存在bug
    class func isBugBuildHash(for buildHash: String) -> Bool {
        let userDefaults = UserDefaults(suiteName: kSuitNameKey) ?? UserDefaults.standard
        let rollbackBugBuildhashs = userDefaults.array(forKey: kRollbackBugBuildhashKey) as? [String] ?? []
        return rollbackBugBuildhashs.contains(buildHash)
    }
    
    // 回滚更新出错的所有模块
    class func rollbackIfNeeded(_ completion: ((_ error: Error?) -> Void)? = nil) {
        DispatchQueue(label: "com.RNPush.rollback").async {
            do {
                let userDefaults = UserDefaults(suiteName: kSuitNameKey) ?? UserDefaults.standard
                let rollbackModules = userDefaults.array(forKey: kRollbackKey) as? [String] ?? []
                
                for module in rollbackModules {
                    try rollback(for: module, recordAsBug: true)
                    removeRollbackIfNeeded(for: module)
                }
                DispatchQueue.main.async {
                    completion?(nil)
                }
            } catch let error {
                DispatchQueue.main.async {
                    completion?(error)
                }
            }
        }
    }
    
    // 回滚指定模块
    class func rollback(for module: String, recordAsBug: Bool = false) throws {
        if recordAsBug { // 记录当前回滚模块的buildHash，下次如果是此buildHash则不要更新此版本
            let buildHash = RNPushManager.ml_buildHash(for: module)
            let userDefaults = UserDefaults(suiteName: kSuitNameKey) ?? UserDefaults.standard
            var rollbackBugBuildhashs = userDefaults.array(forKey: kRollbackBugBuildhashKey) as? [String] ?? []
            if !rollbackBugBuildhashs.contains(buildHash) {
                rollbackBugBuildhashs.append(buildHash)
            }
            userDefaults.set(rollbackBugBuildhashs, forKey: kRollbackBugBuildhashKey)
        }

        // 删除patch文件
        let patchPath = RNPushManager.patchPath(for: module)
        if FileManager.default.fileExists(atPath: patchPath) {
            try FileManager.default.removeItem(atPath: patchPath)
        }
        
        // 删除unpatched文件
        let unpatchedPath = RNPushManager.unpatchedPath(for: module)
        if FileManager.default.fileExists(atPath: unpatchedPath) {
            try FileManager.default.removeItem(atPath: unpatchedPath)
        }
        
        // 检测是否存在rollback的备份文件
        let rollbackPath = RNPushManager.rollbackPath(for: module)
        if FileManager.default.fileExists(atPath: rollbackPath) {
            try FileManager.default.moveItem(atPath: rollbackPath, toPath: unpatchedPath)
        }
    }

}

/// MARK: 网络相关
extension RNPushManager {
    
    class public func request(_ urlString: String, _ params: [String: Any]? = nil, _ httpMethod: String?, _ completion: ((Data?, URLResponse?, Error?) -> Void)?) {
        
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        request.httpMethod = httpMethod
        var httpBody = ""
        if let bodies = params {
            httpBody = bodies.reduce("") { (result, param) -> String in
                return "\(result)\(result == "" ? "" : "&")\(param.key)=\(param.value)"
            }
            request.httpBody = httpBody.data(using: .utf8)
        }
        RNPushLog("RNPushManager request: \(urlString)  \n params : \(httpBody)")

        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let task = session.dataTask(with: request) { (data, response, error) in
            RNPushLog("RNPushManager response:  \(response?.url?.path ?? "")   \(String(describing: data == nil ? "" : String(data: data!, encoding: String.Encoding.utf8)))  \n error: \(String(describing: error))")
            completion?(data, response, error)
        }
        task.resume()
    }
    
    class public func download(urlPath: String, save filePath: String?, progress: ((_ totalBytesWritten: Int64, _ totalBytesExpectedToWrite: Int64) -> Void)?, completion: ((_ path: String, _ error: Error?) -> Void)?) {
        var savePath = filePath
        if savePath == nil {
            savePath = RNPushManager.patchPath()
        }
        
        RNPushDownloader.download(urlPath: urlPath, save: savePath!, progress: progress, completion: completion)
    }
    
}

/// MARK: 本地文件处理
extension RNPushManager {
    
    // 热更文件存储所在的文件夹
    class func sanboxPath(_ pathComponent: String = "", isDirectory: Bool = true) -> String {
        let supportPath = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first ?? ""
        let userDefaults = UserDefaults(suiteName: kSuitNameKey) ?? UserDefaults.standard
        var sanboxPath = "\(supportPath)/\(userDefaults.string(forKey: RNPushManager.kBundleResourceKey) ?? "RNPush")_\(RNPushManager.appVersion)_\(RNPushManager.buildVersion)"
        if !FileManager.default.fileExists(atPath: sanboxPath, isDirectory: nil) {
            try? FileManager.default.createDirectory(atPath: sanboxPath, withIntermediateDirectories: true, attributes: nil)
        }
       
        if pathComponent != "" {
            sanboxPath = sanboxPath.appendingFormat("/%@", pathComponent)
            if isDirectory && !FileManager.default.fileExists(atPath: sanboxPath, isDirectory: nil) {
                try? FileManager.default.createDirectory(atPath: sanboxPath, withIntermediateDirectories: true, attributes: nil)
            }
        }
        return sanboxPath
    }
    
    // 更新文件地址
    class func patchPath(for module: String = "") -> String {
        let userDefaults = UserDefaults(suiteName: kSuitNameKey) ?? UserDefaults.standard
        let bundleResource = userDefaults.string(forKey: kBundleResourceKey) ?? "main.jsbundle"
        return sanboxPath() + "/" + (module == "" ? bundleResource : module) + (bundleResource.hasSuffix(".jsbundle") ? "" : kPatchSuffixKey)
    }
    
    // 更新文件解压地址
    class func unpatchedPath(for module: String = "") -> String {
        let userDefaults = UserDefaults(suiteName: kSuitNameKey) ?? UserDefaults.standard
        let bundleResource = userDefaults.string(forKey: kBundleResourceKey) ?? "main"
        return sanboxPath() + "/" + (module == "" ? bundleResource : module)
    }
    
    // 更新文件解压地址临时存储地址
    class func unpatchedTmpPath(for module: String = "") -> String {
        return unpatchedPath(for: module) + "_tmp"
    }
    
    // 回滚文件地址
    class func rollbackPath(for module: String = "") -> String {
        let userDefaults = UserDefaults(suiteName: kSuitNameKey) ?? UserDefaults.standard
        let bundleResource = userDefaults.string(forKey: kBundleResourceKey) ?? "main"
        return sanboxPath() + "/" + (module == "" ? bundleResource : module) + kRollBackSuffixKey
    }
    
    // 解压
    class func unzip(_ sourcePath: String, _ destinationPath: String, _ progress: ((_ entry: String, _ entryNumber: Int, _ total: Int) -> Void)?, completion: ((_ path: String, _ success: Bool, _ error: Error?) -> Void)?) {
        guard destinationPath != "" else { return }
        DispatchQueue(label: "com.RNPush.unzip").async {
            if FileManager.default.fileExists(atPath: destinationPath) {
                try? FileManager.default.removeItem(atPath: destinationPath)
            }
            
            RNPushLog("RNPushManager unzip: \(sourcePath)  successed : \(destinationPath)")
            SSZipArchive.unzipFile(atPath: sourcePath, toDestination: destinationPath, progressHandler: { (entry, info, entryNumber, total) in
                DispatchQueue.main.async {
                    RNPushLog("RNPushManager unzip progress: \(entry)   \(entryNumber)  \(total)")
                    progress?(entry, entryNumber, total)
                }
            }, completionHandler: { (path, successed, error) in
                DispatchQueue.main.async {
                    RNPushLog("RNPushManager unzip completion: \(path)   \(successed)  \(String(describing: error))")
                    completion?(path, successed, error)
                }
            })
        }
    }
    
    // 拷贝文件
    class func copy(_ sourcePath: String, _ destPath: String, _ shouldDeleteDest: Bool = false, _ complection: ((_ error: Error?) -> Void)? = nil) {
        DispatchQueue(label: "com.RNPush.copy").async {
            do {
                if shouldDeleteDest && FileManager.default.fileExists(atPath: destPath) {
                    try FileManager.default.removeItem(atPath: destPath)
                }
                try FileManager.default.copyItem(atPath: sourcePath, toPath: destPath)
                DispatchQueue.main.async {
                    complection?(nil)
                }
            } catch let error {
                DispatchQueue.main.async {
                    complection?(error)
                }
            }
        }
    }
    
    // 合并文件夹
    class func merge(_ sourceDir: String, _ destDir: String, _ deletes: [String] = [], _ completion: ((_ error: Error?) -> Void)? = nil) {
        DispatchQueue(label: "com.RNPush.merge").async {
            do {
                RNPushLog("RNPushManager merge: \(sourceDir)  --->  \(destDir)")
                var isSourceDirectory: ObjCBool = true
                var isDestDirectory: ObjCBool = true
                guard FileManager.default.fileExists(atPath: sourceDir, isDirectory: &isSourceDirectory), isSourceDirectory.boolValue, FileManager.default.fileExists(atPath: destDir, isDirectory: &isDestDirectory), isDestDirectory.boolValue else {
                    DispatchQueue.main.async {
                        completion?(nil)
                    }
                    return
                }
                
                for deletePath in deletes {
                    let filePath = destDir + "/" + deletePath
                    if FileManager.default.fileExists(atPath: filePath) {
                        try FileManager.default.removeItem(atPath: filePath)
                    }
                }
                
                if FileManager.default.fileExists(atPath: sourceDir, isDirectory: &isSourceDirectory), isSourceDirectory.boolValue == true, let directoryEnumerator = FileManager.default.enumerator(atPath: sourceDir){
                    var subPath: String? = directoryEnumerator.nextObject() as? String
                    while subPath != nil {
                        let sourceFullPath = sourceDir.appending("/\(subPath!)")
                        let potentialDestFullPath = destDir.appending("/\(subPath!)")
                        
                        let isSourceExists = FileManager.default.fileExists(atPath: sourceFullPath, isDirectory: &isSourceDirectory)
                        let isDestExists = FileManager.default.fileExists(atPath: potentialDestFullPath, isDirectory: &isDestDirectory)
                        
                        if isSourceExists && isSourceDirectory.boolValue {
                            if !isDestExists {
                                try FileManager.default.createDirectory(atPath: potentialDestFullPath, withIntermediateDirectories: true, attributes: nil)
                            }
                        } else if isSourceExists {
                            if isDestExists && !isDestDirectory.boolValue {
                                try FileManager.default.removeItem(atPath: potentialDestFullPath)
                            }
                            try FileManager.default.copyItem(atPath: sourceFullPath, toPath: potentialDestFullPath)
                        }
                        subPath = directoryEnumerator.nextObject() as? String
                    }
                }

                DispatchQueue.main.async {
                    completion?(nil)
                }
            } catch let error {
                DispatchQueue.main.async {
                    completion?(error)
                }
            }
        }
    }
    
}
