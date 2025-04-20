//
//  GameListView.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2025/1/24.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import UIKit
import RealmSwift
import ManicEmuCore
import UniformTypeIdentifiers
import Fireworks
import VisualEffectView
import IceCream

class GameListView: BaseView {
    private lazy var collectionView: BlankSlateCollectionView = {
        let view = BlankSlateCollectionView(frame: .zero, collectionViewLayout: createLayout())
        view.backgroundColor = Constants.Color.Background
        view.contentInsetAdjustmentBehavior = .never
        view.register(cellWithClass: GameCollectionViewCell.self)
        view.register(supplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withClass: GamesCollectionReusableView.self)
        view.register(supplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withClass: RandomGameCollectionReusableView.self)
        view.showsVerticalScrollIndicator = false
        view.dataSource = self
        view.delegate = self
        view.allowsMultipleSelection = true
        let top = Constants.Size.ContentInsetTop + Constants.Size.ItemHeightMid + Constants.Size.ItemHeightHuge
        let bottom = Constants.Size.ContentInsetBottom + Constants.Size.HomeTabBarSize.height + Constants.Size.ContentSpaceMax
        view.contentInset = UIEdgeInsets(top: top, left: 0, bottom: bottom, right: 0)
        view.blankSlateView = GamesListBlankSlateView()
        return view
    }()
    
    
    private lazy var indexView: SectionIndexView = {
        let view = SectionIndexView()
        view.isItemIndicatorAlwaysInCenterY = true
        view.delegate = self
        view.dataSource = self
        return view
    }()
    
    
    private lazy var fireworks = ClassicFireworkController()
    
    
    private var normalDatas: [GameType: [Game]] = [:]
    
    var totalGamesCountForCurrentMode: Int { (isSearchMode ? searchDatas : normalDatas).values.reduce(0) { $0 + $1.count } }
    
    
    private lazy var searchDatas: [GameType: [Game]] = [:]
    
    
    var isSelectionMode: Bool { selectionMode != .normalMode }
    var selectionMode: SelectionChangeMode = .normalMode {
        didSet {
            guard selectionMode != oldValue else { return }
            for (gameTypeIndex, gameType) in self.sortDatasKeys().enumerated() {
                if let games = (isSearchMode ? searchDatas : normalDatas)[gameType] {
                    for (gameIndex, _) in games.enumerated() {
                        switch selectionMode {
                        case .normalMode, .selectionMode:
                            if selectionMode == .normalMode {
                                
                                collectionView.allowsSelection = false
                                collectionView.allowsMultipleSelection = false
                                collectionView.allowsSelection = true
                                collectionView.allowsMultipleSelection = true
                            }
                            if let cell = collectionView.cellForItem(at: IndexPath(row: gameIndex, section: gameTypeIndex)) as? GameCollectionViewCell {
                                cell.updateViews(isSelect: selectionMode == .normalMode ? false : true)
                            }
                        case .selectAll:
                            collectionView.selectItem(at: IndexPath(row: gameIndex, section: gameTypeIndex), animated: true, scrollPosition: [])
                        case .deSelectAll:
                            collectionView.deselectItem(at: IndexPath(row: gameIndex, section: gameTypeIndex), animated: true)
                        }
                    }
                }
            }
        }
    }
    
