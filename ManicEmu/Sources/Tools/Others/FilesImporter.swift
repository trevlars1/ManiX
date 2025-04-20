//
//  FilesImporter.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2025/1/19.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import UniformTypeIdentifiers
import RealmSwift
import ManicEmuCore
import SSZipArchive
import ZIPFoundation
import IceCream
import SmartCodable
#if !targetEnvironment(simulator)
import Cytrus
#endif
import SWCompression

class FilesImporter: NSObject {
    static let shared = FilesImporter()
    private override init() {}
    private var manualHandle: (([URL])->Void)? = nil
    
    func presentImportController(supportedTypes: [UTType] = UTType.allTypes, allowsMultipleSelection: Bool = true, manualHandle: (([URL])->Void)? = nil) {
        let documentPickerViewController = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
        documentPickerViewController.delegate = self
        documentPickerViewController.overrideUserInterfaceStyle = .dark
        documentPickerViewController.allowsMultipleSelection = allowsMultipleSelection
        documentPickerViewController.modalPresentationStyle = .formSheet
        documentPickerViewController.sheetPresentationController?.preferredCornerRadius = Constants.Size.CornerRadiusMax
        topViewController()?.present(documentPickerViewController, animated: true)
        self.manualHandle = manualHandle
    }
}

extension FilesImporter: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if manualHandle != nil {
            manualHandle?(urls)
            manualHandle = nil
        } else {
            FilesImporter.importFiles(urls: urls)
        }
    }
}

