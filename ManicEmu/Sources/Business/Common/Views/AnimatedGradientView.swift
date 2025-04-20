//
//  AnimatedGradientView.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2025/1/1.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import UIKit
import ColorfulX

class AnimatedGradientView: AnimatedMulticolorGradientView {
    override init() {
        super.init()
        self.setColors(Constants.Color.Gradient, animated: false)
        self.speed = 1
        self.transitionSpeed = 10
        self.bias = 0.0025
        self.renderScale = 2
    }
}
