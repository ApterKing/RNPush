//
//  RNPushDownloader.swift
//  Pods-RNPush_Example
//
//  Created by wangcong on 2018/9/10.
//

import UIKit

/// MARK: 下载
public class RNPushDownloader: NSObject {
    typealias progressHandler = ((_ progress: Int64, _ total: Int64) -> Void)
    typealias completionHandler = ((_ path: String, _ error: Error?) -> Void)
    
    fileprivate var progressHandler: progressHandler?
    fileprivate var completionHandler: completionHandler?
    fileprivate var filePath: String?
    
    static func download(urlPath: String, save filePath: String?, progress: progressHandler?, completion: completionHandler?) {
        let downloader = RNPushDownloader()
        downloader.filePath = filePath
        downloader.progressHandler = progress
        downloader.completionHandler = completion
        
        downloader._download(urlPath)
    }
    
    private func _download(_ path: String) {
        guard let url = URL(string: path) else { return }
        
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        
        let task: URLSessionDownloadTask = session.downloadTask(with: url)
        task.resume()
    }
}

extension RNPushDownloader: URLSessionDownloadDelegate {
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        #if DEBUG
        print("download progress:  \(bytesWritten)  \(totalBytesWritten)  \(totalBytesExpectedToWrite)")
        #endif
        
        self.progressHandler?(totalBytesWritten, totalBytesExpectedToWrite)
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            var url = location
            if let path = filePath {  // 指定了存储的地址，则需写入文件
                let data = try Data(contentsOf: location)
                url = URL(fileURLWithPath: path, isDirectory: false)
                try data.write(to: url, options: Data.WritingOptions.atomicWrite)
            }
            self.completionHandler?(url.path, nil)
        } catch let error {
            self.completionHandler?(filePath ?? "", error)
        }
    }
    
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        self.completionHandler?(filePath ?? "", error)
    }
}
