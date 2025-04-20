//
//  GameTypeExtensions.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2025/1/20.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import ManicEmuCore
import RealmSwift

extension GameType {
    static let gbc = GameType("public.aoshuang.game.gbc")
    static let gba = GameType("public.aoshuang.game.gba")
    static let nes = GameType("public.aoshuang.game.nes")
    static let snes = GameType("public.aoshuang.game.snes")
    static let ds = GameType("public.aoshuang.game.ds")
}


extension GameType {
    init?(fileExtension: String) {
        let ext = fileExtension.lowercased()
        if ["gba"].contains(ext)  {
            self = .gba
        } else if ["gbc", "gb"].contains(ext) {
            self = .gbc
        } else if ["ds", "nds"].contains(ext) {
            self = .ds
        } else if ["nes", "fc"].contains(ext)  {
            self = .nes
        } else if ["smc", "sfc", "fig", "snes"].contains(ext) {
            self = .snes
        } else if ["3ds", "cia", "app", "cci", "cxi"].contains(ext) {
            self = ._3ds
        } else {
            return nil
        }
    }
    
    init?(saveFileExtension: String) {
        switch saveFileExtension.lowercased() {
        case "dsv": self = .ds
        case "srm": self = .snes
        default: return nil
        }
    }
}


extension GameType: @retroactive PersistableEnum {
    public static var allCases: [GameType] {
        System.allCases.map { $0.gameType }
    }
}
