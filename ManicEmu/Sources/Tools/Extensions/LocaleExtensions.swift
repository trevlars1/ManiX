//
//  LocaleExtensions.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2025/2/28.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

extension Locale {
    static var isRTLLanguage: Bool {
        guard let languageCode = Locale.current.languageCode else { return false }
        return Locale.characterDirection(forLanguage: languageCode) == .rightToLeft
    }
    
    
    static var prefersCN: Bool {
        
        let prefersChinese: Bool = {
            Locale.preferredLanguages.contains { lang in
                lang.lowercased().hasPrefix("zh") 
            }
        }()
        
        
        let regionCode = Locale.current.regionCode?.uppercased() ?? ""
        
        
        if prefersChinese && regionCode == "CN" {
            return true          
        } else {
            return false    
        }
    }
    
    static func getSystemLanguageDisplayName(preferredLanguage: String?) -> String {
        guard let preferredLanguage = preferredLanguage ?? Locale.preferredLanguages.first else {
            return "Unknown"
        }
        
        
        let components = preferredLanguage.components(separatedBy: "-")
        let baseComponents = Array(components.prefix(2)) 
        let baseLanguageCode = baseComponents.joined(separator: "-")
        
        
        let localeIdentifier = baseComponents.joined(separator: "_")
        let locale = Locale(identifier: localeIdentifier)
        
        
        guard let displayName = locale.localizedString(forLanguageCode: baseLanguageCode) else {
            return baseLanguageCode
        }
        return displayName
    }
}
