//
//  GameInfoView.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2025/3/9.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
import ProHUD
import SwipeCellKit
import RealmSwift

class GameInfoView: BaseView {
    
    private var navigationBlurView: UIView = {
        let view = UIView()
        view.makeBlur()
        view.alpha = 0
        return view
    }()
    
    
    private var navigationGameCoverView: UIImageView = {
        let view = UIImageView()
        view.layerCornerRadius = Constants.Size.CornerRadiusTiny
        view.contentMode = .scaleAspectFill
        view.alpha = 0
        
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
    
    
    private lazy var gameCoverView: GameInfoCoverView = {
        let view = GameInfoCoverView(game: self.game)
        view.didCoverUpdate = { [weak self] image in
            guard let self = self else { return }
            self.navigationGameCoverView.image = image?.scaled(toSize: CGSize(Constants.Size.ItemHeightMax - Constants.Size.ContentSpaceMin*2))
        }
        return view
    }()
    
    
    private class HitTestCollectionView: UICollectionView {
        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            if let cell = self.cellForItem(at: IndexPath(row: 0, section: 0)) as? BlankPlaceholderCollectionViewCell {
                if cell.point(inside: self.convert(point, to: cell), with: event) {
                    if let gameCoverView = self.superview?.subviews.first(where: { $0 is GameInfoCoverView }) {
                        if gameCoverView.point(inside: self.convert(point, to: gameCoverView), with: event) {
                            if let gameCoverView = gameCoverView as? GameInfoCoverView, gameCoverView.maskTopView.alpha < 0.5 {
                                return nil
                            }
                        }
                    }
                }
            }
            return super.hitTest(point, with: event)
        }
    }
    
    private lazy var collectionView: UICollectionView = {
        let view = HitTestCollectionView(frame: .zero, collectionViewLayout: createLayout())
        view.backgroundColor = .clear
        view.contentInsetAdjustmentBehavior = .never
        view.register(cellWithClass: GameSaveEmptyCollectionViewCell.self)
        view.register(cellWithClass: BlankPlaceholderCollectionViewCell.self)
        view.register(cellWithClass: SaveItemCollectionViewCell.self)
        view.register(supplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withClass: GameInfoDetailReusableView.self)
        view.register(supplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withClass: GameSavePurchaseGuideReusableView.self)
        view.showsVerticalScrollIndicator = false
        view.dataSource = self
        view.delegate = self
        view.allowsSelection = false
        view.contentInset = UIEdgeInsets(top: Constants.Size.ItemHeightMax, left: 0, bottom: Constants.Size.ContentInsetBottom, right: 0)
        return view
    }()
    
    private var gameInfoView: GameInfoDetailReusableView?
    private var lastContentOffsetY = 0.0
    private let BlankCellHeight = 256.0
    private let GameInfoHeaderHeight = 235.0

    private let game: Game
    private var manualGameSaveStates: Results<GameSaveState>
    private var autoGameSaveStates: Results<GameSaveState>
    private var isManualGameSaveStatesPage: Bool
    private var isGameSaveStatesPageEmpty: Bool {
        (self.isManualGameSaveStatesPage && self.manualGameSaveStates.count == 0) || (!self.isManualGameSaveStatesPage && self.autoGameSaveStates.count == 0)
    }
    private lazy var deleteImage = UIImage(symbol: .trash, backgroundColor: Constants.Color.Red, imageSize: .init(Constants.Size.ItemHeightMin)).withRoundedCorners()
    
    
    var didTapClose: (()->Void)? = nil
    
    enum ReadyAction {
        case `default`, rename, changeCover
    }
    
    var readyAction: ReadyAction
    
    let showGameSaveOnly: Bool
    var forGamingSelection: ((GameSaveState)->Void)? = nil
    
    private var membershipNotification: Any? = nil
    
    deinit {
        Log.debug("\(String(describing: Self.self)) deinit")
        if let membershipNotification = membershipNotification {
            NotificationCenter.default.removeObserver(membershipNotification)
        }
    }
    
