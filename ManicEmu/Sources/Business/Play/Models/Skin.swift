//
//  Skin.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2025/1/19.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import RealmSwift
import ManicEmuCore
import IceCream

extension Skin: CKRecordConvertible & CKRecordRecoverable { }

enum SkinType: Int, PersistableEnum {
    case `default`, manic, delta
    
    init?(fileExtension: String) {
        if fileExtension == "manicskin" {
            self = .manic
        } else if fileExtension == "deltaskin" {
            self = .delta
        } else {
            return nil
        }
    }
    
}


class Skin: Object, ObjectUpdatable {
    
    @Persisted(primaryKey: true) var id: String
    
    @Persisted var identifier: String
    
    @Persisted var name: String
    
    @Persisted var fileName: String
    
    @Persisted var gameType: GameType
    
    @Persisted var skinType: SkinType
    
    @Persisted var skinData: CreamAsset?
    
    @Persisted var isDeleted: Bool = false
    
    
    var isFileExtsts: Bool {
        return FileManager.default.fileExists(atPath: fileURL.path)
    }
    
    var fileURL: URL {
        if skinType == .default {
            let core = System(gameType: gameType).manicEmuCore
            return core.resourceBundle.url(forResource: core.name, withExtension: "manicskin")!
        } else if let filePath = skinData?.filePath {
            return filePath
        }
        
        return URL(fileURLWithPath: Constants.Path.Document.appendingPathComponent(fileName))
    }
}
