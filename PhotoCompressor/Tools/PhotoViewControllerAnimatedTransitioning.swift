//
//  PhotoViewControllerAnimatedTransitioning.swift
//  PhotoCompressor
//
//  Created by Cirno MainasuK on 2018-7-23.
//  Copyright © 2018年 MainasuK. All rights reserved.
//

import UIKit
import AVFoundation

protocol PhotoViewControllerTransitioningDelegate: class {
    var initiallyInteractive: Bool { get }
    func animationEnded(_ transitionCompleted: Bool)
}

class PhotoViewControllerAnimatedTransitioning: NSObject {

    let transitionItem: PhotoTransitionItem
    let operation: UINavigationController.Operation
    let panGestureRecognizer: UIPanGestureRecognizer

    private var popInteractiveTransitionAnimator = PhotoViewControllerAnimatedTransitioning.animator(initialVelocity: .zero)
    private var itemInteractiveTransitionAnimator = PhotoViewControllerAnimatedTransitioning.animator(initialVelocity: .zero)

    var transitionContext: UIViewControllerContextTransitioning!
    var isInteractive: Bool { return transitionContext.isInteractive }

    weak var delegate: PhotoViewControllerTransitioningDelegate?

    class func animator(initialVelocity: CGVector = .zero) -> UIViewPropertyAnimator {
        let timingParameters = UISpringTimingParameters(mass: 4.0, stiffness: 1300, damping: 180, initialVelocity: initialVelocity)
        return UIViewPropertyAnimator(duration: 0.5, timingParameters: timingParameters)
    }

    init?(operation: UINavigationController.Operation, transitionItem item: PhotoTransitionItem, panGestureRecognizer: UIPanGestureRecognizer) {
        if operation == .none { return nil }

        self.operation = operation
        self.transitionItem = item
        self.panGestureRecognizer = panGestureRecognizer
        super.init()
    }

}

// MARK: - UIViewControllerAnimatedTransitioning
extension PhotoViewControllerAnimatedTransitioning: UIViewControllerAnimatedTransitioning {

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return TimeInterval(UINavigationController.hideShowBarDuration)
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        self.transitionContext = transitionContext
        switch operation {
        case .push: pushTransition(using: transitionContext)
        case .pop:  popTransition(using: transitionContext)
        default:
            assertionFailure()
            return
        }
    }

}

extension PhotoViewControllerAnimatedTransitioning {

    private func pushTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let _ = transitionContext.viewController(forKey: .from),
        let toViewController = transitionContext.viewController(forKey: .to),
        let fromView = transitionContext.view(forKey: UITransitionContextViewKey.from),
        let toView = transitionContext.view(forKey: UITransitionContextViewKey.to) else {
            assertionFailure()
            return
        }

        let containerView = transitionContext.containerView

        // Set transition image view
        let aspectRatio = CGSize(width: transitionItem.asset.pixelWidth, height: transitionItem.asset.pixelHeight)
        transitionItem.targetFrame = AVMakeRect(aspectRatio: aspectRatio, insideRect: toView.bounds)
        transitionItem.imageView = {
            let imageView = UIImageView(frame: containerView.convert(transitionItem.initialFrame, from: nil))
            imageView.clipsToBounds = true
            imageView.contentMode = .scaleAspectFill
            imageView.isUserInteractionEnabled = false
            imageView.image = transitionItem.image

            containerView.addSubview(imageView)
            return imageView
        }()

        // set to controller black background
        toView.backgroundColor = .clear
        toView.alpha = 0.0

        let animator = PhotoViewControllerAnimatedTransitioning.animator(initialVelocity: .zero)

        animator.addAnimations {
            self.transitionItem.imageView?.frame = self.transitionItem.targetFrame!
            toView.backgroundColor = .black
            fromView.alpha = 0.0
            toView.alpha = 1.0
        }
        animator.addCompletion { position in
            toView.frame = transitionContext.finalFrame(for: toViewController)
            containerView.addSubview(toView)
            self.transitionItem.imageView?.removeFromSuperview()
            transitionContext.completeTransition(true)
            fromView.alpha = 1.0
        }