extension FilesImporter {
    static func importFiles(urls: [URL],
                            preErrors: [Error] = [],
                            silentMode: Bool = PlayViewController.isGaming,
                            importCompletion: (()->Void)? = nil) {
        if urls.isEmpty {
            UIView.hideLoading()
            if preErrors.count > 0 {
                UIView.makeToast(message: String.errorMessage(from: preErrors))
            } else {
                UIView.makeToast(message: R.string.localizable.filesImporterErrorEmptyContent())
            }
            importCompletion?()
            return
        }
        
        
        let unzipUrls = handleZip(urls: urls, silentMode: silentMode)
        let urls = urls.filter({ !FileType.zip.extensions.contains($0.pathExtension) }) + unzipUrls
        
        if !silentMode {
            UIView.makeLoading()
        }
        let group = DispatchGroup()
        var errors: [ImportError] = []
        var gameErrors: [ImportError] = []
        var skinErrors: [ImportError] = []
        var gameSaveErrors: [ImportError] = []
        var importGames: [String] = []
        var importSkins: [String] = []
        var importGameSaves: [String] = []
        for url in urls {
            if let fileType = FileType(fileExtension: url.pathExtension) {
                
                switch fileType {
                case .game:
                    group.enter()
                    importGame(url: url) { gameName, error in
                        if let error = error {
                            gameErrors.append(error)
                        }
                        if let gameName = gameName {
                            importGames.append(gameName)
                        }
                        group.leave()
                    }
                case .gameSave:
                    
                    group.enter()
                    importSave(url: url) { gameSaveName, error in
                        if let error = error {
                            gameSaveErrors.append(error)
                        }
                        if let gameSaveName = gameSaveName {
                            importGameSaves.append(gameSaveName)
                        }
                        group.leave()
                    }
                case .skin:
                    group.enter()
                    importSkin(url: url) { skinName, error in
                        if let error = error {
                            skinErrors.append(error)
                        }
                        if let skinName = skinName {
                            importSkins.append(skinName)
                        }
                        group.leave()
                    }
                default:
                    break
                }
            } else {
                
                group.enter()
                errors.append(.noPermission(fileUrl: url))
                group.leave()
            }
        }
        group.notify(queue: .main) {
            UIView.hideLoading()
            if silentMode {
                importCompletion?()
                return
            }
            
            ErrorHandler.shared.handleErrors(gameSaveErrors) { error in
                switch error {
                case .saveNoMatchGames(_), .saveAlreadyExist(_, _), .saveMatchToMuch(_, _):
                    return true
                default:
                    return false
                }
            } handleAction: { error, actionCompletion in
                if Database.realm.objects(Game.self).count == 0 {
                    
                    switch error {
                    case .saveNoMatchGames(let url), .saveMatchToMuch(let url, _):
                        UIView.makeAlert(title: R.string.localizable.importErrorTitle(),
                                         detail: R.string.localizable.importGameSaveFailedNoGameError(url.lastPathComponent), hideAction: {
                            actionCompletion()
                        })
                    default:
                        actionCompletion()
                    }
                } else {
                    switch error {
                    case .saveNoMatchGames(let url):

                        GameSaveMatchGameView.show(gameSaveUrl: url,
                                                   title: R.string.localizable.gameSaveMatchTitle(),
                                                   detail: error.localizedDescription,
                                                   cancelTitle: R.string.localizable.cancelTitle()) {
                            actionCompletion()
                        }
                    case .saveAlreadyExist(let url, let game):
                        UIView.makeAlert(title: R.string.localizable.gameSaveAlreadyExistTitle(),
                                         detail: error.localizedDescription,
                                         confirmTitle: R.string.localizable.confirmTitle(),
                                         enableForceHide: false,
                                         confirmAction: {
                            try? FileManager.safeCopyItem(at: url, to: game.gameSaveUrl, shouldReplace: true)
                            SyncManager.uploadLocalOfflineFiles()
                            actionCompletion()
                        })
                    case .saveMatchToMuch(let url, let games):
                        GameSaveMatchGameView.show(gameSaveUrl: url,
                                                   showGames: games,
                                                   title: R.string.localizable.gameSaveMathToMuchTitle(),
                                                   detail: error.localizedDescription,
                                                   cancelTitle: R.string.localizable.cancelTitle()) {
                            actionCompletion()
                        }
                    default:
                        actionCompletion()
                    }
                }
            } completion: { unhandledErrors in
                func handleImportSuccess() {
                    if importGames.count > 0 && importSkins.count == 0 && importGameSaves.count == 0 {
                        
                        if let home = topViewController(appController: true) as? HomeViewController, home.currentSelection == .games {
                            UIView.makeToast(message: R.string.localizable.importGameSuccessTitle())
                        } else {
                            let detail: String
                            let confirmTitle: String
                            if importGames.count == 1 {
                                detail = R.string.localizable.importGameSuccessDetailForOne(String.successMessage(from: importGames))
                                confirmTitle = R.string.localizable.startGameTitle()
                            } else {
                                detail = R.string.localizable.importGameSuccessDetail(String.successMessage(from: importGames))
                                confirmTitle =  R.string.localizable.checkTitle()
                            }
                            
                            UIView.makeAlert(title: R.string.localizable.importGameSuccessTitle(),
                                             detail: detail,
                                             confirmTitle: confirmTitle,
                                             confirmAction: {
                                UIView.hideAllAlert {
                                    if importGames.count == 1 {
                                        startGame(gameName: importGames.first!)
                                    } else {
                                        NotificationCenter.default.post(name: Constants.NotificationName.HomeSelectionChange, object: HomeTabBar.BarSelection.games)
                                    }
                                }
                            })
                        }
                    } else if importSkins.count > 0 && importGames.count == 0 && importGameSaves.count == 0 {
                        if let _ = topViewController(appController: true) as? SkinSettingsViewController {
                            UIView.makeToast(message: R.string.localizable.importSkinSuccessTitle())
                        } else {
                            
                            UIView.makeAlert(title: R.string.localizable.importSkinSuccessTitle(),
                                             detail: R.string.localizable.importSkinSuccessDetail(String.successMessage(from: importSkins)),
                                             confirmTitle: R.string.localizable.checkTitle(),
                                             confirmAction: {
                                UIView.hideAllAlert {
                                    let vc: SkinSettingsViewController
                                    if importSkins.count == 1 {
                                        let skinName = importSkins.first!
                                        if let gameType = Database.realm.objects(Skin.self).first(where: { $0.name == skinName })?.gameType {
                                            vc = SkinSettingsViewController(gameType: gameType)
                                        } else {
                                            vc = SkinSettingsViewController()
                                        }
                                    } else {
                                        vc = SkinSettingsViewController()
                                    }
                                    
                                    DispatchQueue.main.asyncAfter(delay: 0.15) {
                                        topViewController()?.present(vc, animated: true)
                                    }
                                }
                            })
                        }
                    } else if importGameSaves.count > 0 && importGames.count == 0 && importSkins.count == 0 {
                        
                        let detail: String
                        var confirmTitle: String? = nil
                        if importGameSaves.count == 1 {
                            detail = R.string.localizable.importGameSaveSuccessForOne(String.successMessage(from: importGameSaves))
                            confirmTitle = R.string.localizable.startGameTitle()
                        } else {
                            detail = R.string.localizable.importGameSaveSuccessDetail(String.successMessage(from: importGameSaves))
                        }
                        UIView.makeAlert(title: R.string.localizable.importGameSaveSuccessTitle(),
                                         detail: detail,
                                         confirmTitle: confirmTitle,
                                         confirmAction: {
                            UIView.hideAllAlert {
                                startGame(gameName: importGameSaves.first!)
                            }
                        })
                    } else if importGameSaves.count > 0 || importGames.count > 0 || importSkins.count > 0 {
                        
                        UIView.makeToast(message: R.string.localizable.alertImportFilesSuccess())
                    }
                }
                
                errors.append(contentsOf: unhandledErrors)
                errors.append(contentsOf: gameErrors)
                errors.append(contentsOf: skinErrors)
                if errors.count > 0 {
                    UIView.makeAlert(title: R.string.localizable.importErrorTitle(),
                                     detail: String.errorMessage(from: errors),
                                     cancelTitle: R.string.localizable.confirmTitle(),
                                     hideAction: {
                        handleImportSuccess()
                    })
                } else {
                    handleImportSuccess()
                }
                importCompletion?()
            }
        }
    }
    
