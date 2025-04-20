//
//  PlayViewController.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2025/1/13.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import UIKit
import ManicEmuCore
import Schedule
import Haptica
import RealmSwift
import ProHUD
import IceCream
import StoreKit
#if targetEnvironment(simulator)
import MetalKit
#endif


class PlayViewController: GameViewController {
    
    private let manicGame: Game
    private let gameFileName: String
    
    private var loadSaveState: GameSaveState? = nil
    
    private var gameControllerDidConnectNotification: Any? = nil
    private var keyboardDidConnectNotification: Any? = nil
    private var sceneWillConnectNotification: Any? = nil
    private var sceneDidDisconnectNotification: Any? = nil
    private var scenewillDeactivateNotification: Any? = nil
    private var sceneDidActivateNotification: Any? = nil
    private var windowDidBecomeKeyNotification: Any? = nil
    private var membershipNotification: Any? = nil

    
    private lazy var repeatTimer: Schedule.Task = {
        if let task = TaskCenter.default.tasks(forTag: String(describing: Self.self)).first {
            return task
        } else {
            let task = Plan.every(Constants.Numbers.AutoSaveGameDuration.seconds).do(queue: .global()) { [weak self] in
                guard let self = self else { return }
                
                self.calculatePlayTime()
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.saveState(type: .autoSaveState)
                }
            }
            TaskCenter.default.addTag(String(describing: Self.self), to: task)
            return task
        }
    }()
    
    static var skinControllerPlayerIndex = 0 {
        didSet {
            if let currentPlayViewController = currentPlayViewController {
                currentPlayViewController.controllerView.playerIndex = skinControllerPlayerIndex
            }
        }
    }
    
    static weak var currentPlayViewController: PlayViewController? = nil
    
    private var functionButtonContainer = FunctionButtonContainerView()
    
    private var threesDSMetalView: MTKView? = nil
    private var threeDSCore: ThreeDSEmulatorBridge? = nil
    
    deinit {
        Log.debug("\(String(describing: Self.self)) deinit")
        if let gameControllerDidConnectNotification = gameControllerDidConnectNotification {
            NotificationCenter.default.removeObserver(gameControllerDidConnectNotification)
        }
        if let keyboardDidConnectNotification = keyboardDidConnectNotification {
            NotificationCenter.default.removeObserver(keyboardDidConnectNotification)
        }
        if let sceneWillConnectNotification = sceneWillConnectNotification {
            NotificationCenter.default.removeObserver(sceneWillConnectNotification)
        }
        if let sceneDidDisconnectNotification = sceneDidDisconnectNotification {
            NotificationCenter.default.removeObserver(sceneDidDisconnectNotification)
        }
        if let scenewillDeactivateNotification = scenewillDeactivateNotification {
            NotificationCenter.default.removeObserver(scenewillDeactivateNotification)
        }
        if let sceneDidActivateNotification = sceneDidActivateNotification {
            NotificationCenter.default.removeObserver(sceneDidActivateNotification)
        }
        if let windowDidBecomeKeyNotification = windowDidBecomeKeyNotification {
            NotificationCenter.default.removeObserver(windowDidBecomeKeyNotification)
        }
        if let membershipNotification = membershipNotification {
            NotificationCenter.default.removeObserver(membershipNotification)
        }
        if DownloadManager.shared.hasDownloadTask || SyncManager.shared.hasDownloadTask {
            UIView.makeLoadingToast(message: R.string.localizable.loadingTitle())
        }
    }
    
    
    private var gameUpdateToken: Any? = nil
    private var cheatCodeUpdateToken: Any? = nil
    private var settingsUpdateToken: Any? = nil
    
    private var lastSaveDate: Date? = nil
    private var lastLoadDate: Date? = nil
    
    static func startGame(game: Game, saveState: GameSaveState? = nil) {
        if game.isRomExtsts {
            if SyncManager.isiCloudFile(url: game.romUrl), !SyncManager.iCloudFileHasDownloaded(iCloudUrl: game.romUrl) {
                
                UIView.makeLoadingToast(message: R.string.localizable.loadingTitle())
                let fileName = game.fileName
                SyncManager.downloadiCloudFile(fileName: fileName) { error in
                    UIView.hideLoadingToast()
                    UIView.makeToast(message: R.string.localizable.loadRomSuccess(fileName))
                }
                return
            } else {
                UIView.hideLoadingToast(forceHide: true)
                func showPlayView() {
                    if game.gameType == ._3ds, !UIDevice.current.hasA11ProcessorOrBetter, !UserDefaults.standard.bool(forKey: Constants.DefaultKey.HasShow3DSNotSupportAlert) {
                        UIView.makeAlert(title: R.string.localizable.threeDSNoSupportDeviceTitle(), detail: R.string.localizable.threeDSNoSupportDeviceDetail(), confirmTitle: R.string.localizable.gameSaveContinue(), confirmAction: {
                            UserDefaults.standard.set(true, forKey: Constants.DefaultKey.HasShow3DSNotSupportAlert)
                            topViewController(appController: true)?.present(PlayViewController(game: game, saveState: saveState), animated: true)
                        })
                    } else {
                        topViewController(appController: true)?.present(PlayViewController(game: game, saveState: saveState), animated: true)
                    }
                }
                if game.gameType == ._3ds, !UserDefaults.standard.bool(forKey: Constants.DefaultKey.HasShow3DSPlayAlert) {
                    UIView.makeAlert(title: R.string.localizable.threeDSBetaAlertTitle(),
                                     detail: R.string.localizable.threeDSBetaAlertDetail(),
                                     detailAlignment: .left,
                                     cancelTitle: R.string.localizable.confirmTitle(), cancelAction: {
                        UserDefaults.standard.set(true, forKey: Constants.DefaultKey.HasShow3DSPlayAlert)
                        showPlayView()
                    });
                } else {
                    showPlayView()
                }
            }
        } else {
            UIView.makeToast(message: R.string.localizable.loadGameErrorRomNotExist())
            return
        }
    }
    
    
    private init(game: Game, saveState: GameSaveState? = nil) {
        manicGame = game
        gameFileName = game.fileName
        super.init()
        Log.debug("\(String(describing: Self.self)) init")
        prefersVolumeEnable = manicGame.volume
        loadSaveState = saveState
        modalPresentationStyle = .fullScreen
        delegate = self
        self.game = ManicEmuCore.Game(fileURL: game.romUrl, type: game.gameType)
        
        
        
        gameControllerDidConnectNotification = NotificationCenter.default.addObserver(forName: .externalGameControllerDidConnect, object: nil, queue: .main) { [weak self] notification in
            
            self?.updateExternalGameController()
        }
        keyboardDidConnectNotification = NotificationCenter.default.addObserver(forName: .externalKeyboardDidConnect, object: nil, queue: .main) { [weak self] notification in
            
            self?.updateExternalGameController()
        }
        
        sceneWillConnectNotification = NotificationCenter.default.addObserver(forName: UIScene.willConnectNotification, object: nil, queue: .main) { [weak self] notification in
            
            self?.updateAirPlay()
        }
        sceneDidDisconnectNotification = NotificationCenter.default.addObserver(forName: UIScene.didDisconnectNotification, object: nil, queue: .main) { [weak self] notification in
            
            self?.updateAirPlay()
        }
        
        scenewillDeactivateNotification = NotificationCenter.default.addObserver(forName: UIScene.willDeactivateNotification, object: nil, queue: .main) { [weak self] notification in
            
            guard let self = self else { return }
            if self.manicGame.gameType == ._3ds {
                self.threeDSCore?.pause()
            }
        }
        
        sceneDidActivateNotification = NotificationCenter.default.addObserver(forName: UIScene.didActivateNotification, object: nil, queue: .main) { [weak self] notification in
            
            self?.setNeedsUpdateOfScreenEdgesDeferringSystemGestures()
            guard let self = self else { return }
            if self.manicGame.gameType == ._3ds, self.gameViewControllerShouldResume(self) {
                self.threeDSCore?.resume()
            }
        }
        
        
        windowDidBecomeKeyNotification = NotificationCenter.default.addObserver(forName: UIWindow.didBecomeKeyNotification, object: nil, queue: .main) { [weak self] notification in
            self?.setNeedsUpdateOfScreenEdgesDeferringSystemGestures()
        }
        
        
        membershipNotification = NotificationCenter.default.addObserver(forName: Constants.NotificationName.MembershipChange, object: nil, queue: .main) { [weak self] notification in
            if PurchaseManager.isMember {
                UIView.hideAllAlert { [weak self] in
                    if ExternalSceneDelegate.isAirPlaying {
                        if Settings.defalut.airPlay {
                            self?.updateAirPlay()
                        } else {
                            
                            UIView.makeAlert(detail: R.string.localizable.turnOnAirPlayAsk(), confirmTitle: R.string.localizable.confirmTitle(), confirmAction: { [weak self] in
                                Settings.change { realm in
                                    Settings.defalut.airPlay = true
                                }
                                self?.updateAirPlay()
                            }, hideAction: { [weak self] in
                                self?.resumeEmulationAndHandleAudio()
                            })
                        }
                    } else {
                        self?.resumeEmulationAndHandleAudio()
                    }
                }
            }
        }
        
        
        updateLatestPlayDate()
        
        
        repeatTimer.resume()
        
        
        cheatCodeUpdateToken = manicGame.gameCheats.observe { [weak self] change in
            guard let self = self else { return }
            switch change {
            case .update(_ , let deletions, let insertions, let modifications):
                if !deletions.isEmpty || !insertions.isEmpty || !modifications.isEmpty {
                    self.updateCheatCodes()
                }
            default:
                break
            }
        }
        
        
        gameUpdateToken = manicGame.observe(keyPaths: [\Game.portraitSkin, \Game.landscapeSkin, \Game.filterName, \Game.orientation, \Game.haptic, \Game.volume]) { [weak self] change in
            guard let self = self else { return }
            switch change {
            case .change(_, let properties):
                
                for property in properties {
                    if property.name == "filterName" {
                        
                        self.updateFilter()
                    } else if property.name == "portraitSkin" || property.name == "landscapeSkin" {
                        
                        self.gameViews.forEach { gameView in
                            gameView.isEnabled = false
                        }
                        
                        self.updateSkin()
                    } else if property.name == "orientation" {
                        
                        self.startOrientation()
                    } else if property.name == "haptic" {
                        
                        self.updateHaptic()
                    }
                    
                    if property.name == "volume" ||  property.name == "haptic" {
                        let settings = Settings.defalut
                        if let controllerSkin = controllerView.controllerSkin,
                            let skin = Database.realm.objects(Skin.self).first(where: { $0.identifier == controllerSkin.identifier }),
                            skin.skinType == .default,
                           settings.displayGamesFunctionCount > 0 {
                            if property.name == "volume", settings.gameFunctionList.prefix(settings.displayGamesFunctionCount).contains(where: { $0 == GameSetting.ItemType.volume.rawValue }) {
                                self.updateFunctionButton()
                            } else if property.name == "haptic", settings.gameFunctionList.prefix(settings.displayGamesFunctionCount).contains(where: { $0 == GameSetting.ItemType.haptic.rawValue }) {
                                self.updateFunctionButton()
                            }
                        }
                    }
                    
                    
                }
            default:
                break
            }
        }
        
        
        settingsUpdateToken = Settings.defalut.observe(keyPaths: [\Settings.gameFunctionList, \Settings.displayGamesFunctionCount]) { [weak self] change in
            guard let self = self else { return }
            switch change {
            case .change(_, _):
                self.updateFunctionButton()
            default:
                break
            }
        }
    }
    
    @MainActor required init() {
        fatalError("init() has not been implemented")
    }
    
    @MainActor required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        PlayViewController.currentPlayViewController = self
        
        
        NotificationCenter.default.post(name: Constants.NotificationName.StartPlayGame, object: nil)
        
        
        view.addSubview(functionButtonContainer)
        functionButtonContainer.snp.makeConstraints { make in
            make.leading.trailing.equalTo(gameView)
            make.top.equalTo(gameView.snp.bottom)
            make.height.equalTo(Constants.Size.ItemHeightMid)
        }
        
        updateExternalGameController()
        
        loadConfig()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if manicGame.gameType != ._3ds {
            super.viewWillAppear(animated)
        }
        setOrientationConfig()
        setNeedsUpdateOfScreenEdgesDeferringSystemGestures()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        updateSkin()
        
        updateAudio()
        if manicGame.gameType != ._3ds {
            
            manicEmuCore?.setRate(speed: manicGame.speed)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resetOrientationConfig()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        repeatTimer.suspend()
        
        if let airPlayViewController = ExternalSceneDelegate.airPlayViewController, let airPlayGameView = airPlayViewController.gameView, manicGame.gameType != ._3ds {
            self.manicEmuCore?.remove(airPlayGameView)
            airPlayGameView.removeFromSuperview()
            airPlayViewController.gameView = nil
        }
        
        if manicGame.totalPlayDuration > 30 * 60 * 1000 { 
            if let scene = ApplicationSceneDelegate.applicationScene {
                if let showDate = UserDefaults.standard.date(forKey: Constants.DefaultKey.ShowRequestReviewDate), showDate.isInToday {
                    return
                }
                SKStoreReviewController.requestReview(in: scene)
                UserDefaults.standard.set(Date(), forKey: Constants.DefaultKey.ShowRequestReviewDate)
            }
        }
        
        if manicGame.gameType == ._3ds {
            threeDSCore?.destory()
        }
        
        PlayViewController.currentPlayViewController = nil
        
        
        NotificationCenter.default.post(name: Constants.NotificationName.StopPlayGame, object: nil)
    }
    
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        if manicGame.orientation == .landscape {
            return .landscapeRight
        } else if manicGame.orientation == .portrait {
            return .portrait
        }
        return super.preferredInterfaceOrientationForPresentation
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        let fromSize = Constants.Size.WindowSize
        let toSize = size
        if manicGame.orientation == .portrait {
            
            if fromSize.height > fromSize.width && toSize.height < toSize.width {
                return
            }
        } else if manicGame.orientation == .landscape {
            
            if fromSize.height < fromSize.width && toSize.height > toSize.width {
                return
            }
        }
        UIView.hideAllAlert()
        super.viewWillTransition(to: size, with: coordinator)
        guard UIApplication.shared.applicationState != .background else { return }
                
        coordinator.animate(alongsideTransition: { [weak self] (context) in
            guard let self = self else { return }
            self.updateSkin()
            self.view.setNeedsLayout()
        }) { [weak self] _ in
            guard let self = self else { return }
            self.resumeEmulationAndHandleAudio()
        }
    }
    
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        return .all
    }
    
    override func gameController(_ gameController: any GameController, didActivate input: any Input, value: Double) {
        super.gameController(gameController, didActivate: input, value: value)
        
        if input.stringValue == "menu" {
            guard !GameSettingView.isShow else { return }
            if manicGame.gameType == ._3ds {
                threeDSCore?.pause()
            } else {
                pauseEmulation()
            }
            GameSettingView.show(game: manicGame,
                                 gameViewRect: gameView.frame,
                                 didSelectItem: { [weak self] item, sheet in
                
                guard let self = self else { return true }
                return self.handleMenuGameSetting(item, sheet)
            }, hideCompletion: { [weak self] in
                
                guard let self = self else { return }
                self.resumeEmulationAndHandleAudio()
            })
        }
    }
    
    override func gameController(_ gameController: any GameController, didDeactivate input: any Input) {
        super.gameController(gameController, didDeactivate: input)
    }
}


