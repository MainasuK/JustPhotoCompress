//
//  PhotoGalleryViewController.swift
//  PhotoCompress
//
//  Created by Cirno MainasuK on 2021-7-12.
//  Copyright © 2021 MainasuK. All rights reserved.
//

import UIKit
import SwiftUI

final class PhotoGalleryViewController: UIViewController {

    let context = AppContext.shared

}

extension PhotoGalleryViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Photos"
        
        let hostingController = UIHostingController(
            rootView: PhotoGalleryView().environmentObject(context)
        )
        addChild(hostingController)
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hostingController.view.frame = view.bounds
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
    }

}
