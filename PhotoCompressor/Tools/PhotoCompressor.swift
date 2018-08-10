//
//  PhotoCompressor.swift
//  PhotoCompress
//
//  Created by Cirno MainasuK on 2018-8-1.
//  Copyright © 2018年 MainasuK. All rights reserved.
//

import UIKit

public class PhotoCompressor {

    // MARK: - Singleton
    private static let instance = PhotoCompressor()

    private init() {

    }

    public static var shared: PhotoCompressor {
        return self.instance
    }

    public enum Quality: CGFloat {
        case great  = 0.92
        case good   = 0.85
        case normal = 0.75

        public var string: String {
            switch self {
            case .great: return NSLocalizedString("Great", comment: "")
            case .good: return NSLocalizedString("Good", comment: "")
            case .normal: return NSLocalizedString("Normal", comment: "")
            }
        }
    }

    public enum Size: CGFloat {
        case large  = 0.75
        case medium = 0.50
        case small  = 0.25

        public var string: String {
            switch self {
            case .large: return NSLocalizedString("Large", comment: "")
            case .medium: return NSLocalizedString("Medium", comment: "")
            case .small: return NSLocalizedString("Small", comment: "")
            }
        }
    }

    public func jpgData(for image: UIImage, of compressionQuality: Quality, of size: Size) -> Data? {
        return UIImageJPEGRepresentation(image.scaleFitSize(with: size.rawValue), compressionQuality.rawValue)
    }

    public func imageInfo(of data: Data) -> (short: String, large: String) {
        let image = UIImage(data: data)!
        let imageSizeMB = Float(data.count) / (1024 * 1024)
        let imageSizeMBString = String(format: "%.3fMiB", imageSizeMB)
        let pixelString = "\(Int(image.size.width))×\(Int(image.size.height))"

        let format = NSLocalizedString("Original: %.3fMiB", comment: "")
        return (String(format: format, imageSizeMB),
                [imageSizeMBString, pixelString].compactMap { $0 }.joined(separator: "|"))
    }

}

extension UIImage {

    func scaleFitSize(with ratio: CGFloat) -> UIImage {
        let newSize = size.scale(with: ratio)

        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = true

        let render = UIGraphicsImageRenderer(size: newSize, format: format)
        return render.image { context in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

}

extension CGSize {

    func scale(with ratio: CGFloat) -> CGSize {
        // Safe floor. Avoid 0
        return CGSize(width: max(1, floor(width * ratio)), height: max(1, floor(height * ratio)))
    }
}
