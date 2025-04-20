//
//  GameCheat.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2025/1/20.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import RealmSwift
import IceCream

extension GameCheat: CKRecordConvertible & CKRecordRecoverable {}

class GameCheat: Object {
    
    @Persisted(primaryKey: true) var id: Int = PersistedKit.incrementID
    
    @Persisted var name: String
    
    @Persisted var code: String
    
    @Persisted var type: String
    
    @Persisted var activate: Bool = false
    
    @Persisted var isDeleted: Bool = false
}
