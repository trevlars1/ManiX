//
//  UIFontExtensions.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2023/5/31.
//  Copyright © 2023 Manic EMU. All rights reserved.
//

import Foundation

extension UIFont {
    func withTraits(traits:UIFontDescriptor.SymbolicTraits...) -> UIFont {
        if let descriptor = self.fontDescriptor.withSymbolicTraits(UIFontDescriptor.SymbolicTraits(traits)) {
            return UIFont(descriptor: descriptor, size: 0)
        }
        return self
    }
}
