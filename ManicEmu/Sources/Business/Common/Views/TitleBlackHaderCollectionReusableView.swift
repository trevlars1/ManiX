//
//  TitleHaderCollectionReusableView.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2025/1/21.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import UIKit

class TitleBlackHaderCollectionReusableView: UICollectionReusableView {
    var titleLabel: UILabel = {
        let view = UILabel()
        view.textColor = Constants.Color.LabelPrimary
        view.font = Constants.Font.title(size: .s)
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubviews([titleLabel])
        makeBlur(blurColor: .black)
        
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMax)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
}

class TitleBackgroundColorHaderCollectionReusableView: UICollectionReusableView {
    var titleLabel: UILabel = {
        let view = UILabel()
        view.textColor = Constants.Color.LabelPrimary
        view.font = Constants.Font.title(size: .s)
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubviews([titleLabel])
        makeBlur(blurColor: Constants.Color.Background)
        
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMax)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
}
