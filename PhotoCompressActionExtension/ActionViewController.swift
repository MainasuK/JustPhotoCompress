//
//  ActionViewController.swift
//  PhotoCompressActionExtension
//
//  Created by Cirno MainasuK on 2018-8-1.
//  Copyright © 2018年 MainasuK. All rights reserved.
//

import UIKit
import MobileCoreServices
import AVFoundation

let blockUTI = "com.mainasuk.PhotoCompressor.Item"

class ActionViewController: UIViewController {

    @IBOutlet weak var closeBarButtonItem: UIBarButtonItem! {
        didSet {
            closeBarButtonItem.title = NSLocalizedString("Close", comment: "")
        }
    }

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var qualityBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var sizeBarButtonItem: UIBarButtonItem!


    var isActionExtension: Bool {
        return extensionContext != nil
    }

    var originImage: UIImage!
    var originImageSizeMB: Float = 0.0
    var quality: PhotoCompressor.Quality = .good {
        didSet {
            qualityBarButtonItem.title = "\(qualityString): \(quality.string)"
        }
    }
    var size: PhotoCompressor.Size = .medium {
        didSet {
            sizeBarButtonItem.title = "\(sizeString): \(size.string)"
        }
    }

    lazy var formSheetFrame: CGRect = {
        let navigationBarHeight = navigationController?.navigationBar.bounds.height ?? 50.0
        let toolbarHeight = toolbar.bounds.height == 0 ? 44.0 : toolbar.bounds.height
        return CGRect(origin: .zero, size: CGSize(width: 540, height: 620 - navigationBarHeight - toolbarHeight))
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        if originImage != nil {
            imageView.image = originImage
            navigationController?.navigationBar.barStyle = .blackTranslucent
            toolbar.barStyle = .blackTranslucent

            view.backgroundColor = .black

            self.preferredContentSize = self.bestContentSize(with: originImage)
            self.view.setNeedsLayout()

            if originImageSizeMB > 0.0 {
                let format = NSLocalizedString("Original: %.3fMiB", comment: "")
                navigationItem.prompt = String(format: format, originImageSizeMB)
            }

            setupToolbar()
            compress()
            
            return
        }

        var imageFound = false
        for item in extensionContext!.inputItems as! [NSExtensionItem] {
            for provider in item.attachments! as! [NSItemProvider] where provider.hasItemConformingToTypeIdentifier(kUTTypeImage as String) {
                weak var weakImageView = imageView
                provider.loadItem(forTypeIdentifier: kUTTypeImage as String, options: nil, completionHandler: { (imageURL, error) in
                    consolePrint(error)

                    DispatchQueue.main.async {
                        if let imageView = weakImageView,
                        let imageURL = imageURL as? URL,
                        let data = try? Data(contentsOf: imageURL),
                        let image = UIImage(data: data) {
                            imageView.image = image
                            self.originImage = image

                            // Set view frame to fit image
                            self.preferredContentSize = self.bestContentSize(with: image)

                            let info = PhotoCompressor.shared.imageInfo(of: data)
                            self.navigationItem.prompt = info.short
                            self.title = info.large
                            self.setupToolbar()
                            self.compress()
                            self.view.setNeedsLayout()
                        }
                    }
                })

                imageFound = true
                break
            }   // end for provider

            if imageFound {
                break
            }
        }   // end for item

        if !imageFound {
            title = NSLocalizedString("Not Found Photo", comment: "")
            toolbar.isHidden = true
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.layoutIfNeeded()
    }

    @IBAction func doneBarButtonItemPressed(_ sender: UIBarButtonItem) {
        if isActionExtension {
            assert(extensionContext != nil)
            extensionContext?.completeRequest(returningItems: self.extensionContext!.inputItems, completionHandler: nil)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }

    @IBAction func actionBarButtonItemPressed(_ sender: UIBarButtonItem) {
        guard let image = originImage else { return }
        let controller = UIActivityViewController(activityItems: [image, ActionExtensionBlockerItem()], applicationActivities: nil)

        present(controller, animated: true, completion: nil)
    }

    private let qualityString = NSLocalizedString("Quality", comment: "")
    private let sizeString = NSLocalizedString("Size", comment: "")

    private func setupToolbar() {
        qualityBarButtonItem.target = self
        qualityBarButtonItem.action = #selector(ActionViewController.qualityBarButtonItemPressed(_:))

        // Not show size option in action extension to prevent memory issue (limit 128MiB)
        if !isActionExtension {
            sizeBarButtonItem.target = self
            sizeBarButtonItem.action = #selector(ActionViewController.sizeBarButtonItemPressed(_:))
        } else {
            sizeBarButtonItem.tintColor = .clear
        }

        quality = .good
        size = .medium
    }

    @objc func qualityBarButtonItemPressed(_ sender: UIBarButtonItem) {
        if isActionExtension {
            let controller = ActionOptionTableViewController()
            let viewModel = ActionQualityOptionTableViewModel()
            viewModel.delegate = self
            controller.viewModel = viewModel
            navigationController?.pushViewController(controller, animated: true)
        } else {
            let title = NSLocalizedString("Quality", comment: "")
            let alertController = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)

            let greatAction = UIAlertAction(title: NSLocalizedString("Great", comment: ""), style: .default) { _ in
                self.quality = .great
                self.compress()
            }
            let goodAction = UIAlertAction(title: NSLocalizedString("Good", comment: ""), style: .default) { _ in
                self.quality = .good
                self.compress()
            }
            let normalAction = UIAlertAction(title: NSLocalizedString("Normal", comment: ""), style: .default) { _ in
                self.quality = .normal
                self.compress()
            }

            alertController.addAction(greatAction)
            alertController.addAction(goodAction)
            alertController.addAction(normalAction)

            let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
            alertController.addAction(cancelAction)

            present(alertController, animated: true, completion: nil)
        }
    }

    @objc func sizeBarButtonItemPressed(_ sender: UIBarButtonItem) {
        if isActionExtension {
            let controller = ActionOptionTableViewController()
            let viewModel = ActionSizeOptionTableViewModel()
            viewModel.delegate = self
            controller.viewModel = viewModel
            navigationController?.pushViewController(controller, animated: true)
        } else {
            let title = NSLocalizedString("Size", comment: "")
            let alertController = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)

            let largeAction = UIAlertAction(title: NSLocalizedString("Large", comment: ""), style: .default) { _ in
                self.size = .large
                self.compress()
            }
            let mediumAction = UIAlertAction(title: NSLocalizedString("Medium", comment: ""), style: .default) { _ in
                self.size = .medium
                self.compress()
            }
            let smallAction = UIAlertAction(title: NSLocalizedString("Small", comment: ""), style: .default) { _ in
                self.size = .small
                self.compress()
            }

            alertController.addAction(largeAction)
            alertController.addAction(mediumAction)
            alertController.addAction(smallAction)

            let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            
            present(alertController, animated: true, completion: nil)
        }
    }

