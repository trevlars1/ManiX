//
//  SymbolView.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2024/12/31.
//  Copyright © 2024 Manic EMU. All rights reserved.
//

import UIKit

class SymbolView: UIImageView {
    
    var normalSymbol: SFSymbol? {
        didSet {
            updateViews()
        }
    }
    
    
    var selectedSymbol: SFSymbol? {
        didSet {
            updateViews()
        }
    }
    
    
    var normalColor: UIColor {
        didSet {
            updateViews()
        }
    }
    
    
    var selectedColor: UIColor? {
        didSet {
            updateViews()
        }
    }
    
    
    var symbolPointSize: CGFloat {
        didSet {
            updateViews()
        }
    }
    
    
    var isSelected: Bool = false {
        didSet {
            updateViews()
        }
    }
    
    
    var animated: Bool = true {
        didSet {
            updateViews()
        }
    }
    
    init(normalSymbol: SFSymbol? = nil,
         selectedSymbol: SFSymbol? = nil,
         normalColor: UIColor = Constants.Color.LabelPrimary,
         selectedColor: UIColor? = nil,
         symbolPointSize: CGFloat = Constants.Size.SymbolSize,
         isSelected: Bool = false,
         animated: Bool = true) {
        self.normalColor = normalColor
        self.symbolPointSize = symbolPointSize
        super.init(frame: .zero)
        self.normalSymbol = normalSymbol
        self.selectedSymbol = selectedSymbol
        self.selectedColor = selectedColor
        self.isSelected = isSelected
        self.animated = animated
        self.contentMode = .center
        updateViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateViews() {
        guard let normalSymbol = self.normalSymbol else { return }
        let img = UIImage(symbol: isSelected ? (selectedSymbol ?? normalSymbol) : normalSymbol,
                          size: symbolPointSize,
                          color: isSelected ? (selectedColor ?? normalColor) : normalColor)
        image = img
    }
}
