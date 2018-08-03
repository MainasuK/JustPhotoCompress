//
//  PhotoCollectionView.swift
//  PhotoCompressor
//
//  Created by Cirno MainasuK on 2018-7-19.
//  Copyright © 2018年 MainasuK. All rights reserved.
//

import UIKit

protocol PhotoCollectionViewDelegate: UICollectionViewDelegate { }

class PhotoCollectionView: UICollectionView {

    let viewModel: PhotoCollectionViewModel

    weak var photoCollectionViewDelegate: PhotoCollectionViewDelegate?
    var previousIndexPathAndOffsetYAtCenter: (IndexPath, CGFloat)?

    init(viewModel: PhotoCollectionViewModel) {
        self.viewModel = viewModel

        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 1.0
        layout.minimumInteritemSpacing = 1.0    // Keep it const
        layout.sectionInsetReference = .fromSafeArea

        super.init(frame: .zero, collectionViewLayout: layout)

        backgroundColor = .darkText

        delegate = self
        dataSource = viewModel
        prefetchDataSource = viewModel
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension PhotoCollectionView: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, targetContentOffsetForProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        guard let indexPath = previousIndexPathAndOffsetYAtCenter?.0,
            let offsetY = previousIndexPathAndOffsetYAtCenter?.1 else {
//            assertionFailure()
            return proposedContentOffset
        }

        let attribute = collectionView.layoutAttributesForItem(at: indexPath)
        guard var origin = attribute?.frame.origin else {
            assertionFailure()
            return proposedContentOffset
        }

        origin.x = 0
        origin.y -= 0.5 * collectionView.bounds.height + offsetY

        if origin.y < 0.5 * collectionView.bounds.height {
            origin.y = -collectionView.safeAreaInsets.top
        }

        let lastSection = collectionView.numberOfSections - 1
        let lastIndexPath: IndexPath? = lastSection >= 0 ? IndexPath(item: collectionView.numberOfItems(inSection: lastSection) - 1, section: lastSection)  : nil

        if lastIndexPath == collectionView.indexPathsForVisibleItems.sorted().last,
        let layout = collectionViewLayout as? UICollectionViewFlowLayout {
            origin.y += layout.itemSize.height
        }

        return origin
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        photoCollectionViewDelegate?.collectionView?(collectionView, didSelectItemAt: indexPath)
    }

}

extension PhotoCollectionView: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let layout = collectionViewLayout as! UICollectionViewFlowLayout
        let numberInRow = collectionView.bounds.size.width < collectionView.bounds.size.height ? 4 : 7
        let totalSpacing = layout.minimumInteritemSpacing * CGFloat(numberInRow - 1)
        let safeAreaMargin = safeAreaInsets.left + safeAreaInsets.right
        let size = floor((collectionView.bounds.width - totalSpacing - safeAreaMargin) / CGFloat(numberInRow))

        layout.minimumLineSpacing = (collectionView.bounds.width - safeAreaMargin - size * CGFloat(numberInRow)) / CGFloat(numberInRow - 1)

        return CGSize(width: size, height: size)
    }

}
