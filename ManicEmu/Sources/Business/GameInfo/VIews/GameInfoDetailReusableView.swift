//
//  GameInfoDetailReusableView.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2025/2/14.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import UIKit
import BetterSegmentedControl
import RealmSwift

class GameInfoDetailReusableView: UICollectionReusableView {
    var backgroundBlurView: UIView = {
        let view = UIView()
        view.makeBlur()
        view.alpha = 0
        return view
    }()
    
    lazy var titleTextField: UITextField = {
        let textField = UITextField()
        textField.textColor = Constants.Color.LabelPrimary
        textField.font = UIFont.systemFont(ofSize: 17)
        textField.clearButtonMode = .never
        textField.returnKeyType = .done
        textField.onReturnKeyPress { [weak self, weak textField] in
            guard let self = self else { return }
            textField?.resignFirstResponder()
            if let game = self.game, let text = textField?.text?.trimmed {
                if text.isEmpty {
                    textField?.text = game.aliasName ?? game.name
                    UIView.makeToast(message: R.string.localizable.readyEditTitleFailed())
                } else if text != game.aliasName {
                    Game.change { realm in
                        game.aliasName = text
                    }
                }
            }
        }
        textField.onChange { [weak textField] text in
            if text.count > Constants.Size.GameNameMaxCount {
                if let markRange = textField?.markedTextRange, let _ = textField?.position(from: markRange.start, offset: 0) { } else {
                    textField?.text = String(text.prefix(Constants.Size.GameNameMaxCount))
                }
            }
        }
        return textField
    }()
    
