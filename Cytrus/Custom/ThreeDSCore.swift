//
//  Cytrus.swift
//  Cytrus
//
//  Created by Jarrod Norwell on 12/7/2024.
//

import Foundation
import MetalKit
import UIKit

public struct ThreeDSCore : @unchecked Sendable {
    public static var shared = ThreeDSCore()
    
    public static var currentGameInfo: ThreeDSGameInformation? = nil
    
    public init() {}
    
    fileprivate let threeDSObjC = ThreeDSObjC.shared()
    
    public func information(for cartridge: URL) -> ThreeDSGameInformation? {
        threeDSObjC.informationForGame(at: cartridge)
    }
    
    public func allocateVulkanLibrary() {
        threeDSObjC.allocateVulkanLibrary()
    }
    
    public func deallocateVulkanLibrary() {
        threeDSObjC.deallocateVulkanLibrary()
    }
    
    public func allocateMetalLayer(for layer: CAMetalLayer, with size: CGSize, isSecondary: Bool = false) {
        threeDSObjC.allocateMetalLayer(layer, with: size, isSecondary: isSecondary)
    }
    
    public func deallocateMetalLayers() {
        threeDSObjC.deallocateMetalLayers()
    }
    
    public func insertCartridgeAndBoot(with url: URL) {
        assignGameInfo(with: url)
        threeDSObjC.insertCartridgeAndBoot(url)
    }
    
    public func assignGameInfo(with url: URL?) {
        if let url {
            Self.currentGameInfo = information(for: url)
        } else {
            Self.currentGameInfo = nil
        }
    }
    
    public func importGame(at url: URL) -> ImportResultStatus {
        threeDSObjC.importGame(at: url)
    }
    
    public func touchBegan(at point: CGPoint) {
        threeDSObjC.touchBegan(at: point)
    }
    
    public func touchEnded() {
        threeDSObjC.touchEnded()
    }
    
    public func touchMoved(at point: CGPoint) {
        threeDSObjC.touchMoved(at: point)
    }
    
    public func virtualControllerButtonDown(_ button: VirtualControllerButtonType) {
        threeDSObjC.virtualControllerButtonDown(button)
    }
    
    public func virtualControllerButtonUp(_ button: VirtualControllerButtonType) {
        threeDSObjC.virtualControllerButtonUp(button)
    }
    
    public func thumbstickMoved(_ thumbstick: VirtualControllerAnalogType, _ x: Float, _ y: Float) {
        threeDSObjC.thumbstickMoved(thumbstick, x: CGFloat(x), y: CGFloat(y))
    }
    
    public func isPaused() -> Bool {
        threeDSObjC.isPaused()
    }
    
    public func pausePlay(_ pausePlay: Bool) {
        threeDSObjC.pausePlay(pausePlay)
    }
    
    public func stop() {
        assignGameInfo(with: nil)
        threeDSObjC.stop()
    }
    
    public func running() -> Bool {
        threeDSObjC.running()
    }
    
    public func stopped() -> Bool {
        threeDSObjC.stopped()
    }
    
    public func orientationChange(with orientation: UIInterfaceOrientation, using mtkView: UIView) {
        threeDSObjC.orientationChanged(orientation, metalView: mtkView)
    }
    
    public func getCIAInfo(url: URL) -> (identifier: UInt64, contentPath: String?, titlePath: String?) {
        let identifier = threeDSObjC.getCIAIdentifier(at: url)
        return (identifier, threeDSObjC.getCIAContentPath(withIdentifier: identifier), threeDSObjC.getCIATitlePath(withIdentifier: identifier))
    }
    
    public func installed() -> [URL] {
        threeDSObjC.installedGamePaths() as? [URL] ?? []
    }
        
    public func system() -> [URL] {
        threeDSObjC.systemGamePaths() as? [URL] ?? []
    }
    
    public func updateSettings() {
        threeDSObjC.updateSettings()
    }
    
    public var stepsPerHour: UInt16 {
        get {
            threeDSObjC.stepsPerHour()
        }
        
        set {
            threeDSObjC.setStepsPerHour(newValue)
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
                return threeDSObjC.loadState(slot)
            } else {
                let states = saves(for: currentGameInfo.identifier).sorted { $0.time > $1.time }
                let newSlot = states[states.startIndex].slot
                return threeDSObjC.loadState(newSlot)
            }
        } else {
            return threeDSObjC.loadState()
        }
    }
    
    public func saveState() -> (isSuccess: Bool, path: String) {
        if let currentGameInfo = Self.currentGameInfo {
            let states = saves(for: currentGameInfo.identifier)
            if states.count == 0 {
                return (threeDSObjC.saveState(), threeDSObjC.saveStatePath(currentGameInfo.identifier, slot: 1))
            } else {
                let maxSlot = states[states.endIndex-1].slot
                if maxSlot >= 50 {
                    let oldSlot = states.sorted(by: { $0.time < $1.time })[states.startIndex].slot
                    return (threeDSObjC.saveState(oldSlot), threeDSObjC.saveStatePath(currentGameInfo.identifier, slot: oldSlot))
                } else {
                    return (threeDSObjC.saveState(maxSlot+1), threeDSObjC.saveStatePath(currentGameInfo.identifier, slot: maxSlot+1))
                }
            }
        } else {
            
            if let currentGameInfo = Self.currentGameInfo {
                return (threeDSObjC.saveState(), threeDSObjC.saveStatePath(currentGameInfo.identifier, slot: 1))
            } else {
                return (false, "")
            }
        }
    }
    
    public func saves(for identifier: UInt64) -> [SaveStateInfo] { threeDSObjC.saveStates(identifier) }
    
    public func saveStatePath(for identifier: UInt64, slot: UInt32) -> String {
        threeDSObjC.saveStatePath(identifier, slot: slot)
    }
    
    public func saveStatePathForRunningGame(slot: UInt32) -> String? {
        if let currentGameInfo = Self.currentGameInfo {
            return threeDSObjC.saveStatePath(currentGameInfo.identifier, slot: slot)
        } else {
            return nil
        }
    }
    
    public static func setWorkSpacePath(_ path: String) {
        ThreeDSObjC.setWorkSpacePath(path)
    }
}
