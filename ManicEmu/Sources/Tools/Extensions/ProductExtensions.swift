//
//  ProductExtensions.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2025/3/16.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import StoreKit

extension Product {
    var freeTrialDay: Int? {
        guard PurchaseManager.hasFreeTrial else { return nil }
        if self.type == .autoRenewable,
           let subscription = self.subscription,
           let promotion = subscription.introductoryOffer,
           promotion.paymentMode == .freeTrial {
            switch promotion.period.unit {
            case .day:
                return promotion.period.value
            case .week:
                return promotion.period.value * 7
            case .month:
                return promotion.period.value * 30
            case .year:
                return promotion.period.value * 365
            default:
                return nil
            }
        }
        return nil
    }
    
    var freeTrialDesc: String? {
        if let freeTrialDay = freeTrialDay {
            return R.string.localizable.subscriptionPromotional(freeTrialDay)
        }
        return nil
    }
    
    var purchaseDisplayInfo: (title: String, detail: String, enable: Bool) {
        var title = R.string.localizable.buyNowTitle()
        var detail = R.string.localizable.foreverPlanDesc()
        var enable = true
        return (title, detail, enable)
    }
}