    var didListViewSelectionChange: ((_ selectionType: SelectionType)->Void)?
    
    
    var didUpdateToolView: ((_ show: Bool, _ showCorner: Bool)->Void)?
    
    
    var didScroll: (()->Void)?
    
    
    var didDatasUpdate: ((_ isEmpty: Bool)->Void)? {
        didSet {
            didDatasUpdate?(normalDatas.isEmpty)
        }
    }
    
    
    var isSearchMode = false
    private var searchString: String? = nil
    
    
    private var lastContentOffsetY = 0.0
    private let gamesNavigationBottom = (Constants.Size.SafeAera.top > 0 ? Constants.Size.SafeAera.top : Constants.Size.ContentSpaceMax) + Constants.Size.ItemHeightMid
    private var gamesToolBottom: CGFloat { gamesNavigationBottom + Constants.Size.ItemHeightHuge }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        Log.debug("\(String(describing: Self.self)) init")
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        addSubview(indexView)
        indexView.snp.makeConstraints { make in
            make.top.bottom.trailing.equalToSuperview()
            make.width.equalTo(31)
        }
        indexView.isHidden = true
        
        
        updateGames()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        Log.debug("\(String(describing: Self.self)) deinit")
    }
    
    private var gamesUpdateToken: NotificationToken? = nil
    private func updateGames() {
        
        let realm = Database.realm
        let games = realm.objects(Game.self).where { !$0.isDeleted }
        
        gamesUpdateToken = games.observe(keyPaths: [\Game.gameCover, \Game.aliasName]) { [weak self] changes in
            guard let self = self else { return }
            switch changes {
            case .update(_, let deletions, let insertions, let modifications):
                
                
                if !deletions.isEmpty || !insertions.isEmpty {
                    self.updateDatas(games: games)
                    self.collectionView.reloadData()
                    self.reloadIndexView()
                }
                
                
                if !modifications.isEmpty {
                    let indexPaths = modifications.compactMap({ self.getIndexPath(for: games[$0]) })
                    self.collectionView.reloadItems(at: indexPaths)
                }
            default:
                break
            }
        }
        
        updateDatas(games: games)
        if games.count > 0 {
            
            collectionView.reloadData()
            
            reloadIndexView()
        }
    }
    
    
    private func updateDatas(games: Results<Game>) {
        let groupGames = Dictionary(grouping: games, by: { $0.gameType })
        normalDatas = groupGames.mapValues { $0.sorted(by: { $0.name < $1.name }) } 
        if isSearchMode {
            
            updateSearchDatas()
        }
        didDatasUpdate?(normalDatas.isEmpty)
    }
    
    
    private func updateSearchDatas() {
        if let searchString = searchString {
            searchDatas.removeAll()
            for (gameTypeSection, gameType) in sortDatasKeys().enumerated() {
                for game in getGames(at: gameTypeSection) {
                    if ((game.aliasName ?? game.name) + game.fileExtension).contains(searchString, caseSensitive: false) {
                        var gamesList = searchDatas[gameType]
                        if gamesList == nil {
                            gamesList = []
                            searchDatas[gameType] = gamesList
                        }
                        searchDatas[gameType]?.append(game)
                    }
                }
            }
        }
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout  { [weak self] sectionIndex, env in
            guard let self = self else { return nil }
            
            let sectionInset = Constants.Size.ContentSpaceHuge
            let itemSpacing = Constants.Size.ContentSpaceMax - Constants.Size.GamesListSelectionEdge*2
            var column = 2.0
            if UIDevice.isPad {
                column = UIDevice.isLandscape ? 3 : (UIDevice.isPadMini ? 4 : 5 )
            }
            let widthDimension: NSCollectionLayoutDimension = .fractionalWidth(1/column)
            
            let totleSpacing = (Constants.Size.ContentSpaceHuge-Constants.Size.GamesListSelectionEdge)*2 + itemSpacing*(column-1)
            let itemEstimatedWidth = (env.container.contentSize.width - totleSpacing)/column 
            let coverHeight = (itemEstimatedWidth-Constants.Size.GamesListSelectionEdge*2)/Constants.Size.GameCoverRatio 
            
            let itemEstimatedHeight = Constants.Size.GamesListSelectionEdge + coverHeight + Constants.Size.ContentSpaceMin + Constants.Font.body().lineHeight + Constants.Size.GamesListSelectionEdge
            
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: widthDimension,
                                                                                 heightDimension: .absolute(itemEstimatedHeight)))
            
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                              heightDimension: .absolute(itemEstimatedHeight)),
                                                           subitem: item, count: Int(column))
            group.interItemSpacing = NSCollectionLayoutSpacing.fixed(itemSpacing)
            group.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                          leading: sectionInset-Constants.Size.GamesListSelectionEdge,
                                                          bottom: 0,
                                                          trailing: sectionInset-Constants.Size.GamesListSelectionEdge)
            
            
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = itemSpacing
            section.contentInsets = NSDirectionalEdgeInsets(top: Constants.Size.ContentSpaceUltraTiny,
                                                            leading: 0,
                                                            bottom: (sectionIndex != (self.normalDatas.count - 1)) ? Constants.Size.ContentSpaceHuge : 0,
                                                            trailing: 0)
            
            let headerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                                            heightDimension: .estimated(Constants.Size.ItemHeightMin)),
                                                                         elementKind: UICollectionView.elementKindSectionHeader,
                                                                         alignment: .top)
            headerItem.pinToVisibleBounds = true
            section.boundarySupplementaryItems = [headerItem]
            
            if !isSearchMode && sectionIndex == self.normalDatas.count - 1 && self.collectionView.numberOfItems() > Constants.Numbers.RandomGameLimit {
                
                let footerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                                                heightDimension: .absolute(55)),
                                                                             elementKind: UICollectionView.elementKindSectionFooter,
                                                                             alignment: .bottom)
                section.boundarySupplementaryItems.append(footerItem)
            }
            
            return section
            
        }
        return layout
    }
    
    func searchDatas(string: String) {
        guard searchString != string else { return }
        
        let games = collectionView.indexPathsForSelectedItems?.compactMap({ getGame(at: $0) })
        isSearchMode = false
        searchString = string
        updateSearchDatas()
        isSearchMode = true
        collectionView.reloadData { [weak self] in
            guard let self = self else { return }
            if let games = games {
                
                games.forEach {
                    if let indexPath = self.getIndexPath(for: $0) {
                        self.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                    }
                }
                var mode: SelectionType = .selectNone
                if games.count == self.totalGamesCountForCurrentMode, self.totalGamesCountForCurrentMode > 0 {
                    mode = .selectAll
                } else if games.count > 0 {
                    mode = .selectSome(onlyOne: games.count == 1)
                }
                
                if self.totalGamesCountForCurrentMode > 0 {
                    self.didListViewSelectionChange?(mode)
                }
            }
        }
        reloadIndexView()
    }
    
    func stopSearch() {
        if isSearchMode {
            
            let games = collectionView.indexPathsForSelectedItems?.compactMap({ getGame(at: $0) })
            isSearchMode = false
            searchString = nil
            searchDatas.removeAll()
            collectionView.reloadData { [weak self] in
                guard let self = self else { return }
                if let games = games {
                    
                    games.forEach { self.collectionView.selectItem(at: self.getIndexPath(for: $0), animated: false, scrollPosition: []) }
                    var mode: SelectionType = .selectNone
                    if games.count == self.totalGamesCountForCurrentMode {
                        mode = .selectAll
                    } else if games.count > 0 {
                        mode = .selectSome(onlyOne: games.count == 1)
                    }
                    
                    self.didListViewSelectionChange?(mode)
                }
            }
            reloadIndexView()
        }
    }
    
    private func reloadIndexView() {
        let datasCount = (isSearchMode ? searchDatas : normalDatas).count
        if datasCount == 0 {
            indexView.isHidden = true
            return
        } else {
            indexView.isHidden = false
        }
        indexView.reloadData()
        indexView.deselectCurrentItem()
        indexView.selectItem(at: 0)
    }
    
    func editGame(item: GameEditToolItem, indexPath: IndexPath? = nil) {
        var games: [Game] = []
        if let indexPath = indexPath, let game = self.getGame(at: indexPath) {
            games.append(game)
        } else if let tempIndexPaths = collectionView.indexPathsForSelectedItems {
            games.append(contentsOf: tempIndexPaths.compactMap({ getGame(at: $0) }))
        } else {
            return
        }
        
        if games.count == 0 {
            return
        }
        
        let firstGame = games.first!
        
        switch item {
        case .rename:
            topViewController()?.present(GameInfoViewController(game: firstGame, readyAction: .rename), animated: true)
        case .cover:
            topViewController()?.present(GameInfoViewController(game: firstGame, readyAction: .changeCover), animated: true)
        case .checkSave:
            topViewController()?.present(GameInfoViewController(game: firstGame), animated: true)
        case .skin:
            topViewController()?.present(SkinSettingsViewController(game: firstGame), animated: true)
        case .shareRom:
            ShareManager.shareFiles(games: games, shareFileType: .rom)
        case .importSave:
            if firstGame.gameType == ._3ds {
                UIView.makeToast(message: R.string.localizable.threeDSNotSupportImportSave())
            } else {
                FilesImporter.shared.presentImportController(supportedTypes: UTType.gamesaveTypes, allowsMultipleSelection: false) { urls in
                    if let url = urls.first {
                        if firstGame.isSaveExtsts {
                            UIView.makeAlert(title: R.string.localizable.gameSaveAlreadyExistTitle(),
                                             detail: ImportError.saveAlreadyExist(gameSaveUrl: url, game: firstGame).localizedDescription,
                                             confirmTitle: R.string.localizable.confirmTitle(),
                                             enableForceHide: false,
                                             confirmAction: {
                                try? FileManager.safeCopyItem(at: url, to: firstGame.gameSaveUrl, shouldReplace: true)
                                UIView.makeToast(message: R.string.localizable.importGameSaveSuccessTitle())
                            })
                        } else {
                            try? FileManager.safeCopyItem(at: url, to: firstGame.gameSaveUrl, shouldReplace: true)
                            UIView.makeToast(message: R.string.localizable.importGameSaveSuccessTitle())
                        }
                    }
                }
            }
            
        case .shareSave:
            if firstGame.gameType == ._3ds {
                UIView.makeToast(message: R.string.localizable.threeDSNotSupportShareSave())
            } else {
                ShareManager.shareFiles(games: games, shareFileType: .save)
            }
        case .delete:
            UIView.makeAlert(title: R.string.localizable.gamesDelete(),
                             detail: R.string.localizable.deleteGameAlertDetail(),
                             confirmTitle: R.string.localizable.confirmDelte(),
                             confirmAction: {
                Game.change { realm in
                    for game in games {
                        if game.isRomExtsts {
                            if game.gameType == ._3ds, game.fileExtension.lowercased() == "app", let range = game.romUrl.path.range(of: "/content/00000000.app") {
                                let gamePath = String(game.romUrl.path[...range.lowerBound])
                                try FileManager.safeRemoveItem(at: URL(fileURLWithPath: gamePath))
                                SyncManager.deleteCloudFile(fileName: gamePath)
                                
                                let updatePath = gamePath.replacingOccurrences(of: "/00040000/", with: "/0004000e/")
                                try FileManager.safeRemoveItem(at: URL(fileURLWithPath: updatePath))
                                let dlcPath = gamePath.replacingOccurrences(of: "/00040000/", with: "/0004008c/")
                                try FileManager.safeRemoveItem(at: URL(fileURLWithPath: dlcPath))
                            } else {
                                try FileManager.safeRemoveItem(at: game.romUrl)
                                SyncManager.deleteCloudFile(fileName: game.fileName)
                            }
                        }
                        if game.isSaveExtsts {
                            try FileManager.safeRemoveItem(at: game.gameSaveUrl)
                            SyncManager.deleteCloudFile(fileName: game.gameSaveUrl.lastPathComponent)
                        }
                        if let coverData = game.gameCover {
                            coverData.deleteAndClean(realm: realm)
                        }
                        CreamAsset.batchDeleteAndClean(assets: game.gameSaveStates.compactMap({ $0.stateCover }), realm: realm)
                        CreamAsset.batchDeleteAndClean(assets: game.gameSaveStates.compactMap({ $0.stateData }), realm: realm)
                        if Settings.defalut.iCloudSyncEnable {
                            
                            game.gameCheats.forEach { $0.isDeleted = true }
                            game.gameSaveStates.forEach { $0.isDeleted = true }
                            game.isDeleted = true
                        } else {
                            
                            realm.delete(game.gameCheats)
                            realm.delete(game.gameSaveStates)
                            realm.delete(game)
                        }
                    }
                }
            })
        }
    }
}

