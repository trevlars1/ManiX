//
//  SettingItem.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2025/2/28.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

struct SettingItem {
    
    enum ItemType: String {
        case leftHand, quickGame, airPlay, iCloud, AppIcon, widget, FAQ, feedback, shareApp, community, clearCache, language, userAgreement, privacyPolicy
    }
    
    var type: ItemType
    var isOn: Bool? = false
    var arrowDetail: String? = nil
    
    var backgroundColor: UIColor {
        switch type {
        case .leftHand, .feedback:
            Constants.Color.Magenta
        case .quickGame, .shareApp:
            Constants.Color.Green
        case .airPlay, .FAQ, .clearCache:
            Constants.Color.Blue
        case .iCloud, .language:
            Constants.Color.Indigo
        case .AppIcon, .userAgreement:
            Constants.Color.Purple
        case .widget, .privacyPolicy:
            Constants.Color.Yellow
        case .community:
                .clear
        }
    }
    
    var icon: UIImage {
        switch type {
        case .leftHand:
            UIImage(symbol: .handPointLeftFill, font: Constants.Font.body(size: .s, weight: .medium))
        case .quickGame:
            UIImage(symbol: .hareFill, font: Constants.Font.caption(size: .m, weight: .medium))
        case .airPlay:
            UIImage(symbol: .airplayvideo, font: Constants.Font.body(size: .s, weight: .medium))
        case .iCloud:
            if #available(iOS 17.0, *) {
                UIImage(symbol: .arrowTriangle2CirclepathIcloudFill, font: Constants.Font.body(size: .s, weight: .medium))
            } else {
                UIImage(symbol: .cloudFill, font: Constants.Font.body(size: .s, weight: .medium))
            }
        case .AppIcon:
            UIImage(symbol: .appFill, font: Constants.Font.body(size: .s, weight: .medium)).rotated(by: 15/180) ?? UIImage(symbol: .appFill)
        case .widget:
            R.image.customWidgetSmall()!.applySymbolConfig(font: Constants.Font.body(size: .s, weight: .medium))
        case .FAQ:
            UIImage(symbol: .questionmarkAppFill, font: Constants.Font.body(size: .s, weight: .medium))
        case .feedback:
            UIImage(symbol: .questionmarkAppFill, font: Constants.Font.body(size: .s, weight: .medium))
        case .shareApp:
            UIImage(symbol: .squareAndArrowUpFill, font: Constants.Font.body(size: .s, weight: .medium))
        case .community:
            Locale.prefersCN ? R.image.settings_qq()! : R.image.settings_telegram()!
        case .clearCache:
            UIImage(symbol: .paintbrushFill, font: Constants.Font.body(size: .s, weight: .medium))
        case .language:
            UIImage(symbol: .globe, font: Constants.Font.body(size: .s, weight: .medium))
        case .userAgreement:
            UIImage(symbol: .docTextFill, font: Constants.Font.body(size: .s, weight: .medium))
        case .privacyPolicy:
            UIImage(symbol: .shieldLefthalfFilled, font: Constants.Font.body(size: .s, weight: .medium))
        }
    }
    
    var title: String {
        switch type {
        case .leftHand:
            R.string.localizable.quickGameTitle()
        case .quickGame:
            R.string.localizable.quickGameTitle()
        case .airPlay:
            R.string.localizable.airPlayTitle()
        case .iCloud:
            R.string.localizable.iCloudTitle()
        case .AppIcon:
            R.string.localizable.appIconTitle()
        case .widget:
            R.string.localizable.widgetTitle()
        case .FAQ:
            R.string.localizable.qaTitle()
        case .feedback:
            R.string.localizable.feedbackTitle()
        case .shareApp:
            R.string.localizable.shareAppTitle()
        case .community:
            Locale.prefersCN ? R.string.localizable.joinQQTitle() : R.string.localizable.joinTelegramTitle()
        case .clearCache:
            R.string.localizable.clearCacheTitle()
        case .language:
            R.string.localizable.languageTitle()
        case .userAgreement:
            R.string.localizable.userAgreementTitle()
        case .privacyPolicy:
            R.string.localizable.privacyPolicyTitle()
        }
    }
    
    var detail: String? {
        if type == .leftHand {
            return R.string.localizable.leftHandDetail()
        } else if type == .quickGame {
            return R.string.localizable.quickGameDetail()
        } else if type == .airPlay {
            return R.string.localizable.airPlayDetail()
        } else if type == .iCloud {
            return R.string.localizable.iCloudDetail()
        }
        return nil
    }
}
