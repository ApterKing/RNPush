//
//  RNPushDownloader.swift
//  Pods-RNPush_Example
//
//  Created by wangcong on 2018/9/20.
//

import Foundation

/// MARK: 文件下载
class RNPushDownloader: NSObject {
    typealias progressHandler = ((_ totalBytesWritten: Int64, _ totalBytesExpectedToWrite: Int64) -> Void)
    typealias completionHandler = ((_ path: String, _ error: Error?) -> Void)
    
    fileprivate var progressHandler: progressHandler?
    fileprivate var completionHandler: completionHandler?
    fileprivate var filePath: String?
    
    fileprivate var task: URLSessionDownloadTask?
    
    static func download(urlPath: String, save filePath: String?, progress: progressHandler?, completion: completionHandler?) {
        let downloader = RNPushDownloader()
        downloader.filePath = filePath
        downloader.progressHandler = progress
        downloader.completionHandler = completion
        
        downloader._download(urlPath)
    }
    
    private func _download(_ urlPath: String) {
        guard let url = URL(string: urlPath) else { return }
        
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        
        #if DEBUG
        NSLog("RNPushDownloader  download from: \(urlPath)")
        #endif
        task = session.downloadTask(with: url)
        task?.resume()
    }
    
    deinit {
        task?.cancel()
    }
    
}

extension RNPushDownloader: URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        #if DEBUG
        NSLog("RNPushDownloader progress:  \(bytesWritten)  \(totalBytesWritten)  \(totalBytesExpectedToWrite)")
        #endif
        
        self.progressHandler?(totalBytesWritten, totalBytesExpectedToWrite)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            var url = location
            #if DEBUG
            NSLog("RNPushDownloader didFinishDownloadingTo location:  \(location.path)   \(location.pathExtension)")
            #endif
            // 指定了存储的地址，则需重新写入文件
            if let path = filePath {
                let data = try Data(contentsOf: location)
                url = URL(fileURLWithPath: path, isDirectory: false)
                
                // 检查extension是否匹配
                if url.pathExtension != location.pathExtension {
                    url = url.deletingPathExtension()
                    url.appendPathExtension(location.pathExtension)
                }
                try data.write(to: url, options: Data.WritingOptions.atomicWrite)
            }
            #if DEBUG
            NSLog("RNPushDownloader  didFinishDownloadingTo save to:  \(url.path)   \(url.pathExtension)")
            #endif
            filePath = url.path
            self.completionHandler?(filePath ?? "", nil)
        } catch let error {
            self.completionHandler?(filePath ?? "", error)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        #if EDBUG
        NSLog("RNPushDownloader didCompleteWithError: \(String(describing: error))")
        #endif
        self.completionHandler?(filePath ?? "", error)
    }
}
