//
//  PhotoThumbnailView.swift
//  PhotoCompress
//
//  Created by Cirno MainasuK on 2021-7-9.
//  Copyright © 2021 MainasuK. All rights reserved.
//

import os.log
import SwiftUI
import Combine
import Photos
import Kingfisher

@MainActor
class PhotoThumbnailViewModel: ObservableObject {

    let logger = Logger(subsystem: "PhotoThumbnailViewModel", category: "ViewModel")

    let context: AppContext
    private var imageManager: PHImageManager {
        context.photoService.imageManager
    }

    var disposeBag = Set<AnyCancellable>()

    // input
    let index: Int

    let isAppear = CurrentValueSubject<Bool, Never>(false)
    let frame = CurrentValueSubject<CGRect, Never>(.zero)

    var imageRequestID: PHImageRequestID?

    // output
    @Published var photo: UIImage?

    init(context: AppContext, index: Int) {
        self.context = context
        self.index = index

        let scale = UIScreen.main.scale

        Publishers.CombineLatest(
            isAppear.removeDuplicates(),
            frame.map { CGSize(width: $0.size.width * scale, height: $0.size.height * scale) }.removeDuplicates()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] isAppear, size in
            guard let self = self else { return }
            guard isAppear, size != .zero else {
                self.invalid()
                return
            }


            self.fetchThumbnail(targetSize: size)
        }
        .store(in: &disposeBag)

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
                assert(Thread.isMainThread)
                self.photo = image
            }
        }
    }

    private func cancelFetch() {
        if let imageRequestID = self.imageRequestID {
            imageManager.cancelImageRequest(imageRequestID)
        }
        imageRequestID = nil
    }

    func invalid() {
        logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): invalid \(self.index)")
        cancelFetch()
        photo = nil
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
                }
            }
            .onAppear {
                viewModel.isAppear.value = true
            }
            .onDisappear {
                viewModel.isAppear.value = false
            }
            .preference(
                key: PhotoThumbnailFramePreferenceKey.self,
                value: proxy.frame(in: .global)
            )
            .onPreferenceChange(PhotoThumbnailFramePreferenceKey.self) { frame in
                viewModel.frame.value = frame
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
