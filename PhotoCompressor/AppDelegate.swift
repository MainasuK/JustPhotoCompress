//
//  AppDelegate.swift
//  PhotoCompressor
//
//  Created by Cirno MainasuK on 2018-7-16.
//  Copyright © 2018年 MainasuK. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        UINavigationBar.appearance().backgroundColor = .darkText

        let navigationController = UINavigationController(rootViewController: PhotoViewController())
        navigationController.navigationBar.barStyle = .black
        window?.rootViewController = navigationController
        window?.tintColor = .red

        // window?.layer.speed = 0.2

        return true
    }

}