    private static func startGame(gameName: String) {
        let realm = Database.realm
        if let game = realm.objects(Game.self).first(where: {
            if $0.gameType == ._3ds {
                return $0.aliasName == gameName
            } else {
                return $0.name == gameName
            }
        }) {
            if Settings.defalut.quickGame {
                PlayViewController.startGame(game: game)
            } else {
                topViewController(appController: true)?.present(GameInfoViewController(game: game), animated: true)
            }
        }
    }
    
    class ErrorHandler {
        static let shared = ErrorHandler()
        
        func handleErrors(_ errors: [ImportError],
                          shouldHandle: @escaping (_ error: ImportError)->Bool,
                          handleAction: @escaping (_ error: ImportError, _ actionCompletion: @escaping ()->Void)->Void,
                          completion: @escaping (_ unhandledErrors: [ImportError]) -> Void) {
            var unhandledErrors = [ImportError]()
            var currentIndex = 0
            
            
            func processNext() {
                guard currentIndex < errors.count else {
                    completion(unhandledErrors)
                    return
                }
                
                let error = errors[currentIndex]
                currentIndex += 1
                
                if shouldHandle(error) {
                    
                    handleAction(error) {
                        
                        processNext()
                    }
                } else {
                    
                    unhandledErrors.append(error)
                    processNext()
                }
            }
            
            processNext()
        }
    }
    
