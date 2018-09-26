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

    public override init() {
        super.init()
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
            NSLog("RNPushManager response: \(response?.url?.path ?? "")  \n error: \(String(describing: error))")
            #endif
            completion?(data, response, error)
        }
        task.resume()
    }
    
    /// 下载文件
    public func download(urlPath: String, save filePath: String?, progress: ((_ totalBytesWritten: Int64, _ totalBytesExpectedToWrite: Int64) -> Void)?, completion: ((_ path: String, _ error: Error?) -> Void)?) {
        RNPushDownloader.download(urlPath: urlPath, save: filePath, progress: progress, completion: completion)
    }
}

/// MARK: 本地文件处理
public extension RNPushManager {
    
    /// MARK: 拷贝文件
    
    /// 解压文件
    public func unzip(_ sourcePath: String, _ destinationPath: String, _ progress: ((_ entry: String, _ entryNumber: Int, _ total: Int) -> Void)?, completion: ((_ path: String, _ successed: Bool, _ error: Error?) -> Void)?) {
        guard destinationPath != "" else { return }
        DispatchQueue.global().async {
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
