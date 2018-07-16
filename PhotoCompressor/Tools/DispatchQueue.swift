//
//  DispatchQueue.swift
//  PhotoCompressor
//
//  Created by Cirno MainasuK on 2018-7-19.
//  Copyright © 2018年 MainasuK. All rights reserved.
//

import Foundation

public extension DispatchQueue {

    private static var _onceTracker = [String]()

    public class func once(token: String, block: () -> Void) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        if _onceTracker.contains(token) {
            return
        }

        _onceTracker.append(token)
        block()
    }
}
