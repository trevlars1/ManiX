//
//  ResourcesKit.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2025/3/22.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import SSZipArchive

struct ResourcesKit {
    static func loadResources(completion: ((Bool)->Void)? = nil) {
        var forceRefresh = false
        if let systemCoreVersion = UserDefaults.standard.string(forKey: Constants.DefaultKey.SystemCoreVersion) {
            let appVersion = Constants.Config.AppVersion
            let appVersionNumber = UInt64(appVersion.replacingOccurrences(ofPattern: "\\.", withTemplate: ""))!
            let systemCoreVersionNumber = UInt64(systemCoreVersion.replacingOccurrences(ofPattern: "\\.", withTemplate: ""))!
            if systemCoreVersionNumber < appVersionNumber {
                
                try? FileManager.safeRemoveItem(at: URL(fileURLWithPath: Constants.Path.Resource))
                forceRefresh = true
            }
        } else {
            
            try? FileManager.safeRemoveItem(at: URL(fileURLWithPath: Constants.Path.Resource))
            forceRefresh = true
        }
#if DEBUG
        forceRefresh = true
#endif
        
        if forceRefresh || !FileManager.default.fileExists(atPath: Constants.Path.Resource) {
            let resourceUrl = Bundle.main.url(forResource: "System", withExtension: "core")!
            
            SSZipArchive.unzipFile(atPath: resourceUrl.path, toDestination: Constants.Path.Resource, overwrite: true, password: Constants.Cipher.UnzipKey, progressHandler: nil) { _, isSuccess, error in
                
                completion?(isSuccess)
                if isSuccess {                    
                    UserDefaults.standard.set(Constants.Config.AppVersion, forKey: Constants.DefaultKey.SystemCoreVersion)
                } else {
                    
                }
            }
        } else {
            completion?(true)
        }
    }
}
