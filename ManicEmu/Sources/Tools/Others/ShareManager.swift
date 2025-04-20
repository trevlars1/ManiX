//
//  ShareManager.swift
//  LandArt
//
//  Created by Aushuang Lee on 2023/5/17.
//  Copyright © 2023 Manic EMU. All rights reserved.
//

import UIKit
import LinkPresentation
import ZIPFoundation
import UniformTypeIdentifiers

enum ShareFileType {
    case rom, save
}




class ShareManager: NSObject {
    private static let shared = ShareManager()
    private lazy var metadata: LPLinkMetadata = {
        
        let data = LPLinkMetadata()
        data.url = Constants.URLs.AppStoreUrl
        
        data.title = Constants.Config.AppName
        
        data.originalURL = URL(fileURLWithPath: R.string.localizable.shareAppSubtitle())
        
        data.iconProvider = NSItemProvider(object: UIImage.placeHolder())
        return data
    }()
    private var documentInteractionController: UIDocumentInteractionController? = nil
}

extension ShareManager: UIActivityItemSource {
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return metadata.url!
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return metadata.url
    }
    
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        return metadata
    }
    
    static func shareApp(senderForIpad: UIView? = nil) {
        let activityViewController = UIActivityViewController(activityItems: [ShareManager.shared], applicationActivities: nil)
        
        activityViewController.excludedActivityTypes = [.saveToCameraRoll, .airDrop, .copyToPasteboard, .print]
        DispatchQueue.main.async {
            if let topVc = topViewController() {
                if let ppvc = activityViewController.popoverPresentationController {
                    ppvc.sourceView = senderForIpad
                }
                topVc.present(activityViewController, animated: true)
            }
        }
    }
}

extension ShareManager: UIDocumentInteractionControllerDelegate {
    static func shareFiles(games: [Game], shareFileType: ShareFileType) {
        guard games.count > 0 else {
            UIView.makeToast(message: {
                switch shareFileType {
                case .rom:
                    R.string.localizable.shareRomFilesFailed()
                case .save:
                    R.string.localizable.shareSaveFilesFailed()
                }
            }())
            
            return
        }
        
        if games.count == 1 {
            
            let game = games.first!
            var url: URL
            var uti: String
            switch shareFileType {
            case .rom:
                if !game.isRomExtsts {
                    UIView.makeToast(message: R.string.localizable.shareRomFilesFailed())
                    return
                }
                url = game.romUrl
                uti = game.gameType.rawValue
            case .save:
                if !game.isSaveExtsts {
                    UIView.makeToast(message: R.string.localizable.shareSaveFilesFailed())
                    return
                }
                url = game.gameSaveUrl
                uti = "public.data"
            }
            let documentInteractionController = UIDocumentInteractionController()
            ShareManager.shared.documentInteractionController = documentInteractionController
            documentInteractionController.delegate = ShareManager.shared
            documentInteractionController.url = url
            documentInteractionController.uti = uti
            if let view = topViewController()?.view {
                documentInteractionController.presentOptionsMenu(from: view.frame, in: view, animated: true)
            }
        } else {
            
            var urls: [URL] = []
            var zipWorkspaceName: String
            switch shareFileType {
            case .rom:
                urls.append(contentsOf: games.compactMap { $0.isRomExtsts ? $0.romUrl : nil })
                zipWorkspaceName = "Manic ROMs"
            case .save:
                urls.append(contentsOf: games.compactMap { $0.isSaveExtsts ? $0.gameSaveUrl : nil })
                zipWorkspaceName = "Manic Saves"
            }
            if urls.count == 0 {
                UIView.makeToast(message: {
                    switch shareFileType {
                    case .rom:
                        R.string.localizable.shareRomFilesFailed()
                    case .save:
                        R.string.localizable.shareSaveFilesFailed()
                    }
                }())
                return
            }
            UIView.makeLoading()
            DispatchQueue.global().async {
                let zipWorkspaceUrl = URL(fileURLWithPath: Constants.Path.ShareWorkSpace.appendingPathComponent("\(zipWorkspaceName) \(Date().string(withFormat: Constants.Strings.FileNameTimeFormat))"))
                
                do {
                    for url in urls {
                        try FileManager.safeCopyItem(at: url, to: zipWorkspaceUrl.appendingPathComponent(url.lastPathComponent), shouldReplace: true)
                    }
                } catch {
                    DispatchQueue.main.async {
                        UIView.hideLoading()
                        UIView.makeToast(message: R.string.localizable.shareFilesCopyFailed())
                    }
                    return
                }
                
                let zipFileUrl = zipWorkspaceUrl.appendingPathExtension("zip")
                do {
                    try FileManager.default.zipItem(at: zipWorkspaceUrl, to: zipFileUrl)
                } catch {
                    DispatchQueue.main.async {
                        UIView.hideLoading()
                        UIView.makeToast(message: R.string.localizable.shareFilesCompressFailed())
                    }
                    return
                }
                DispatchQueue.main.async {
                    UIView.hideLoading()
                    let documentInteractionController = UIDocumentInteractionController()
                    ShareManager.shared.documentInteractionController = documentInteractionController
                    documentInteractionController.delegate = ShareManager.shared
                    documentInteractionController.url = zipFileUrl
                    documentInteractionController.uti = UTType.zip.identifier
                    if let view = topViewController(appController: true)?.view {
                        documentInteractionController.presentOptionsMenu(from: view.frame, in: view, animated: true)
                    }
                    
                }
            }
        }
    }
    func documentInteractionControllerDidDismissOptionsMenu(_ controller: UIDocumentInteractionController) {
        
        documentInteractionController = nil
    }
}
