//
//  SheerExtensions.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2025/3/9.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import ProHUD


extension SheetTarget {
    func configGamePlayingStyle(isForGameMenu: Bool = false, gameViewRect:CGRect, hideCompletion: (()->Void)? = nil) {
        
        self.onTappedBackground { sheet in
            sheet.pop(completon: hideCompletion)
        }
        self.onViewDidDisappear { _ in
            hideCompletion?()
        }
        
        self.contentMaskView.alpha = 0
        self.config.backgroundViewMask { mask in
            mask.backgroundColor = .clear
        }
        
        self.config.windowEdgeInset = 0
        self.config.cardCornerRadius = 0

        
        let sheetSize: CGSize
        if UIDevice.isPhone {
            let width = UIDevice.isLandscape ? gameViewRect.width : Constants.Size.WindowWidth
            var height = Constants.Size.WindowHeight - Constants.Size.SafeAera.bottom - 10
            if isForGameMenu && !UIDevice.isLandscape {
                
                height = GameSettingView.estimatedHeight(for: width)
            } else if !isForGameMenu && !UIDevice.isLandscape {
                
                height = Constants.Size.WindowHeight - Constants.Size.ItemHeightHuge
            }
            sheetSize = CGSize(width: width, height: height)
        } else {
            let width = 500.0
            var height = GameSettingView.estimatedHeight(for: width)
            let maxHeight = Constants.Size.WindowHeight - Constants.Size.ItemHeightHuge*2
            if height > maxHeight {
                height = maxHeight
            }
            sheetSize = CGSize(width: width, height: height)
        }
        self.config.cardMaxWidth = sheetSize.width
        self.config.cardMaxHeight = sheetSize.height
    }
}
