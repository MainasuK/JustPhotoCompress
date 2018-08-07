//
//  PhotoCollectionViewCell.swift
//  PhotoCompressor
//
//  Created by Cirno MainasuK on 2018-7-16.
//  Copyright © 2018年 MainasuK. All rights reserved.
//

import UIKit
import Photos

class PhotoCollectionViewCell: UICollectionViewCell {

    override func prepareForReuse() {
        super.prepareForReuse()

        representedAssetIdentifier = ""
        imageView.image = nil
    }

    let imageView = UIImageView()

    var representedAssetIdentifier: String!

    override init(frame: CGRect) {
        super.init(frame: frame)

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
