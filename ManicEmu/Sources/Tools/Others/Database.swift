//
//  Database.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2025/2/20.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import RealmSwift
import ManicEmuCore

struct Database {
    static func setup(completion: (()->Void)? = nil) {
        do {
            let realm = Database.realm
            
            let oldSettings = realm.object(ofType: Settings.self, forPrimaryKey: Settings.defaultName)
            if oldSettings == nil {
                let settings = Settings()
                
                let genDefaultSkins = generateDefaultSkins()
                settings.skinConfig = genDefaultSkins.defaultSkinMap
                
                
                settings.gameFunctionList =  GameSetting.ItemType.allCases.reduce(List<Int>()) { partialResult, type in
                    partialResult.append(type.rawValue)
                    return partialResult
                }
                
                try realm.write {
                    realm.add(genDefaultSkins.defaultSkins)
                    realm.add(settings)
                }
            } else if let oldSettings = oldSettings {
                
                let defaultSkins = realm.objects(Skin.self).where { $0.skinType == .default }
                let defaultSkinsCount = defaultSkins.count
                if defaultSkinsCount != System.allCases.count {
                    
                    try? realm.write {
                        realm.delete(defaultSkins)
                    }
                    
                    let genDefaultSkins = generateDefaultSkins()
                    try? realm.write {
                        realm.add(genDefaultSkins.defaultSkins)
                        oldSettings.skinConfig = genDefaultSkins.defaultSkinMap
                    }
                }
            }
        } catch {
            
        }
        completion?()
    }
    
    static var realm: Realm {
        do {
            return try Realm(configuration: defaultConfig)
        } catch {
            
        }
        return try! Realm()
    }
    
    private static var defaultConfig: Realm.Configuration {
        var config = Realm.Configuration.defaultConfiguration
        
        if !FileManager.default.fileExists(atPath: Constants.Path.Realm) {
            try? FileManager.default.createDirectory(atPath: Constants.Path.Realm, withIntermediateDirectories: true)
        }
        config.fileURL = URL(fileURLWithPath: Constants.Path.RealmFilePath)
        
        config.schemaVersion = UInt64(Constants.Config.AppVersion.replacingOccurrences(ofPattern: "\\.", withTemplate: ""))!
        return config
    }
    
    private static func generateDefaultSkins() -> (defaultSkins: [Skin], defaultSkinMap: String) {
        
        var defaultSkins = [Skin]()
        var defaultSkinMap = [String: String]()
        System.allCores.forEach { core in
            let gameType = core.gameType
            if let controllerSkin = ControllerSkin.standardControllerSkin(for: gameType),
                let hash = FileHashUtil.truncatedHash(url: controllerSkin.fileURL) {
                if let skin = realm.object(ofType: Skin.self, forPrimaryKey: hash) {
                    
                    
                    defaultSkins.append(skin)
                    defaultSkinMap[gameType.rawValue] = skin.id
                } else {
                    let skin = Skin()
                    skin.id = hash
                    skin.identifier = controllerSkin.identifier
                    skin.name = controllerSkin.name
                    skin.fileName = controllerSkin.fileURL.lastPathComponent
                    skin.gameType = controllerSkin.gameType
                    skin.skinType = .default
                    defaultSkins.append(skin)
                    defaultSkinMap[gameType.rawValue] = skin.id
                }
            }
        }
        if let jsonString = SkinConfig(portraitSkins: defaultSkinMap, landscapeSkins: defaultSkinMap).jsonString {
            return (defaultSkins, jsonString)
        }
        return (defaultSkins, "")
    }
}
