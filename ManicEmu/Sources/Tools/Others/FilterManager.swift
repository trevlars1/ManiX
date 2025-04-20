//
//  FilterManager.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2025/3/8.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

struct FilterManager {
    
    static func allFilters(completion: (([CIFilter])->Void)? = nil) {
        DispatchQueue.global().async {
            var results = [CIFilter]()
            results.append(OriginFilter())
            results.append(CRTFilter())
            enumerateLutFilters { path in
                if let lut = UIImage(contentsOfFile: path), let lutFilter = CICubeColorGenerator(image: lut)?.filter() {
                    lutFilter.name = path.lastPathComponent.deletingPathExtension
                    results.append(lutFilter)
                }
                return false
            }
            DispatchQueue.main.async {
                completion?(results)
            }
        }
    }
    
    
    
    
    static func find(name: String) -> CIFilter? {
        if name == OriginFilter.name {
            return OriginFilter()
        }
        if name == CRTFilter.name {
            return CRTFilter()
        }
        var filter: CIFilter? = nil
        enumerateLutFilters { path in
            if path.lastPathComponent.deletingPathExtension == name {
                if let lut = UIImage(contentsOfFile: path), let lutFilter = CICubeColorGenerator(image: lut)?.filter() {
                    filter = lutFilter
                    return true
                }
            }
            return false
        }
        return filter
    }
    
    
    
    
    private static func enumerateLutFilters(foreach: (_ path: String)->Bool) {
        let fileManager = FileManager.default
        let resourcePath = Constants.Path.Resource
        if let contents = try? fileManager.contentsOfDirectory(atPath: resourcePath) {
            let lutNames = contents.filter { $0.hasSuffix(".png") }
            for lutName in lutNames {
                if foreach(resourcePath.appendingPathComponent(lutName)) {
                    break
                }
            }
        }
    }
}

struct CICubeColorGenerator {
    
    let image: UIImage
    let dimension: Int
    
    init?(image: UIImage) {
        self.image = image
        
        // check
        let imageWidth = self.image.size.width * self.image.scale
        let imageHeight = self.image.size.height * self.image.scale
        
        dimension = Int(cbrt(Double(imageWidth * imageHeight)))
        
        if Int(imageWidth) % dimension != 0 || Int(imageHeight) % dimension != 0 {
            assertionFailure("invalid image size")
            return nil
        }
        if (dimension * dimension * dimension != Int(imageWidth * imageHeight)) {
            assertionFailure("invalid image size")
            return nil
        }
    }
    
    
    func filter() -> CIFilter? {
        
        // get image uncompressed data
        guard let cgImage = image.cgImage else { return nil }
        guard let dataProvider = cgImage.dataProvider else { return nil }
        guard let data = dataProvider.data else { return nil }
        
        guard var pixels = CFDataGetBytePtr(data) else { return nil }
        let length = CFDataGetLength(data)
        let original = pixels
        
        let imageWidth = self.image.size.width * self.image.scale
        let imageHeight = self.image.size.height * self.image.scale
        
        let row = Int(imageHeight) / dimension
        let column = Int(imageWidth) / dimension
        
        // create cube
        var cube = UnsafeMutablePointer<Float>.allocate(capacity: length)
        let origCube = cube
        
        // transform pixels into cube
        for r in 0..<row {
            for c in 0..<column {
                
                
                pixels = original
                pixels += Int(imageWidth) * (r * dimension) * 4 + c * dimension * 4
                
                
                for lr in 0..<dimension {
                    
                    
                    pixels = original
                    let rowStrides = Int(imageWidth) * (r * dimension + lr) * 4
                    let columnStrides = c * dimension * 4
                    pixels += (rowStrides + columnStrides)
                    
                    
                    for _ in 0..<dimension {
                        cube.pointee = Float(pixels.pointee) / 255.0; cube += 1; pixels += 1 
                        cube.pointee = Float(pixels.pointee) / 255.0; cube += 1; pixels += 1 
                        cube.pointee = Float(pixels.pointee) / 255.0; cube += 1; pixels += 1 
                        cube.pointee = Float(pixels.pointee) / 255.0; cube += 1; pixels += 1 
                    }
                }
            }
        }
        
        guard let filter = CIFilter(name: "CIColorCube") else { return nil }
        filter.setValue(dimension, forKey: "inputCubeDimension")
        filter.setValue(Data(bytes: origCube, count: length * 4), forKey: "inputCubeData")
        return filter
    }
}
