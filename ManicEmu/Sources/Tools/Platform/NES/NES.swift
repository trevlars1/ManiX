//
//  NES.swift
//  ManicEmu
//
//  Created by Riley Testut on 2/25/18.
//  Copyright © 2018 Riley Testut. All rights reserved.
//
//  Created by Aushuang Lee on 2025/3/6.
//  Copyright © 2025 Manic EMU. All rights reserved.

import Foundation
import AVFoundation
import ManicEmuCore


@objc public enum NESGameInput: Int, Input
{
    case up = 0x10
    case down = 0x20
    case left = 0x40
    case right = 0x80
    case a = 0x01
    case b = 0x02
    case start = 0x08
    case select = 0x04
    
    public var type: InputType {
        return .game(.nes)
    }
}

public struct NES: ManicEmuCoreProtocol
{
    public static let core = NES()
    
    public var name: String { "NES" }
    public var identifier: String { "com.aoshuang.NESCore" }
    
    public var gameType: GameType { GameType.nes }
    public var gameInputType: Input.Type { NESGameInput.self }
    public var gameSaveExtension: String { "nes.sav" }
        
    public let audioFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 44100, channels: 1, interleaved: true)!
    public let videoFormat = VideoFormat(format: .bitmap(.rgb565), dimensions: CGSize(width: 256, height: 240))
    
    public var supportCheatFormats: Set<CheatFormat> {
        let gameGenie6Format = CheatFormat(name: NSLocalizedString("Game Genie (6)", comment: ""), format: "XXXXXX", type: .gameGenie6, allowedCodeCharacters: .letters)
        let gameGenie8Format = CheatFormat(name: NSLocalizedString("Game Genie (8)", comment: ""), format: "XXXXXXXX", type: .gameGenie8, allowedCodeCharacters: .letters)
        return [gameGenie6Format, gameGenie8Format]
    }
    
    public var emulatorConnector: EmulatorBase { NESEmulatorBridge.shared }
    
    private init()
    {
    }
}