extension GameListView: UICollectionViewDataSource {
    private func sortDatasKeys() -> [GameType] {
        let predefinedOrder: [GameType] = System.allCases.map { $0.gameType }
        let sortedKeys: [GameType] = predefinedOrder.filter { (isSearchMode ? searchDatas : normalDatas).keys.contains($0) }
        return sortedKeys
    }
    
    private func getGames(at section: Int) -> [Game] {
        let gameTypes = sortDatasKeys()
        let gameType = gameTypes[section]
        if let results = (isSearchMode ? searchDatas : normalDatas)[gameType] {
            return results
        }
        return []
    }
    
    private func getGame(at indexPath: IndexPath) -> Game? {
        let games = getGames(at: indexPath.section)
        if games.count > indexPath.row {
            return games[indexPath.row]
        }
        return nil
    }
    
    private func getIndexPath(for game: Game) -> IndexPath? {
        if let results = (isSearchMode ? searchDatas : normalDatas)[game.gameType] {
            if let section = sortDatasKeys().firstIndex(of: game.gameType), let row = results.firstIndex(of: game) {
                return IndexPath(row: row, section: section)
            }
        }
        return nil
    }
    
    private func deleteGames(indexPaths: [IndexPath]) {
        var sectionRowsDict: [Int: [Int]] = [:]
        for indexPath in indexPaths {
            if sectionRowsDict[indexPath.section] != nil {
                sectionRowsDict[indexPath.section]?.append(indexPath.row)
            } else {
                sectionRowsDict[indexPath.section] = [indexPath.row]
            }
        }
        
        let sortDatasKeys = sortDatasKeys()
        for (key, value) in sectionRowsDict {
            if var games = normalDatas[sortDatasKeys[key]] {
                games.remove(atOffsets: IndexSet(value))
                normalDatas[sortDatasKeys[key]] = games.count == 0 ? nil : games
            }
        }
        
        collectionView.reloadData()
        didDatasUpdate?(normalDatas.isEmpty)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        (isSearchMode ? searchDatas : normalDatas).count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return getGames(at: section).count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withClass: GameCollectionViewCell.self, for: indexPath)
        if let game = getGame(at: indexPath) {
            cell.setData(game: game, isSelect: isSelectionMode, highlightString: searchString)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            //header
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withClass: GamesCollectionReusableView.self, for: indexPath)
            let gameType = sortDatasKeys()[indexPath.section]
            header.setData(title: System(gameType: gameType).localizedShortName, highlightString: searchString)
            header.skinButton.onTap {
                topViewController()?.present(SkinSettingsViewController(gameType: gameType), animated: true)
            }
            return header
        } else {
            
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withClass: RandomGameCollectionReusableView.self, for: indexPath)
            header.addTapGesture { [weak self, weak header] gesture in
                guard let self = self else { return }
                guard let header = header else { return }
                self.fireworks.addFireworks(count: 2, around: header.iconImage)
                header.iconImage.rotateShake(completion: { [weak self] in
                    guard let self = self else { return }
                    let randomSection = 0//Int(arc4random()) % self.normalDatas.count
                    if let games = self.normalDatas[self.sortDatasKeys()[randomSection]] {
                        let randomGame = games[Int(arc4random()) % games.count]
                        
                        PlayViewController.startGame(game: randomGame)
                    }
                })
            }
            return header
        }
    }
}

