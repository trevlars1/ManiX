//
//  PlayHistoryBlankSlateView.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2025/3/11.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

class PlayHistoryBlankSlateView: UIView {
    
    enum TapType {
        case importGame, startGame
    }
    
    deinit {
        Log.debug("\(String(describing: Self.self)) deinit")
    }
    
    init(tapAction: ((TapType)->Void)? = nil) {
        super.init(frame: .zero)
        Log.debug("\(String(describing: Self.self)) init")
        let containerView = UIView()
        addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        let iconImageView = UIImageView(image: R.image.play_history_empty_icon())
        iconImageView.contentMode = .center
        containerView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.size.equalTo(100)
        }
        
        let titleLabel = UILabel()
        titleLabel.textColor = Constants.Color.LabelPrimary
        titleLabel.font = Constants.Font.title(size: .s, weight: .semibold)
        titleLabel.text = R.string.localizable.historyEmptyTitle()
        containerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(iconImageView.snp.bottom).offset(Constants.Size.ContentSpaceHuge)
            make.leading.trailing.equalToSuperview()
        }
        
        
        let gameCount = Database.realm.objects(Game.self).count
        let actionButton = HowToButton(title: gameCount > 0 ? R.string.localizable.historyEmptyStartGame() : R.string.localizable.historyEmptyImportGame()) {}
        actionButton.label.textColor = Constants.Color.LabelPrimary
        actionButton.backgroundColor = Constants.Color.Red
        containerView.addSubview(actionButton)
        actionButton.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Constants.Size.ContentSpaceHuge)
            make.height.equalTo(Constants.Size.ItemHeightUltraTiny)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        let button = UIButton()
        containerView.addSubview(button)
        button.snp.makeConstraints { make in
            make.edges.equalTo(actionButton)
        }
        button.onTap {
            tapAction?(gameCount > 0 ? .startGame : .importGame)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
}
