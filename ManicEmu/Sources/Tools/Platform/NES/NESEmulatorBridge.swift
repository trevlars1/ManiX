//
//  NESEmulatorBridge.swift
//  ManicEmu
//
//  Created by Riley Testut on 6/1/18.
//  Copyright © 2018 Riley Testut. All rights reserved.
//
//  Created by Aushuang Lee on 2025/3/6.
//  Copyright © 2025 Manic EMU. All rights reserved.

import Foundation
import ManicEmuCore

extension NESEmulatorBridge
{
    enum MessageType: String
    {
        case ready
        case audio
        case video
        case save
    }
}

extension RunLoop
{
    func run(until condition: () -> Bool)
    {
        while !condition()
        {
            self.run(mode: RunLoop.Mode.default, before: .distantFuture)
        }
    }
}

public class NESEmulatorBridge : NSObject, EmulatorBase {
    public static let shared = NESEmulatorBridge()
    
    public private(set) var gameURL: URL?
    
    public private(set) var frameDuration: TimeInterval = (1.0 / 60.0)
    
    public var audioRenderer: AudioRenderProtocol?
    public var videoRenderer: VideoRenderProtocol?
    public var saveUpdateHandler: (() -> Void)?
    
    public static var applicationWindow: UIWindow?
    
    private var isReady = false
    
    private override init()
    {
        super.init()
        let databaseURL = NES.core.resourceBundle.url(forResource: "NstDatabase", withExtension: "xml")!
        databaseURL.withUnsafeFileSystemRepresentation { NESInitialize($0!) }
        
        NESSetAudioCallback { (buffer, size) in
            NESEmulatorBridge.shared.audioRenderer?.audioBuffer.write(buffer, size: Int(size))
        }
        
        NESSetVideoCallback { (buffer, size) in
            memcpy(UnsafeMutableRawPointer(NESEmulatorBridge.shared.videoRenderer?.videoBuffer), buffer, Int(size))
        }
        
        NESSetSaveCallback {
            NESEmulatorBridge.shared.saveUpdateHandler?()
        }
        
        self.isReady = true
    }
}

public extension NESEmulatorBridge
{
    func start(withGameURL gameURL: URL)
    {
        if !self.isReady
        {
            RunLoop.current.run(until: { self.isReady })
        }
        
        self.gameURL = gameURL

        gameURL.withUnsafeFileSystemRepresentation { _ = NESStartEmulation($0!) }
        
        self.frameDuration = NESFrameDuration()
    }
    
    func stop()
    {
        self.gameURL = nil

        NESStopEmulation()

    }
    
    func pause()
    {
    }
    
    func resume()
    {
    }
    
    func runFrame(processVideo: Bool)
    {
        NESRunFrame()
        
        
        if processVideo
        {
            self.videoRenderer?.processFrame()
        }
    }
    
    func activateInput(_ input: Int, value: Double, playerIndex: Int)
    {
        NESActivateInput(Int32(input), Int32(playerIndex))
        
    }
    
    func deactivateInput(_ input: Int, playerIndex: Int)
    {
        NESDeactivateInput(Int32(input), Int32(playerIndex))
    }
    
    func resetInputs()
    {
        NESResetInputs()
    }
    
    func saveSaveState(to url: URL)
    {
        url.withUnsafeFileSystemRepresentation { NESSaveSaveState($0!) }
        
    }
    
    func loadSaveState(from url: URL)
    {
        url.withUnsafeFileSystemRepresentation { NESLoadSaveState($0!) }

    }
    
    func saveGameSave(to url: URL)
    {
        url.withUnsafeFileSystemRepresentation { NESSaveGameSave($0!) }

    }
    
    func loadGameSave(from url: URL)
    {
        url.withUnsafeFileSystemRepresentation { NESLoadGameSave($0!) }

    }
    
    func addCheatCode(_ cheatCode: String, type: String) -> Bool
    {
        let cheatType = CheatType(type)
        guard cheatType == .gameGenie6 || cheatType == .gameGenie8 else { return false }

        let codes = cheatCode.split(separator: "\n")
        for code in codes
        {
            if !code.withCString({ NESAddCheatCode($0) })
            {
                return false
            }
        }
        
        return true
    }
    
    func resetCheats()
    {
        NESResetCheats()
    }
    
    func updateCheats()
    {
    }
}
