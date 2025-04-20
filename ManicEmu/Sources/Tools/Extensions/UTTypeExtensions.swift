//
//  UTTypeExtensions.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2025/1/19.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import UniformTypeIdentifiers

extension UTType {
    static var gamesaveTypes: [UTType] { allSystemTypes.gamesaveTypes }
    
    static var gameTypes: [UTType] { allSystemTypes.gameTypes }
    
    static var skinTypes: [UTType] { allSystemTypes.skinTypes }
    
    static var allInfoPlistTypes: [UTType] {
        let (gameTypes, gamesaveTypes, skinTypes, zipTypes) = infoPlistTypes
        return gameTypes + gamesaveTypes + skinTypes + zipTypes
    }
    
    static var allTypes: [UTType] {
        let (gameTypes, gamesaveTypes, skinTypes, zipTypes) = allSystemTypes
        return gameTypes + gamesaveTypes + skinTypes + zipTypes
    }
    
    
    private static var allSystemTypes: (gameTypes: [UTType], gamesaveTypes: [UTType], skinTypes: [UTType], zipTypes: [UTType]) {
        let (gameTypes, gamesaveTypes, skinTypes, zipTypes) = infoPlistTypes
        return (getAllTypes(gameTypes), getAllTypes(gamesaveTypes), getAllTypes(skinTypes), getAllTypes(zipTypes))
    }
    
    
    private static var infoPlistTypes: (gameTypes: [UTType], gamesaveTypes: [UTType], skinTypes: [UTType], zipTypes: [UTType]) {
        var gameTypes: [UTType] = []
        var gamesaveTypes: [UTType] = []
        var skinTypes: [UTType] = []
        var zipTypes: [UTType] = []
        
        if let declarations: [[String: Any]] = Constants.Config.value(forKey: "UTExportedTypeDeclarations") {
            for declaration in declarations {
                if let identifier = declaration["UTTypeIdentifier"] as? String {
                    if identifier.hasPrefix("public.aoshuang.game."), let uttype = UTType(identifier) {
                        gameTypes.append(uttype)
                    } else if identifier.hasPrefix("public.aoshuang.gamesave"), let uttype = UTType(identifier) {
                        gamesaveTypes.append(uttype)
                    } else if identifier.hasPrefix("public.aoshuang.skin"), let uttype = UTType(identifier) {
                        skinTypes.append(uttype)
                    } else if identifier.hasPrefix("public.aoshuang.zip"), let uttype = UTType(identifier) {
                        zipTypes.append(uttype)
                    }
                }
            }
        }
        return (gameTypes, gamesaveTypes, skinTypes, zipTypes)
    }
    
    
    private static func getAllTypes(_ selfRegisterTypes: [UTType]) -> [UTType] {
        
        var allTypes = Set<UTType>()
        for type in selfRegisterTypes {
            if let extensions = type.tags[.filenameExtension] {
                for extens in extensions {
                    UTType.types(tag: extens, tagClass: .filenameExtension, conformingTo: nil).forEach { allTypes.insert($0) }
                }
            }
        }
        return Array(allTypes)
    }
}
