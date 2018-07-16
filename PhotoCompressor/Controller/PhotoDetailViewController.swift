//
//  PhotoDetailViewController.swift
//  PhotoCompressor
//
//  Created by Cirno MainasuK on 2018-7-19.
//  Copyright © 2018年 MainasuK. All rights reserved.
//

import UIKit
import Photos

class PhotoDetailViewController: UIViewController {

    var viewModel: PhotoDetailViewModel!

    let imageView = UIImageView()

    override func viewDidLoad() {
        super.viewDidLoad()

        imageView.contentMode = .scaleAspectFit

        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        viewModel.imageView = imageView
    }

}

extension CGSize {
    func isGreatOrEqual(of size: CGSize) -> Bool {
        return width >= size.width && height >= size.height
    }
}