extension UIView {
    func rotateShake(
        duration: TimeInterval = 1,
        completion: (() -> Void)? = nil) {
            CATransaction.begin()
            let animation = CAKeyframeAnimation(keyPath: "transform.rotation")
            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
            CATransaction.setCompletionBlock(completion)
            animation.duration = duration
            
            animation.values = [-.pi/4.0, .pi/4.0, -.pi/6.0, .pi/6.0, -.pi/8.0, .pi/8.0, -.pi/10.0, .pi/10.0, 0.0]
            layer.add(animation, forKey: "rotateShake")
            CATransaction.commit()
        }
}

extension GameListView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isSelectionMode {
            if let selectedItems = collectionView.indexPathsForSelectedItems?.count {
                if selectedItems == totalGamesCountForCurrentMode && selectedItems > 1 {
                    
                    didListViewSelectionChange?(.selectAll);
                } else if selectedItems > 0 {
                    didListViewSelectionChange?(.selectSome(onlyOne: selectedItems == 1));
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if isSelectionMode {
            return true
        }
        if let game = getGame(at: indexPath) {
            if Settings.defalut.quickGame {
                PlayViewController.startGame(game: game)
            } else {
                topViewController()?.present(GameInfoViewController(game: game), animated: true)
            }
        }
        return false
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let selectCount = collectionView.indexPathsForSelectedItems?.count {
            didListViewSelectionChange?(selectCount > 0 ? .selectSome(onlyOne: selectCount == 1) : .selectNone);
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        didScroll?()
        
        let contentOffsetY = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
        
        
        let isEditMode = isSearchMode || isSelectionMode
        if isEditMode {
            
            if contentOffsetY > Constants.Size.ItemHeightTiny {
                didUpdateToolView?(true, false)
            } else {
                didUpdateToolView?(true, true)
            }
            lastContentOffsetY = contentOffsetY
        } else {
            
            if contentOffsetY > 0 && lastContentOffsetY > 0 && contentOffsetY > lastContentOffsetY && scrollView.contentInset.top != gamesNavigationBottom {
                
                
                didUpdateToolView?(false, true)
                lastContentOffsetY = 0
                UIView.springAnimate { [weak self] in
                    guard let self = self else { return }
                    
                    scrollView.contentInset.top = self.gamesNavigationBottom
                }
            } else if contentOffsetY <= 0 && contentOffsetY < lastContentOffsetY && scrollView.contentInset.top != gamesToolBottom {
                
                
                didUpdateToolView?(true, true)
                lastContentOffsetY += Constants.Size.ItemHeightHuge
                UIView.normalAnimate { [weak self] in
                    guard let self = self else { return }
                    
                    self.collectionView.contentOffset = CGPoint(x: 0, y: -self.gamesToolBottom)
                } completion: { [weak self] _ in
                    guard let self = self else { return }
                    
                    scrollView.contentInset.top = self.gamesToolBottom
                }
            } else {
                lastContentOffsetY = contentOffsetY
            }
        }
        
        
        guard !indexView.isTouching else { return }
        let sections = collectionView.numberOfSections
        var pinnedSection: Int?
        for section in 0..<sections {
            if let layoutAttributes = collectionView.layoutAttributesForSupplementaryElement(ofKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: section)
            ) {
                let headerFrame = layoutAttributes.frame
                if contentOffsetY + 5 >= floor(headerFrame.origin.y) {
                    pinnedSection = section
                } else {
                    break
                }
            }
        }

        if let pinnedSection = pinnedSection {
            guard let item = self.indexView.item(at: pinnedSection), item.bounds != .zero  else { return }
            guard !(self.indexView.selectedItem?.isEqual(item) ?? false) else { return }
            self.indexView.deselectCurrentItem()
            self.indexView.selectItem(at: pinnedSection)
        }
    }
    
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        sectionIndexViewDidSelectSearch(indexView)
        return false
    }
    
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemsAt indexPaths: [IndexPath], point: CGPoint) -> UIContextMenuConfiguration? {
        guard selectionMode == .normalMode, let indexPath = indexPaths.first else { return nil }
        
        let editItems = GameEditToolItem.singleGameEditItems
        var firstGroup: [UIMenuElement] = []
        var secondGroup: [UIMenuElement] = []
        var thirdGroup: [UIMenuElement] = []
        for (index, editItem) in editItems.enumerated() {
            let action = UIAction(title: editItem.title, image: editItem.image, attributes: editItem == .delete ? .destructive : []) { [weak self] _ in
                guard let self = self else { return }
                self.editGame(item: editItems[index], indexPath: indexPath)
            }
            if index < 4 {
                
                firstGroup.append(action)
            } else if index < 7 {
                
                secondGroup.append(action)
            } else {
                
                thirdGroup.append(action)
            }
        }

        if let game = getGame(at: indexPath), let imageView = (collectionView.cellForItem(at: indexPath) as? GameCollectionViewCell)?.imageView {
            return UIContextMenuConfiguration(previewProvider: {
                let previewImageView = UIImageView(frame: CGRect(origin: .zero, size: imageView.size))
                previewImageView.image = imageView.image
                previewImageView.layerCornerRadius = imageView.layerCornerRadius
                let viewController = UIViewController()
                viewController.view.addSubview(previewImageView)
                viewController.preferredContentSize = previewImageView.size
                return  viewController
            }, actionProvider: { _ in
                UIMenu(title: game.aliasName ?? game.name, children: [UIMenu(options: .displayInline, children: firstGroup), UIMenu(options: .displayInline, children: secondGroup), UIMenu(options: .displayInline, children: thirdGroup)])
            })
        }
        return nil
    }
}

