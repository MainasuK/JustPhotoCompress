//
//  PhotoDetailViewController.swift
//  PhotoCompressor
//
//  Created by Cirno MainasuK on 2018-7-19.
//  Copyright © 2018年 MainasuK. All rights reserved.
//

import UIKit
import Photos

class PhotoPageViewController: UIPageViewController {

    var viewModel: PhotoCollectionViewModel!
    var indexPath: IndexPath!

    var isControlHidden = false     // hidden control except image
    weak var transitionImage: UIImage?

    var originImageInfo: (id: String, size: Float) = ("", 0.0)

    lazy var progressView: PhotoLoadingProgressView = {
        let progressView = PhotoLoadingProgressView()
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.widthAnchor.constraint(equalToConstant: 30.0).isActive = true
        progressView.heightAnchor.constraint(equalToConstant: 30.0).isActive = true
        return progressView
    }()
    lazy var tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(PhotoPageViewController.tap(_:)))

    private lazy var progressItem = UIBarButtonItem(customView: progressView)
    private lazy var compressItem = UIBarButtonItem(title: NSLocalizedString("Compress", comment: ""), style: .plain, target: self, action: #selector(PhotoPageViewController.compressButtonPressed(_:)))

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addGestureRecognizer(tapGestureRecognizer)

        let controller = photoDetailViewController(at: indexPath.item)
        controller.imageView.image = transitionImage
        setViewControllers([controller], direction: .forward, animated: false, completion: nil)

        delegate = self
        dataSource = self

        // Setup for init item layout
        navigationItem.rightBarButtonItem = progressItem
        progressView.isHidden = true

        resetImageInfoOnTitle(at: indexPath)
        resetRightButtonItem(with: controller.viewModel)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar.alpha = isControlHidden ? CGFloat.leastNormalMagnitude : 1.0
    }

    func photoDetailViewController(at index: Int) -> PhotoDetailViewController {
        let controller = PhotoDetailViewController()
        controller.viewModel = PhotoDetailViewModel(asset: viewModel.allPhotos[index],
                                                    at: IndexPath(item: index, section: 0),
                                                    requestBy: viewModel.imageManager)
        controller.viewModel.delegate = self
        return controller
    }

    @objc func tap(_ sender: UITapGestureRecognizer) {
        isControlHidden = !isControlHidden

        let statusBarWindow = UIApplication.shared.value(forKey: "statusBarWindow") as? UIWindow
        // #warning("Check this heck")
        // 2018.07.25: iOS 12 beta 4 OK!
        assert(statusBarWindow != nil)
        UIView.animate(withDuration: TimeInterval(UINavigationControllerHideShowBarDuration)) {
            self.navigationController?.navigationBar.alpha = self.isControlHidden ? CGFloat.leastNormalMagnitude : 1.0
            statusBarWindow?.alpha = self.isControlHidden ? CGFloat.leastNormalMagnitude : 1.0
        }

        // Note: set alpha back to 1.0 in pop transition
    }

    @objc func compressButtonPressed(_ sender: UIBarButtonItem) {
        guard let photoDetailViewController = viewControllers?.first as? PhotoDetailViewController,
        let image = photoDetailViewController.imageView.image else { return }

        let bundle = Bundle(for: ActionViewController.self)
        let actionViewController = UIStoryboard(name: "MainInterface", bundle: bundle).instantiateViewController(withIdentifier: "ActionViewController") as! ActionViewController
        actionViewController.originImage = image
        if photoDetailViewController.viewModel.asset.localIdentifier == originImageInfo.id {
            actionViewController.originImageSizeMB = originImageInfo.size
        }
        let controller = UINavigationController(rootViewController: actionViewController)
        controller.modalPresentationStyle = .formSheet

        present(controller, animated: true, completion: nil)
    }

    deinit {
        consolePrint("deinit")
    }

    private func resetImageInfoOnTitle(at indexPath: IndexPath) {
        title = ""
        let asset = viewModel.allPhotos[indexPath.row]
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        viewModel.imageManager.requestImageData(for: asset, options: options) { [weak self] (data, string, _, _) in
            guard let `self` = self else { return }
            guard let data = data else { return }
            guard self.indexPath == indexPath else { return }
            
            // let formatString = string?.split(separator: ".").last?.uppercased()
            let imageSizeMB = Float(data.count) / (1024 * 1024)
            let imageSizeMBString = String(format: "%.3fMiB", imageSizeMB)
            let pixelString = "\(Int(asset.pixelWidth))×\(Int(asset.pixelHeight))"

            self.originImageInfo = (asset.localIdentifier, imageSizeMB)
            self.title = [imageSizeMBString, pixelString].compactMap { $0 }.joined(separator: "|")
        }
    }

    private func resetRightButtonItem(with viewModel: PhotoDetailViewModel) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            assert(viewModel.indexPath == self.indexPath)
            self.progressView.progress = CGFloat(viewModel.progress)
            self.progressView.isHidden = viewModel.progress == 1.0
            self.navigationItem.rightBarButtonItem = viewModel.progress == 1.0 ? self.compressItem : self.progressItem
        }
    }
}

