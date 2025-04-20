
//
//  PlayHistoryItemCollectionCell.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2025/2/23.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import MarqueeLabel

class PlayHistoryItemCollectionCell: UICollectionViewCell {
    private var iconView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.layerCornerRadius = Constants.Size.CornerRadiusTiny
        return view
    }()
    
    private var titleLabel: UILabel = {
        let view = MarqueeLabel()
        view.font = Constants.Font.body()
        view.textColor = Constants.Color.LabelPrimary
        view.type = .leftRight
        return view
    }()
    
    private var subTitleLabel: UILabel = {
        let view = UILabel()
        view.font = Constants.Font.caption()
        view.textColor = Constants.Color.LabelSecondary
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = Constants.Color.Background
        layerCornerRadius = Constants.Size.CornerRadiusMid
        enableInteractive = true
        delayInteractiveTouchEnd = true

        addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMin)
            make.centerY.equalToSuperview()
            make.size.equalTo(50)
        }
        
        let titleContainerView = UIView()
        addSubview(titleContainerView)
        titleContainerView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(iconView.snp.trailing).offset(Constants.Size.ContentSpaceTiny)
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceTiny)
        }
        
        titleContainerView.addSubviews([titleLabel, subTitleLabel])
        titleLabel.snp.makeConstraints { make in
            make.leading.top.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
        }
        subTitleLabel.snp.makeConstraints { make in
            make.leading.bottom.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(Constants.Size.ContentSpaceUltraTiny)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func setData(game: Game) {
        let estimated = iconView.size == .zero ? .init(40) : iconView.size
        iconView.image = .tryDataImageOrPlaceholder(tryData: game.gameCover?.storedData(), preferenceSize: estimated)
        titleLabel.text = game.aliasName ?? game.name
        if let timeAgo = game.latestPlayDate?.timeAgo() {
            subTitleLabel.text = R.string.localizable.readyGameInfoSubTitle(timeAgo, Date.timeDuration(milliseconds: Int(game.totalPlayDuration)))
        } else {
            subTitleLabel.text = ""
        }
    }
}
