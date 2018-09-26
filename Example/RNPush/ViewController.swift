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
        gesture.delegate = self
        view.addGestureRecognizer(gesture)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func gestureAction(_ gesture: UIGestureRecognizer) {
        print("gestureAction")
        RNPushManager.default.ml_downloadIfNeeded("Base") { (successed) in
            print("gestureAction -------  \(successed)")
        }
    }

}

extension ViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        print("----  gestureRecognizerShouldBegin ----")
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        print("----  shouldRecognizeSimultaneouslyWith ----")
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        print("----  shouldRequireFailureOf ----")
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        print("----  shouldBeRequiredToFailBy ----")
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        print("----  shouldReceive touch ----")
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive press: UIPress) -> Bool {
        print("----  shouldReceive press ----")
        return true
    }

}