    private static func importGame(url: URL, completion: ((_ gameName: String?, _ error: ImportError?)->Void)?) {
        DispatchQueue.global(qos: .userInitiated).async {
            let realm = Database.realm
            var ciaTitleUrl: URL? = nil
            let originalUrl = url
#if !targetEnvironment(simulator)
            var url = url
            var threeDSGameInfo: ThreeDSGameInformation? = nil
            if FileType.get3DSExtensions().contains([url.pathExtension]) {
                if url.pathExtension.lowercased() == "cia" {
                    
                    let status = ThreeDSCore.shared.importGame(at: url)
                    let ciaInfo = ThreeDSCore.shared.getCIAInfo(url: url)
                    if let titlePath = ciaInfo.titlePath {
                        ciaTitleUrl = URL(fileURLWithPath: titlePath)
                    }
                    guard let ciaPath = ciaInfo.contentPath else {
                        
                        Self.removeCIA(ciaTitleUrl: ciaTitleUrl)
                        completion?(nil, .badFile(fileName: url.lastPathComponent.deletingPathExtension))
                        return
                    }
                    
                    switch status {
                    case .success:
                        
                        if ciaPath.contains("/00040000/") {
                            
                            url = URL(fileURLWithPath: ciaPath)
                        } else {
                            
                            
                            let pattern = #"(?<=/title/)0004000[a-zA-Z0-9]"#
                            let gamePath = ciaPath.replacingOccurrences(of: pattern, with: "00040000", options: .regularExpression)
                            if FileManager.default.fileExists(atPath: gamePath) {
                                if let gameInfo = ThreeDSCore.shared.information(for: URL(fileURLWithPath: gamePath)) {
                                    
                                    completion?(gameInfo.title, nil)
                                } else {
                                    
                                    Self.removeCIA(ciaTitleUrl: ciaTitleUrl)
                                    completion?(nil, .badFile(fileName: url.lastPathComponent))
                                }
                            } else {
                                
                                Self.removeCIA(ciaTitleUrl: ciaTitleUrl)
                                completion?(nil, .ciaGameNotExist(fileName: url.lastPathComponent))
                            }
                            return
                        }
                    case .errorEncrypted:
                        
                        Self.removeCIA(ciaTitleUrl: ciaTitleUrl)
                        completion?(nil, .decryptFailed(fileName: url.lastPathComponent))
                        return
                    default:
                        
                        Self.removeCIA(ciaTitleUrl: ciaTitleUrl)
                        completion?(nil, .badFile(fileName: url.lastPathComponent))
                        return
                    }
                }
                if let gameInfo = ThreeDSCore.shared.information(for: url) {
                    
                    threeDSGameInfo = gameInfo
                } else {
                    
                    Self.removeCIA(ciaTitleUrl: ciaTitleUrl)
                    completion?(nil, .badFile(fileName: url.lastPathComponent))
                    return
                }
            }
#endif
            
            if let hash = FileHashUtil.truncatedHash(url: url) {
                if let game = realm.object(ofType: Game.self, forPrimaryKey: hash) {
                    
                    if game.isRomExtsts {
                        
                        
                        completion?(nil, .fileExist(fileName: url.lastPathComponent))
                        return
                    } else {
                        do {
                            try FileManager.safeCopyItem(at: url, to: game.romUrl, shouldReplace: true)
                            
                            completion?(game.name, nil)
                            return
                        } catch {
                            
                            
                            completion?(nil, .badCopy(fileName: game.name))
                            return
                        }
                    }
                } else {
                    
                    let game = Game()
                    game.id = hash
                    game.name = originalUrl.deletingPathExtension().lastPathComponent
                    game.fileExtension = url.pathExtension
                    
#if !targetEnvironment(simulator)
                    if let threeDSGameInfo {
                        
                        var extras = ["identifier": threeDSGameInfo.identifier, "regions": threeDSGameInfo.regions]
                        if ciaTitleUrl != nil  {
                            extras["appRomPath"] = url.path.replacingOccurrences(of: Constants.Path.Data + "/", with: "")
                        }
                        game.extras = extras.jsonData()
                        if !threeDSGameInfo.title.isEmpty {
                            game.aliasName = threeDSGameInfo.title
                        }
                        if let iconFor3DS = threeDSGameInfo.icon,
                            let image = iconFor3DS.decodeRGB565(width: 48, height: 48),
                            let imageData = image.jpegData(compressionQuality: 0.7) {
                            game.gameCover = CreamAsset.create(objectID: game.id, propName: "gameCover", data: imageData)
                        }
                    }
#endif
                    
                    if let gameType = GameType(fileExtension: game.fileExtension) {
                        game.gameType = gameType
                        game.importDate = Date()
                        do {
                            if ciaTitleUrl == nil {
                                
                                if FileManager.default.fileExists(atPath: game.romUrl.path) {
                                    try FileManager.default.removeItem(at: game.romUrl)
                                }
                                try FileManager.safeCopyItem(at: url, to: game.romUrl)
                            }
                            do {
                                try realm.write { realm.add(game) }
                                SyncManager.uploadLocalOfflineFiles()
                                completion?(game.gameType == ._3ds ? game.aliasName : game.name, nil)
                                return
                            } catch {
                                
                                
                                if let ciaTitleUrl {
                                    try? FileManager.safeRemoveItem(at: ciaTitleUrl)
                                }
                                completion?(nil, .writeDatabase(fileName: game.name))
                                return
                            }
                        } catch {
                            
                            
                            if let ciaTitleUrl {
                                try? FileManager.safeRemoveItem(at: ciaTitleUrl)
                            }
                            completion?(nil, .badCopy(fileName: game.name))
                            return
                        }
                    } else {
                        
                        
                        Self.removeCIA(ciaTitleUrl: ciaTitleUrl)
                        completion?(nil, .badExtension(fileName: game.name))
                        return
                    }
                }
            } else {
                
                
                Self.removeCIA(ciaTitleUrl: ciaTitleUrl)
                completion?(nil, .badFile(fileName: url.lastPathComponent))
                return
            }
        }
    }
    
