//
//  ViewControllerViewModel.swift
//  PhotoCompressor
//
//  Created by Cirno MainasuK on 2018-7-16.
//  Copyright © 2018年 MainasuK. All rights reserved.
//

import Foundation
import Photos

final class PhotoCollectionViewModel: NSObject {

    let queue = DispatchQueue(label: "com.mainasuk.prefetchingQueue")

    weak var collectionView: UICollectionView? {
        didSet {
            collectionView?.register(PhotoCollectionViewCell.self, forCellWithReuseIdentifier: "PhotoCollectionViewCell")
        }
    }

    var allPhotos: PHFetchResult<PHAsset> = {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        return PHAsset.fetchAssets(with: options)
    }() {
        didSet { collectionView?.reloadData() }
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

extension PhotoCollectionViewModel: PHPhotoLibraryChangeObserver {

    func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.sync {
            if let changeDetails = changeInstance.changeDetails(for: allPhotos) {
                allPhotos = changeDetails.fetchResultAfterChanges
            }
        }
    }

}

extension PhotoCollectionViewModel: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allPhotos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as! PhotoCollectionViewCell
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        let asset = allPhotos.object(at: indexPath.item)

        cell.representedAssetIdentifier = asset.localIdentifier

        let scale = UIScreen.main.scale
        let targetSize = CGSize(width: layout.itemSize.width * scale, height: layout.itemSize.height * scale)
        cell.label.text = "\(indexPath.row)"
        cell.label.textColor = .red

        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true

        imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options) { image, _ in
            if cell.representedAssetIdentifier == asset.localIdentifier {
                cell.imageView.image = image
            }
        }

        return cell
    }

}

extension PhotoCollectionViewModel: UICollectionViewDataSourcePrefetching {

    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        guard let collectionViewLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            assertionFailure()
            return
        }
        let assets = indexPaths.map { allPhotos[$0.row] }

        imageManager.startCachingImages(for: assets, targetSize: collectionViewLayout.itemSize, contentMode: .aspectFit, options: nil)
    }

    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        guard let collectionViewLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            assertionFailure()
            return
        }
        let assets = indexPaths.map { allPhotos[$0.row] }

        imageManager.stopCachingImages(for: assets, targetSize: collectionViewLayout.itemSize, contentMode: .aspectFit, options: nil)
    }

}
