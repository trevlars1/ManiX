//
//  TransparentHoleView.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2025/3/19.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

class TransparentHoleView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        isUserInteractionEnabled = false
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .black
        isUserInteractionEnabled = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        applyMask()
    }
    
    private func applyMask() {
        let maskLayer = CAShapeLayer()
        let path = UIBezierPath(rect: bounds) 

        
        let transparentRect = self.bounds
        let transparentPath = UIBezierPath(roundedRect: transparentRect, cornerRadius: Constants.Size.CornerRadiusMax*2)
        path.append(transparentPath)
        path.usesEvenOddFillRule = true
        
        maskLayer.path = path.cgPath
        maskLayer.fillRule = .evenOdd
        
        layer.mask = maskLayer
    }
}
