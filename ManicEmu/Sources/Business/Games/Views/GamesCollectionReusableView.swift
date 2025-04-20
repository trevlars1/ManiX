//
//  GamesCollectionReusableView.swift
//  ManicReader
//
//  Created by Aushuang Lee on 2025/1/3.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import UIKit

class GamesCollectionReusableView: UICollectionReusableView {
    var titleLabel: UILabel = {
        let view = UILabel()
        return view
    }()
    
    var skinButton: UIButton = {
        let view = UIButton(type: .custom)
        view.titleLabel?.font = Constants.Font.body(weight: .medium)
        view.setTitleColor(Constants.Color.LabelSecondary, for: .normal)
        view.setTitle(R.string.localizable.gamesSpecifySkin(), for: .normal)
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        if UIDevice.isPad {
            backgroundColor = Constants.Color.Background.withAlphaComponent(0.965)
        } else {
            makeBlur(blurColor: Constants.Color.Background)
        }
        
        
        addSubviews([titleLabel, skinButton])
        
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMax)
        }
        
        skinButton.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMax)
        }
    }
    
    func setData(title: String, highlightString: String? = nil) {
        titleLabel.attributedText = NSAttributedString(string: title, attributes: [.font: Constants.Font.title(), .foregroundColor: Constants.Color.LabelPrimary]).highlightString(highlightString)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
}