        animator.startAnimation()
    }

    private func popTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromViewController = transitionContext.viewController(forKey: .from),
        let toViewController = transitionContext.viewController(forKey: .to),
        let photoPageViewController = fromViewController as? PhotoPageViewController,
        let _ = photoPageViewController.viewControllers?.first as? PhotoDetailViewController,
        let indexPath = photoPageViewController.indexPath,
        let collectionView = (toViewController as? PhotoViewController)?.collectionView,
        let fromView = transitionContext.view(forKey: UITransitionContextViewKey.from),
        let toView = transitionContext.view(forKey: UITransitionContextViewKey.to) else {
            assertionFailure()
            return
        }

        let containerView = transitionContext.containerView

        if !collectionView.indexPathsForVisibleItems.contains(indexPath) {
            collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
            collectionView.layoutIfNeeded()
        }

        guard let cell = collectionView.cellForItem(at: indexPath) as? PhotoCollectionViewCell else {
            assertionFailure()
            return
        }

        toView.alpha = 0.0
        toView.frame = transitionContext.finalFrame(for: toViewController)
        fromView.alpha = 0.0
        containerView.insertSubview(toView, at: 0)
        collectionView.cellForItem(at: indexPath)?.alpha = 0.0

        toViewController.view.layoutIfNeeded()
        transitionItem.targetFrame = cell.convert(cell.bounds, to: nil)
        transitionItem.imageView = {
            let imageView = UIImageView(frame: containerView.convert(transitionItem.initialFrame, from: nil))
            imageView.clipsToBounds = true
            imageView.contentMode = .scaleAspectFill
            imageView.isUserInteractionEnabled = true
            imageView.image = transitionItem.image

            containerView.addSubview(imageView)
            return imageView
        }()

        let animator = PhotoViewControllerAnimatedTransitioning.animator(initialVelocity: .zero)

        animator.addAnimations {
            toViewController.navigationController?.navigationBar.alpha = 1.0

            if #available(iOS 13.0, *) {
            } else {
                let statusBarWindow = UIApplication.shared.value(forKey: "statusBarWindow") as? UIWindow
                statusBarWindow?.alpha = 1.0
            }

            self.transitionItem.imageView?.frame = self.transitionItem.targetFrame!
            fromView.backgroundColor = .clear
            toView.alpha = 1.0
        }
        animator.addCompletion { position in
            collectionView.cellForItem(at: indexPath)?.alpha = 1.0
            self.transitionItem.imageView?.removeFromSuperview()
            fromView.alpha = 1.0
            fromView.removeFromSuperview()

            transitionContext.completeTransition(true)
        }

        animator.startAnimation()
    }

    func animationEnded(_ transitionCompleted: Bool) {
        delegate?.animationEnded(transitionCompleted)
    }

}

// MARK: - UIViewControllerInteractiveTransitioning
extension PhotoViewControllerAnimatedTransitioning: UIViewControllerInteractiveTransitioning {

    func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        self.transitionContext = transitionContext

        switch operation {
        case .pop:  popInteractiveTransition(using: transitionContext)
        default:
            assertionFailure()
            return
        }
    }


    var wantsInteractiveStart: Bool {
        consolePrint(delegate?.initiallyInteractive)
        return delegate?.initiallyInteractive ?? false
    }

}



extension PhotoViewControllerAnimatedTransitioning {

