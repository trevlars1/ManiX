//
//  SkinSettingsView.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2025/3/6.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import UIKit
import ManicEmuCore

import RealmSwift
import BetterSegmentedControl
import UniformTypeIdentifiers
import ProHUD

class SkinSettingsView: BaseView {
    
    private var navigationBlurView: UIView = {
        let view = UIView()
        view.makeBlur()
        return view
    }()
    
    private var contextMenuButton: ContextMenuButton = {
        let view = ContextMenuButton()
        return view
    }()
    
    private lazy var navigationSymbolTitle: SymbolButton = {
        let defaultTitle = System(gameType: game?.gameType ?? gameType).localizedShortName
        let view = SymbolButton(image: game == nil ? UIImage(symbol: .chevronUpChevronDown, font: Constants.Font.caption(weight: .bold)) : nil,
                                title: defaultTitle,
                                titleFont: Constants.Font.title(size: .s),
                                edgeInsets: .zero,
                                titlePosition: .left,
                                imageAndTitlePadding: Constants.Size.ContentSpaceUltraTiny)
        view.layerCornerRadius = 0
        view.backgroundColor = .clear
        if isSettingForGame {
            view.enableInteractive = false
        } else {
            view.addTapGesture { [weak self] gesture in
                guard let self = self else { return }
                let allGameTypes = System.allCases.map { $0.gameType }
                let itemTitles = System.allCases.map { $0.localizedShortName }
                var items: [UIAction] = []
                let currentGameTypeName = System(gameType: self.gameType).localizedShortName
                for (index, title) in itemTitles.enumerated() {
                    items.append(UIAction(title: title,
                                          image: currentGameTypeName == title ? UIImage(symbol: .checkmarkCircleFill) : nil,
                                          handler: { [weak self] _ in
                        guard let self = self else { return }
                        self.gameType = allGameTypes[index]
                        self.navigationSymbolTitle.titleLabel.text = itemTitles[index]
                        self.updateDatas()
                    }))
                }
                self.contextMenuButton.menu = UIMenu(children: items)
                self.contextMenuButton.triggerTapGesture()
            }
        }
        return view
    }()
    
    private lazy var navigationSubTitle: SymbolButton = {
        let view = SymbolButton(image: UIImage(symbol: .megaphone, font: Constants.Font.caption(), color: Constants.Color.LabelSecondary),
                                title: game == nil ? R.string.localizable.skinNavigationSubTitleCommon() : R.string.localizable.skinNavigationSubTitleSpecifiedGame(game?.aliasName ?? game!.name),
                                titleFont: Constants.Font.caption(),
                                titleColor: Constants.Color.LabelSecondary,
                                titleAlignment: .left,
                                edgeInsets: .zero,
                                titlePosition: .right,
                                imageAndTitlePadding: Constants.Size.ContentSpaceUltraTiny)
        view.layerCornerRadius = 0
        view.backgroundColor = .clear
        view.enableInteractive = false
        view.titleLabel.lineBreakMode = .byTruncatingMiddle
        return view
    }()
    
    private var howToFetchSkinButton: HowToButton = {
        let view = HowToButton(title: R.string.localizable.howToFetch()) {
            topViewController()?.present(WebViewController(url: Constants.URLs.SkinUsageGuide), animated: true)
        }
        return view
    }()
    
