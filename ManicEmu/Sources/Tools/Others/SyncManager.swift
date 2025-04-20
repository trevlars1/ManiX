//
//  SyncManager.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2025/3/12.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import UIKit
import Foundation
import IceCream
import iCloudSync
import CloudKit

class SyncManager: NSObject {
    static let shared = SyncManager()
    
    private var realmSyncEngine: SyncEngine?
    
    private var documentSyncEngine: iCloud = iCloud.shared
    
    var iCloudServiceEnable: Bool? = nil
    
    var iCloudStatus: CKAccountStatus? = nil
    
    var hasDownloadTask: Bool {
        downloadFileNames.count > 0
    }
    
    private var downloadFileNames: [String] = []
    
    private var iCloudFileDownloadStatus = [String: Bool]()
    
    private var iCloudAccountChangedNotification: Any? = nil
    
    deinit {
        if let iCloudAccountChangedNotification = iCloudAccountChangedNotification {
            NotificationCenter.default.removeObserver(iCloudAccountChangedNotification)
        }
    }
    
    private override init() {
        super.init()
        updateiCloudAccountstatus()
        iCloudAccountChangedNotification = NotificationCenter.default.addObserver(forName: .CKAccountChanged, object: nil, queue: .main) { [weak self] notification in
            guard let self = self else { return }
            self.updateiCloudAccountstatus()
        }
    }
    
    
    func startSync() {
        if realmSyncEngine == nil {
            setupRealmSync()
            setupDocumentSync()
        }
    }
    
    
    func stopSync() {
        realmSyncEngine = nil
        documentSyncEngine.notificationCenter.removeObserver(documentSyncEngine)
        
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            if let cloudUrls = self.documentSyncEngine.listCloudFiles {
                for cloudUrl in cloudUrls {
                    if let localUrl = self.documentSyncEngine.localDocumentsURL?.appendingPathComponent(cloudUrl.lastPathComponent) {
                        if !FileManager.default.fileExists(atPath: localUrl.path) {
                            
                            let document: iCloudDocument = iCloudDocument(fileURL: cloudUrl)
                            try? document.contents.write(to: localUrl, options: Data.WritingOptions.atomicWrite)
                        }
                    }
                }
            }
        }
    }
    
    private func setupDocumentSync() {
        
        documentSyncEngine.delegate = self
        documentSyncEngine.setupiCloud()
    }

    private func setupRealmSync() {
        guard realmSyncEngine == nil else { return }
        
        let configuration = Database.realm.configuration
        realmSyncEngine = SyncEngine(objects: [
            SyncObject(realmConfiguration: configuration, type: Game.self, uListElementType: GameSaveState.self, vListElementType: GameCheat.self),
            SyncObject(realmConfiguration: configuration, type: GameCheat.self),
            SyncObject(realmConfiguration: configuration, type: Skin.self),
            SyncObject(realmConfiguration: configuration, type: GameSaveState.self),
            SyncObject(realmConfiguration: configuration, type: ImportService.self),
            SyncObject(realmConfiguration: configuration, type: Settings.self)
        ])
    }
    
    private func updateiCloudAccountstatus() {
        CKContainer.default().accountStatus { [weak self] status, error in
            guard let self = self else { return }
            
            self.iCloudServiceEnable = status == .available
            self.iCloudStatus = status
        }
    }
    
    static func uploadLocalOfflineFiles() {
        if Settings.defalut.iCloudSyncEnable {
            SyncManager.shared.documentSyncEngine.uploadLocalOfflineDocuments()
        }
    }
    
    static func deleteCloudFile(fileName: String) {
        if Settings.defalut.iCloudSyncEnable {
            SyncManager.shared.documentSyncEngine.deleteDocument(fileName)
        }
    }
    
    static func downloadiCloudFile(fileName: String, completion: ((Error?)->Void)? = nil) {
        Self.shared.downloadFileNames.append(fileName)
        SyncManager.shared.documentSyncEngine.retrieveCloudDocument(fileName) { _, _, error in
            Self.shared.downloadFileNames.removeAll { $0 == fileName }
            completion?(error)
        }
    }
    
    
    
    
    static func iCloudUrlFor(localUrl: URL) -> URL? {
        var filePath = localUrl.lastPathComponent
        if let range = localUrl.path.range(of: "Documents/Datas/") {
            filePath = String(localUrl.path[range.upperBound...])
        }
        if Settings.defalut.iCloudSyncEnable,
            SyncManager.shared.documentSyncEngine.fileExistInCloud(filePath),
            let iCloudRootUrl = SyncManager.shared.documentSyncEngine.cloudDocumentsURL {
            return iCloudRootUrl.appendingPathComponent(filePath)
        }
        return nil
    }
    
    
    static func isiCloudFile(url: URL) -> Bool {
        return url.path.contains("iCloud")
    }
    
    static func iCloudFileHasDownloaded(iCloudUrl: URL) -> Bool {
        if let hasDownloaded = SyncManager.shared.iCloudFileDownloadStatus[iCloudUrl.lastPathComponent], hasDownloaded {
            return true
        }
        return false
    }
    
    static func iCloudUrl() -> URL? {
        if Settings.defalut.iCloudSyncEnable {
            return SyncManager.shared.documentSyncEngine.cloudDocumentsURL
        }
        return nil
    }
}

