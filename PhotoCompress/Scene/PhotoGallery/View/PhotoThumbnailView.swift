//
//  PhotoThumbnailView.swift
//  PhotoCompress
//
//  Created by Cirno MainasuK on 2021-7-9.
//  Copyright © 2021 MainasuK. All rights reserved.
//

import os.log
import SwiftUI
import Photos
import Kingfisher

class PhotoThumbnailViewModel: ObservableObject {

    let logger = Logger(subsystem: "PhotoThumbnailViewModel", category: "ViewModel")

    let context: AppContext
    private var imageManager: PHImageManager {
        context.photoService.imageManager
    }

    // input
    let index: Int

    // output
    var isFirstAppear = true
    var imageRequestID: PHImageRequestID?
    var frame: CGRect? = .zero
    @Published var photo: UIImage?

    init(context: AppContext, index: Int) {
        self.context = context
        self.index = index
    }

    func fetchThumbnail(targetSize: CGSize) {
        logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch assert: \(self.index) size: \(targetSize.debugDescription)")

        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true

        cancelFetch()
        let asset = context.photoService.photos[index]
        self.imageRequestID = self.imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options) { [weak self] image, options in
            guard let self = self else { return }
            if let image = image {
                self.photo = image
            }
        }
    }

    func cancelFetch() {
        if let imageRequestID = self.imageRequestID {
            imageManager.cancelImageRequest(imageRequestID)
        }
        imageRequestID = nil
    }

    func invalid() {
        logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): invalid \(self.index)")
        cancelFetch()
        photo = nil
        frame = nil
    }

    deinit {
        invalid()
    }

}

struct PhotoThumbnailView: View {

    @ObservedObject var viewModel: PhotoThumbnailViewModel

    var body: some View {
        GeometryReader { proxy in
            VStack {
                if let photo = viewModel.photo {
                    Image(uiImage: photo)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color(uiColor: .systemFill)
                        .onAppear {
                            let scale = UIScreen.main.scale
                            let targetSize = CGSize(width: proxy.size.width * scale, height: proxy.size.height * scale)
                            viewModel.fetchThumbnail(targetSize: targetSize)
                        }
                }
            }
            .onDisappear {
                viewModel.invalid()                         /// photo set to nil but still leaking
                print("\(viewModel.index) Disappear")
            }
            .onAppear(perform: {
                print("\(viewModel.index) Appear")
            })
            .preference(
                key: PhotoThumbnailFramePreferenceKey.self,
                value: proxy.frame(in: .global)
            )
            .onPreferenceChange(PhotoThumbnailFramePreferenceKey.self) { frame in
                viewModel.frame = frame
            }
        }
        .clipped()
    }
}

struct PhotoThumbnailView_Previews: PreviewProvider {
    static var previews: some View {
        PhotoThumbnailView(viewModel: PhotoThumbnailViewModel(context: AppContext.shared, index: 0))
            .frame(width: 300, height: 300)
    }
}

struct PhotoThumbnailFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) { }
}