extension PlayViewController {
    
    private func calculatePlayTime() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let latestPlayDate =  manicGame.latestPlayDate {
                Game.change { realm in
                    self.manicGame.latestPlayDuration = Date().timeIntervalSince1970ms - latestPlayDate.timeIntervalSince1970ms
                    self.manicGame.totalPlayDuration += Double(Constants.Numbers.AutoSaveGameDuration*1000)
                }
                
            }
        }
    }
    
    private func saveStateFor3DS(type: GameSaveStateType) {
        let now = Date.now
        if type == .manualSaveState, let lastSaveDate = lastSaveDate, now.timeIntervalSince1970ms - lastSaveDate.timeIntervalSince1970ms < 5000 {
            UIView.makeToast(message: R.string.localizable.saveStateTooFrequent(), identifier: "saveStateTooFrequent")
            return
        }
            
        if let threeDSCore = self.threeDSCore {
            let now = Date()
            
            let result = threeDSCore.saveState()
            if result.isSuccess {
                var image: UIImage? = nil
                if let imageData = threeDSCore.requestScreenshot(), let tempImage = UIImage(data: imageData) {
                    image = tempImage.cropped(to: CGRect(origin: .zero, size: CGSize(width: tempImage.size.width, height: tempImage.size.height/2))).scaled(toHeight: 150)
                }
                DispatchQueue.main.asyncAfter(delay: 2) {
                    let state = GameSaveState()
                    state.name = "\(now.string(withFormat: Constants.Strings.FileNameTimeFormat))_" + result.path.lastPathComponent
                    state.type = type
                    state.date = now
                    if let imageData = image?.jpegData(compressionQuality: 0.7) {
                        state.stateCover = CreamAsset.create(objectID: state.name, propName: "stateCover", data: imageData)
                    }
                    state.stateData = CreamAsset.create(objectID: state.name, propName: "stateData", url: URL(fileURLWithPath: result.path))
                    let autoSaveStates = self.manicGame.gameSaveStates.where({ $0.type == .autoSaveState }).sorted(by: \GameSaveState.date)
                    Game.change { realm in
                        
                        if autoSaveStates.count >= Constants.Numbers.AutoSaveGameCount {
                            let needToDeletes = autoSaveStates.prefix(autoSaveStates.count - Constants.Numbers.AutoSaveGameCount + 1)
                            CreamAsset.batchDeleteAndClean(assets: needToDeletes.compactMap({ $0.stateCover }), realm: realm)
                            CreamAsset.batchDeleteAndClean(assets: needToDeletes.compactMap({ $0.stateData }), realm: realm)
                            if Settings.defalut.iCloudSyncEnable {
                                needToDeletes.forEach { $0.isDeleted = true }
                            } else {
                                realm.delete(needToDeletes)
                            }
                        }
                        self.manicGame.gameSaveStates.append(state)
                    }
                    if type == .manualSaveState {
                        self.lastSaveDate = Date.now
                        UIView.makeToast(message: R.string.localizable.gameSaveStateSuccess(), identifier: "gameSaveStateSuccess")
                    }
                    
                }
            }
        }
    }
    
    
    
    private func saveState(type: GameSaveStateType) {
        if manicGame.gameType == ._3ds {
            return
        }
        let now = Date.now
        if type == .manualSaveState, let lastSaveDate = lastSaveDate, now.timeIntervalSince1970ms - lastSaveDate.timeIntervalSince1970ms < 1000 {
            UIView.makeToast(message: R.string.localizable.saveStateTooFrequent(), identifier: "saveStateTooFrequent")
            return
        }
            
        if let manicEmuCore = self.manicEmuCore {
            
            guard manicEmuCore.state == .running || type == .manualSaveState else { return }
            let now = Date()
            if !FileManager.default.fileExists(atPath: Constants.Path.SaveStateWorkSpace) {
                try? FileManager.default.createDirectory(atPath: Constants.Path.SaveStateWorkSpace, withIntermediateDirectories: true)
            }
            let fileUrl = URL(fileURLWithPath: Constants.Path.SaveStateWorkSpace).appendingPathComponent("\(now.timeIntervalSince1970).savestate")
            pauseEmulation()
            manicEmuCore.saveSaveState(to: fileUrl)
            resumeEmulationAndHandleAudio()
            if FileManager.default.fileExists(atPath: fileUrl.path) {
                var image = manicEmuCore.videoManager.snapshot()
                if manicGame.gameType == .ds, let tempImage = image {
                    image = tempImage.cropped(to: CGRect(origin: .zero, size: CGSize(width: tempImage.size.width, height: tempImage.size.height/2))).scaled(toHeight: 150)
                }
                let state = GameSaveState()
                state.name = "\(manicGame.id)_\(now.string(withFormat: Constants.Strings.FileNameTimeFormat))"
                state.type = type
                state.date = now
                if let imageData = image?.jpegData(compressionQuality: 0.7) {
                    state.stateCover = CreamAsset.create(objectID: state.name, propName: "stateCover", data: imageData)
                }
                state.stateData = CreamAsset.create(objectID: state.name, propName: "stateData", url: fileUrl)
                let autoSaveStates = self.manicGame.gameSaveStates.where({ $0.type == .autoSaveState }).sorted(by: \GameSaveState.date)
                Game.change { realm in
                    
                    if autoSaveStates.count >= Constants.Numbers.AutoSaveGameCount {
                        let needToDeletes = autoSaveStates.prefix(autoSaveStates.count - Constants.Numbers.AutoSaveGameCount + 1)
                        CreamAsset.batchDeleteAndClean(assets: needToDeletes.compactMap({ $0.stateCover }), realm: realm)
                        CreamAsset.batchDeleteAndClean(assets: needToDeletes.compactMap({ $0.stateData }), realm: realm)
                        if Settings.defalut.iCloudSyncEnable {
                            needToDeletes.forEach { $0.isDeleted = true }
                        } else {
                            realm.delete(needToDeletes)
                        }
                    }
                    self.manicGame.gameSaveStates.append(state)
                }
                if type == .manualSaveState {
                    self.lastSaveDate = Date.now
                    UIView.makeToast(message: R.string.localizable.gameSaveStateSuccess(), identifier: "gameSaveStateSuccess")
                }
                
            }
        }
    }
    
    private func quickLoadStateFor3DS(_ state: GameSaveState?) {
        let now = Date.now
        if let lastLoadDate = lastLoadDate, now.timeIntervalSince1970ms - lastLoadDate.timeIntervalSince1970ms < 5000 {
            UIView.makeToast(message: R.string.localizable.loadStateTooFrequent(), identifier: "loadStateTooFrequent")
            return
        }
        
        if let state = state ?? manicGame.gameSaveStates.last(where: { $0.type == .manualSaveState }),
            let threeDSCore = self.threeDSCore,
            let slot = UInt32(state.name.deletingPathExtension.pathExtension) {
            
            if let fileUrl = state.stateData?.filePath {
                threeDSCore.addSaveState(fileUrl: fileUrl, slot: slot)
            }
            threeDSCore.loadState(slot)
            UIView.makeToast(message: R.string.localizable.gameSaveStateLoadSuccess())
            lastLoadDate = Date.now
            updateCheatCodes()
        } else {
            UIView.makeToast(message: R.string.localizable.gameSaveStateQuickLoadFailed())
        }
    }
    
    
    
    private func quickLoadStateAndResume(_ state: GameSaveState?) {
        let now = Date.now
        if let lastLoadDate = lastLoadDate, now.timeIntervalSince1970ms - lastLoadDate.timeIntervalSince1970ms < 1000 {
            UIView.makeToast(message: R.string.localizable.loadStateTooFrequent(), identifier: "loadStateTooFrequent")
            return
        }
        
        if let state = state ?? manicGame.gameSaveStates.last(where: { $0.type == .manualSaveState }), let fileUrl = state.stateData?.filePath, let manicEmuCore = self.manicEmuCore {
            manicEmuCore.stop()
            manicEmuCore.videoManager.isEnabled = false
            manicEmuCore.start()
            manicEmuCore.pause()
            do {
                try manicEmuCore.load(SaveState(fileURL: fileUrl, gameType: manicGame.gameType))
                UIView.makeToast(message: R.string.localizable.gameSaveStateLoadSuccess())
                lastLoadDate = Date.now
            } catch {
                
                UIView.makeToast(message: R.string.localizable.gameSaveStateLoadFailed())
            }
            manicEmuCore.videoManager.isEnabled = true
            resumeEmulationAndHandleAudio()
            updateCheatCodes()
        } else {
            UIView.makeToast(message: R.string.localizable.gameSaveStateQuickLoadFailed())
        }
    }
    
    
    
    
    @discardableResult
    private func handleMenuGameSetting(_ item: GameSetting, _ menuSheet: SheetTarget?) -> Bool {
        switch item.type {
        case .saveState:
            
            if !PurchaseManager.isMember && manicGame.gameSaveStates.filter({ $0.type == .manualSaveState }).count >= Constants.Numbers.NonMemberManualSaveGameCount {
                
                if menuSheet == nil {
                    if manicGame.gameType == ._3ds {
                        threeDSCore?.pause()
                    } else {
                        pauseEmulation()
                    }
                }
                UIView.makeAlert(identifier: Constants.Strings.PlayPurchaseAlertIdentifier,
                                 detail: R.string.localizable.manualGameSaveCountLimit(),
                                 confirmTitle: R.string.localizable.goToUpgrade(),
                                 confirmAutoHide: false,
                                 confirmAction: {
                    topViewController()?.present(PurchaseViewController(), animated: true)
                }) { [weak self] in
                    if menuSheet == nil {
                        self?.resumeEmulationAndHandleAudio()
                    }
                }
                return false
            }
            
            
            if manicGame.gameType == ._3ds {
                saveStateFor3DS(type: .manualSaveState)
            } else {
                saveState(type: .manualSaveState)
            }
        case .quickLoadState:
            
            if manicGame.gameType == ._3ds {
                quickLoadStateFor3DS(item.loadState)
            } else {
                quickLoadStateAndResume(item.loadState)
            }
        case .volume:
            
            
            Game.change { realm in
                manicGame.volume = item.volumeOn
            }
            prefersVolumeEnable = item.volumeOn
            if menuSheet == nil {
                
                updateAudio()
            }
            UIView.makeToast(message: item.volumeOn ? R.string.localizable.volumeOn(): R.string.localizable.volumeOff(), identifier: "gameVolume")
        case .fastForward:
            
            if !PurchaseManager.isMember && item.fastForwardSpeed.rawValue > GameSetting.FastForwardSpeed.two.rawValue {
                
                if menuSheet == nil {
                    pauseEmulation()
                }
                UIView.makeAlert(identifier: Constants.Strings.PlayPurchaseAlertIdentifier,
                                 detail: R.string.localizable.fastForwardSpeedLimit(),
                                 cancelTitle: R.string.localizable.resetSpeed(),
                                 confirmTitle: R.string.localizable.goToUpgrade(),
                                 confirmAutoHide: false, cancelAction: { [weak self] in
                    guard let self = self else { return }
                    self.manicEmuCore?.setRate(speed: .one)
                    Game.change { realm in
                        self.manicGame.speed = .one
                    }
                    UIView.makeToast(message: R.string.localizable.gameSettingFastForwardResume())
                }, confirmAction: {
                    topViewController()?.present(PurchaseViewController(), animated: true)
                }) { [weak self] in
                    if menuSheet == nil {
                        self?.resumeEmulationAndHandleAudio()
                    }
                }
            } else {
                if manicGame.speed != item.fastForwardSpeed {
                    manicEmuCore?.setRate(speed: item.fastForwardSpeed)
                    Game.change { realm in
                        manicGame.speed = item.fastForwardSpeed
                    }
                }
                UIView.makeToast(message: item.fastForwardSpeed == .one ? R.string.localizable.gameSettingFastForwardResume() : item.fastForwardSpeed.title, identifier: "gameSpeed")
            }
            return false
        case .stateList:
            if menuSheet == nil {
                if manicGame.gameType == ._3ds {
                    threeDSCore?.pause()
                } else {
                    self.pauseEmulation()
                }
            }
            GameInfoView.show(game: manicGame, gameViewRect: gameView.frame, selection: { [weak self, weak menuSheet] saveState in
                guard let self = self else { return }
                func loadSave() {
                    if self.manicGame.gameType == ._3ds {
                        DispatchQueue.main.asyncAfter(delay: 1) {
                            self.threeDSCore?.resume()
                            self.quickLoadStateFor3DS(saveState)
                        }
                    } else {
                        self.quickLoadStateAndResume(saveState)
                    }
                }
                if menuSheet == nil {
                    loadSave()
                } else {
                    menuSheet?.pop {
                        loadSave()
                    }
                }
            }, hideCompletion: { [weak self] in
                if menuSheet == nil {
                    self?.resumeEmulationAndHandleAudio()
                }
            })
            return false
        case .cheatCode:
            if menuSheet == nil {
                pauseEmulation()
            }
            CheatCodeListView.show(game: manicGame, gameViewRect: gameView.frame, hideCompletion: { [weak self] in
                if menuSheet == nil {
                    self?.resumeEmulationAndHandleAudio()
                }
            })
            return false
        case .skins:
            if menuSheet == nil {
                if manicGame.gameType == ._3ds {
                    threeDSCore?.pause()
                } else {
                    pauseEmulation()
                }
            }
            SkinSettingsView.show(game: manicGame, gameViewRect: gameView.frame, hideCompletion: { [weak self] in
                if menuSheet == nil {
                    self?.resumeEmulationAndHandleAudio()
                }
            })
            return false
        case .filter:
            if menuSheet == nil {
                pauseEmulation()
            }
            var snapshot = manicEmuCore?.videoManager.snapshot()
            if manicGame.gameType == .ds, let temp = snapshot {
                snapshot = temp.cropped(to: CGRect(origin: .zero, size: CGSize(width: temp.size.width, height: temp.size.height/2)))
            }
            FilterSelectionView.show(game: manicGame, snapshot: snapshot, gameViewRect: gameView.frame, hideCompletion: { [weak self] in
                if menuSheet == nil {
                    self?.resumeEmulationAndHandleAudio()
                }
            })
            return false
        case .screenShot:
            
            if manicGame.gameType == ._3ds {
                if let threeDSCore {
                    DispatchQueue.global().asyncAfter(delay: menuSheet == nil ? 0 : 1, execute: {
                        if let imageData = threeDSCore.requestScreenshot() {
                            PhotoSaver.save(datas: [imageData])
                        }
                    })
                }
            } else {
                PhotoSaver.save(datas: gameViews.compactMap { $0.snapshot()?.processGameSnapshop() })
                return false
            }
        case .haptic:
            switch item.hapticType {
            case .off:
                break
            case .soft:
                Haptic.impact(.soft).generate()
            case .light:
                Haptic.impact(.light).generate()
            case .medium:
                Haptic.impact(.medium).generate()
            case .heavy:
                Haptic.impact(.heavy).generate()
            case .rigid:
                Haptic.impact(.rigid).generate()
            }
            if manicGame.haptic != item.hapticType {
                Game.change { realm in
                    manicGame.haptic = item.hapticType
                }
            }
            UIView.makeToast(message: item.hapticType.title, identifier: "hapticType")
            return false
        case .airplay:
            if menuSheet == nil {
                if manicGame.gameType == ._3ds {
                    threeDSCore?.pause()
                } else {
                    pauseEmulation()
                }
            }
            let vc = WebViewController(url: Constants.URLs.AirPlayUsageGuide, isShow: true)
            vc.didClose = { [weak self] in
                if menuSheet == nil {
                    self?.resumeEmulationAndHandleAudio()
                }
            }
            topViewController()?.present(vc, animated: true)
            return false
        case .controllerSetting:
            if menuSheet == nil {
                if manicGame.gameType == ._3ds {
                    threeDSCore?.pause()
                } else {
                    pauseEmulation()
                }
            }
            ControllersSettingView.show(gameViewRect: gameView.frame, hideCompletion: { [weak self] in
                if menuSheet == nil {
                    self?.resumeEmulationAndHandleAudio()
                }
            })
            return false
        case .orientation:
            if manicGame.orientation != item.orientation {
                Game.change { realm in
                    manicGame.orientation = item.orientation
                }
                
                DispatchQueue.main.asyncAfter(delay: 0.5) {
                    UIView.makeToast(message: item.orientation.title)
                }
            } else {
                UIView.makeToast(message: item.orientation.title)
            }
            return true
        case .functionSort:
            if menuSheet == nil {
                if manicGame.gameType == ._3ds {
                    threeDSCore?.pause()
                } else {
                    pauseEmulation()
                }
            }
            GameSettingView.show(game: manicGame, gameViewRect: gameView.frame, isEditingMode: true, hideCompletion: { [weak self] in
                if menuSheet == nil {
                    self?.resumeEmulationAndHandleAudio()
                }
            })
            return false
        case .reload:
            manicEmuCore?.stop()
            manicEmuCore?.start()
        case .quit:
            if manicGame.gameType == ._3ds {
                threeDSCore?.stop()
                DispatchQueue.main.asyncAfter(delay: 0.5) {
                    self.dismiss(animated: true)
                }
            } else {
                manicEmuCore?.stop()
                dismiss(animated: true)
            }
        }
        
        return true
    }
    
    
    private func updateExternalGameController() {
        if let manicEmuCore = self.manicEmuCore {
            for controler in ExternalGameControllerUtils.shared.linkedControllers {
                controler.addReceiver(self)
                controler.addReceiver(manicEmuCore)
            }
        }
    }
    
    
    private func updateLatestPlayDate() {
        let date = Date()
        
        Game.change { _ in
            self.manicGame.latestPlayDate = date
        }
    }
    
    private func resumeEmulationAndHandleAudio() {
        if manicGame.gameType == ._3ds {
            threeDSCore?.resume()
            updateAudio()
        } else {
            resumeEmulation()
            updateAudio()
            if PurchaseManager.isMember, Settings.defalut.airPlay, ExternalSceneDelegate.isAirPlaying, let airPlayGameView = ExternalSceneDelegate.airPlayViewController?.gameView {
                if !airPlayGameView.isEnabled {
                    airPlayGameView.isEnabled = true
                }
            } else {
                gameViews.forEach { gameView in
                    if !gameView.isEnabled {
                        gameView.isEnabled = true
                    }
                }
            }
        }
    }
    
    private func updateAudio() {
        if manicGame.gameType == ._3ds {
            if manicGame.volume {
                threeDSCore?.enableVolume()
            } else {
                threeDSCore?.disableVolume()
            }
        } else {
            if let manicEmuCore = manicEmuCore {
                if manicGame.volume && !manicEmuCore.audioManager.isEnabled {
                    manicEmuCore.audioManager.isEnabled = true
                } else if manicEmuCore.audioManager.isEnabled && !manicGame.volume {
                    manicEmuCore.audioManager.isEnabled = false
                }
            }
        }
    }
    
    private func updateCheatCodes() {
        if manicGame.gameType == ._3ds {
            if let extras = manicGame.extras,
                let jsonDict = try? JSONSerialization.jsonObject(with: extras, options: []) as? [String: Any],
                let identifier = jsonDict["identifier"] as? UInt64 {
                var cheatsTxt = ""
                var enableCheats: [String] = []
                for cheatCode in manicGame.gameCheats {
                    cheatsTxt += "[\(cheatCode.name)]\n\(cheatCode.code)\n"
                    if cheatCode.activate {
                        enableCheats.append("[\(cheatCode.name)]")
                    }
                }
                if !cheatsTxt.isEmpty  {
                    ThreeDS.setupCheats(identifier: identifier, cheatsTxt: cheatsTxt, enableCheats: enableCheats)
                    if enableCheats.count > 0 {
                        UIView.makeToast(message: R.string.localizable.gameCheatActivateSuccess(String.successMessage(from: enableCheats)))
                    }
                }
            }
        } else {
            if let manicEmuCore = manicEmuCore {
                let lastState = manicEmuCore.state
                pauseEmulation()
                var success = [String]()
                for cheatCode in manicGame.gameCheats {
                    if cheatCode.activate {
                        if manicEmuCore.cheatCodes[cheatCode.code] == nil {
                            do {
                                try manicEmuCore.activate(Cheat(code: cheatCode.code, type: CheatType(cheatCode.type)))
                                success.append(cheatCode.name)
                            } catch {
                                UIView.makeToast(message: R.string.localizable.gameCheatActivateFailed(cheatCode.name))
                            }
                        }
                    } else {
                        manicEmuCore.deactivate(Cheat(code: cheatCode.code, type: CheatType(cheatCode.type)))
                    }
                }
                if success.count > 0 {
                    UIView.makeToast(message: R.string.localizable.gameCheatActivateSuccess(String.successMessage(from: success)))
                }
                if lastState == .running {
                    resumeEmulationAndHandleAudio()
                }
            }
        }
    }
    
    private func updateFilter() {
        guard manicGame.gameType != ._3ds else { return }
        func handleGameViewFilter(_ newFilter: CIFilter?, handleGameView: GameView) {
            if let newFilter = newFilter {
                
                if let oldFilter = handleGameView.filter as? FilterChain {
                    var filters = oldFilter.inputFilters.filter { !($0 is CRTFilter) && $0.name !=  "CIColorCube" }
                    filters.append(newFilter)
                    handleGameView.filter = FilterChain(filters: filters)
                } else {
                    handleGameView.filter = newFilter
                }
            } else {
                
                if let oldFilter = handleGameView.filter {
                    if let oldFilter = oldFilter as? FilterChain {
                        let filters = oldFilter.inputFilters.filter { !($0 is CRTFilter) && $0.name !=  "CIColorCube" }
                        handleGameView.filter = FilterChain(filters: filters)
                    } else {
                        handleGameView.filter = nil
                    }
                }
            }
        }
        
        if let filterName = self.manicGame.filterName {
            if PurchaseManager.isMember, Settings.defalut.airPlay, ExternalSceneDelegate.isAirPlaying {
                if let airPlayGameView = ExternalSceneDelegate.airPlayViewController?.gameView {
                    handleGameViewFilter(FilterManager.find(name: filterName), handleGameView: airPlayGameView)
                }
            } else {
                gameViews.forEach { gameView in
                    handleGameViewFilter(FilterManager.find(name: filterName), handleGameView: gameView)
                }
            }
        } else {
            if PurchaseManager.isMember, Settings.defalut.airPlay, ExternalSceneDelegate.isAirPlaying {
                if let airPlayGameView = ExternalSceneDelegate.airPlayViewController?.gameView {
                    handleGameViewFilter(nil, handleGameView: airPlayGameView)
                }
            } else {
                gameViews.forEach { gameView in
                    handleGameViewFilter(nil, handleGameView: gameView)
                }
            }
        }
    }
    
    
    private func loadConfig() {
        
        if let saveState = loadSaveState {
            DispatchQueue.main.asyncAfter(delay: 1) { [weak self] in
                guard let self = self else { return }
                
                if self.manicGame.gameType == ._3ds {
                    DispatchQueue.main.asyncAfter(delay: 5) {
                        self.quickLoadStateFor3DS(saveState)
                    }
                } else {
                    self.quickLoadStateAndResume(saveState)
                }
            }
        }
        
        updateHaptic()
        
        DispatchQueue.main.asyncAfter(delay: manicGame.gameType == ._3ds ? 0 : 1) { [weak self] in
            
            self?.updateCheatCodes()
            
            self?.updateAirPlay()
        }
        
    }
    
    
    private func updateSkin() {
        if UIDevice.isLandscape {
            
            if let skin = manicGame.landscapeSkin {
                controllerView.controllerSkin = ControllerSkin(fileURL: skin.fileURL)
            } else if let skin = SkinConfig.prefferedLandscapeSkin(gameType: manicGame.gameType) {
                controllerView.controllerSkin = ControllerSkin(fileURL: skin.fileURL)
            }
        } else {
            
            if let skin = manicGame.portraitSkin {
                controllerView.controllerSkin = ControllerSkin(fileURL: skin.fileURL)
            } else if let skin = SkinConfig.prefferedPortraitSkin(gameType: manicGame.gameType) {
                controllerView.controllerSkin = ControllerSkin(fileURL: skin.fileURL)
            }
        }
        
        controllerView.playerIndex = PlayViewController.skinControllerPlayerIndex
        
        updateFilter()
        
        updateFunctionButton()
        if manicGame.gameType == .ds || manicGame.gameType == ._3ds {
            updateFunctionButtonContainer()
        }
    }
    
    
    private func startOrientation() {
        if #available(iOS 16.0, *) {
            self.setNeedsUpdateOfSupportedInterfaceOrientations()
            if let scene = ApplicationSceneDelegate.applicationScene {
                if manicGame.orientation == .landscape {
                    scene.requestGeometryUpdate(UIWindowScene.GeometryPreferences.iOS.init(interfaceOrientations: .landscapeRight))
                } else if manicGame.orientation == .portrait {
                    scene.requestGeometryUpdate(UIWindowScene.GeometryPreferences.iOS.init(interfaceOrientations: .portrait))
                }
            }
        } else {
            if manicGame.orientation == .landscape {
                UIDevice.current.setValue(NSNumber(integerLiteral: UIInterfaceOrientation.landscapeRight.rawValue), forKey: "orientation")
            } else if manicGame.orientation == .portrait {
                UIDevice.current.setValue(NSNumber(integerLiteral: UIInterfaceOrientation.portrait.rawValue), forKey: "orientation")
            }
        }
        setOrientationConfig()
    }
    
    
    

    private func setOrientationConfig() {
        AppDelegate.orientation = {
            if manicGame.orientation == .landscape {
                return .landscape
            } else if manicGame.orientation == .portrait {
                return .portrait
            } else {
                return UIDevice.isPad ? .all : .allButUpsideDown
            }
        }()
    }
    
    
    private func resetOrientationConfig() {
        AppDelegate.orientation = UIDevice.isPad ? .all : .portrait
    }
    
    
    private func updateHaptic() {
        switch manicGame.haptic {
        case .off:
            controllerView.isButtonHaptic = false
            controllerView.isThumbstickHaptic = false
        default:
            controllerView.isButtonHaptic = true
            controllerView.isThumbstickHaptic = true
        }
        
        switch manicGame.haptic {
        case .soft:
            controllerView.hapticFeedbackStyle = .soft
        case .light:
            controllerView.hapticFeedbackStyle = .light
        case .medium:
            controllerView.hapticFeedbackStyle = .medium
        case .heavy:
            controllerView.hapticFeedbackStyle = .heavy
        case .rigid:
            controllerView.hapticFeedbackStyle = .rigid
        default:
            break
        }
    }
    
    
    private func updateAirPlay() {
        guard manicGame.gameType != ._3ds else { return }
        if let traits = self.controllerView.controllerSkinTraits,
           let supportedTraits = self.controllerView.controllerSkin?.supportedTraits(for: traits),
           let screens = self.controllerView.controllerSkin?.screens(for: supportedTraits) {
            for (screen, gameView) in zip(screens, self.gameViews) {
                if PurchaseManager.isMember, Settings.defalut.airPlay, ExternalSceneDelegate.isAirPlaying {
                    
                    gameView.isEnabled = screen.isTouchScreen
                    if gameView == self.gameView {
                        gameView.isAirPlaying = true
                        gameView.isHidden = false
                    }
                    
                    
                    if !screen.isTouchScreen {
                        if let airPlayViewController = ExternalSceneDelegate.airPlayViewController {
                            let newGameView = GameView()
                            newGameView.update(for: screen)
                            newGameView.frame = gameView.bounds
                            self.manicEmuCore?.add(newGameView)
                            airPlayViewController.addGameView(newGameView)
                        }
                    }
                    
                } else {
                    
                    gameView.isEnabled = true
                    gameView.isAirPlaying = false
                    gameView.isHidden = false

                    
                    if let airPlayViewController = ExternalSceneDelegate.airPlayViewController, let airPlayGameView = airPlayViewController.gameView {
                        self.manicEmuCore?.remove(airPlayGameView)
                    }
                }
            }
            self.updateFilter()
        }
    }
    
    private func updateFunctionButton() {
        functionButtonContainer.subviews.forEach { $0.removeFromSuperview() }
        if manicGame.gameType == ._3ds && UIDevice.isPad {
            return
        }
        if let controllerSkin = controllerView.controllerSkin {
            if let skin = Database.realm.objects(Skin.self).first(where: { $0.identifier == controllerSkin.identifier }) {
                if skin.skinType == .default {
                    
                    let settings = Settings.defalut
                    let functionButtonCount = settings.displayGamesFunctionCount
                    guard functionButtonCount > 0 else { return }
                    let disableFor3DS = GameSetting.disableFor3DS.map { $0.rawValue }
                    for (index, settingTypeValue) in settings.gameFunctionList.filter({
                        if self.manicGame.gameType == ._3ds {
                            return !disableFor3DS.contains([$0])
                        }
                        return true
                    }).prefix(functionButtonCount).enumerated() {
                        if let settingType = GameSetting.ItemType(rawValue: settingTypeValue) {
                            var gameSetting = GameSetting(type: settingType)
                            gameSetting.volumeOn = manicGame.volume
                            gameSetting.hapticType = manicGame.haptic
                            let button = UIImageView(image: gameSetting.image.withRenderingMode(.alwaysTemplate).applySymbolConfig(color: Constants.Color.LabelTertiary))
                            button.tintColor = Constants.Color.LabelTertiary
                            button.contentMode = .center
                            button.isUserInteractionEnabled = true
                            button.enableInteractive = true
                            functionButtonContainer.addSubview(button)
                            button.snp.makeConstraints { make in
                                if manicGame.gameType == .ds || manicGame.gameType == ._3ds {
                                    if UIDevice.isPhone {
                                        make.width.equalTo(31)
                                        make.height.equalToSuperview().dividedBy(2)
                                        if index == 0 {
                                            make.leading.equalToSuperview()
                                            make.top.equalToSuperview()
                                        } else if index == 1 {
                                            make.leading.equalToSuperview()
                                            make.top.equalTo(functionButtonContainer.subviews[index - 1].snp.bottom)
                                        } else if index == 2 {
                                            make.trailing.equalToSuperview()
                                            make.top.equalToSuperview()
                                        } else if index == 3 {
                                            make.trailing.equalToSuperview()
                                            make.top.equalTo(functionButtonContainer.subviews[index - 1].snp.bottom)
                                        }
                                    } else {
                                        make.width.equalTo(50)
                                        make.top.bottom.equalToSuperview()
                                        if index == 0 {
                                            make.leading.equalToSuperview()
                                        } else if index == 1 {
                                            make.leading.equalTo(functionButtonContainer.subviews[index-1].snp.trailing)
                                        } else if index == 2 {
                                            make.trailing.equalToSuperview().inset(50)
                                        } else if index == 3 {
                                            make.trailing.equalToSuperview()
                                        }
                                    }
                                } else {
                                    if index == 0 {
                                        make.leading.equalToSuperview()
                                    } else {
                                        make.leading.equalTo(functionButtonContainer.subviews[index-1].snp.trailing)
                                    }
                                    make.top.bottom.equalToSuperview()
                                    if index == functionButtonCount-1 && functionButtonCount == Constants.Numbers.GameFunctionButtonCount {
                                        make.trailing.equalToSuperview()
                                    }
                                    make.width.equalToSuperview().dividedBy(Constants.Numbers.GameFunctionButtonCount)
                                }
                            }
                            button.addTapGesture { [weak self, weak button] gesture in
                                guard let self = self else { return }
                                var newGameSetting = GameSetting(type: settingType)
                                switch settingType {
                                case .volume:
                                    newGameSetting.volumeOn = !self.manicGame.volume
                                    button?.image = newGameSetting.image.applySymbolConfig(color: Constants.Color.LabelTertiary)
                                case .fastForward:
                                    newGameSetting.fastForwardSpeed = self.manicGame.speed.next
                                case .haptic:
                                    newGameSetting.hapticType = self.manicGame.haptic.next
                                case .orientation:
                                    newGameSetting.orientation = self.manicGame.orientation.next
                                default:
                                    break
                                }
                                self.handleMenuGameSetting(newGameSetting, nil)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func updateFunctionButtonContainer() {
        if (manicGame.gameType == .ds || (UIDevice.isPhone && manicGame.gameType == ._3ds)) &&  UIDevice.isPhone {
            functionButtonContainer.snp.remakeConstraints { make in
                if gameViews.count > 1 {
                    
                    if UIDevice.isLandscape {
                        make.leading.equalTo(gameViews[0]).inset(-33)
                        make.trailing.equalTo(gameViews[1]).inset(-33)
                        make.top.equalToSuperview()
                    } else {
                        make.leading.trailing.equalTo(gameViews[1]).inset(-33)
                        make.top.equalTo(gameViews[1])
                    }
                    
                    if manicGame.gameType == ._3ds {
                        if let displayType = controllerView.controllerSkinTraits?.displayType, displayType == .standard {
                            
                            make.height.equalTo(80)
                        } else {
                            
                            make.height.equalTo(96)
                        }
                    } else {
                        if let displayType = controllerView.controllerSkinTraits?.displayType, displayType == .standard, !UIDevice.isLandscape {
                            make.height.equalTo(87)
                        } else {
                            make.height.equalTo(113)
                        }
                    }
                    
                    
                    
                    
                    
                    
                    if let displayType = controllerView.controllerSkinTraits?.displayType, displayType == .standard {
                        if manicGame.gameType == ._3ds {
                            if UIDevice.isLandscape || UIDevice.isSmallScreenPhone {
                                make.height.equalTo(80)
                            } else {
                                make.height.equalTo(96)
                            }
                        } else {
                            if UIDevice.isLandscape {
                                make.height.equalTo(113)
                            } else {
                                make.height.equalTo(87)
                            }
                        }
                    }
                }
            }
        }
    }
}


extension PlayViewController: GameViewControllerDelegate {
    
    func gameViewController(_ gameViewController: GameViewController, optionsFor game: GameBase) -> [EmulatorCore.Option: Any] {
        var options: [EmulatorCore.Option: Any] = [.metal: false]
        if #available(iOS 18, macOS 15, *), ProcessInfo.processInfo.isiOSAppOnMac {
            options[.metal] = true
        }
        return options
    }
    
    func gameViewControllerShouldResume(_ gameViewController: GameViewController) -> Bool {
        if SheetProvider.find(identifier: Constants.Strings.PlayPurchaseAlertIdentifier).count > 0 {
            return false
        }
        return (GameSettingView.isShow || GameInfoView.isShow || CheatCodeListView.isShow || SkinSettingsView.isShow || FilterSelectionView.isShow || ControllersSettingView.isShow || GameSettingView.isEditingShow || WebViewController.isShow) ? false : true
    }
    
    func gameViewController(_ gameViewController: GameViewController, didUpdateGameViews gameViews: [GameView]) {
        if manicGame.gameType == ._3ds, gameViews.count == 2 {
            DispatchQueue.main.asyncAfter(delay: 1) {
                if let threesDSMetalView = self.threesDSMetalView {
                    let topView = gameViews.first!
                    let bottomView = gameViews.last!
                    threesDSMetalView.snp.remakeConstraints { make in
                        if UIDevice.isPad || !UIDevice.isLandscape {
                            make.leading.top.trailing.equalTo(topView)
                            make.bottom.equalTo(bottomView)
                        } else {
                            make.leading.top.bottom.equalTo(topView)
                            make.trailing.equalTo(bottomView)
                        }
                    }
                    self.threeDSCore?.updateViews(topRect: topView.frame, bottomRect: bottomView.frame)
                } else {
                    
                    let topView = gameViews.first!
                    let bottomView = gameViews.last!
                    self.threeDSCore = self.manicEmuCore?.manicCore.emulatorConnector as? ThreeDSEmulatorBridge
                    self.threesDSMetalView = .init(frame: .zero, device: MTLCreateSystemDefaultDevice())
                    guard let threesDSMetalView = self.threesDSMetalView else { return }
                    self.view.insertSubview(threesDSMetalView, belowSubview: self.controllerView)
                    threesDSMetalView.snp.makeConstraints { make in
                        if UIDevice.isPad || !UIDevice.isLandscape {
                            make.leading.top.trailing.equalTo(topView)
                            make.bottom.equalTo(bottomView)
                        } else {
                            make.leading.top.bottom.equalTo(topView)
                            make.trailing.equalTo(bottomView)
                        }
                    }
                    self.threeDSCore?.start(withGameURL: self.manicGame.romUrl, metalView: threesDSMetalView, topRect: topView.frame, bottomRect: bottomView.frame, mute: !self.manicGame.volume)
                }
            }
        }
    }
}


extension PlayViewController {
    static var isGaming: Bool { currentPlayViewController != nil }
    
    static var playingGameType: GameType {
        if let currentPlayViewController {
            return currentPlayViewController.manicGame.gameType
        }
        return .unknown
    }
}
