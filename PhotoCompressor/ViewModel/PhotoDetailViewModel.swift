//
//  PhotoDetailViewModel.swift
//  PhotoCompressor
//
//  Created by Cirno MainasuK on 2018-7-25.
//  Copyright © 2018年 MainasuK. All rights reserved.
//


import Foundation
import Photos

protocol PhotoDetailViewModelDelegate: class {
        func photoDetailViewModel(_ viewModel: PhotoDetailViewModel, willRequestImageFor asset: PHAsset, of requestID: PHImageRequestID)
        func photoDetailViewModel(_ viewModel: PhotoDetailViewModel, download asset: PHAsset, progress: Double, error: Error?, stop: UnsafeMutablePointer<ObjCBool>, info: [AnyHashable : Any]?) -> Void
}

final class PhotoDetailViewModel {

    let asset: PHAsset
    let indexPath: IndexPath
    let imageManager: PHCachingImageManager

    var requestID: PHImageRequestID?
    var progress = 1.0

    weak var delegate: PhotoDetailViewModelDelegate?
    weak var imageView: UIImageView? {
        didSet {
            requestImage()
        }
    }

    init(asset: PHAsset, at indexPath: IndexPath, requestBy imageManager: PHCachingImageManager) {
        self.asset = asset
        self.indexPath = indexPath
        self.imageManager = imageManager
    }

    func requestImage() {
        guard let imageView = imageView else {
            assertionFailure()
            return
        }

        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .opportunistic
        options.progressHandler = { [weak self] (progress, error, stop, info) in
            guard let `self` = self else { return }
            // consolePrint("\(self.asset.localIdentifier): \(progress)")
            self.progress = progress
            self.delegate?.photoDetailViewModel(self, download: self.asset, progress: progress, error: error, stop: stop, info: info)
        }

        let targetSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
        let id = imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .default, options: options) { image, info in
            let largeImage = (image?.size ?? .zero).isGreatOrEqual(of: imageView.image?.size ?? .zero) ? image : imageView.image
            imageView.image = largeImage

            // consolePrint("deliver: \(String(describing: image?.size))")
            // guard let info = info else { return }
            // consolePrint(info)
            // consolePrint(info[PHImageResultIsInCloudKey])
            // consolePrint(info[PHImageErrorKey])
        }

        requestID = id
        delegate?.photoDetailViewModel(self, willRequestImageFor: asset, of: id)
    }

    deinit {
        requestID.flatMap { imageManager.cancelImageRequest($0) }
    }

}
