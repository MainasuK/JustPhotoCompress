import UIKit

var str = "Hello, playground"

enum Device: CaseIterable {
    case iPhoneX
    case iPhoneX_Safe_Portrait
    case iPhoneX_Safe_Landscape
    case iPhone8
    case iPhone8P
    case iPhoneSE
    case iPhone4S
    case iPad
    case iPadPro

    var size: CGSize {
        switch self {
        case .iPhoneX:  return CGSize(width: 375, height: 812)
        case .iPhoneX_Safe_Portrait:  return CGSize(width: 375, height: 812)
        case .iPhoneX_Safe_Landscape:  return CGSize(width: 375, height: 812)
        case .iPhone8:  return CGSize(width: 375, height: 667)
        case .iPhone8P: return CGSize(width: 414, height: 736)
        case .iPhoneSE: return CGSize(width: 320, height: 568)
        case .iPhone4S: return CGSize(width: 320, height: 480)
        case .iPad:     return CGSize(width: 768, height: 1024)
        case .iPadPro:  return CGSize(width: 1024, height: 1366)
        }
    }
}

private func itemSize(for device: Device, isHorizontal: Bool) -> (itemSize: CGSize, lineSpacing: CGFloat, numberInRow: Int) {
    let w = isHorizontal ? CGFloat(device.size.width) : CGFloat(device.size.height)
    let h = isHorizontal ? CGFloat(device.size.height) : CGFloat(device.size.width)

    let numberInRow = w < h ? 4 : 7
    let totalSpacing = 1.0 * CGFloat(numberInRow - 1)
    let size = floor((w - totalSpacing) / CGFloat(numberInRow))
    let spacing = (w - size * CGFloat(numberInRow)) / CGFloat(numberInRow - 1)

    return (CGSize(width: size, height: size), spacing, numberInRow)
}

Device.allCases
    .map { (String(describing: $0), itemSize(for: $0, isHorizontal: true), itemSize(for: $0, isHorizontal: false)) }
    .forEach { print($0) }

