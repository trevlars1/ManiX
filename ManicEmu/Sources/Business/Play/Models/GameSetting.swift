//
//  GameSetting.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2025/3/5.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import RealmSwift

struct GameSetting: SettingCellItem {
    static let disableFor3DS: [GameSetting.ItemType] = [.fastForward, .cheatCode, .filter, .reload]
    
    enum ControllerType: Int, PersistableEnum {
        case dPad, thumbStick
        
        var image: UIImage {
            switch self {
            case .dPad:
                UIImage(symbol: .dpad)
            case .thumbStick:
                R.image.customArcadeStick()!.applySymbolConfig()
            }
        }
        
        var title: String {
            switch self {
            case .dPad:
                R.string.localizable.gameSettingControllerTypeDPad()
            case .thumbStick:
                R.string.localizable.gameSettingControllerTypeStick()
            }
        }
        
        var next: ControllerType {
            return self == .dPad ? .thumbStick : .dPad
        }
    }
    
    enum HapticType: Int, PersistableEnum {
        case off, soft, light, medium, heavy, rigid
        
        var image: UIImage {
            switch self {
            case .off:
                UIImage(symbol: .iphoneSlash)
            default:
                UIImage(symbol: .iphoneRadiowavesLeftAndRight)
            }
        }
        
        var title: String {
            switch self {
            case .off:
                R.string.localizable.gameSettingHapticOff()
            case .soft:
                R.string.localizable.gameSettingHapticSoft()
            case .light:
                R.string.localizable.gameSettingHapticLight()
            case .medium:
                R.string.localizable.gameSettingHapticMedium()
            case .heavy:
                R.string.localizable.gameSettingHapticHeavy()
            case .rigid:
                R.string.localizable.gameSettingHapticRigid()
            }
        }
        
        var next: HapticType {
            if let type = HapticType(rawValue: self.rawValue + 1) {
                return type
            } else {
                return .off
            }
        }
    }
    
    enum OrientationType: Int, PersistableEnum {
        case auto, portrait, landscape
        
        var title: String {
            switch self {
            case .auto:
                R.string.localizable.gameSettingOrientationAuto()
            case .portrait:
                R.string.localizable.gameSettingOrientationPortrait()
            case .landscape:
                R.string.localizable.gameSettingOrientationLandscape()
            }
        }
        
        var next: OrientationType {
            if let type = OrientationType(rawValue: self.rawValue + 1) {
                return type
            } else {
                return .auto
            }
        }
    }
    
    enum FastForwardSpeed: Int, CaseIterable, PersistableEnum  {
        case one = 1, two, three, four, five
        
        var title: String {
            R.string.localizable.gameSettingFastForward(self == .one ? "" : " x\(self.rawValue)")
        }
        
        var next: FastForwardSpeed {
            if let speed = FastForwardSpeed(rawValue: self.rawValue + 1) {
                return speed
            } else {
                return .one
            }
        }
    }
    
    enum ItemType: Int, CaseIterable {
        case saveState, quickLoadState, volume, fastForward, stateList, cheatCode, skins, filter, screenShot, haptic, airplay, controllerSetting, orientation, functionSort, reload, quit
    }
    
    var type: ItemType
    var loadState: GameSaveState? = nil
    var volumeOn: Bool = true
    var fastForwardSpeed: FastForwardSpeed = .one
    var hapticType: HapticType = .soft
    var controllerType: ControllerType = .dPad
    var orientation: OrientationType = .auto
    
    var image: UIImage {
        switch type {
        case .saveState:
            R.image.customArrowDownDocument()!.applySymbolConfig()
        case .quickLoadState:
            R.image.customTextDocument()!.applySymbolConfig()
        case .stateList:
            UIImage(symbol: .listTriangle)
        case .volume:
            if volumeOn {
                UIImage(symbol: .speakerWave2)
            } else {
                UIImage(symbol: .speakerSlash)
            }
        case .fastForward:
            UIImage(symbol: .forward)
        case .cheatCode:
            R.image.customAppleTerminal()!.applySymbolConfig()
        case .skins:
            UIImage(symbol: .tshirt)
        case .filter:
            UIImage(symbol: .cameraFilters)
        case .screenShot:
            UIImage(symbol: .cameraViewfinder)
        case .haptic:
            hapticType.image
//        case .controllerType:
//            controllerType.image
        case .airplay:
            UIImage(symbol: .airplayvideo)
        case .controllerSetting:
            R.image.customArcadeStickConsole()!.applySymbolConfig()
        case .orientation:
            R.image.customRectangleLandscapeRotate()!.applySymbolConfig()
        case .functionSort:
            UIImage(symbol: .sliderHorizontalBelowRectangle)
        case .reload:
            R.image.customArrowTriangleheadClockwise()!.applySymbolConfig()
        case .quit:
            UIImage(symbol: .rectanglePortraitAndArrowRight)
        }
    }
    
    var title: String {
        switch type {
        case .saveState:
            R.string.localizable.gameSettingSaveState()
        case .quickLoadState:
            R.string.localizable.gameSettingQuickLoadState()
        case .volume:
            R.string.localizable.gameSettingVolume()
        case .fastForward:
            fastForwardSpeed.title
        case .stateList:
            R.string.localizable.gameSettingStateList()
        case .cheatCode:
            R.string.localizable.gamesCheatCode()
        case .skins:
            R.string.localizable.gameSettingSkins()
        case .filter:
            R.string.localizable.gameSettingFilter()
        case .screenShot:
            R.string.localizable.gameSettingScreenShot()
        case .haptic:
            hapticType.title
//        case .controllerType:
//            controllerType.title
        case .airplay:
            R.string.localizable.gameSettingAirplay()
        case .controllerSetting:
            R.string.localizable.gameSettingControllerSetting()
        case .orientation:
            orientation.title
        case .functionSort:
            R.string.localizable.gameSettingFunctionSort()
        case .reload:
            R.string.localizable.gameSettingReload()
        case .quit:
            R.string.localizable.gameSettingQuit()
        }
    }
}
