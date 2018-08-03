//
//  ViewController.swift
//  PhotoCompressor
//
//  Created by Cirno MainasuK on 2018-7-16.
//  Copyright © 2018年 MainasuK. All rights reserved.
//

import UIKit
import Photos

class PhotoViewController: UIViewController {

    let viewModel = PhotoCollectionViewModel()
    var collectionView: PhotoCollectionView!
    private var transitionController: PhotoViewTransitionController?

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController.flatMap {
            transitionController = PhotoViewTransitionController(navigationController: $0)
            $0.delegate = transitionController
        }

        title = NSLocalizedString("Photos", comment: "")
        
        setupCollectionView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

         #warning("FIXME: init auth status issue")
        DispatchQueue.once(token: "firstViewDidAppear") {
            view.layoutIfNeeded()

            PHPhotoLibrary.requestAuthorization { status in
                DispatchQueue.main.async {
                    let indexPath = IndexPath(item: self.collectionView.numberOfItems(inSection: 0) - 1, section: 0)
                    self.collectionView.scrollToItem(at: indexPath, at: .bottom, animated: false)
                }
            }
        }
    }

    private func setupCollectionView() {
        collectionView = PhotoCollectionView(viewModel: viewModel)
        collectionView.photoCollectionViewDelegate = self
        viewModel.collectionView = collectionView

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        collectionView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
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