    private func bestContentSize(with image: UIImage) -> CGSize {
        let toolbarHeight = toolbar.bounds.size.height
        let aspectRatio = CGSize(width: image.size.width, height: image.size.height)
        let imageSize = AVMakeRect(aspectRatio: aspectRatio, insideRect: formSheetFrame).size
        let contentSize = CGSize(width: max(imageSize.width, 400), height: imageSize.height + toolbarHeight)

        return contentSize
    }

    private func compress() {
        assert(originImage != nil)

        DispatchQueue.global().async {
            guard let data = PhotoCompressor.shared.jpgData(for: self.originImage, of: self.quality, of: self.size),
                let image = UIImage(data: data) else {
                    return
            }
            let info = PhotoCompressor.shared.imageInfo(of: data)

            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }
                self.imageView.image = image
                self.title = info.large
            }
        }
    }

}

// MARK: - ActionQualityOptionTableViewModelDelegate
extension ActionViewController: ActionQualityOptionTableViewModelDelegate {
    func didSelect(option: PhotoCompressor.Quality) {
        quality = option
        compress()
    }
}

// MARK: - ActionSizeOptionTableViewModelDelegate
extension ActionViewController: ActionSizeOptionTableViewModelDelegate {
    func didSelect(option: PhotoCompressor.Size) {
        size = option
        compress()
    }
}

class ActionExtensionBlockerItem: NSObject, UIActivityItemSource {
    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        return blockUTI
    }
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return NSObject()
    }
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return ""
    }
    func activityViewController(_ activityViewController: UIActivityViewController, thumbnailImageForActivityType activityType: UIActivity.ActivityType?, suggestedSize size: CGSize) -> UIImage? {
        return nil
    }
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return ""
    }
}