extension PhotoPageViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed, let photoDetailViewController = pageViewController.viewControllers?.first as? PhotoDetailViewController else { return }
        indexPath = photoDetailViewController.viewModel.indexPath

        resetImageInfoOnTitle(at: indexPath)
        resetRightButtonItem(with: photoDetailViewController.viewModel)
    }
}

extension PhotoPageViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let controller = viewController as? PhotoDetailViewController else {
            return nil
        }

        let offset = 5

        let minIndex = max(0, controller.viewModel.indexPath.item - offset)
        let maxIndex = min(viewModel.allPhotos.count - 1, controller.viewModel.indexPath.item + offset)
        let assets = (minIndex...controller.viewModel.indexPath.item).map { viewModel.allPhotos[$0] }
        let assetsRemove = (controller.viewModel.indexPath.item...maxIndex).map { viewModel.allPhotos[$0] }

        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .opportunistic

        let targetSize = CGSize(width: view.bounds.width * UIScreen.main.scale,
                                height: view.bounds.height * UIScreen.main.scale)
        viewModel.queue.async {
            self.viewModel.imageManager.startCachingImages(for: assets, targetSize: targetSize, contentMode: .default, options: options)
            self.viewModel.imageManager.startCachingImages(for: assetsRemove, targetSize: targetSize, contentMode: .default, options: nil)
        }

        return controller.viewModel.indexPath.item > 0 ? photoDetailViewController(at: controller.viewModel.indexPath.item - 1) : nil
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let controller = viewController as? PhotoDetailViewController else {
            return nil
        }

        let offset = 5

        let minIndex = max(0, controller.viewModel.indexPath.item - offset)
        let maxIndex = min(viewModel.allPhotos.count - 1, controller.viewModel.indexPath.item + offset)
        let assets = (controller.viewModel.indexPath.item...maxIndex).map { viewModel.allPhotos[$0] }
        let assetsRemove = (minIndex...controller.viewModel.indexPath.item).map { viewModel.allPhotos[$0] }

        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .opportunistic

        let targetSize = CGSize(width: view.bounds.width * UIScreen.main.scale,
                                height: view.bounds.height * UIScreen.main.scale)
        viewModel.queue.async {
            self.viewModel.imageManager.startCachingImages(for: assets, targetSize: targetSize, contentMode: .default, options: options)
            self.viewModel.imageManager.startCachingImages(for: assetsRemove, targetSize: targetSize, contentMode: .default, options: options)
        }

        return controller.viewModel.indexPath.item + 1 < viewModel.allPhotos.count ? photoDetailViewController(at: controller.viewModel.indexPath.item + 1) : nil
    }

}

extension PhotoPageViewController: PhotoDetailViewModelDelegate {

    func photoDetailViewModel(_ viewModel: PhotoDetailViewModel, willRequestImageFor asset: PHAsset, of requestID: PHImageRequestID) {
        // consolePrint("\(requestID): \(asset)")
    }


    func photoDetailViewModel(_ viewModel: PhotoDetailViewModel, download asset: PHAsset, progress: Double, error: Error?, stop: UnsafeMutablePointer<ObjCBool>, info: [AnyHashable : Any]?) {
        guard viewModel.indexPath == indexPath else { return }
        resetRightButtonItem(with: viewModel)
    }

}
