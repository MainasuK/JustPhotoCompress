//
//  PHAuthorizationStatus.swift
//  PhotoCompress
//
//  Created by Cirno MainasuK on 2021-7-12.
//  Copyright © 2021 MainasuK. All rights reserved.
//

import Photos

extension PHAuthorizationStatus: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .notDetermined:    return "notDetermined"
        case .restricted:       return "restricted"
        case .denied:           return "denied"
        case .authorized:       return "authorized"
        case .limited:          return "limited"
        @unknown default:
            assertionFailure()
            return "@unknown"
        }
    }
}
