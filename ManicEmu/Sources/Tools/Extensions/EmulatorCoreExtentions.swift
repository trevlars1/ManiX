//
//  EmulatorCoreExtentions.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2025/3/6.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
import ManicEmuCore

extension EmulatorCore {
    func setRate(speed: GameSetting.FastForwardSpeed) {
        switch speed {
        case .one:
            self.rate = 1
        default:
            let count = Double(GameSetting.FastForwardSpeed.allCases.count)
            self.rate = 1 + (maximumFastForwardSpeed - 1)/(count-1)*Double(speed.rawValue-1)
        }
    }
    
    var maximumFastForwardSpeed: Double {
        switch self.manicCore
        {
        case NES.core, SNES.core, GBC.core: return 5
        case GBA.core: return 5
        case MelonDS.core where UIDevice.current.hasA15ProcessorOrBetter: return 5
        case MelonDS.core where UIDevice.current.hasA11ProcessorOrBetter: return 3
        default: return 1
        }
    }
    
}