    private lazy var editTitleButton: SymbolButton = {
        let view = SymbolButton(image: R.image.customPencilLine()?.applySymbolConfig(size: Constants.Size.IconSizeMin.height))
        view.backgroundColor = .clear
        view.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            if !self.titleTextField.isFirstResponder {
                self.titleTextField.becomeFirstResponder()
            }
        }
        return view
    }()
    
    private var subtitleIcon: UIImageView = {
        let view = UIImageView()
        view.image = .symbolImage(.starCircleFill)
        return view
    }()
    
    private var subtitleLabel: UILabel = {
        let view = UILabel()
        view.textColor = Constants.Color.LabelSecondary
        view.font = Constants.Font.body()
        return view
    }()

    private lazy var skinButton: SymbolButton = {
        let view = SymbolButton(symbol: .tshirt, title: R.string.localizable.gamesSpecifySkin())
        view.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            if let game = self.game {
                topViewController()?.present(SkinSettingsViewController(game: game), animated: true)
            }
        }
        return view
    }()
    
    private lazy var cheatCodeButton: SymbolButton = {
        let view = SymbolButton(image: R.image.customAppleTerminal()?.applySymbolConfig(), title: R.string.localizable.gamesCheatCode())
        view.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            if let game = self.game {
                topViewController()?.present(CheatCodeViewController(game: game), animated: true)
            }
        }
        return view
    }()
    
    private lazy var threeDScontextMenuButton: ContextMenuButton = {
        var actions: [UIMenuElement] = []
        actions.append((UIAction(title: R.string.localizable.threeDSModePerformance()) { [weak self] _ in
            guard let self = self else { return }
            self.threeDSModeButton.titleLabel.text = R.string.localizable.threeDSModePerformance()
            Settings.change { realm in
                Settings.defalut.threeDSMode = .performance
            }
        }))
        actions.append(UIAction(title: R.string.localizable.threeDSModeCompatibility()) { [weak self] _ in
            guard let self = self else { return }
            self.threeDSModeButton.titleLabel.text = R.string.localizable.threeDSModeCompatibility()
            Settings.change { realm in
                Settings.defalut.threeDSMode = .compatibility
            }
        })
        actions.append((UIAction(title: R.string.localizable.threeDSModeQuality()) { [weak self] _ in
            guard let self = self else { return }
            self.threeDSModeButton.titleLabel.text = R.string.localizable.threeDSModeQuality()
            Settings.change { realm in
                Settings.defalut.threeDSMode = .quality
            }
        }))
        let view = ContextMenuButton(image: nil, menu: UIMenu(children: actions))
        view.isHidden = true
        return view
    }()
    
    private lazy var threeDSModeButton: SymbolButton = {
        let title: String
        switch Settings.defalut.threeDSMode {
        case .performance:
            title = R.string.localizable.threeDSModePerformance()
        case .compatibility:
            title = R.string.localizable.threeDSModeCompatibility()
        case .quality:
            title = R.string.localizable.threeDSModeQuality()
        }
        let view = SymbolButton(symbol: .gearshape2, title: title, horizontalContian: true)
        view.titleLabel.numberOfLines = 0
        view.isHidden = true
        view.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            self.threeDScontextMenuButton.triggerTapGesture()
        }
        return view
    }()
    
    private lazy var startGameButton: SymbolButton = {
        let view = SymbolButton(symbol: .playFill)
        view.backgroundColor = Constants.Color.Red
        view.layerCornerRadius = Constants.Size.ItemHeightMid/2
        view.addTapGesture { [weak self] gesture in
            guard let self = self, let game = self.game else { return }
            PlayViewController.startGame(game: game)
        }
        return view
    }()
    
    var didSegmentChange: ((_ index: Int)->Void)?
    lazy var segmentView: BetterSegmentedControl = {
        let titles = [R.string.localizable.readySegmentManualSave(), R.string.localizable.readySegmentAutoSave()]
        let segments = LabelSegment.segments(withTitles: titles,
                                             normalFont: Constants.Font.body(),
                                             normalTextColor: Constants.Color.LabelSecondary,
                                            selectedTextColor: Constants.Color.LabelPrimary)
        let options: [BetterSegmentedControl.Option] = [
            .backgroundColor(Constants.Color.BackgroundSecondary),
            .indicatorViewInset(5),
            .indicatorViewBackgroundColor(Constants.Color.BackgroundTertiary),
            .cornerRadius(16)
        ]
        let view = BetterSegmentedControl(frame: .zero,
                                          segments: segments,
                                          options: options)
        
        view.on(.valueChanged) { [weak self] sender, forEvent in
            guard let self = self, let index = (sender as? BetterSegmentedControl)?.index else { return }
            UIDevice.generateHaptic()
            self.didSegmentChange?(index)
        }
        
        return view
    }()
    
    
    
    var game: Game? = nil {
        didSet {
            if let game = game {
                titleTextField.text = game.aliasName ?? game.name
                if let timeAgo = game.latestPlayDate?.timeAgo() {
                    subtitleLabel.text = R.string.localizable.readyGameInfoSubTitle(timeAgo, Date.timeDuration(milliseconds: Int(game.totalPlayDuration)))
                } else {
                    subtitleLabel.text = R.string.localizable.readyGameInfoNeverPlayed()
                }
                if game.gameType == ._3ds {
                    threeDScontextMenuButton.isHidden = false
                    threeDSModeButton.isHidden = false
                }
            }
        }
    }
    
    func resetForGamingUsing() {
        subviews.forEach {
            if $0 is BetterSegmentedControl {
                $0.snp.remakeConstraints { make in
                    make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceHuge)
                    make.top.equalToSuperview().offset(10)
                    make.height.equalTo(50)
                    make.bottom.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
                }
            } else {
                $0.isHidden = true
            }
        }
        backgroundBlurView.isHidden = false
        backgroundBlurView.alpha = 1
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(backgroundBlurView)
        backgroundBlurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        addSubview(titleTextField)
        titleTextField.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceHuge)
            make.top.equalToSuperview()
        }
        
        addSubview(editTitleButton)
        editTitleButton.snp.makeConstraints { make in
            make.size.equalTo(Constants.Size.IconSizeMin)
            make.top.equalTo(titleTextField)
            make.leading.equalTo(titleTextField.snp.trailing).offset(Constants.Size.ContentSpaceUltraTiny)
            make.trailing.lessThanOrEqualToSuperview().offset(-Constants.Size.ContentSpaceMax)
        }
        
        addSubview(subtitleIcon)
        subtitleIcon.snp.makeConstraints { make in
            make.size.equalTo(Constants.Size.IconSizeTiny)
            make.leading.equalTo(titleTextField)
            make.top.equalTo(titleTextField.snp.bottom).offset(Constants.Size.ContentSpaceUltraTiny)
        }
        
        addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(subtitleIcon)
            make.leading.equalTo(subtitleIcon.snp.trailing).offset(Constants.Size.ContentSpaceUltraTiny)
            make.trailing.lessThanOrEqualToSuperview().offset(-Constants.Size.ContentSpaceMax)
        }
        
        addSubview(skinButton)
        skinButton.snp.makeConstraints { make in
            make.top.equalTo(subtitleIcon.snp.bottom).offset(Constants.Size.ContentSpaceMid)
            make.leading.equalTo(titleTextField)
            make.size.equalTo(Constants.Size.IconSizeHuge)
        }
        
        addSubview(cheatCodeButton)
        cheatCodeButton.snp.makeConstraints { make in
            make.centerY.equalTo(skinButton)
            make.leading.equalTo(skinButton.snp.trailing).offset(Constants.Size.ContentSpaceMin)
            make.size.equalTo(Constants.Size.IconSizeHuge)
        }
        
        addSubview(threeDScontextMenuButton)
        threeDScontextMenuButton.snp.makeConstraints { make in
            make.centerY.equalTo(skinButton)
            make.leading.equalTo(cheatCodeButton.snp.trailing).offset(Constants.Size.ContentSpaceMin)
            make.size.equalTo(Constants.Size.IconSizeHuge)
        }
        
        addSubview(threeDSModeButton)
        threeDSModeButton.snp.makeConstraints { make in
            make.centerY.equalTo(skinButton)
            make.leading.equalTo(cheatCodeButton.snp.trailing).offset(Constants.Size.ContentSpaceMin)
            make.size.equalTo(Constants.Size.IconSizeHuge)
        }
        
        addSubview(startGameButton)
        startGameButton.snp.makeConstraints { make in
            make.centerY.equalTo(skinButton)
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMax)
            make.size.equalTo(Constants.Size.ItemHeightMid)
        }
        
        addSubview(segmentView)
        segmentView.snp.makeConstraints { make in
            make.top.equalTo(skinButton.snp.bottom).offset(29)
            make.height.equalTo(50)
            make.leading.equalTo(skinButton)
            make.trailing.equalTo(startGameButton)
            make.bottom.equalToSuperview().offset(-Constants.Size.ContentSpaceMax)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
