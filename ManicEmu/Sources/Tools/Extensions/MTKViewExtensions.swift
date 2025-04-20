//
//  MTKViewExtensions.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2025/4/13.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import MetalKit

extension MTKView {
    func snapshot() -> Data? {
        guard let texture = self.currentDrawable?.texture else {
                print("Failed to get texture")
                return nil
            }

            let width = texture.width
            let height = texture.height
            let bytesPerPixel = 4
            let bytesPerRow = width * bytesPerPixel
            let imageByteCount = bytesPerRow * height

            var rawPixels = [UInt8](repeating: 0, count: imageByteCount)
            let region = MTLRegionMake2D(0, 0, width, height)
            texture.getBytes(&rawPixels, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)

            // BGRA -> RGBA
            for i in stride(from: 0, to: rawPixels.count, by: 4) {
                let b = rawPixels[i]
                let r = rawPixels[i + 2]
                rawPixels[i] = r
                rawPixels[i + 2] = b
            }

        return rawPixels.withUnsafeMutableBytes { ptr in
            guard let context = CGContext(data: ptr.baseAddress,
                                          width: width,
                                          height: height,
                                          bitsPerComponent: 8,
                                          bytesPerRow: bytesPerRow,
                                          space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)
            else {
                print("Failed to create CGContext")
                return nil
            }
            
            guard let cgImage = context.makeImage() else {
                print("Failed to make CGImage")
                return nil
            }
            
            let image = UIImage(cgImage: cgImage)
            return image.jpegData(compressionQuality: 0.7)
        }
    }
}
