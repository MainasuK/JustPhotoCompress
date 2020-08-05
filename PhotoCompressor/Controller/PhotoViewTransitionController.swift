//
//  PhotoViewTransitionController.swift
//  PhotoCompressor
//
//  Created by Cirno MainasuK on 2018-7-25.
//  Copyright © 2018年 MainasuK. All rights reserved.
//

import UIKit
import Photos

final class PhotoViewTransitionController: NSObject {

    weak var navigationController: UINavigationController?
    var indexPathToTransition: IndexPath?
    var initiallyInteractive = false

    private var panGestureRecognizer = UIPanGestureRecognizer()
    private var popInteractiveTransitioning: PhotoViewControllerAnimatedTransitioning?

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        super.init()

        navigationController.interactivePopGestureRecognizer?.isEnabled = false
        setupPanGestureRecognizer()
    }

    // For interactive pop page controller (a.k.a. detail controller)
    private func setupPanGestureRecognizer() {
        panGestureRecognizer.delegate = self
        panGestureRecognizer.maximumNumberOfTouches = 1
        panGestureRecognizer.addTarget(self, action: #selector(PhotoViewTransitionController.initInteractiveTransition(_:)))
        navigationController?.view.addGestureRecognizer(panGestureRecognizer)

        guard let interactivePopGestureRecognizer = navigationController?.interactivePopGestureRecognizer else { return }
        panGestureRecognizer.require(toFail: interactivePopGestureRecognizer)
    }

    @objc func initInteractiveTransition(_ sender: UIPanGestureRecognizer) {
        if sender.state == .began && popInteractiveTransitioning == nil {
            initiallyInteractive = true
            
            // restore control state before transition
            if let fromViewController = navigationController?.topViewController as? PhotoPageViewController {
                fromViewController.isControlHidden = false
                fromViewController.navigationController?.setNeedsStatusBarAppearanceUpdate()
            } else {
                assertionFailure()
            }
            
            navigationController?.setNavigationBarHidden(false, animated: false)
            navigationController?.popViewController(animated: true)
        }
    }

}


// MARK: - UIGestureRecognizerDelegate
extension PhotoViewTransitionController: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === panGestureRecognizer {
            guard let interactiveTransitioning = popInteractiveTransitioning else {    // if not poping
                let translation = panGestureRecognizer.translation(in: panGestureRecognizer.view)
                let translationIsVertical = (translation.y > 0) && (abs(translation.y) > abs(translation.x))
                return translationIsVertical && (navigationController?.viewControllers.count ?? 0 > 1)
            }

            return interactiveTransitioning.isInteractive
        }

        return true
    }
}

// MARK: - UINavigationControllerDelegate
extension PhotoViewTransitionController: UINavigationControllerDelegate {

    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        switch operation {
        case .push:
            guard let photoPageViewController = toVC as? PhotoPageViewController,
                let photoViewController = fromVC as? PhotoViewController,
                let indexPath = indexPathToTransition,
                let cell = photoViewController.collectionView.cellForItem(at: indexPath) as? PhotoCollectionViewCell,
                let image = cell.imageView.image else {
                    return nil
            }
            let asset = photoViewController.viewModel.allPhotos[indexPath.row]

            let options = PHImageRequestOptions()
            options.isSynchronous = true

            var largeImage: UIImage?
            let targetSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
            photoViewController.viewModel.imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .default, options: options) { image, info in
                largeImage = image
                // consolePrint("deliver: \(String(describing: image?.size))")
            }

            photoPageViewController.transitionImage = largeImage ?? image
            let item = PhotoTransitionItem(initialFrame: cell.convert(cell.bounds, to: nil),
                                           image: largeImage ?? image,
                                           indexPath: indexPath,
                                           asset: asset)

            return PhotoViewControllerAnimatedTransitioning(operation: operation, transitionItem: item, panGestureRecognizer: panGestureRecognizer)

        case .pop:
            guard let photoViewController = toVC as? PhotoViewController,
                let photoPageViewController = fromVC as? PhotoPageViewController,
                let photoDetailViewController = photoPageViewController.viewControllers?.first as? PhotoDetailViewController,
                let indexPath = photoPageViewController.indexPath,
                let layout = photoViewController.collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
                    return nil
            }

            let asset = photoViewController.viewModel.allPhotos[indexPath.row]
            var transitionImage = photoDetailViewController.imageView.image

            if transitionImage == nil {
                let targetSize = layout.itemSize
                let options = PHImageRequestOptions()
                options.isSynchronous = true
                photoViewController.viewModel.imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .default, options: options) { image, info in
                    transitionImage = image
                    // consolePrint("deliver: \(String(describing: image?.size))")
                }
            }

            // let imageView = photoDetailViewController.imageView

            // FIXME:
            let aspectRatio = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
            let initialFrame = AVMakeRect(aspectRatio: aspectRatio, insideRect: photoDetailViewController.view.bounds)

            guard let image = transitionImage else { return nil }
            let item = PhotoTransitionItem(initialFrame: initialFrame,
                                           image: image,
                                           indexPath: indexPath,
                                           asset: asset)

            assert(item.initialFrame != .zero)

            return PhotoViewControllerAnimatedTransitioning(operation: operation, transitionItem: item, panGestureRecognizer: panGestureRecognizer)

        default:
            return nil
        }
    }

    func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        guard let transitioning = animationController as? PhotoViewControllerAnimatedTransitioning,
        transitioning.operation == .pop, initiallyInteractive else {
            return nil
        }

        popInteractiveTransitioning = transitioning
        transitioning.delegate = self
        return transitioning
    }

}

// MARK: - PhotoViewControllerTransitioningDelegate
extension PhotoViewTransitionController: PhotoViewControllerTransitioningDelegate {

    func animationEnded(_ transitionCompleted: Bool) {
        consolePrint(transitionCompleted)

        indexPathToTransition = nil
        initiallyInteractive = false
        popInteractiveTransitioning = nil
    }

}
