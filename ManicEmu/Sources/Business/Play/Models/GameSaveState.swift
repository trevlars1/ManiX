//
//  GameSaveState.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2025/1/19.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import RealmSwift
import IceCream
import Device

extension GameSaveState: CKRecordConvertible & CKRecordRecoverable { }

class GameSaveState: Object {
    
    @Persisted(primaryKey: true) var name: String
    
    @Persisted var type: GameSaveStateType
    
    @Persisted var date: Date
    
    @Persisted var stateCover: CreamAsset?
    
    @Persisted var stateData: CreamAsset?
    
    @Persisted var device: String = Device.version().rawValue
    
    @Persisted var osVersion: String = UIDevice.current.systemVersion
    
    @Persisted var isDeleted: Bool = false
    
    
    var isCompatible: Bool {
        if device == Device.version().rawValue && osVersion == UIDevice.current.systemVersion {
            return true
        }
        return false
    }
    
    var gameSaveStateDeviceInfo: String {
        device + " " + osVersion
    }
    
    var currentDeviceInfo: String {
        Device.version().rawValue + " " + UIDevice.current.systemVersion
    }
}

enum GameSaveStateType: Int, PersistableEnum {
    case autoSaveState, manualSaveState
}
