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
    fileprivate var urlPath: String!
    fileprivate var filePath: String!
    
    fileprivate var task: URLSessionDownloadTask?
    
    static func download(urlPath: String, save filePath: String, progress: progressHandler?, completion: completionHandler?) {
        let downloader = RNPushDownloader()
        downloader.urlPath = urlPath
        downloader.filePath = filePath
        downloader.progressHandler = progress
        downloader.completionHandler = completion
        
        downloader._download(urlPath)
    }
    
    private func _download(_ urlPath: String) {
        guard let url = URL(string: urlPath) else { return }
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        RNPushLog("RNPushDownloader  download from: \(urlPath)")
        task = session.downloadTask(with: url)
        task?.resume()
    }
    
    deinit {
        let state = task?.state ?? .running
        if state == .running || state == .suspended {
            task?.cancel()
        }
    }
    
}

extension RNPushDownloader: URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        RNPushLog("RNPushDownloader progress:  \(bytesWritten)  \(totalBytesWritten)  \(totalBytesExpectedToWrite)")

        self.progressHandler?(totalBytesWritten, totalBytesExpectedToWrite)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            RNPushLog("RNPushDownloader didFinishDownloadingTo location:  \(location.path)   \(location.pathExtension)")

            let data = NSData(contentsOf: location)
            try data?.write(toFile: filePath, options: .atomicWrite)

            RNPushLog("RNPushDownloader  didFinishDownloadingTo save to:  \(filePath)")
        } catch let error {
            RNPushLog("RNPushDownloader  didFinishDownloadingTo fail")
            self.completionHandler?(filePath, error)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        RNPushLog("RNPushDownloader didCompleteWithError: \(String(describing: error))")
        self.completionHandler?(filePath, error)
    }
}
