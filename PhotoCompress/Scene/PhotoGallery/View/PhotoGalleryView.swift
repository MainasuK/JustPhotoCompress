//
//  PhotoGalleryView.swift
//  PhotoCompress
//
//  Created by Cirno MainasuK on 2021-7-12.
//  Copyright © 2021 MainasuK. All rights reserved.
//

import os.log
import SwiftUI

struct PhotoGalleryView: View {

    static let logger = Logger(subsystem: "PhotoGalleryView", category: "UI")

    @EnvironmentObject var context: AppContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass: UserInterfaceSizeClass?

    var columns: [GridItem] {
        guard let horizontalSizeClass = horizontalSizeClass else {
            return [GridItem(.adaptive(minimum: 90, maximum: 150), spacing: 1)]
        }

        switch horizontalSizeClass {
        case .compact:
            return [GridItem(.adaptive(minimum: 90, maximum: 150), spacing: 1)]
        case .regular:
            return [GridItem(.adaptive(minimum: 150, maximum: 300), spacing: 1)]
        @unknown default:
            return [GridItem(.adaptive(minimum: 150, maximum: 300), spacing: 1)]
        }
    }

    var body: some View {
        ScrollView(.vertical) {
            GeometryReader { geometry in
                Color.clear.preference(
                    key: ScrollOffsetPreferenceKey.self,
                    value: geometry.frame(in: .named("PhotoGalleryScrollView")).origin
                )
            }.frame(width: 0, height: 0)
            LazyVGrid(columns: columns, spacing: 1) {
                ForEach(0..<context.photoService.photos.count) { index in
                    let viewModel = PhotoThumbnailViewModel(context: context, index: index)
                    PhotoThumbnailView(viewModel: viewModel)
                        .aspectRatio(1, contentMode: .fill)
                }
            }
        }
        .coordinateSpace(name: "PhotoGalleryScrollView")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { contentOffset in
            // print(contentOffset)
        }
        .onAppear {
            PhotoGalleryView.logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): onAppear")
            context.photoService.setupPhotoAuthorization()
        }
    }
}

struct PhotoGalleryView_Previews: PreviewProvider {
    static var previews: some View {
        PhotoGalleryView()
    }
}

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero

    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) { }
}