    var manualGameSaveStatesUpdate: Any? = nil
    var autoGameSaveStatesUpdate: Any? = nil
    init(game: Game, readyAction: ReadyAction = .default, showGameSaveOnly: Bool = false) {
        self.game = game
        self.manualGameSaveStates = game.gameSaveStates.sorted(by: \GameSaveState.date, ascending: false).where { $0.type == .manualSaveState && !$0.isDeleted }
        self.autoGameSaveStates = game.gameSaveStates.sorted(by: \GameSaveState.date, ascending: false).where { $0.type == .autoSaveState && !$0.isDeleted }
        self.isManualGameSaveStatesPage = autoGameSaveStates.count == 0 || manualGameSaveStates.count > 0
        self.readyAction = readyAction
        self.showGameSaveOnly = showGameSaveOnly
        super.init(frame: .zero)
        Log.debug("\(String(describing: Self.self)) init")
        manualGameSaveStatesUpdate = manualGameSaveStates.observe { [weak self] changes in
            switch changes {
            case .update(_, _, _, _):
                
                self?.collectionView.reloadData()
            default:
                break
            }
        }
        
        autoGameSaveStatesUpdate = autoGameSaveStates.observe { [weak self] changes in
            switch changes {
            case .update(_, _, _, _):
                
                self?.collectionView.reloadData()
            default:
                break
            }
        }
        
        membershipNotification = NotificationCenter.default.addObserver(forName: Constants.NotificationName.MembershipChange, object: nil, queue: .main) { [weak self] notification in
            self?.collectionView.reloadData()
        }
        
        if !showGameSaveOnly {
            addSubview(gameCoverView)
            gameCoverView.snp.makeConstraints { make in
                make.leading.top.trailing.equalToSuperview()
            }
        }
        
        
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        addSubview(navigationBlurView)
        navigationBlurView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
            make.height.equalTo(Constants.Size.ItemHeightMax)
        }
        
        if showGameSaveOnly {
            navigationBlurView.alpha = 1
            
            let headerLabel = UILabel()
            headerLabel.font = Constants.Font.title(size: .s, weight: .bold)
            headerLabel.textColor = Constants.Color.LabelPrimary
            headerLabel.text = R.string.localizable.gameSaveListTitle()
            navigationBlurView.addSubview(headerLabel)
            headerLabel.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMax)
            }
        }
        
        if !showGameSaveOnly {
            navigationBlurView.addSubview(navigationGameCoverView)
            navigationGameCoverView.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.size.equalTo(CGSize(Constants.Size.ItemHeightMax - Constants.Size.ContentSpaceMin*2))
            }
            navigationGameCoverView.image = .tryDataImageOrPlaceholder(tryData: game.gameCover?.storedData(), preferenceSize: CGSize(Constants.Size.ItemHeightMax - Constants.Size.ContentSpaceMin*2))
        }
        
        if showGameSaveOnly {
            navigationBlurView.addSubview(closeButton)
            closeButton.snp.makeConstraints { make in
                make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMax)
                make.centerY.equalToSuperview()
                make.size.equalTo(Constants.Size.ItemHeightUltraTiny)
            }
        } else {
            addSubview(closeButton)
            closeButton.snp.makeConstraints { make in
                make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMax)
                make.top.equalToSuperview().offset(Constants.Size.ContentSpaceMin)
                make.size.equalTo(Constants.Size.ItemHeightUltraTiny)
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var isFirstInit = true
    
    func controllerViewDidAppear() {
        if isFirstInit {
            switch readyAction {
            case .default:
                break
            case .rename:
                if let gameInfoView {
                    gameInfoView.titleTextField.becomeFirstResponder()
                }
            case .changeCover:
                self.gameCoverView.editCoverButton.triggerTapGesture()
            }
            isFirstInit = false
        }
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout  { [weak self] sectionIndex, env in
            guard let self = self else { return nil }
            if sectionIndex == 0 && !self.showGameSaveOnly {
                
                let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1)))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(self.BlankCellHeight)), subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                return section
            } else {
                let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1)))
                
                var gameSaveStatesPageEmptyCellHeight: CGFloat = 0
                if self.showGameSaveOnly {
                    gameSaveStatesPageEmptyCellHeight = self.height - Constants.Size.ItemHeightMax - Constants.Size.ItemHeightHuge - Constants.Size.ContentInsetBottom
                } else {
                    gameSaveStatesPageEmptyCellHeight = self.height - Constants.Size.ItemHeightMax - self.BlankCellHeight - self.GameInfoHeaderHeight - Constants.Size.ContentInsetBottom
                }
                if gameSaveStatesPageEmptyCellHeight < 200 {
                    gameSaveStatesPageEmptyCellHeight = 200
                }
                
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: self.isGameSaveStatesPageEmpty ? .estimated(gameSaveStatesPageEmptyCellHeight) : .absolute(Constants.Size.ItemHeightMax)), subitems: [item])
                
                if !self.isGameSaveStatesPageEmpty {
                    group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: Constants.Size.ContentSpaceHuge, bottom: 0, trailing: Constants.Size.ContentSpaceHuge)
                }
                
                let section = NSCollectionLayoutSection(group: group)
                
                if !self.isGameSaveStatesPageEmpty {
                    section.interGroupSpacing = Constants.Size.ContentSpaceMid
                }
                
                let headerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(self.showGameSaveOnly ? Constants.Size.ItemHeightMid + 26 : self.GameInfoHeaderHeight)), elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
                headerItem.pinToVisibleBounds = true
                section.boundarySupplementaryItems = [headerItem]
                
                if !PurchaseManager.isMember && !self.isGameSaveStatesPageEmpty {
                    let footerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                                                    heightDimension: .estimated(178.4)),
                                                                                 elementKind: UICollectionView.elementKindSectionFooter,
                                                                                 alignment: .bottom)
                    section.boundarySupplementaryItems.append(footerItem)
                }
                
                return section
            }
        }
        return layout
    }
}