    private lazy var closeButton: SymbolButton = {
        let view = SymbolButton(image: UIImage(symbol: .xmark, font: Constants.Font.body(weight: .bold)))
        view.enableRoundCorner = true
        view.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            self.didTapClose?()
        }
        return view
    }()
    
    private lazy var segmentView: BetterSegmentedControl = {
        let titles = [R.string.localizable.skinSegmentPortraitTitle(), R.string.localizable.skinSegmentLandscapeTitle()]
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
            self.isPortraitSkinPage = index == 0
            self.reloadDataAndSelectSkin()
        }
        return view
    }()
    
    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        view.backgroundColor = .clear
        view.contentInsetAdjustmentBehavior = .never
        view.register(cellWithClass: SkinCollectionViewCell.self)
        view.register(cellWithClass: AddSkinCollectionViewCell.self)
        view.showsVerticalScrollIndicator = false
        view.dataSource = self
        view.delegate = self
        view.allowsSelection = true
        view.allowsMultipleSelection = false
        view.contentInset = UIEdgeInsets(top: 150, left: 0, bottom: Constants.Size.ContentInsetBottom, right: 0)
        return view
    }()

    
    private var game: Game? = nil
    
    private var gameType: GameType = .gba
    
    private var isSettingForGame: Bool { game != nil }
    
    private var allSkins: Results<Skin>
    
    private var portraitSkins: [ControllerSkin] = []
    private var landscapeSkins: [ControllerSkin] = []
    
    private var portraitInitialSelectedIndex: Int?
    
    private var landscapeInitialSelectedIndex: Int?
    
    private var isPortraitSkinPage: Bool = true
    
    private let defaultTraits: ControllerSkin.Traits = ControllerSkin.Traits.defaults(for: UIWindow.applicationWindow ?? UIWindow(frame: .init(origin: .zero, size: Constants.Size.WindowSize)))
    
    private lazy var portraitTraits: ControllerSkin.Traits = {
        ControllerSkin.Traits(device: self.defaultTraits.device, displayType: self.defaultTraits.displayType, orientation: .portrait)
    }()
    
    private lazy var landscapeTraits: ControllerSkin.Traits = {
        ControllerSkin.Traits(device: self.defaultTraits.device, displayType: self.defaultTraits.displayType, orientation: .landscape)
    }()
    
    private var skinsUpdateToken: NotificationToken? = nil
    
    var didTapClose: (()->Void)? = nil
    
    deinit {
        Log.debug("\(String(describing: Self.self)) deinit")
    }
    
    
    
    
    
    init(game: Game? = nil, gameType: GameType? = nil) {
        
        let realm = Database.realm
        allSkins = realm.objects(Skin.self).where({ !$0.isDeleted })
        super.init(frame: .zero)
        Log.debug("\(String(describing: Self.self)) init")
        
        skinsUpdateToken = allSkins.observe { [weak self] changes in
            guard let self = self else { return }
            if case .update(_, let deletions, let insertions, _) = changes {
                
                
                if !insertions.isEmpty || !deletions.isEmpty {
                    self.updateDatas()
                }
            }
        }
        
        if let game = game {
            self.game = game
            self.gameType = game.gameType
        } else if let gameType = gameType {
            self.gameType = gameType
        }
        
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        addSubview(navigationBlurView)
        navigationBlurView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
            make.height.equalTo(130)
        }
        
        navigationBlurView.addSubview(navigationSymbolTitle)
        navigationSymbolTitle.snp.makeConstraints { make in
            make.leading.equalTo(Constants.Size.ContentSpaceMax)
            make.top.equalToSuperview().offset(Constants.Size.ContentSpaceMid)
        }
        
        if !isSettingForGame {
            navigationBlurView.insertSubview(contextMenuButton, belowSubview: navigationSymbolTitle)
            contextMenuButton.snp.makeConstraints { make in
                make.edges.equalTo(navigationSymbolTitle)
            }
        }
        
        navigationBlurView.addSubview(navigationSubTitle)
        navigationSubTitle.imageView.setContentHuggingPriority(.required, for: .horizontal)
        navigationSubTitle.imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        navigationSubTitle.titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        navigationSubTitle.titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        navigationSubTitle.snp.makeConstraints { make in
            make.leading.equalTo(navigationSymbolTitle)
            make.top.equalTo(navigationSymbolTitle.snp.bottom).offset(Constants.Size.ContentSpaceUltraTiny/2)
        }
        
        navigationBlurView.addSubview(segmentView)
        segmentView.snp.makeConstraints { make in
            make.top.equalTo(navigationSubTitle.snp.bottom).offset(Constants.Size.ContentSpaceMin)
            make.height.equalTo(Constants.Size.ItemHeightMid)
            make.leading.equalTo(Constants.Size.ContentSpaceMid)
            make.trailing.equalTo(-Constants.Size.ContentSpaceMid)
        }
        
        navigationBlurView.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMax)
            make.top.equalToSuperview().offset(10)
            make.size.equalTo(Constants.Size.ItemHeightUltraTiny)
        }
        
        navigationBlurView.addSubview(howToFetchSkinButton)
        howToFetchSkinButton.label.setContentCompressionResistancePriority(.required, for: .horizontal)
        howToFetchSkinButton.label.setContentHuggingPriority(.required, for: .horizontal)
        howToFetchSkinButton.snp.makeConstraints { make in
            make.height.equalTo(Constants.Size.ItemHeightUltraTiny)
            make.leading.equalTo(navigationSubTitle.snp.trailing).offset(Constants.Size.ContentSpaceMid)
            make.trailing.equalTo(closeButton.snp.leading).offset(-Constants.Size.ContentSpaceMax)
            make.centerY.equalTo(closeButton)
        }
        
        updateDatas()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout  { [weak self] sectionIndex, env in
            guard let self = self else { return nil }

            let column = self.isPortraitSkinPage ? 2.0 : 1.0
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1/column), heightDimension: .fractionalHeight(1)))
            
            let screenRation = Constants.Size.WindowSize.maxDimension/Constants.Size.WindowSize.minDimension
            let itemWidth = (env.container.contentSize.width - Constants.Size.ContentSpaceMid*4 - ((column-1)*Constants.Size.ContentSpaceMid))/column
            let itemHeight = self.isPortraitSkinPage ? itemWidth*screenRation : itemWidth/screenRation
            
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(itemHeight)), subitem: item, count: Int(column))
            group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: Constants.Size.ContentSpaceMid, bottom: 0, trailing: Constants.Size.ContentSpaceMid)
            group.interItemSpacing = NSCollectionLayoutSpacing.fixed(Constants.Size.ContentSpaceMid)
            
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = Constants.Size.ContentSpaceMid

            section.decorationItems = [NSCollectionLayoutDecorationItem.background(elementKind: String(describing: SkinDecorationCollectionReusableView.self))]
            section.contentInsets = NSDirectionalEdgeInsets(top: Constants.Size.ContentSpaceMid, leading: Constants.Size.ContentSpaceMid, bottom: Constants.Size.ContentSpaceMid, trailing: Constants.Size.ContentSpaceMid)
            
            return section
        }
        layout.register(SkinDecorationCollectionReusableView.self, forDecorationViewOfKind: String(describing: SkinDecorationCollectionReusableView.self))
        return layout
    }
    
    class SkinDecorationCollectionReusableView: UICollectionReusableView {
        var backgroundView: UIView = {
            let view = UIView()
            view.layerCornerRadius = Constants.Size.CornerRadiusMax
            view.backgroundColor = Constants.Color.BackgroundSecondary
            return view
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            addSubview(backgroundView)
            backgroundView.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    private func updateDatas() {
        portraitSkins.removeAll()
        landscapeSkins.removeAll()
        
        let skins = allSkins.filter({ $0.gameType == self.gameType && $0.isFileExtsts }).sorted {
            if $0.skinType == .default {
                return true
            } else if $1.skinType == .default {
                return false
            }
            return true
        }
        for skin in skins {
            if let controllerSkin = ControllerSkin(fileURL: skin.fileURL) {
                if controllerSkin.supports(portraitTraits) {
                    portraitSkins.append(controllerSkin)
                }
                if controllerSkin.supports(landscapeTraits) {
                    landscapeSkins.append(controllerSkin)
                }
            }
        }
        
        
        func getIndex(for skin: Skin, in controllerSkins: [ControllerSkin]) -> Int? {
            for (index, controllerSkin) in controllerSkins.enumerated() {
                if controllerSkin.fileURL == skin.fileURL {
                    return index
                }
            }
            return nil
        }
        
        
        if isSettingForGame, let game = game {
            
            if let storedSkin = game.portraitSkin {
                portraitInitialSelectedIndex = getIndex(for: storedSkin, in: portraitSkins)
            }
            if let storedSkin = game.landscapeSkin {
                landscapeInitialSelectedIndex = getIndex(for: storedSkin, in: landscapeSkins)
            }
        }
        
        
        if portraitInitialSelectedIndex == nil {
            if let storedSkin = SkinConfig.prefferedPortraitSkin(gameType: gameType) {
                portraitInitialSelectedIndex = getIndex(for: storedSkin, in: portraitSkins) ?? 0
            } else {
                portraitInitialSelectedIndex = 0
            }
        }
        
        if landscapeInitialSelectedIndex == nil {
            if let storedSkin = SkinConfig.prefferedLandscapeSkin(gameType: gameType) {
                landscapeInitialSelectedIndex = getIndex(for: storedSkin, in: landscapeSkins) ?? 0
            } else {
                landscapeInitialSelectedIndex = 0
            }
        }
        
        self.reloadDataAndSelectSkin()
    }
    
    private func reloadDataAndSelectSkin() {
        collectionView.reloadData { [weak self] in
            guard let self = self else { return }
            if isPortraitSkinPage, let portraitInitialSelectedIndex = portraitInitialSelectedIndex {
                
                self.collectionView.selectItem(at: IndexPath(row: portraitInitialSelectedIndex, section: 0), animated: true, scrollPosition: .top)
            }
            if !isPortraitSkinPage, let landscapeInitialSelectedIndex = landscapeInitialSelectedIndex {
                
                self.collectionView.selectItem(at: IndexPath(row: landscapeInitialSelectedIndex, section: 0), animated: true, scrollPosition: .top)
            }
        }
    }
}

extension SkinSettingsView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        (isPortraitSkinPage ? portraitSkins.count : landscapeSkins.count) + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let skins = (isPortraitSkinPage ? portraitSkins : landscapeSkins)
        if indexPath.row == skins.count {
            return collectionView.dequeueReusableCell(withClass: AddSkinCollectionViewCell.self, for: indexPath)
        } else {
            let cell = collectionView.dequeueReusableCell(withClass: SkinCollectionViewCell.self, for: indexPath)
            
            cell.setData(controllerSkin: skins[indexPath.row], traits: isPortraitSkinPage ? portraitTraits : landscapeTraits)
            return cell
        }
    }
}

