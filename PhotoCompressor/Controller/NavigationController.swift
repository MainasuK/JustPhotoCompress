//
//  NavigationController.swift
//  PhotoCompress
//
//  Created by Cirno MainasuK on 2020/8/5.
//  Copyright © 2020 MainasuK. All rights reserved.
//

import os
import UIKit

final class NavigationController: UINavigationController {
    
    override var childForStatusBarHidden: UIViewController? {
        os_log("%{public}s[%{public}ld], %{public}s: delegate to %s", ((#file as NSString).lastPathComponent), #line, #function, topViewController.debugDescription)
        return topViewController
    }
    
}
