//
//  Untitled.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2025/3/20.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import StableID

public class StableIDGenerator: IDGenerator {
    public init() { }
    
    public func generateID() -> String {
        return String(UUID().uuidString.suffix(12))
    }
}