extension SkinSettingsView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        if let indexPaths = collectionView.indexPathsForSelectedItems, indexPaths.contains(where: { $0 == indexPath }) {
            
            return false
        }
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        let skins = (isPortraitSkinPage ? portraitSkins : landscapeSkins)
        if indexPath.row == skins.count {
            
            FilesImporter.shared.presentImportController(supportedTypes: UTType.skinTypes)
            return false
        }
        
        
        if isPortraitSkinPage {
            portraitInitialSelectedIndex = indexPath.row
        } else {
            landscapeInitialSelectedIndex = indexPath.row
        }
        
        
        if let indexPaths = collectionView.indexPathsForSelectedItems, !indexPaths.contains(where: { $0 == indexPath }) {
            if let skin = allSkins.first(where: { $0.fileURL == skins[indexPath.row].fileURL }) {
                if let game = game {
                    Game.change { realm in
                        if isPortraitSkinPage {
                            game.portraitSkin = skin
                        } else {
                            game.landscapeSkin = skin
                        }
                    }
                } else {
                    SkinConfig.setDefaultSkin(skin, isLandscape: isPortraitSkinPage)
                }
            }
        }
        
        return true
    }
    
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemsAt indexPaths: [IndexPath], point: CGPoint) -> UIContextMenuConfiguration? {
        guard let indexPath = indexPaths.first else { return nil }
        let skins = (isPortraitSkinPage ? portraitSkins : landscapeSkins)
        if indexPath.row == skins.count {
            
            return nil
        }
        
        if indexPath.row == 0 {
            
            UIView.makeToast(message: R.string.localizable.defaultSkinCannotEdit())
            return nil
        }
        
        if let skin = allSkins.first(where: { $0.fileURL == skins[indexPath.row].fileURL }) {
            return UIContextMenuConfiguration(actionProvider:  { [weak self] _ in
                UIMenu(children: [UIAction(title: R.string.localizable.skinDelete(), image: UIImage(systemSymbol: .trash), attributes: .destructive, handler: { _ in
                    UIView.makeAlert(title: R.string.localizable.skinDelete(),
                                     detail: R.string.localizable.deleteSkinAlertDetail(),
                                     confirmTitle: R.string.localizable.confirmDelte(),
                                     confirmAction: { [weak self] in
                        Skin.change { realm in
                            skin.skinData?.deleteAndClean(realm: realm)
                            if Settings.defalut.iCloudSyncEnable {
                                skin.isDeleted = true
                            } else {
                                realm.delete(skin)
                            }
                        }
                        if let self = self {
                            if self.isPortraitSkinPage {
                                self.portraitInitialSelectedIndex = nil
                            } else {
                                self.landscapeInitialSelectedIndex = nil
                            }
                        }
                    })
                })])
            })
        }

        return nil
    }
}

