//
//  PhotoService.swift
//  PhotoCompress
//
//  Created by Cirno MainasuK on 2021-7-9.
//  Copyright © 2021 MainasuK. All rights reserved.
//

import os.log
import Foundation
import Photos

class PhotoService: NSObject, ObservableObject {

    private let logger = Logger(subsystem: "PhotoService", category: "service")

    var photos: PHFetchResult<PHAsset> = {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)

        let albums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: nil)
        guard albums.count == 1, let allPhotos = albums.firstObject else {
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            return PHAsset.fetchAssets(with: options)
        }

        return PHAsset.fetchAssets(in: allPhotos, options: options)
    }() {
        didSet { objectWillChange.send() }
    }

    let imageManager = PHCachingImageManager()

    override init() {
        super.init()
        PHPhotoLibrary.shared().register(self)
    }

    deinit {
        imageManager.stopCachingImagesForAllAssets()
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

}

extension PhotoService {
    func setupPhotoAuthorization(status: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus()) {
        logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): status \(status.debugDescription)")

        switch status {
        case .authorized:
            break

        case .denied, .restricted:
            break
//            let title = NSLocalizedString("Access Photo Library", comment: "")
//            let message = NSLocalizedString("Please Allow App Access Photo", comment: "")
//            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
//
//            let openSettings = NSLocalizedString("Settings", comment: "")
//            let openSettingsAction = UIAlertAction(title: openSettings, style: .default) { _ in
//                if let appSettings = URL(string: UIApplication.openSettingsURLString) {
//                    UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
//                }
//            }
//            alertController.addAction(openSettingsAction)
//
//            let cancel = NSLocalizedString("Cancel", comment: "")
//            let cancelAction = UIAlertAction(title: cancel, style: .cancel, handler: nil)
//            alertController.addAction(cancelAction)

            //            present(alertController, animated: true, completion: nil)

        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { (newStatus) in
                DispatchQueue.main.async {
                    if newStatus == .authorized {
//                        self.collectionView.reloadData()
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
//                            self.scrollToBottom(animated: true)
//                        })
                    } else {
                        self.setupPhotoAuthorization(status: newStatus)
                    }
                }
            }
        case .limited:
            break
        @unknown default:
            assertionFailure()
        }
    }
}

// MARK: - PHPhotoLibraryChangeObserver
extension PhotoService: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        if let changeDetails = changeInstance.changeDetails(for: photos) {
            DispatchQueue.main.sync {
                logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): photos updated")
                self.photos = changeDetails.fetchResultAfterChanges
            }
        }
    }
}
