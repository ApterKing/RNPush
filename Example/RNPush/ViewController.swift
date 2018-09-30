//
//  ViewController.swift
//  RNPush
//
//  Created by wangcong on 09/10/2018.
//  Copyright (c) 2018 wangcong. All rights reserved.
//

import UIKit
import RNPush

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(gestureAction(_:)))
        gesture.numberOfTapsRequired = 1
        view.addGestureRecognizer(gesture)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func gestureAction(_ gesture: UIGestureRecognizer) {
        RNPushManager.ml_updateIfNeeded("HuaFang") { (shouldReload) in
            print("gestureAction -------  \(shouldReload)      jump:  \(RNPushManager.ml_validate(module: "TimeSpace", route: "TSPublish"))    \(RNPushManager.ml_validate(module: "TimeSpace", route: "TSPublis"))")
        }

    }

}
