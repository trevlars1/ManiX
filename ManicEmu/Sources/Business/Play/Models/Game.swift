//
//  Game.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2025/1/19.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import RealmSwift
import ManicEmuCore
import IceCream
#if !targetEnvironment(simulator)
import Cytrus
#endif

enum ThreeDSMode: Int, PersistableEnum {
    case compatibility, performance, quality
}

extension Game: CKRecordConvertible & CKRecordRecoverable {}

class Game: Object, ObjectUpdatable {
    
    @Persisted(primaryKey: true) var id: String
    
    @Persisted var name: String
    
    @Persisted var aliasName: String? = nil
    
    @Persisted var fileExtension: String
    
    @Persisted var gameType: GameType
    
    @Persisted var gameCover: CreamAsset?
    
    @Persisted var gameCheats: List<GameCheat>
    
    @Persisted var portraitSkin: Skin?
    
    @Persisted var landscapeSkin: Skin?
    
    @Persisted var importDate: Date
    
    @Persisted var latestPlayDate: Date?
    
    @Persisted var totalPlayDuration: Double = 0
    
    @Persisted var latestPlayDuration: Double = 0
    
    @Persisted var gameSaveStates: List<GameSaveState>
    
    @Persisted var volume: Bool = true
    
    @Persisted var speed: GameSetting.FastForwardSpeed = .one
    
    @Persisted var haptic: GameSetting.HapticType = .soft
    
    @Persisted var controllerType: GameSetting.ControllerType = .dPad
    
    @Persisted var orientation: GameSetting.OrientationType = .auto
    
    @Persisted var filterName: String? = nil
    
    @Persisted var extras: Data?
    
    @Persisted var isDeleted: Bool = false

    
    var isRomExtsts: Bool {
        FileManager.default.fileExists(atPath: romUrl.path)
    }
    
    var isSaveExtsts: Bool {
        FileManager.default.fileExists(atPath: gameSaveUrl.path)
    }
    
    
    var fileName: String {
        "\(name).\(fileExtension)"
    }
    
    
    var romUrl: URL {
        var localUrl = URL(fileURLWithPath: Constants.Path.Data.appendingPathComponent(fileName))
        if gameType == ._3ds,
           fileExtension.lowercased() == "app",
            let extras,
            let extraInfos = try? extras.jsonObject() as? [String: Any],
            let appRomPath = extraInfos["appRomPath"] as? String {
            localUrl = URL(fileURLWithPath: Constants.Path.Data.appendingPathComponent(appRomPath))
        }
        if !FileManager.default.fileExists(atPath: localUrl.path), let iCloudUrl = SyncManager.iCloudUrlFor(localUrl: localUrl) {
            return iCloudUrl
        }
        return localUrl
    }
    
    var gameSaveUrl: URL {
        let system = System(gameType: gameType)
        let localUrl = URL(fileURLWithPath: Constants.Path.Data.appendingPathComponent("\(name).\(system.manicEmuCore.gameSaveExtension)"))
        if !FileManager.default.fileExists(atPath: localUrl.path), let iCloudUrl = SyncManager.iCloudUrlFor(localUrl: localUrl) {
            return iCloudUrl
        }
        return localUrl
    }
    
    var identifierFor3DS: UInt64 {
        if gameType == ._3ds,
            let extras,
           let extraInfos = try? extras.jsonObject() as? [String: Any],
            let identifier = extraInfos["identifier"] as? UInt64 {
            return identifier
        } else {
#if !targetEnvironment(simulator)
            if let info = ThreeDSCore.shared.information(for: romUrl) {
                return info.identifier
            }
#endif
            return 0
        }
    }
}
