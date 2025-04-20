//
//  UIimageExtensions.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2023/5/9.
//  Copyright © 2023 Manic EMU. All rights reserved.
//

import Foundation
import DominantColors

extension UIImage {
    
    static func symbolImage(_ symbol: SFSymbol) -> UIImage {
        UIImage(symbol: symbol)
    }

    convenience init(symbol: SFSymbol,
                     size: CGFloat = Constants.Size.SymbolSize,
                     weight: UIFont.Weight = .regular,
                     font: UIFont? = nil,
                     color: UIColor = Constants.Color.LabelPrimary,
                     colors: [UIColor]? = nil) {
        let sizeConfig = UIImage.SymbolConfiguration(font: font ?? UIFont.systemFont(ofSize: size))
        let colorConfig = UIImage.SymbolConfiguration(paletteColors: colors ?? [color])
        self.init(systemSymbol: symbol, withConfiguration: sizeConfig.applying(colorConfig))
    }
    
    
    convenience init(symbol: SFSymbol,
                     size: CGFloat = Constants.Size.SymbolSize,
                     weight: UIFont.Weight = .regular,
                     font: UIFont? = nil,
                     color: UIColor = Constants.Color.LabelPrimary,
                     colors: [UIColor]? = nil,
                     backgroundColor: UIColor,
                     imageSize: CGSize) {
        let symbolImage = UIImage(symbol: symbol, size: size, weight: weight, font: font, color: color, colors: colors)
        let format = UIGraphicsImageRendererFormat()
        guard let image = UIGraphicsImageRenderer(size: imageSize, format: format).image(actions: { context in
            backgroundColor.setFill()
            context.fill(context.format.bounds)
            symbolImage.draw(in: CGRect(center: CGPoint(x: imageSize.width/2, y: imageSize.height/2), size: CGSize(width: size, height: size)))
        }).cgImage else {
            self.init()
            return
        }
        self.init(cgImage: image, scale: UIWindow.applicationWindow?.screen.scale ?? 1, orientation: .up)
    }
    
    
    
    
    
    
    
    
    
    func applySymbolConfig(size: CGFloat = Constants.Size.SymbolSize,
                           weight: UIFont.Weight = .regular,
                           font: UIFont? = nil,
                           color: UIColor = Constants.Color.LabelPrimary,
                           colors: [UIColor]? = nil) -> UIImage {
        let sizeConfig = UIImage.SymbolConfiguration(font: font ?? UIFont.systemFont(ofSize: Constants.Size.SymbolSize))
        let colorConfig = UIImage.SymbolConfiguration(paletteColors: colors ?? [color])
        return self.withConfiguration(sizeConfig.applying(colorConfig))
    }
    
    
    
    
    static func placeHolder(preferenceSize: CGSize? = nil) -> UIImage {
        let image = R.image.place_holder()!
        if let preferenceSize = preferenceSize {
            return image.scaled(toSize: preferenceSize) ?? image
        }
        return image
    }
    
    
    func scaled(toSize: CGSize, opaque: Bool = false) -> UIImage? {
        guard toSize != .zero else { return self }
        
        var toSize = toSize
        if let scene = ApplicationSceneDelegate.applicationScene, self.scale != scene.screen.scale {
            
            let ratio = scene.screen.scale/self.scale
            toSize = CGSize(width: toSize.width * ratio, height: toSize.height * ratio)
        }
        
        var isMaxHeight: Bool = false
        var isSideEqual: Bool = false
        let scaledImage: UIImage?
        if toSize.width >= toSize.height {
            scaledImage = scaled(toHeight: toSize.height, opaque: opaque)
            isSideEqual = true
        }else {
            scaledImage = scaled(toWidth: toSize.width, opaque: opaque)
            isMaxHeight = true
        }
        
        guard let scaledImage = scaledImage else { return self }
        
        if isSideEqual {
            return scaledImage
        } else {
            let croppedRect = CGRect(center: isMaxHeight ? .init(x: scaledImage.size.width/2, y: 0) : .init(x: 0, y: scaledImage.size.height/2), size: toSize)
            return scaledImage.cropped(to: croppedRect)
        }
    }
    
    
    static func tryDataImageOrPlaceholder(tryData: Data?, preferenceSize: CGSize? = nil) -> UIImage {
        if let tryData = tryData, let image = UIImage(data: tryData, scale: ApplicationSceneDelegate.applicationScene?.screen.scale ?? 1) {
            if let preferenceSize = preferenceSize {
                return image.scaled(toSize: preferenceSize) ?? image
            }
            return image
        } else {
            return UIImage.placeHolder(preferenceSize: preferenceSize)
        }
    }
    
    
    var dominantBackground: UIColor {
        return dominantColors().background ?? Constants.Color.BackgroundPrimary
    }
    
    func dominantColors() -> (background: UIColor?, primary: UIColor?, secondary: UIColor?) {
        if let cgImage = self.cgImage,
            let colors = try? DominantColors.dominantColors(image: cgImage, options: [.excludeGray]),
            let contrastColors = ContrastColors(orderedColors: colors, ignoreContrastRatio: true) {
            return (contrastColors.background.uiColor, contrastColors.primary.uiColor, contrastColors.secondary?.uiColor)
        }
        return (nil, nil, nil)
    }
    
    func processGameSnapshop() -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let imageScale = Constants.Numbers.GameSnapshotScaleRatio
        let imageSize = CGSize(width: self.size.width * imageScale, height: self.size.height * imageScale)
        
        let renderer = UIGraphicsImageRenderer(size: imageSize, format: format)
        let screenshotData = renderer.pngData { (context) in
            context.cgContext.interpolationQuality = .none
            self.draw(in: CGRect(origin: .zero, size: imageSize))
        }
        return screenshotData
    }
    
    func applyFilter(filter: CIFilter) -> UIImage? {
        if filter is OriginFilter {
            return self
        }
        guard let ciImage = CIImage(image: self) else { return nil }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        guard let outputCIImage = filter.outputImage else { return nil }
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(outputCIImage, from: outputCIImage.extent) else { return nil }
        let filteredImage = UIImage(cgImage: cgImage)
        return filteredImage
    }
}