extension SyncManager: iCloudDelegate {
    func iCloudFilesDidChange(_ files: [NSMetadataItem], with filenames: [String]) {
        for (index, file) in files.enumerated() {
            let fileName = filenames[index]
            if let downloadingStatus = file.value(forAttribute: NSMetadataUbiquitousItemDownloadingStatusKey) as? String {
                if downloadingStatus == NSMetadataUbiquitousItemDownloadingStatusNotDownloaded {
                    
                    iCloudFileDownloadStatus[fileName] = false
                } else {
                    iCloudFileDownloadStatus[fileName] = true
                }
            }
        }
    }

    func iCloudFileConflictBetweenCloudFile(_ cloudFile: [String: Any]?, with localFile: [String: Any]?) {
        if let cloudFile = cloudFile, let localFile = localFile {
            

            UIView.makeAlert(title: R.string.localizable.iCloudSyncConfilictTitle(),
                             detail: R.string.localizable.iCloudSyncConfilictDetail(conflictFileInfo(file: cloudFile), conflictFileInfo(file: localFile)),
                             cancelTitle: R.string.localizable.iCloudSyncConfilictSaveiCloud(),
                             confirmTitle: R.string.localizable.iCloudSyncConfilictSaveiCloud(),
                             enableForceHide: false,
                             cancelAction: { [weak self] in
                
                if let url = localFile["fileURL"] as? URL {
                    try? self?.documentSyncEngine.fileManager.removeItem(at: url)
                    self?.documentSyncEngine.updateFiles()
                }
                
            },
                             confirmAction: { [weak self] in
                
                if let url = cloudFile["fileURL"] as? URL {
                    self?.documentSyncEngine.deleteDocument(url.lastPathComponent, completion: { [weak self] error in
                        if error == nil {
                            self?.documentSyncEngine.uploadLocalDocumentToCloud(url.lastPathComponent)
                        }
                    })
                }
                
                
            })
        }
    }
    
    private func conflictFileInfo(file: [String: Any]) -> String {
        var fileInfo = ""
        if let fileURL = file["fileURL"] as? URL {
            fileInfo += fileURL.lastPathComponent
        }
        if let fileContents = file["fileContents"] as? Data,
            let size = FileType.humanReadableFileSize(UInt64(fileContents.count)) {
            fileInfo += ((fileInfo.isEmpty ? "" : " ") + size)
        }
        if let modifiedDate = file["modifiedDate"] as? Date {
            fileInfo += ((fileInfo.isEmpty ? "" : "\n") + modifiedDate.dateTimeString())
        }
        return fileInfo
    }
}
