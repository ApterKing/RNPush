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
    
    static fileprivate let kBundleResourceKey = "com.RNPush.kBundleResourceKey"
    static fileprivate let kRollbackKey = "com.RNPush.kRollbackKey"
    static fileprivate let kRollBackSuffixKey = ".rollback"
    static fileprivate let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    static fileprivate let buildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
}

public extension RNPushManager {
    
    /// 注册相关配置，此方法在willFinishLaunchingWithOptions/didFinishLaunchingWithOptions中需要调用
    class public func register(serverUrl: String, deploymentKey: String, bundleResource: String = "RNPush") {
        RNPushConfig.register(serverUrl: serverUrl, deploymentKey: deploymentKey)
        let userDefaults = UserDefaults(suiteName: kSuitNameKey) ?? UserDefaults.standard
        userDefaults.set(bundleResource, forKey: kBundleResourceKey)
        
        rollbackIfNeeded()
    }

    /// 模块所在的位置
    class public func bundleURL(for module: String = "") -> URL? {
        let userDefaults = UserDefaults(suiteName: kSuitNameKey) ?? UserDefaults.standard

        // 从sanbox中获取bundleURL
        let bundlePath = RNPushManager.unzipedPath(for: module)
        if FileManager.default.fileExists(atPath: bundlePath) {
            return URL(fileURLWithPath: bundlePath)
        }
        
        // 从应用包中获取bundleURL
        let bundleResource = userDefaults.string(forKey: kBundleResourceKey) ?? "main.jsbundle"
        let bundleURL = Bundle.main.url(forResource: bundleResource, withExtension: nil)
        return module == "" ? bundleURL : bundleURL?.appendingPathComponent(module)
    }
    
    class public func binaryBundleURL(for module: String = "") -> URL? {
        return RNPushManager.bundleURL(for: module)?.appendingPathComponent(module == "" ? "main.js" : "index.js")
    }
    
    /// 回滚更新出错的模块
    class private func rollbackIfNeeded(_ completion: ((_ error: Error?) -> Void)? = nil) {
        
        DispatchQueue(label: "com.RNPush.rollback").async {
            do {
                let userDefaults = UserDefaults(suiteName: kSuitNameKey) ?? UserDefaults.standard
                let rollbackModules = userDefaults.array(forKey: kRollbackKey) as? [String] ?? []
                
                for module in rollbackModules {
                    // 删除更新后的unzip文件
                    let unzipPath = RNPushManager.unzipedPath(for: module)
                    if FileManager.default.fileExists(atPath: unzipPath) {
                        try FileManager.default.removeItem(atPath: unzipPath)
                    }
                    
                    if FileManager.default.fileExists(atPath: unzipPath) {
                        try FileManager.default.removeItem(atPath: unzipPath)
                    }
                    
                    // 删除更新后的zip文件
                    let zipPath = RNPushManager.zipPath(for: module)
                    if FileManager.default.fileExists(atPath: zipPath) {
                        try FileManager.default.removeItem(atPath: zipPath)
                    }
                    
                    // 检测是否存在rollback备份文件, 存在则重新解压
                    let rollbackPath = RNPushManager.rollbackPath(for: module)
                    if FileManager.default.fileExists(atPath: rollbackPath) {
                        try FileManager.default.moveItem(atPath: rollbackPath, toPath: zipPath)
                        try FileManager.default.removeItem(atPath: rollbackPath)
                        RNPushManager.unzip(RNPushManager.zipPath(for: module), RNPushManager.unzipedPath(for: module), nil, completion: nil)
                    }
                    
                    // 每完成一个回滚，则重设kRollbackKey
                    var tmpRollbackModules = userDefaults.array(forKey: kRollbackKey) as? [String] ?? []
                    if let index = tmpRollbackModules.index(of: module) {
                        tmpRollbackModules.remove(at: index)
                        userDefaults.set(tmpRollbackModules, forKey: kRollbackKey)
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
    
    public func success(for module: String = "") {
        
    }
    
    public func pending(for module: String = "") {
        
    }
    
    public func fail(for module: String = "") {
        
    }
}

/// MARK: 网络相关
extension RNPushManager {
    
    /// 网络请求
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
    
    /// 下载文件
    class public func download(urlPath: String, save filePath: String?, progress: ((_ totalBytesWritten: Int64, _ totalBytesExpectedToWrite: Int64) -> Void)?, completion: ((_ path: String, _ error: Error?) -> Void)?) {
        var savePath = filePath
        if savePath == nil {
            savePath = RNPushManager.zipPath()
        }
        RNPushDownloader.download(urlPath: urlPath, save: savePath!, progress: progress, completion: completion)
    }
    
}

/// MARK: 本地文件处理
extension RNPushManager {
    
    // 下载文件的存储地址
    class fileprivate func sanboxPath(_ pathComponent: String = "", isDirectory: Bool = true) -> String {
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
    
    // 压缩文件地址
    class func zipPath(for module: String = "") -> String {
        let userDefaults = UserDefaults(suiteName: kSuitNameKey) ?? UserDefaults.standard
        let bundleResource = userDefaults.string(forKey: kBundleResourceKey) ?? "main.jsbundle"
        return sanboxPath("zip", isDirectory: true) + "/" + (module == "" ? bundleResource : module) + ".zip"
    }
    
    // 解压文件地址
    class func unzipedPath(for module: String = "") -> String {
        let userDefaults = UserDefaults(suiteName: kSuitNameKey) ?? UserDefaults.standard
        let bundleResource = userDefaults.string(forKey: kBundleResourceKey) ?? "main.jsbundle"
        return sanboxPath("unzip", isDirectory: true) + "/" + (module == "" ? bundleResource : module)
    }
    
    // 回滚文件地址
    class func rollbackPath(for module: String = "") -> String {
        let userDefaults = UserDefaults(suiteName: kSuitNameKey) ?? UserDefaults.standard
        let bundleResource = userDefaults.string(forKey: kBundleResourceKey) ?? "main.jsbundle"
        return sanboxPath("rollback", isDirectory: true) + "/" + (module == "" ? bundleResource : module) + kRollBackSuffixKey
    }
    
    /// 解压文件
    class public func unzip(_ sourcePath: String, _ destinationPath: String, _ progress: ((_ entry: String, _ entryNumber: Int, _ total: Int) -> Void)?, completion: ((_ path: String, _ successed: Bool, _ error: Error?) -> Void)?) {
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
    
    class public func merge(_ module: String = "", _ completion: ((_ error: Error?) -> Void)?) {
        DispatchQueue(label: "com.RNPush.merge").async {
            
            DispatchQueue.main.async {
                completion?(nil)
            }
        }
    }
    
}