extension SkinSettingsView {
    static var isShow: Bool {
        Sheet.find(identifier: String(describing: SkinSettingsView.self)).count > 0 ? true : false
    }
    
    static func show(game: Game, gameViewRect: CGRect, hideCompletion: (()->Void)? = nil, didTapClose: (()->Void)? = nil) {
        Sheet.lazyPush(identifier: String(describing: SkinSettingsView.self)) { sheet in
            sheet.configGamePlayingStyle(gameViewRect: gameViewRect, hideCompletion: hideCompletion)
            
            let view = UIView()
            let containerView = RoundAndBorderView(roundCorner: (UIDevice.isPad || UIDevice.isLandscape) ? .allCorners : [.topLeft, .topRight])
            containerView.backgroundColor = Constants.Color.BackgroundPrimary
            view.addSubview(containerView)
            containerView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
                if let maxHeight = sheet.config.cardMaxHeight {
                    make.height.equalTo(maxHeight)
                }
            }
            view.addPanGesture { [weak view, weak sheet] gesture in
                guard let view = view, let sheet = sheet else { return }
                let point = gesture.translation(in: gesture.view)
                view.transform = .init(translationX: 0, y: point.y <= 0 ? 0 : point.y)
                if gesture.state == .recognized {
                    let v = gesture.velocity(in: gesture.view)
                    if (view.y > view.height*2/3 && v.y > 0) || v.y > 1200 {
                        
                        sheet.pop()
                    }
                    UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.5, options: [.allowUserInteraction, .curveEaseOut], animations: {
                        view.transform = .identity
                    })
                }
            }
            
            let listView = SkinSettingsView(game: game)
            listView.didTapClose = { [weak sheet] in
                sheet?.pop()
                didTapClose?()
            }
            containerView.addSubview(listView)
            listView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            sheet.set(customView: view).snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }
}
