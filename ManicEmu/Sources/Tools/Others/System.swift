//
//  System.swift
//  Delta
//
//  Created by Aushuang Lee on 2025/3/6.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import ManicEmuCore

enum System: CaseIterable
{
    case _3ds
    case ds
    case gba
    case gbc
    case nes
    case snes

    static var registeredSystems: [System] {
        let systems = System.allCases.filter { ManicEmu.registeredCores.keys.contains($0.gameType) }
        return systems
    }
    
    static var allCores: [ManicEmuCoreProtocol] {
        return [NES.core, SNES.core, ThreeDS.core, GBC.core, GBA.core, MelonDS.core]
    }
}

extension System
{
    var localizedName: String {
        switch self
        {
        case .nes: return NSLocalizedString("Nintendo", comment: "")
        case .snes: return NSLocalizedString("Super Nintendo", comment: "")
        case ._3ds: return NSLocalizedString("Nintendo 3DS", comment: "")
        case .gbc: return NSLocalizedString("Game Boy Color", comment: "")
        case .gba: return NSLocalizedString("Game Boy Advance", comment: "")
        case .ds: return NSLocalizedString("Nintendo DS", comment: "")
        }
    }
    
    var localizedShortName: String {
        switch self
        {
        case .nes: return NSLocalizedString("NES", comment: "")
        case .snes: return NSLocalizedString("SNES", comment: "")
        case ._3ds: return NSLocalizedString("3DS", comment: "")
        case .gbc: return NSLocalizedString("GBC", comment: "")
        case .gba: return NSLocalizedString("GBA", comment: "")
        case .ds: return NSLocalizedString("NDS", comment: "")
        }
    }
    
    var year: Int {
        switch self
        {
        case .nes: return 1985
        case .snes: return 1990
        case ._3ds: return 2011
        case .gbc: return 1998
        case .gba: return 2001
        case .ds: return 2004
        }
    }
}

extension System
{
    var manicEmuCore: ManicEmuCoreProtocol {
        switch self
        {
        case .nes: return NES.core
        case .snes: return SNES.core
        case ._3ds: return ThreeDS.core
        case .gbc: return GBC.core
        case .gba: return GBA.core
        case .ds: return MelonDS.core
        }
    }
    
    var gameType: ManicEmuCore.GameType {
        switch self
        {
        case .nes: return .nes
        case .snes: return .snes
        case ._3ds: return ._3ds
        case .gbc: return .gbc
        case .gba: return .gba
        case .ds: return .ds
        }
    }
    
    init(gameType: ManicEmuCore.GameType)
    {
        switch gameType
        {
        case GameType.nes: self = .nes
        case GameType.snes: self = .snes
        case GameType._3ds: self = ._3ds
        case GameType.gbc: self = .gbc
        case GameType.gba: self = .gba
        case GameType.ds: self = .ds
        default: self = .gba
        }
    }
}
