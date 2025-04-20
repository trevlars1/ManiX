//
//  PriceItemCollectionCell.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2025/3/15.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import StoreKit

class PriceItemCollectionCell: UICollectionViewCell {
    
    private var infoLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        return view
    }()
    
    private var product: Product? = nil
    
    private var promptContainer: UIView = {
        let view = UIView()
        view.layerCornerRadius = Constants.Size.IconSizeMin.height/2
        return view
    }()
    
    private var promptLabel: UILabel = {
        let view = UILabel()
        view.textAlignment = .center
        view.textColor = Constants.Color.LabelPrimary
        view.font = Constants.Font.caption(weight: .bold)
        return view
    }()
    
    private var roundAndBorderView: RoundAndBorderView = {
        let view = RoundAndBorderView(roundCorner: .allCorners, radius: Constants.Size.CornerRadiusMax, borderWidth: 2)
        view.enableInteractive = true
        view.delayInteractiveTouchEnd = true
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(roundAndBorderView)
        roundAndBorderView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        roundAndBorderView.addSubview(infoLabel)
        infoLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMid)
            make.centerY.equalToSuperview()
        }
        
        roundAndBorderView.addSubview(promptContainer)
        promptContainer.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMid)
            make.height.equalTo(Constants.Size.IconSizeMin.height)
            make.width.greaterThanOrEqualTo(56)
            make.leading.greaterThanOrEqualTo(infoLabel.snp.trailing).offset(Constants.Size.ContentSpaceTiny)
        }
        
        promptContainer.addSubview(promptLabel)
        promptLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceTiny)
            make.top.bottom.equalToSuperview()
        }
    }
    
    override var isSelected: Bool {
        willSet {
            setData(product: product, isSelected: newValue)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setData(product: Product?, isSelected: Bool) {
        if let product = product {
            self.product = product
            
            
            let labelColor =  isSelected ? Constants.Color.LabelPrimary : Constants.Color.LabelSecondary
            
            let smallFontAttributes: [NSAttributedString.Key : Any] = [.font: Constants.Font.caption(size: .l, weight: .semibold), .foregroundColor: labelColor]
            
            let bigFontAttributes: [NSAttributedString.Key : Any] = [.font: Constants.Font.title(size: .l, weight: .bold), .foregroundColor: labelColor]
            
            let currencySymbol = product.priceFormatStyle.locale.currencySymbol ?? product.priceFormatStyle.currencyCode
            
            let priceString = NSMutableAttributedString(string: "\n" + currencySymbol + "\(product.price)", attributes: bigFontAttributes)
            
            var description = ""
            
            description += R.string.localizable.foreverDescription()
            priceString.append(NSAttributedString(string: " ", attributes: bigFontAttributes))
            var newSmallFontAttributes = smallFontAttributes
            newSmallFontAttributes[.strikethroughStyle] = NSNumber(value: NSUnderlineStyle.single.rawValue as Int)
            priceString.append(NSAttributedString(string:"\(currencySymbol)" + "\(product.price*2)", attributes: newSmallFontAttributes))
            promptLabel.text = R.string.localizable.promptLabelForForever()
            promptContainer.backgroundColor = Constants.Color.Yellow
            
            
            let descriptionString = NSMutableAttributedString(string: description, attributes: smallFontAttributes)
            if Locale.isRTLLanguage {
                infoLabel.attributedText = priceString + " " + descriptionString
            } else {
                infoLabel.attributedText = descriptionString + priceString
            }
            
            
            roundAndBorderView.borderColor = isSelected ? Constants.Color.Red : Constants.Color.LabelSecondary
            roundAndBorderView.backgroundColor = isSelected ? Constants.Color.Red.withAlphaComponent(0.1) : Constants.Color.BackgroundSecondary
        }
    }
}
