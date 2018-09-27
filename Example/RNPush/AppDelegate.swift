//
//  AppDelegate.swift
//  RNPush
//
//  Created by wangcong on 09/10/2018.
//  Copyright (c) 2018 wangcong. All rights reserved.
//

import UIKit
import RNPush

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
//        #if DEBUG
        RNPushManager.register(serverUrl: "http://pm.qa.medlinker.com/api",
                               deploymentKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoibWVkLXJuLWlvcyIsImVudiI6ImRldmVsb3BtZW50IiwiaWF0IjoxNTMwNjk3MzAyfQ.43XEuT6zm8l9OSiwGoPzDYNl6ULHzBgwCs5U9yNo6r0",
                               bundleResource: "RNResources")
//        #else
//        RNPushManager.register(serverUrl: "https://pm.medlinker.com/api/",
//                               deploymentKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoibWVkLXJuLWlvcyIsImVudiI6InByb2R1Y3Rpb24iLCJpYXQiOjE1MzA2OTczMDJ9.JTtq93c1a-ysiS_kUCZhuvgtRK0_rVJkIvn_968LJPI",
//                               bundleResource: "RNResources")
//        #endif

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

