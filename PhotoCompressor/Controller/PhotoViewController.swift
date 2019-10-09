//
//  ViewController.swift
//  PhotoCompressor
//
//  Created by Cirno MainasuK on 2018-7-16.
//  Copyright © 2018年 MainasuK. All rights reserved.
//

import UIKit
import Photos
import os.activity

class PhotoViewController: UIViewController {

    let viewModel = PhotoCollectionViewModel()
    var collectionView: PhotoCollectionView!

    private let titleViewButton = UIButton(type: .custom)
    private var transitionController: PhotoViewTransitionController?

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController.flatMap {
            transitionController = PhotoViewTransitionController(navigationController: $0)
            $0.delegate = transitionController
        }

        titleViewButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleViewButton.setTitleColor(UIColor.white, for: .normal)
        titleViewButton.setTitle(NSLocalizedString("Photos", comment: ""), for: .normal)
        titleViewButton.addTarget(self, action: #selector(PhotoViewController.navigationBarPressed(_:)), for: .touchUpInside)
        navigationItem.titleView = titleViewButton

        navigationController?.navigationBar.backgroundColor = .clear

        setupCollectionView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        setupPhotoAuthorization()
    }

    private func setupPhotoAuthorization(status: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus()) {
        switch status {
        case .authorized:
            DispatchQueue.once(token: "firstViewDidAppear") {
                self.scrollToBottom()
            }

        case .denied, .restricted:
            let title = NSLocalizedString("Access Photo Library", comment: "")
            let message = NSLocalizedString("Please Allow App Access Photo", comment: "")
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

            let openSettings = NSLocalizedString("Settings", comment: "")
            let openSettingsAction = UIAlertAction(title: openSettings, style: .default) { _ in
                if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
                }
            }
            alertController.addAction(openSettingsAction)

            let cancel = NSLocalizedString("Cancel", comment: "")
            let cancelAction = UIAlertAction(title: cancel, style: .cancel, handler: nil)
            alertController.addAction(cancelAction)

            present(alertController, animated: true, completion: nil)

        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { (newStatus) in
                DispatchQueue.main.async {
                    if newStatus == .authorized {
                        self.collectionView.reloadData()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                            self.scrollToBottom(animated: true)
                        })
                    } else {
                        self.setupPhotoAuthorization(status: newStatus)
                    }
                }
            }
        @unknown default:
            assertionFailure()
        }
    }

    private func setupCollectionView() {
        collectionView = PhotoCollectionView(viewModel: viewModel)
        collectionView.photoCollectionViewDelegate = self
        viewModel.collectionView = collectionView

        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.frame = view.bounds
        view.addSubview(collectionView)
    }

    private func scrollToBottom(animated: Bool = false) {
        DispatchQueue.main.async {
            guard self.collectionView.numberOfItems(inSection: 0) > 0 else { return }
            let indexPath = IndexPath(item: self.collectionView.numberOfItems(inSection: 0) - 1, section: 0)
            self.collectionView.scrollToItem(at: indexPath, at: .bottom, animated: animated)
        }
    }

    // Hue degree (0 ~ 360)
    private func updateTitleColor(of degree: CGFloat) {
        let color = UIColor(hue: degree / 360.0, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        titleViewButton.setTitleColor(color, for: .normal)
    }

    @objc func navigationBarPressed(_ sender: UIButton) {
        guard isViewLoaded && view.window != nil else { return }
        scrollToBottom(animated: true)
    }

}

extension PhotoViewController {

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        let center = CGPoint(x: collectionView.bounds.size.width * 0.4, y: collectionView.contentOffset.y + collectionView.bounds.size.height * 0.5)

        if let indexPath = collectionView.indexPathForItem(at: center),
            let attribute = collectionView.layoutAttributesForItem(at: indexPath) {
            let offsetY = attribute.frame.minY - center.y

            collectionView.previousIndexPathAndOffsetYAtCenter = (indexPath, offsetY)
        }

        self.collectionView.collectionViewLayout.invalidateLayout()
    }

}

// MARK: - PhotoCollectionViewDelegate
extension PhotoViewController: PhotoCollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let controller = PhotoPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: [UIPageViewController.OptionsKey.interPageSpacing : 8.0])
        controller.viewModel = viewModel
        controller.indexPath = indexPath
        transitionController?.indexPathToTransition = indexPath
        navigationController?.pushViewController(controller, animated: true)
    }

}