    @objc func updatePanGestureInteractive(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began, .changed:
            let translation = sender.translation(in: transitionContext.containerView)
            let percent = popInteractiveTransitionAnimator.fractionComplete + progressStep(for: translation)
            popInteractiveTransitionAnimator.fractionComplete = percent
            transitionContext.updateInteractiveTransition(percent)

            consolePrint("changing")
            updateTransitionItemPosition(of: translation)

            // Reset translation to zero
            sender.setTranslation(CGPoint.zero, in: transitionContext.containerView)
        case .ended, .cancelled:
            let targetPosition = completionPosition()
            targetPosition == .end ? transitionContext.finishInteractiveTransition() : transitionContext.cancelInteractiveTransition()

            animate(targetPosition)

        default:
            return
        }
    }

    private func convert(_ velocity: CGPoint, for item: PhotoTransitionItem?) -> CGVector {
        guard let currentFrame = item?.imageView?.frame, let targetFrame = item?.targetFrame else {
            return CGVector.zero
        }

        let dx = abs(targetFrame.midX - currentFrame.midX)
        let dy = abs(targetFrame.midY - currentFrame.midY)

        guard dx > 0.0 && dy > 0.0 else {
            return CGVector.zero
        }

        let range = CGFloat(35.0)
        let clippedVx = clip(-range, range, velocity.x / dx)
        let clippedVy = clip(-range, range, velocity.y / dy)
        return CGVector(dx: clippedVx, dy: clippedVy)
    }

    private func completionPosition() -> UIViewAnimatingPosition {
        let completionThreshold: CGFloat = 0.33
        let flickMagnitude: CGFloat = 1200 // pts/sec
        let velocity = panGestureRecognizer.velocity(in: transitionContext.containerView).vector
        let isFlick = (velocity.magnitude > flickMagnitude)
        let isFlickDown = isFlick && (velocity.dy > 0.0)
        let isFlickUp = isFlick && (velocity.dy < 0.0)

        if (operation == .push && isFlickUp) || (operation == .pop && isFlickDown) {
            return .end
        } else if (operation == .push && isFlickDown) || (operation == .pop && isFlickUp) {
            return .start
        } else if popInteractiveTransitionAnimator.fractionComplete > completionThreshold {
            return .end
        } else {
            return .start
        }
    }

    // Create item animator an start it
    func animate(_ toPosition: UIViewAnimatingPosition) {
        consolePrint("to end: \(toPosition == .end)")
        // Create a property animator to animate each image's frame change
        let gestureVelocity = panGestureRecognizer.velocity(in: transitionContext.containerView)
        let velocity = convert(gestureVelocity, for: transitionItem)
        let itemAnimator = PhotoViewControllerAnimatedTransitioning.animator(initialVelocity: velocity)

        itemAnimator.addAnimations {
            self.transitionItem.imageView?.frame = toPosition == .end ? self.transitionItem.targetFrame! : self.transitionItem.initialFrame
        }

        // Start the property animator and keep track of it
        self.itemInteractiveTransitionAnimator = itemAnimator
        itemAnimator.startAnimation()

        // Reverse the transition animator if we are returning to the start position
        popInteractiveTransitionAnimator.isReversed = (toPosition == .start)

        if popInteractiveTransitionAnimator.state == .inactive {
            popInteractiveTransitionAnimator.startAnimation()
        } else {
            let durationFactor = CGFloat(itemAnimator.duration / popInteractiveTransitionAnimator.duration)
            popInteractiveTransitionAnimator.continueAnimation(withTimingParameters: nil, durationFactor: durationFactor)
        }
    }

    private func progressStep(for translation: CGPoint) -> CGFloat {
        return (operation == .push ? -1.0 : 1.0) * translation.y / transitionContext.containerView.bounds.midY
    }

    private func updateTransitionItemPosition(of translation: CGPoint) {
        let progress = progressStep(for: translation)

        consolePrint(transitionContext.isInteractive)
        let initialSize = transitionItem.initialFrame.size
        assert(initialSize != .zero)

        guard let imageView = transitionItem.imageView,
        let finalSize = transitionItem.targetFrame?.size else {
            return
        }

        if imageView.frame.size == .zero {
            imageView.frame.size = initialSize
        }

        let currentSize = imageView.frame.size
        consolePrint(currentSize)

        assert((finalSize.width - initialSize.width) != 0.0)
        let itemPercentComplete = clip(-0.05, 1.05, (currentSize.width - initialSize.width) / (finalSize.width - initialSize.width) + progress)
        let itemWidth = lerp(initialSize.width, finalSize.width, itemPercentComplete)
        let itemHeight = lerp(initialSize.height, finalSize.height, itemPercentComplete)
        assert(currentSize.width != 0.0)
        assert(currentSize.height != 0.0)
        let scaleTransform = CGAffineTransform(scaleX: (itemWidth / currentSize.width), y: (itemHeight / currentSize.height))
        let scaledOffset = transitionItem.touchOffset.apply(transform: scaleTransform)

        imageView.center = (imageView.center + (translation + (transitionItem.touchOffset - scaledOffset))).point
        imageView.bounds = CGRect(origin: CGPoint.zero, size: CGSize(width: itemWidth, height: itemHeight))
        consolePrint("bounds: \(imageView.bounds)")
        transitionItem.touchOffset = scaledOffset
    }

    private func popInteractiveTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromViewController = transitionContext.viewController(forKey: .from),
            let toViewController = transitionContext.viewController(forKey: .to),
            let photoPageViewController = fromViewController as? PhotoPageViewController,
            let _ = photoPageViewController.viewControllers?.first as? PhotoDetailViewController,
            let indexPath = photoPageViewController.indexPath,
            let collectionView = (toViewController as? PhotoViewController)?.collectionView,
            let fromView = transitionContext.view(forKey: UITransitionContextViewKey.from),
            let toView = transitionContext.view(forKey: UITransitionContextViewKey.to) else {
                assertionFailure()
                return
        }

        let containerView = transitionContext.containerView
        let animator = popInteractiveTransitionAnimator

        // Set transition image view
        let aspectRatio = CGSize(width: transitionItem.asset.pixelWidth, height: transitionItem.asset.pixelHeight)
        if !collectionView.indexPathsForVisibleItems.contains(indexPath) {
            collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
            collectionView.layoutIfNeeded()
        }

        guard let cell = collectionView.cellForItem(at: indexPath) as? PhotoCollectionViewCell else {
            assertionFailure()
            return
        }

        toView.alpha = 0.0
        toView.frame = transitionContext.finalFrame(for: toViewController)
        toView.layoutIfNeeded()

        fromView.alpha = 0.0
        containerView.insertSubview(toView, at: 0)
        collectionView.cellForItem(at: indexPath)?.alpha = 0.0

        transitionItem.targetFrame = cell.convert(cell.bounds, to: nil)
        transitionItem.imageView = {
            let imageView = UIImageView(frame: AVMakeRect(aspectRatio: aspectRatio, insideRect: containerView.convert(transitionItem.initialFrame, to: nil)))
            imageView.clipsToBounds = true
            imageView.contentMode = .scaleAspectFill
            imageView.isUserInteractionEnabled = true
            imageView.image = transitionItem.image

            containerView.addSubview(imageView)
            return imageView
        }()

        animator.addAnimations {
            fromView.backgroundColor = .clear
            toView.alpha = 1.0

            toViewController.navigationController?.navigationBar.alpha = 1.0
            if #available(iOS 13.0, *) {

            } else {
                let statusBarWindow = UIApplication.shared.value(forKey: "statusBarWindow") as? UIWindow
                statusBarWindow?.alpha = 1.0
            }
        }
        animator.addCompletion { position in
            collectionView.cellForItem(at: indexPath)?.alpha = 1.0
            self.transitionItem.imageView?.removeFromSuperview()
            fromView.alpha = 1.0

            let alpha = (position == .end) ? 1.0 : (photoPageViewController.isControlHidden ? CGFloat.leastNormalMagnitude : 1.0)
            if #available(iOS 13.0, *) {

            } else {
                let statusBarWindow = UIApplication.shared.value(forKey: "statusBarWindow") as? UIWindow
                statusBarWindow?.alpha = alpha
            }

            toViewController.navigationController?.navigationBar.alpha = alpha

            transitionContext.completeTransition(position == .end)
        }

        // Note: change item.imageView transform via pan gesture
        panGestureRecognizer.addTarget(self, action: #selector(PhotoViewControllerAnimatedTransitioning.updatePanGestureInteractive(_:)))
    }

}

