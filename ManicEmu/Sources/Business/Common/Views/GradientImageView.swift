//
//  GradientImageView.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2025/3/17.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

class GradientImageView: UIImageView {
    private let gradientLayer = CAGradientLayer()
    private let maskLayer = CALayer()
    
    override init(image: UIImage?) {
        super.init(image: image)
        maskLayer.contents = image?.withRenderingMode(.alwaysTemplate).cgImage
        gradientLayer.colors = Constants.Color.Gradient.reversed().map({ $0.cgColor })
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        layer.addSublayer(gradientLayer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let size = image?.size {
            gradientLayer.frame = CGRect(origin: .zero, size: CGSize(width: size.width, height: size.height))
            maskLayer.frame = gradientLayer.frame
        }
        gradientLayer.mask = maskLayer
        image = image?.withTintColor(.clear, renderingMode: .alwaysOriginal)
    }
}
