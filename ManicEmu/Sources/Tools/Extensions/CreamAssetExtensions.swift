//
//  CreamAssetExtensions.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2025/3/24.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import IceCream
import RealmSwift

extension CreamAsset: ObjectUpdatable {
    func deleteAndClean(realm: Realm) {
        if !Settings.defalut.iCloudSyncEnable {
            
            try? FileManager.safeRemoveItem(at: self.filePath)
        }
        realm.delete(self)
    }
    
    static func batchDeleteAndClean(assets: [CreamAsset], realm: Realm) {
        if !Settings.defalut.iCloudSyncEnable {
            
            assets.forEach { asset in
                try? FileManager.safeRemoveItem(at: asset.filePath)
            }
        }
        realm.delete(assets)
    }
}
