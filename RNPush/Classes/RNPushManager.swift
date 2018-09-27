//
//  RNPushManager.swift
//  Pods-RNPush_Example
//
//  Created by wangcong on 2018/9/21.
//

import Foundation
import SSZipArchive

public class RNPushManager: NSObject {
    static public let `default` = RNPushManager()
    static fileprivate let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    static fileprivate let buildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    static fileprivate let kUpdateInfoKey = "com.RNPush.kUpdateInfoKey"
    static fileprivate let kUpdateInfoPackageVersionKey = "com.RNPush.kUpdateInfoPackageVersionKey"
    static fileprivate let kUpdateInfoCurrentVersionKey = "com.RNPush.kUpdateInfoCurrentVersionKey"
    static fileprivate let kUpdateInfoLatestVersionKey = "com.RNPush.kUpdateInfoLatestVersionKey"
    static fileprivate let kUpdateInfoIsFirstLoadOkKey = "com.RNPush.kUpdateInfoIsFirstLoadOkKey"
    static fileprivate let kUpdateInfoIsFirstTimeKey = "com.RNPush.kUpdateInfoIsFirstTimeKey"
    static fileprivate let kPackageUpdatedMarked = "com.RNPush.kPackageUpdatedMarked"
    static fileprivate let kRolledBackMarked = "com.RNPush.kRolledBackMarked"
    static fileprivate let kFirstLoadMarked = "com.RNPush.kFirstLoadMarked"
    static fileprivate let kBundleResourceKey = "com.RNPush.kBundleResourceKey"
    
    fileprivate let asyncQueue = DispatchQueue(label: "com.RNPush")
}

/// MARK: 注册相关配置，此方法在willFinishLaunchingWithOptions/didFinishLaunchingWithOptions中需要调用
public extension RNPushManager {
    
    class public func register(serverUrl: String, deploymentKey: String, bundleResource: String = "RNPush") {
        RNPushConfig.register(serverUrl: serverUrl, deploymentKey: deploymentKey)
        let userDefaults = UserDefaults(suiteName: "RNPush") ?? UserDefaults.standard
        userDefaults.set(bundleResource, forKey: kBundleResourceKey)
        
        // 检测相关更新文件
        if let updateInfo = userDefaults.dictionary(forKey: kUpdateInfoKey) {
            let curPackageVersion = RNPushManager.appVersion
            let updPackageVersion = updateInfo[kUpdateInfoPackageVersionKey] as? String ?? ""
            let shouldClearUpdateInfo = curPackageVersion != updPackageVersion
            
            if shouldClearUpdateInfo {   // 是否需要更新存储的信息
                userDefaults.setValue(nil, forKey: kUpdateInfoKey)
                userDefaults.set(true, forKey: kPackageUpdatedMarked)
                userDefaults.synchronize()
            } else {
                let curVersion = updateInfo[kUpdateInfoCurrentVersionKey] as? String ?? ""
                let latestVersion = updateInfo[kUpdateInfoLatestVersionKey] as? String ?? ""
                
                let isFirstTime = updateInfo[kUpdateInfoIsFirstTimeKey] as? Bool ?? true
                let isFirstLoadOk = updateInfo[kUpdateInfoIsFirstTimeKey] as? Bool ?? false
                
                var loadVersion = curVersion
                let shouldRollback = (isFirstTime == false && isFirstLoadOk == false) || loadVersion.count <= 0
                if shouldRollback {   // 需要回滚
                    loadVersion = latestVersion
                    if loadVersion.count != 0 {
                        userDefaults.set([
                                kUpdateInfoPackageVersionKey: curPackageVersion,
                                kUpdateInfoCurrentVersionKey: latestVersion,
                                kUpdateInfoIsFirstTimeKey: false,
                                kUpdateInfoIsFirstLoadOkKey: true
                            ], forKey: kUpdateInfoKey)
                    } else {
                        userDefaults.set(nil, forKey: kUpdateInfoKey)
                    }
                    userDefaults.set(true, forKey: kRolledBackMarked)
                    userDefaults.synchronize()
                } else if isFirstTime {
                    var newUpdateInfo = updateInfo
                    newUpdateInfo[kUpdateInfoIsFirstTimeKey] = false
                    userDefaults.set(newUpdateInfo, forKey: kUpdateInfoKey)
                    userDefaults.set(true, forKey: kFirstLoadMarked)
                    userDefaults.synchronize()
                }
                
                if loadVersion.count != 0 {
                    
                }
            }
        }
    }
}

