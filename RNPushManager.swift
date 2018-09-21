//
//  RNPushManager.swift
//  Pods-RNPush_Example
//
//  Created by wangcong on 2018/9/21.
//

import UIKit

public class RNPushManager: NSObject {
    
    static let `default` = RNPushManager()
    
    public override init() {
        super.init()
    }

    
    public func request(_ urlString: String, _ params: [String: Any]? = nil, _ httpMethod: String?, _ completion: ((Data?, URLResponse?, Error?) -> Void)?) {
        
        guard let url = URL(string: urlString) else { return }
        
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)

        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let task = session.dataTask(with: request) { (data, response, error) in
            #if DEBUG
            NSLog("RNPushManager request: \(response?.url?.path ?? "")  \n error: \(String(describing: error))")
            #endif
            completion?(data, response, error)
        }
        task.resume()
    }
}