extension GameListView: SectionIndexViewDataSource, SectionIndexViewDelegate {
    func numberOfScetions(in sectionIndexView: SectionIndexView) -> Int {
        (isSearchMode ? searchDatas : normalDatas).count
    }
    
    func sectionIndexView(_ sectionIndexView: SectionIndexView, itemAt section: Int) -> any SectionIndexViewItem {
        let item = SectionIndexViewItemView()
        if let title = System(gameType: sortDatasKeys()[section]).localizedShortName.first?.uppercased() {
            item.title = title
        } else {
            item.title = "?"
        }
        item.titleColor = Constants.Color.LabelTertiary
        item.titleSelectedColor = Constants.Color.LabelPrimary
        item.selectedColor = Constants.Color.Red
        item.titleFont = Constants.Font.caption(size: .s, weight: .bold)
        return item
    }
    
    func sectionIndexView(_ sectionIndexView: SectionIndexView, didSelect section: Int) {
        sectionIndexView.hideCurrentItemIndicator()
        sectionIndexView.deselectCurrentItem()
        sectionIndexView.selectItem(at: section)
        sectionIndexView.showCurrentItemIndicator()
        sectionIndexView.impact()
        collectionView.panGestureRecognizer.isEnabled = false
        collectionView.scrollToItem(at: IndexPath(row: 0, section: section), at: .top, animated: true)
    }
    
    func sectionIndexViewToucheEnded(_ sectionIndexView: SectionIndexView) {
        UIView.animate(withDuration: 0.3) {
            sectionIndexView.hideCurrentItemIndicator()
        }
        collectionView.panGestureRecognizer.isEnabled = true
    }
    
    func sectionIndexViewDidSelectSearch(_ sectionIndexView: SectionIndexView) {
        collectionView.scrollToTop()
    }
}
