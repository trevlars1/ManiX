//
//  MelonDS.swift
//  ManicEmu
//
//  Created by Riley Testut on 10/31/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//
//  Created by Aushuang Lee on 2025/3/6.
//  Copyright © 2025 Manic EMU. All rights reserved.

import Foundation
import AVFoundation
import ManicEmuCore

@objc public enum MelonDSGameInput: Int, Input
{
    case a = 1
    case b = 2
    case select = 4
    case start = 8
    case right = 16
    case left = 32
    case up = 64
    case down = 128
    case r = 256
    case l = 512
    case x = 1024
    case y = 2048
    
    case touchScreenX = 4096
    case touchScreenY = 8192
    
    case lid = 16_384
    
    public var type: InputType {
        return .game(.ds)
    }
    
    public var isContinuous: Bool {
        switch self
        {
        case .touchScreenX, .touchScreenY: return true
        default: return false
        }
    }
}

public struct MelonDS: ManicEmuCoreProtocol
{
    public static let core = MelonDS()
    
    public var name: String { "DS" }
    public var identifier: String { "com.aoshuang.DSCore" }
    public var version: String? { "0.9.5" }
    
    public var gameType: GameType { GameType.ds }
    public var gameInputType: Input.Type { MelonDSGameInput.self }
    public var gameSaveExtension: String { "dsv" }
    
    public let audioFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 32768, channels: 2, interleaved: true)!
    public let videoFormat = VideoFormat(format: .bitmap(.bgra8), dimensions: CGSize(width: 256, height: 384))
    
    public var supportCheatFormats: Set<CheatFormat> {
        let actionReplayFormat = CheatFormat(name: NSLocalizedString("Action Replay", comment: ""), format: "XXXXXXXX YYYYYYYY", type: .actionReplay)
        return [actionReplayFormat]
    }
    
    public var emulatorConnector: EmulatorBase { MelonDSEmulatorBridge.shared }
    
    private init()
    {
    }
}
