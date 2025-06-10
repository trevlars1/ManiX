//
//  N64.swift
//  N64
//
//  Created by Jarrod Norwell on 12/7/2024.
//

import Foundation
import MetalKit
import UIKit

public struct N64Core : @unchecked Sendable {
    public static var shared = N64Core()
    
    public static var currentGameInfo: N64GameInformation? = nil
    
    public init() {}
    
    fileprivate let n64ObjC = N64ObjC.shared()
    
    public func information(for cartridge: URL) -> N64GameInformation? {
        n64ObjC.informationForGame(at: cartridge)
    }
    
    public func allocateVulkanLibrary() {
        n64ObjC.allocateVulkanLibrary()
    }
    
    public func deallocateVulkanLibrary() {
        n64ObjC.deallocateVulkanLibrary()
    }
    
    public func allocateMetalLayer(for layer: CAMetalLayer, with size: CGSize, isSecondary: Bool = false) {
        n64ObjC.allocateMetalLayer(layer, with: size, isSecondary: isSecondary)
    }
    
    public func deallocateMetalLayers() {
        n64ObjC.deallocateMetalLayers()
    }
    
    public func insertCartridgeAndBoot(with url: URL) {
        assignGameInfo(with: url)
        n64ObjC.insertCartridgeAndBoot(url)
    }
    
    public func assignGameInfo(with url: URL?) {
        if let url {
            Self.currentGameInfo = information(for: url)
        } else {
            Self.currentGameInfo = nil
        }
    }
    
    public func importGame(at url: URL) -> ImportResultStatus {
        n64ObjC.importGame(at: url)
    }
    
    public func touchBegan(at point: CGPoint) {
        n64ObjC.touchBegan(at: point)
    }
    
    public func touchEnded() {
        n64ObjC.touchEnded()
    }
    
    public func touchMoved(at point: CGPoint) {
        n64ObjC.touchMoved(at: point)
    }
    
    public func virtualControllerButtonDown(_ button: VirtualControllerButtonType) {
        n64ObjC.virtualControllerButtonDown(button)
    }
    
    public func virtualControllerButtonUp(_ button: VirtualControllerButtonType) {
        n64ObjC.virtualControllerButtonUp(button)
    }
    
    public func thumbstickMoved(_ thumbstick: VirtualControllerAnalogType, _ x: Float, _ y: Float) {
        n64ObjC.thumbstickMoved(thumbstick, x: CGFloat(x), y: CGFloat(y))
    }
    
    public func isPaused() -> Bool {
        n64ObjC.isPaused()
    }
    
    public func pausePlay(_ pausePlay: Bool) {
        n64ObjC.pausePlay(pausePlay)
    }
    
    public func stop() {
        assignGameInfo(with: nil)
        n64ObjC.stop()
    }
    
    public func running() -> Bool {
        n64ObjC.running()
    }
    
    public func stopped() -> Bool {
        n64ObjC.stopped()
    }
    
    public func orientationChange(with orientation: UIInterfaceOrientation, using mtkView: UIView) {
        n64ObjC.orientationChanged(orientation, metalView: mtkView)
    }
    
    public func getCIAInfo(url: URL) -> (identifier: UInt64, contentPath: String?, titlePath: String?) {
        let identifier = n64ObjC.getCIAIdentifier(at: url)
        return (identifier, n64ObjC.getCIAContentPath(withIdentifier: identifier), n64ObjC.getCIATitlePath(withIdentifier: identifier))
    }
    
    public func installed() -> [URL] {
        n64ObjC.installedGamePaths() as? [URL] ?? []
    }
        
    public func system() -> [URL] {
        n64ObjC.systemGamePaths() as? [URL] ?? []
    }
    
    public func updateSettings() {
        n64ObjC.updateSettings()
    }
    
    public var stepsPerHour: UInt16 {
        get {
            n64ObjC.stepsPerHour()
        }
        
        set {
            n64ObjC.setStepsPerHour(newValue)
        }
    }
    
    public var saveStateCount: Int {
        if let currentGameInfo = Self.currentGameInfo {
            return saves(for: currentGameInfo.identifier).count
        }
        return 0
    }
    
    public func loadState(_ slot: UInt32? = nil) -> Bool {
        if let currentGameInfo = Self.currentGameInfo {
            if let slot {
                return n64ObjC.loadState(slot)
            } else {
                let states = saves(for: currentGameInfo.identifier).sorted { $0.time > $1.time }
                let newSlot = states[states.startIndex].slot
                return n64ObjC.loadState(newSlot)
            }
        } else {
            return n64ObjC.loadState()
        }
    }
    
    public func saveState() -> (isSuccess: Bool, path: String) {
        if let currentGameInfo = Self.currentGameInfo {
            let states = saves(for: currentGameInfo.identifier)
            if states.count == 0 {
                return (n64ObjC.saveState(), n64ObjC.saveStatePath(currentGameInfo.identifier, slot: 1))
            } else {
                let maxSlot = states[states.endIndex-1].slot
                if maxSlot >= 50 {
                    let oldSlot = states.sorted(by: { $0.time < $1.time })[states.startIndex].slot
                    return (n64ObjC.saveState(oldSlot), n64ObjC.saveStatePath(currentGameInfo.identifier, slot: oldSlot))
                } else {
                    return (n64ObjC.saveState(maxSlot+1), n64ObjC.saveStatePath(currentGameInfo.identifier, slot: maxSlot+1))
                }
            }
        } else {
            
            if let currentGameInfo = Self.currentGameInfo {
                return (n64ObjC.saveState(), n64ObjC.saveStatePath(currentGameInfo.identifier, slot: 1))
            } else {
                return (false, "")
            }
        }
    }
    
    public func saves(for identifier: UInt64) -> [SaveStateInfo] { n64ObjC.saveStates(identifier) }
    
    public func saveStatePath(for identifier: UInt64, slot: UInt32) -> String {
        n64ObjC.saveStatePath(identifier, slot: slot)
    }
    
    public func saveStatePathForRunningGame(slot: UInt32) -> String? {
        if let currentGameInfo = Self.currentGameInfo {
            return n64ObjC.saveStatePath(currentGameInfo.identifier, slot: slot)
        } else {
            return nil
        }
    }
    
    public static func setWorkSpacePath(_ path: String) {
        N64ObjC.setWorkSpacePath(path)
    }
}