extension GameInfoView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        showGameSaveOnly ? 1 : 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if showGameSaveOnly {
            return isGameSaveStatesPageEmpty ? 1 : (isManualGameSaveStatesPage ? manualGameSaveStates.count : autoGameSaveStates.count)
        }
        if section == 0 || isGameSaveStatesPageEmpty {
            return 1
        }
        return isManualGameSaveStatesPage ? manualGameSaveStates.count : autoGameSaveStates.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 && !showGameSaveOnly {
            let cell = collectionView.dequeueReusableCell(withClass: BlankPlaceholderCollectionViewCell.self, for: indexPath)
            return cell
        } else {
            if isGameSaveStatesPageEmpty {
                let cell = collectionView.dequeueReusableCell(withClass: GameSaveEmptyCollectionViewCell.self, for: indexPath)
                cell.setGuideViewHidden(PurchaseManager.isMember)
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withClass: SaveItemCollectionViewCell.self, for: indexPath)
                cell.delegate = self
                let gameSaveState = (isManualGameSaveStatesPage ? manualGameSaveStates : autoGameSaveStates)[indexPath.row]
                cell.setData(item: gameSaveState, index: indexPath.row + 1)
                cell.continueButton.addTapGesture { [weak self] gesture in
                    guard let self = self else { return }
                    let state = (self.isManualGameSaveStatesPage ? self.manualGameSaveStates : self.autoGameSaveStates)[indexPath.row]
                    func loadState() {
                        if self.showGameSaveOnly {
                            self.forGamingSelection?(state)
                        } else {
                            PlayViewController.startGame(game: self.game, saveState: state)
                        }
                    }
                    if state.isCompatible {
                        loadState()
                    } else {
                        UIView.makeAlert(title: R.string.localizable.gameSaveUnCompatibleTitle(),
                                         detail: R.string.localizable.gameSaveUnCompatibleDetail(state.gameSaveStateDeviceInfo, state.currentDeviceInfo), confirmTitle: R.string.localizable.gameSaveStateForceLoad(), confirmAction: {
                            loadState()
                        })
                    }
                    
                }
                return cell
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withClass: GameInfoDetailReusableView.self, for: indexPath)
            
            header.didSegmentChange = { [weak self] index in
                guard let self = self else { return }
                self.isManualGameSaveStatesPage = index == 0
                self.collectionView.reloadData()
            }
            header.game = game
            if showGameSaveOnly {
                header.resetForGamingUsing()
            }
            header.segmentView.setIndex(isManualGameSaveStatesPage ? 0 : 1)
            gameInfoView = header
            return header
        } else {
            let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withClass: GameSavePurchaseGuideReusableView.self, for: indexPath)
            footer.guideView.isHidden = PurchaseManager.isMember
            return footer
        }
        
    }
}

