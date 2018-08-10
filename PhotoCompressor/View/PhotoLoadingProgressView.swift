//
//  PhotoLoadingProgressView.swift
//  PhotoCompressor
//
//  Created by Cirno MainasuK on 2018-7-24.
//  Copyright © 2018年 MainasuK. All rights reserved.
//

import UIKit

class PhotoLoadingProgressView: UIView {

    let color = UIColor.white.cgColor
    let radius: CGFloat = 10

    let borderLayer = CAShapeLayer()
    let shapeLayer = CAShapeLayer()
    let maskLayer = CAShapeLayer()
    var progress: CGFloat = 0.0 {
        didSet {
            if progress < maskLayer.strokeEnd {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                maskLayer.strokeEnd = max(0.0, min(1.0, progress))
                CATransaction.commit()
            } else {
                maskLayer.strokeEnd = max(0.0, min(1.0, progress))
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        layer.addSublayer(borderLayer)
        layer.addSublayer(shapeLayer)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.frame = bounds
        borderLayer.frame = bounds
        shapeLayer.frame = bounds
        maskLayer.frame = bounds

        borderLayer.path = {
            let path = UIBezierPath()
            path.addArc(withCenter: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            return path.cgPath
        }()
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.strokeColor = color
        borderLayer.lineWidth = 2.0

        shapeLayer.path = {
            let path = UIBezierPath()
            path.addArc(withCenter: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            return path.cgPath
        }()
        shapeLayer.fillColor = color

        maskLayer.path = {
            let path = UIBezierPath()
            path.addArc(withCenter: center, radius: radius * 0.5, startAngle: 0 - 0.5 * .pi, endAngle: .pi * 2 - 0.5 * .pi, clockwise: true)
            return path.cgPath
        }()
        maskLayer.lineWidth = radius
        maskLayer.lineCap = kCALineCapButt
        maskLayer.fillColor = UIColor.clear.cgColor
        maskLayer.strokeColor = UIColor.black.cgColor
        maskLayer.strokeEnd = progress
        shapeLayer.mask = maskLayer
    }

}
