//
//  SkinCollectionViewCell.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2025/2/20.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import UIKit
import ManicEmuCore

class SkinCollectionViewCell: UICollectionViewCell {
    
    var controllerView: ControllerView = {
        let view = ControllerView()
        view.layerCornerRadius = Constants.Size.CornerRadiusMid
        view.isUserInteractionEnabled = false
        return view
    }()
    
    private var selectImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .center
        view.layerCornerRadius = Constants.Size.IconSizeMin.height/2
        view.layer.shadowColor = Constants.Color.Shadow.cgColor
        view.layer.shadowOpacity = 0.5
        view.layer.shadowRadius = 2
        view.image = UIImage(symbol: .checkmarkCircleFill, weight: .bold, colors: [Constants.Color.LabelPrimary, Constants.Color.Red])
        view.alpha = 0
        return view
    }()
    
    override var isSelected: Bool {
        willSet {
            UIView.springAnimate {
                self.selectImageView.alpha = newValue ? 1 : 0
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        enableInteractive = true
        delayInteractiveTouchEnd = true
        layerCornerRadius = Constants.Size.CornerRadiusMid
        backgroundColor = .black
        addSubview(controllerView)
        controllerView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalToSuperview()
        }
        
        addSubview(selectImageView)
        selectImageView.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceTiny)
            make.size.equalTo(Constants.Size.IconSizeMin)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setData(controllerSkin: ControllerSkin, traits: ControllerSkin.Traits) {
        let screenAspectRatio: CGFloat
        if traits.orientation == .portrait {
            screenAspectRatio = Constants.Size.WindowSize.aspectRatio
        } else {
            screenAspectRatio = Constants.Size.WindowSize.height/Constants.Size.WindowSize.width
        }
        if let aspectRatio = controllerSkin.aspectRatio(for: traits), abs(aspectRatio.aspectRatio - screenAspectRatio) > 0.1 {
            controllerView.snp.updateConstraints { make in
                make.height.equalToSuperview().offset(-(height - (width/aspectRatio.aspectRatio)))
            }
        } else {
            controllerView.snp.updateConstraints { make in
                make.height.equalToSuperview()
            }
        }
        controllerView.customControllerSkinTraits = traits
        controllerView.controllerSkin = controllerSkin
    }
}