extension GameInfoView: UICollectionViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !showGameSaveOnly else { return }
        let contentOffsetY = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
        if contentOffsetY < BlankCellHeight {
            let alphaProgress = 1 - ((BlankCellHeight - contentOffsetY)/BlankCellHeight)
            gameCoverView.maskTopView.alpha = alphaProgress < 0 ? 0 : alphaProgress
            
            
            let navigationChangeOffset = BlankCellHeight - contentOffsetY
            if  navigationChangeOffset < Constants.Size.ItemHeightMax {
                let alphaProgress = (Constants.Size.ItemHeightMax - navigationChangeOffset)/Constants.Size.ItemHeightMax
                navigationBlurView.alpha = alphaProgress
                navigationGameCoverView.alpha = alphaProgress
                gameInfoView?.backgroundBlurView.alpha = alphaProgress
            } else {
                navigationBlurView.alpha = 0
                navigationGameCoverView.alpha = 0
                gameInfoView?.backgroundBlurView.alpha = 0
            }
            
        } else {
            if gameCoverView.maskTopView.alpha != 1 {
                gameCoverView.maskTopView.alpha = 1
                navigationBlurView.alpha = 1
                navigationGameCoverView.alpha = 1
                gameInfoView?.backgroundBlurView.alpha = 1
            }
        }
        lastContentOffsetY = contentOffsetY
    }
}

extension GameInfoView: SwipeCollectionViewCellDelegate {
    func collectionView(_ collectionView: UICollectionView, editActionsForItemAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        let gameSaveState = (isManualGameSaveStatesPage ? manualGameSaveStates : autoGameSaveStates)[indexPath.row]
        UIDevice.generateHaptic()
        if orientation == .right {
            let delete = SwipeAction(style: .default, title: nil) { action, indexPath in
                UIDevice.generateHaptic()
                action.fulfill(with: .reset)
                UIView.makeAlert(title: R.string.localizable.deleteGameGameStateAlertTitle(),
                                 detail: R.string.localizable.deleteGameGameStateAlertDetail(),
                                 confirmTitle: R.string.localizable.confirmDelte(),
                                 confirmAction: {
                    Game.change { realm in
                        gameSaveState.stateCover?.deleteAndClean(realm: realm)
                        gameSaveState.stateData?.deleteAndClean(realm: realm)
                        if Settings.defalut.iCloudSyncEnable {
                            
                            gameSaveState.isDeleted = true
                        } else {
                            
                            realm.delete(gameSaveState)
                        }
                    }
                })
            }
            delete.backgroundColor = .clear
            delete.image = deleteImage
            return [delete]
        } else {
            return nil
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, editActionsOptionsForItemAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeOptions()
        options.expansionStyle = SwipeExpansionStyle(target: .percentage(1),
                                                     elasticOverscroll: true,
                                                     completionAnimation: .fill(.manual(timing: .with)))
        options.expansionDelegate = self
        options.transitionStyle = .border
        options.backgroundColor = Constants.Color.BackgroundPrimary
        options.maximumButtonWidth = Constants.Size.ItemHeightMin + Constants.Size.ContentSpaceTiny*2
        return options
    }
}

extension GameInfoView: SwipeExpanding {
    func animationTimingParameters(buttons: [UIButton], expanding: Bool) -> SwipeCellKit.SwipeExpansionAnimationTimingParameters {
        ScaleAndAlphaExpansion.default.animationTimingParameters(buttons: buttons, expanding: expanding)
    }
    
    func actionButton(_ button: UIButton, didChange expanding: Bool, otherActionButtons: [UIButton]) {
        ScaleAndAlphaExpansion.default.actionButton(button, didChange: expanding, otherActionButtons: otherActionButtons)
        if expanding {
            UIDevice.generateHaptic()
        }
    }
}

extension GameInfoView {
    static var isShow: Bool {
        Sheet.find(identifier: String(describing: GameInfoView.self)).count > 0 ? true : false
    }
    
    static func show(game: Game, gameViewRect: CGRect, selection: ((GameSaveState)->Void)? = nil, hideCompletion: (()->Void)? = nil, didTapClose: (()->Void)? = nil) {
        Sheet.lazyPush(identifier: String(describing: GameInfoView.self)) { sheet in
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
            
            let listView = GameInfoView(game: game, showGameSaveOnly: true)
            listView.forGamingSelection = { [weak sheet] saveState in
                sheet?.pop(completon: {
                    selection?(saveState)
                })
            }
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
