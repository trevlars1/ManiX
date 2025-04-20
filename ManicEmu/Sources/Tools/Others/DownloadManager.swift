//
//  DownloadManager.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2025/2/26.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import Tiercel

class DownloadManager {
    static let shared = DownloadManager()
    
    var hasDownloadTask: Bool {
        sessionManager.tasks.filter({ $0.status == .running }).count > 0
    }
    
    var didProgress: ((DownloadTask)->Void)? = nil
    var didSuccess: ((DownloadTask)->Void)? = nil
    var didFailure: ((DownloadTask)->Void)? = nil
    
    var sessionManager: SessionManager = {
        var config = SessionConfiguration()
        config.allowsCellularAccess = true
        let cache = Cache("DownloadManager", downloadPath: Constants.Path.DownloadWorkSpace)
        let manager = SessionManager(Constants.Config.AppIdentifier, configuration: config, cache: cache)
        let runningTasks = manager.tasks.filter({ $0.status == .running })
        if runningTasks.count > 0 {
            DispatchQueue.main.asyncAfter(delay: 0.35) {
                let fileNames = runningTasks.map({ $0.fileName }).reduce("") { $0 + ($0.isEmpty ? "" : "\n") + $1 }
                UIView.makeToast(message: R.string.localizable.importDownloadContinue(fileNames))
                DispatchQueue.main.asyncAfter(delay: 3) {
                    UIView.makeLoadingToast(message: R.string.localizable.loadingTitle())
                }
            }
        }
#if DEBUG
        manager.logger.option = .default
#endif
        manager.progress { manager in

        }.failure { manager in
            let tasks = manager.tasks.filter { $0.status == .canceled || $0.status == .failed }
            if tasks.count > 0 {
                let message = tasks.reduce("") { $0.isEmpty ? $1.fileName : $0 + "\n" + $1.fileName }
                UIView.makeToast(message: R.string.localizable.importDownloadError(message))
                
                tasks.forEach { manager.remove($0.url) }
            }
        }.success { manager in
            
            
            UIView.hideLoadingToast()
            UIView.makeToast(message: R.string.localizable.downloadCompletion())
            let succeededTasks = manager.succeededTasks
            FilesImporter.importFiles(urls: succeededTasks.map({ URL(fileURLWithPath: $0.filePath) })) {
                succeededTasks.forEach { manager.remove($0.url) }
            }
        }
        return manager
    }()
    
    func downloads(urls: [URL], fileNames: [String], headers: [String: String]? = nil) {
        DispatchQueue.global().async {
            self.sessionManager.multiDownload(urls, headersArray: headers == nil ? nil : urls.map({ _ in headers! }), fileNames: fileNames)
//            for task in tasks {
//                task.progress { task in
//                    self.didProgress?(task)
//                }.success { task in
//                    self.didSuccess?(task)
//                }.failure { task in
//                    self.didFailure?(task)
//                }
//            }
        }
    }
}
