//
//  PhotoTransitionItem.swift
//  PhotoCompressor
//
//  Created by Cirno MainasuK on 2018-7-24.
//  Copyright © 2018年 MainasuK. All rights reserved.
//

import UIKit
import Photos

class PhotoTransitionItem {
    let initialFrame: CGRect
    var image: UIImage {
        didSet {
            imageView?.image = image
        }
    }
    let indexPath: IndexPath
    var asset: PHAsset {
        didSet {
            localIdentifier = asset.localIdentifier
        }
    }
    var targetFrame: CGRect?
    var imageView: UIImageView?
    var touchOffset: CGVector = CGVector.zero
    var localIdentifier: String?

    init(initialFrame: CGRect, image: UIImage, indexPath: IndexPath, asset: PHAsset) {
        self.initialFrame = initialFrame
        self.image = image
        self.indexPath = indexPath
        self.asset = asset
    }
}
