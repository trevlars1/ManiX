//
//  Settings.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2025/2/20.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import RealmSwift
import ManicEmuCore
import IceCream
import SmartCodable

extension Settings: CKRecordConvertible & CKRecordRecoverable {
    var isDeleted: Bool { return false }
}

class Settings: Object, ObjectUpdatable {
    
    static let defalut: Settings  = {
        return Database.realm.object(ofType: Settings.self, forPrimaryKey: Settings.defaultName)!
    }()
    
    static let defaultName = "SettingsDefault"
    
    @Persisted(primaryKey: true) var name: String = Settings.defaultName
    
    
    @Persisted var skinConfig: String
    
    
    @Persisted var quickGame: Bool = false
    
    @Persisted var airPlay: Bool = true
    
    @Persisted var appIconIndex: Int = 0
    
    @Persisted var language: String?
    
    @Persisted var gameFunctionList: List<Int>
    
    @Persisted var displayGamesFunctionCount: Int = Constants.Numbers.GameFunctionButtonCount
    
    var iCloudSyncEnable: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: "iCloudSyncEnable")
            if newValue {
                
                SyncManager.shared.startSync()
            } else {
                
                SyncManager.shared.stopSync()
            }
            ThreeDS.setupWorkSpace()
        }
        get {
            UserDefaults.standard.bool(forKey: "iCloudSyncEnable")
        }
    }
    
    @Persisted var threeDSMode: ThreeDSMode = .compatibility
}

struct SkinConfig: SmartCodable {
    var portraitSkins = [String: String]()
    var landscapeSkins = [String: String]()
    
    static func prefferedPortraitSkin(gameType: GameType) -> Skin? {
        prefferedSkin(gameType: gameType, isLandscape: false)
    }
    
    static func prefferedLandscapeSkin(gameType: GameType) -> Skin? {
        prefferedSkin(gameType: gameType, isLandscape: true)
    }
    
    static func prefferedSkin(gameType: GameType, isLandscape: Bool) -> Skin? {
        if let config = SkinConfig.deserialize(from: Settings.defalut.skinConfig),
           let skinId = isLandscape ? config.landscapeSkins[gameType.rawValue] : config.portraitSkins[gameType.rawValue],
            let skin = Database.realm.object(ofType: Skin.self, forPrimaryKey: skinId) {
            return skin
        } else {
            return Database.realm.objects(Skin.self).first { $0.gameType == gameType && $0.skinType == .default }
        }
    }
    
    static func setDefaultPortraitSkin(_ skin: Skin) {
        setDefaultSkin(skin, isLandscape: false)
    }
    
    static func setDefaultLandscapeSkin(_ skin: Skin) {
        setDefaultSkin(skin, isLandscape: true)
    }
    
    static func setDefaultSkin(_ skin: Skin, isLandscape: Bool) {
        if var config = SkinConfig.deserialize(from: Settings.defalut.skinConfig) {
            if isLandscape {
                config.landscapeSkins[skin.gameType.rawValue] = skin.id
            } else {
                config.portraitSkins[skin.gameType.rawValue] = skin.id
            }
            if let jsonString = config.toJSONString() {
                Settings.change { _ in
                    Settings.defalut.skinConfig = jsonString
                }
            }
        }
    }
    
    var jsonString: String? {
        self.toJSONString()
    }
}
