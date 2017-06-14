//
//  AppDelegate.swift
//  CardNavigationStack
//
//  Created by Stephen Silber on 5/19/17.
//  Copyright © 2017 calendre. All rights reserved.
//

import UIKit

public extension Int {
    static func random(from: Int, to: Int) -> Int {
        guard to > from else {
            assertionFailure("Can not generate negative random numbers")
            return 0
        }
        return Int(arc4random_uniform(UInt32(to - from)) + UInt32(from))
    }
}

extension UIColor {
    static func random() -> UIColor {
        let colors: [UIColor] = [UIColor(red:0.36, green:0.37, blue:0.59, alpha:1.00),
                                 UIColor(red:1.00, green:0.76, blue:0.27, alpha:1.00),
                                 UIColor(red:1.00, green:0.42, blue:0.42, alpha:1.00),
                                 UIColor(red:0.25, green:0.47, blue:0.55, alpha:1.00),
                                 UIColor(red:0.35, green:0.53, blue:1.00, alpha:1.00),
                                 UIColor(red:0.36, green:0.37, blue:0.59, alpha:1.00),
                                 UIColor(red:1.00, green:0.76, blue:0.27, alpha:1.00),
                                 UIColor(red:1.00, green:0.42, blue:0.42, alpha:1.00),
                                 UIColor(red:0.25, green:0.47, blue:0.55, alpha:1.00),
                                 UIColor(red:0.35, green:0.53, blue:1.00, alpha:1.00),
                                 UIColor(red:0.60, green:0.61, blue:0.58, alpha:1.00),
                                 UIColor(red:0.95, green:0.36, blue:0.11, alpha:1.00),
                                 UIColor(red:0.86, green:0.16, blue:0.21, alpha:1.00),
                                 UIColor(red:0.13, green:0.44, blue:0.33, alpha:1.00),
                                 UIColor(red:0.53, green:0.76, blue:0.56, alpha:1.00),
                                 UIColor(red:0.89, green:0.69, blue:0.22, alpha:1.00),
                                 UIColor(red:0.26, green:0.24, blue:0.22, alpha:1.00)]
        
        return colors[Int.random(from: 0, to: colors.count)]
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        window = UIWindow()
        
        window?.rootViewController = RootViewController(nibName: nil, bundle: nil)
        window?.makeKeyAndVisible()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

