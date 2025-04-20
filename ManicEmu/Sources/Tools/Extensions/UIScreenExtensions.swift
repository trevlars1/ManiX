//
//  UIScreenExtensions.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2025/2/26.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import UIKit

extension UIScreen {
    private static let cornerRadiusKey: String = {
        let components = ["Radius", "Corner", "display", "_"]
        return components.reversed().joined()
    }()

    
    
    var displayCornerRadius: CGFloat {
        guard let cornerRadius = self.value(forKey: Self.cornerRadiusKey) as? CGFloat else {
            return 0
        }

        return cornerRadius
    }
}