    private static func removeCIA(ciaTitleUrl: URL?) {
        if let ciaTitleUrl {
            try? FileManager.safeRemoveItem(at: ciaTitleUrl)
        }
    }
    
    private static func importSave(url: URL, completion: ((_ gameName: String?, _ error: ImportError?)->Void)?) {
        DispatchQueue.global().async {
            let realm = Database.realm
            let fileExtension = url.pathExtension
            let fileName = url.deletingPathExtension().lastPathComponent
            var games: Results<Game>
            if let gameType = GameType(saveFileExtension: fileExtension) {
                games = realm.objects(Game.self).where { $0.name == fileName && $0.gameType == gameType }
            } else {
                games = realm.objects(Game.self).where { $0.name == fileName }
            }
            if games.count == 0 {
                
                completion?(nil, .saveNoMatchGames(gameSaveUrl: url))
                return
            } else if games.count == 1 {
                
                
                let game = games.first!
                if game.isSaveExtsts {
                    
                    
                    let ref = ThreadSafeReference(to: game)
                    DispatchQueue.main.async {
                        let realm = Database.realm
                        if let game = realm.resolve(ref) {
                            completion?(nil, .saveAlreadyExist(gameSaveUrl: url, game: game))
                        }
                    }
                    return
                } else {
                    
                    do {
                        try FileManager.safeCopyItem(at: url, to: game.gameSaveUrl)
                        SyncManager.uploadLocalOfflineFiles()
                        completion?(game.name, nil)
                        return
                    } catch {
                        completion?(nil, .badCopy(fileName: "\(url.lastPathComponent)"))
                        return
                    }
                }
            } else if games.count > 0 {
                
                let ref = ThreadSafeReference(to: games)
                DispatchQueue.main.async {
                    let realm = Database.realm
                    if let games = realm.resolve(ref) {
                        completion?(nil, .saveMatchToMuch(gameSaveUrl: url, games: games.map { $0 }))
                    }
                }
                return
            }
        }
    }
    
    private static func importSkin(url: URL, completion: ((_ skinName: String?, _ error: ImportError?)->Void)?) {
        DispatchQueue.global().async {
            if let controllerSkin = ControllerSkin(fileURL: url) {
                if let hash = FileHashUtil.truncatedHash(url: url) {
                    let realm = Database.realm
                    if let skin = realm.object(ofType: Skin.self, forPrimaryKey: hash) {
                        
                        if skin.isFileExtsts {
                            
                            completion?(nil, .fileExist(fileName: skin.fileName))
                            return
                        } else {
                            
                            do {
                                
                                try FileManager.safeCopyItem(at: url, to: skin.fileURL, shouldReplace: true)
                                completion?(skin.name, nil)
                                return
                            } catch {
                                
                                completion?(nil, .badCopy(fileName: skin.fileName))
                                return
                            }
                        }
                    } else {
                        
                        let skin = Skin()
                        skin.id = hash
                        skin.identifier = controllerSkin.identifier
                        skin.name = controllerSkin.name
                        skin.fileName = url.lastPathComponent
                        skin.gameType = controllerSkin.gameType
                        skin.skinType = SkinType(fileExtension: url.pathExtension)!
                        skin.skinData = CreamAsset.create(objectID: skin.id, propName: "skinData", url: url)
                        do {
                            try realm.write {
                                realm.add(skin)
                            }
                            SyncManager.uploadLocalOfflineFiles()
                            completion?(skin.name, nil)
                            return
                        } catch {
                            completion?(nil, .writeDatabase(fileName: skin.fileName))
                            return
                        }
                    }
                } else {
                    completion?(nil, .noPermission(fileUrl: url))
                    return
                }
            } else {
                
                completion?(nil, .skinBadFile(fileName: url.lastPathComponent))
                return
            }
        }
    }
    