/// MARK: 网络相关
public extension RNPushManager {
    
    /// 网络请求
    public func request(_ urlString: String, _ params: [String: Any]? = nil, _ httpMethod: String?, _ completion: ((Data?, URLResponse?, Error?) -> Void)?) {
        
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
        #if DEBUG
        NSLog("RNPushManager request: \(urlString)  \n params : \(httpBody)")
        #endif

        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let task = session.dataTask(with: request) { (data, response, error) in
            #if DEBUG
            NSLog("RNPushManager response:  \(response?.url?.path ?? "")   \(String(describing: data == nil ? "" : String(data: data!, encoding: String.Encoding.utf8)))  \n error: \(String(describing: error))")
            #endif
            completion?(data, response, error)
        }
        task.resume()
    }
    
    /// 下载文件
    public func download(urlPath: String, save filePath: String?, progress: ((_ totalBytesWritten: Int64, _ totalBytesExpectedToWrite: Int64) -> Void)?, completion: ((_ path: String, _ error: Error?) -> Void)?) {
        var savePath = filePath
        if savePath == nil {
            savePath = RNPushManager.downloadPath().appending("/download.zip")
        }
        RNPushDownloader.download(urlPath: urlPath, save: savePath!, progress: progress, completion: completion)
    }
}

/// MARK: 本地文件处理
public extension RNPushManager {
    
    static func downloadPath() -> String {
        let supportPath = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first ?? ""
        let userDefaults = UserDefaults(suiteName: "RNPush") ?? UserDefaults.standard
        let downloadPath = "\(supportPath)/\(userDefaults.string(forKey: RNPushManager.kBundleResourceKey) ?? "RNPush")\(RNPushManager.appVersion)_\(RNPushManager.buildVersion)"
        if !FileManager.default.fileExists(atPath: downloadPath, isDirectory: nil) {
            try? FileManager.default.createDirectory(atPath: downloadPath, withIntermediateDirectories: true, attributes: nil)
        }
        return downloadPath
    }
    
    static func zipPath(for module: String = "") -> String {
        return downloadPath() + "/" + (module == "" ? "download" : module) + ".zip"
    }
    
    /// 拷贝文件
    public func copy(_ completion: ((_ success: Bool) -> Void)?) {
        asyncQueue.async {
            
            DispatchQueue.main.async {
                completion?(true)
            }
        }
    }
    
    /// 解压文件
    public func unzip(_ sourcePath: String, _ destinationPath: String, _ progress: ((_ entry: String, _ entryNumber: Int, _ total: Int) -> Void)?, completion: ((_ path: String, _ successed: Bool, _ error: Error?) -> Void)?) {
        guard destinationPath != "" else { return }
        asyncQueue.async {
            if FileManager.default.fileExists(atPath: destinationPath) {
                try? FileManager.default.removeItem(atPath: destinationPath)
            }
            
            #if DEBUG
            NSLog("RNPushManager unzip: \(sourcePath)  successed : \(destinationPath)")
            #endif
            
            SSZipArchive.unzipFile(atPath: sourcePath, toDestination: destinationPath, progressHandler: { (entry, info, entryNumber, total) in
                DispatchQueue.main.async {
                    #if DEBUG
                    NSLog("RNPushManager unzip progress: \(entry)   \(entryNumber)  \(total)")
                    #endif
                    progress?(entry, entryNumber, total)
                }
            }, completionHandler: { (path, successed, error) in
                DispatchQueue.main.async {
                    #if DEBUG
                    NSLog("RNPushManager unzip completion: \(path)   \(successed)  \(String(describing: error))")
                    #endif
                    completion?(path, successed, error)
                }
            })
        }
    }
    
}
