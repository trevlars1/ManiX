//
//  PurchaseManager.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2023/6/9.
//  Copyright © 2023 Manic EMU. All rights reserved.
//

import Foundation
import StoreKit

struct PurchaseManager {
    
    private(set) static var isMember: Bool = true
    
    private(set) static var isAnnualMember: Bool = true
    
    private(set) static var isMonthlyMember: Bool = true
    
    private(set) static var isForeverMember: Bool = true
    
    private(set) static var maxFreeTrialDay: Int?
    
    private(set) static var hasFreeTrial: Bool = false

    
}