    static func handleZip(urls: [URL], silentMode: Bool) -> [URL] {
        var results = [URL]()
        for url in urls {
            if FileType.zip.extensions.contains(url.pathExtension) {
                var innerResults = [URL]()
                if url.pathExtension.lowercased() == "zip" {
                    
                    if SSZipArchive.isFilePasswordProtected(atPath: url.path) {
                        
                        if !silentMode {
                            UIView.makeToast(message: R.string.localizable.notSupportPasswordZip(url.lastPathComponent))
                        }
                        continue
                    } else {
                        
                        if let archive = try? Archive(url: url, accessMode: .read, pathEncoding: nil) {
                            for entry in archive {
                                if entry.type == .file, let _ = FileType(fileExtension: entry.path.pathExtension) {
                                    do {
                                        let dstPath = Constants.Path.ZipWorkSpace.appendingPathComponent(entry.decodedPath)
                                        let destUrl = URL(fileURLWithPath: dstPath)
                                        if FileManager.default.fileExists(atPath: dstPath) {
                                            try FileManager.safeRemoveItem(at: destUrl)
                                        }
                                        _ = try archive.extract(entry, to: destUrl)
                                        innerResults.append(destUrl)
                                    } catch {
                                        if !silentMode {
                                            UIView.makeToast(message: R.string.localizable.unzipFailed(entry.path.lastPathComponent))
                                        }
                                    }
                                }
                            }
                            results.append(contentsOf: innerResults)
                        } else {
                            if !silentMode {
                                UIView.makeToast(message: R.string.localizable.unzipFailed(url.lastPathComponent))
                            }
                            continue
                        }
                    }
                } else if url.pathExtension.lowercased() == "7z"  {
                    do {
                        
                        let archive = try SevenZipContainer.open(container: Data(contentsOf: url))
                        for entry in archive {
                            if entry.info.type == .regular, let _ = FileType(fileExtension: entry.info.name.pathExtension) {
                                
                                let dstPath = Constants.Path.ZipWorkSpace.appendingPathComponent(entry.info.name)
                                
                                let destUrl = URL(fileURLWithPath: dstPath)
                                if FileManager.default.fileExists(atPath: dstPath) {
                                    try FileManager.safeRemoveItem(at: destUrl)
                                }
                                if !FileManager.default.fileExists(atPath: dstPath.deletingLastPathComponent) {
                                    try FileManager.default.createDirectory(at: URL(fileURLWithPath: dstPath.deletingLastPathComponent), withIntermediateDirectories: true)
                                }
                                try entry.data?.write(to: destUrl)
                                
                                innerResults.append(destUrl)
                            }
                        }
                        results.append(contentsOf: innerResults)
                    } catch(SevenZipError.encryptionNotSupported) {
                        UIView.makeToast(message: R.string.localizable.notSupportPasswordZip(url.lastPathComponent))
                    } catch {
                        
                        UIView.makeToast(message: R.string.localizable.unzipFailed(url.lastPathComponent))
                    }
                }
                if innerResults.isEmpty {
                    if !silentMode {
                        UIView.makeToast(message: R.string.localizable.noSupportInZip(url.lastPathComponent))
                    }
                }
            }
        }
        return results
    }
}
