//
//  Constants.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2024/12/25.
//  Copyright © 2024 Manic EMU. All rights reserved.
//

import UIKit
import RealmSwift
import KeychainAccess

struct Constants {
    struct Size {

        static var WindowSize: CGSize { UIWindow.applicationWindow?.bounds.size ?? .zero }
        static var WindowWidth: CGFloat { WindowSize.width }
        static var WindowHeight: CGFloat { WindowSize.height }
        static var SafeAera: UIEdgeInsets { UIWindow.applicationWindow?.safeAreaInsets ?? .zero}

        static let ContentSpaceHuge = 24.0
        
        static let ContentSpaceMax = 20.0
        
        static let ContentSpaceMid = 16.0
        
        static let ContentSpaceMin = 12.0
        
        static let ContentSpaceTiny = 8.0
        
        static let ContentSpaceUltraTiny = 4.0
        
        
        static let IconSizeHuge = CGSize(width: 76, height: 76)
        
        static let IconSizeMax = CGSize(width: 36, height: 36)
        
        static let IconSizeMid = CGSize(width: 30, height: 30)
        
        static let IconSizeMin = CGSize(width: 24, height: 24)
        
        static let IconSizeTiny = CGSize(width: 18, height: 18)
        
        
        static let CornerRadiusMax = 20.0
        
        static let CornerRadiusMid = 16.0
        
        static let CornerRadiusMin = 12.0
        
        static let CornerRadiusTiny = 8.0
        
        
        static let ItemHeightHuge = 76.0
        
        static let ItemHeightMax = 60.0
        
        static let ItemHeightMid = 50.0
        
        static let ItemHeightMin = 44.0
        
        static let ItemHeightTiny = 36.0
        
        static let ItemHeightUltraTiny = 30.0
        
        
        static let SymbolSize = 16.0
        
        
        static let HomeTabBarSize = CGSize(width: 300, height: ItemHeightMax)
        
        static let SideMenuWidth = UIDevice.isPhone ? WindowSize.minDimension * 0.874 : 300
        
        static let BorderLineHeight = 1.0
        
        static let GameCoverRatio = 1.0
        
        static let GamesListSelectionEdge = 6.0
        
        static let GameCoverMaxSize = 300.0
        
        static let GameNameMaxCount = 255
        
        
        static var ContentInsetTop: CGFloat {
            let safeArea = Constants.Size.SafeAera
            return safeArea.top > 0 ? safeArea.top : Constants.Size.ContentSpaceMax
        }
        
        
        static var ContentInsetBottom: CGFloat {
            let safeArea = Constants.Size.SafeAera
            return safeArea.bottom > 0 ? safeArea.bottom : Constants.Size.ContentSpaceMax
        }
    }
    
    struct Color {
        
        static let LabelPrimary = UIColor(.dm,
                                          light: UIColor(hexString: "#222224")!,
                                          dark: UIColor(hexString: "#ffffff")!)
        static let LabelSecondary = UIColor(.dm,
                                            light: UIColor(hexString: "#8c8d9b")!,
                                            dark: UIColor(hexString: "#8F8F92")!)
        static let LabelTertiary = UIColor(.dm,
                                           light: UIColor(hexString: "#8c8d9b", transparency: 0.8)!,
                                           dark: UIColor(hexString: "#403E46")!)
        static let LabelQuaternary = UIColor(.dm,
                                             light: UIColor(hexString: "#8c8d9b", transparency: 0.6)!,
                                             dark: UIColor(hexString: "#3f3f3f", transparency: 0.8)!)
        
        
        static let Border = UIColor(.dm,
                                    light: UIColor(hexString: "#e2e2ea")!,
                                    dark: .white.withAlphaComponent(0.1))
        
        
        static let Background = UIColor(.dm,
                                              light: UIColor(hexString: "#ffffff")!,
                                              dark: UIColor(hexString: "#17171D")!)
        
        static let BackgroundPrimary = UIColor(.dm,
                                              light: UIColor(hexString: "#ffffff")!,
                                              dark: UIColor(hexString: "#1E1E24")!)
        
        static let BackgroundSecondary = UIColor(.dm,
                                           light: UIColor(hexString: "#ffffff")!,
                                           dark: UIColor(hexString: "#26262E")!)
        
        static let BackgroundTertiary = UIColor(.dm,
                                           light: UIColor(hexString: "#ffffff")!,
                                           dark: UIColor(hexString: "#464651")!)
        
        static let Selection = UIColor(.dm,
                                       light: UIColor(hexString: "#ffffff")!.darken(),
                                       dark: UIColor(hexString: "#2c2c30")!)
        
        
        static let Shadow = BackgroundPrimary
        
        
        static let Gradient = [UIColor(hexString: "#EB7500")!, UIColor(hexString: "#F2416B")!, UIColor(hexString: "#BB64FF")!, UIColor(hexString: "#0096FF")!]
        
        static let Red = UIColor(.dm,
                                 light: UIColor(hexString: "#FF2442")!,
                                 dark: UIColor(hexString: "#FF2442")!)
        
        static let Green = UIColor(.dm,
                                   light: UIColor(hexString: "#54D590")!,
                                   dark: UIColor(hexString: "#54D590")!)
        
        static let Blue = UIColor(.dm,
                                  light: UIColor(hexString: "#418CFE")!,
                                  dark: UIColor(hexString: "#418CFE")!)
        
        static let Indigo = UIColor(.dm,
                                    light: UIColor(hexString: "#0BCDDF")!,
                                    dark: UIColor(hexString: "#0BCDDF")!)
        
        static let Purple = UIColor(.dm,
                                    light: UIColor(hexString: "#9390FF")!,
                                    dark: UIColor(hexString: "#9390FF")!)
        
        static let Yellow = UIColor(.dm,
                                    light: UIColor(hexString: "#FFC546")!,
                                    dark: UIColor(hexString: "#FFC546")!)

        
        static let Magenta = UIColor(.dm,
                                     light: UIColor(hexString: "#FF7B7F")!,
                                     dark: UIColor(hexString: "#FF7B7F")!)

        
        static let Orange = UIColor(.dm,
                                    light: UIColor(hexString: "#F14A00")!,
                                    dark: UIColor(hexString: "#F14A00")!)
    }
    
    struct Cipher {
        static let BaiduYunAppKey = ""
        static let BaiduYunSecretKey = ""
        static let DropboxAppKey = ""
        static let DropboxAppSecret = ""
        static let GoogleDriveAppId = ""
        static let OneDriveAppId = ""
        static let OneDriveSecrectKey = ""
        static let AliYunAppId = ""
        static let AliYunSecrectKey = ""
        static let UMAppKey = ""
        static let CLoudflareAPIToken = ""
        static let UnzipKey = "123456"
    }
    
    struct Path {
        static let Document = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        static var Data: String {
            let path = Document.appendingPathComponent("Datas")
            if !FileManager.default.fileExists(atPath: path) {
                try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
            }
            return path
        }
        static let Library = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first!
        static let Cache = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
        static let Temp = NSTemporaryDirectory()
        static let PasteWorkSpace = Temp.appendingPathComponent("PasteWorkSpace")
        static let UploadWorkSpace = Temp.appendingPathComponent("UploadWorkSpace")
        static let ShareWorkSpace = Temp.appendingPathComponent("ShareWorkSpace")
        static let DownloadWorkSpace = Cache.appendingPathComponent("DownloadWorkSpace")
        static let SMBWorkSpace = Temp.appendingPathComponent("SMBWorkSpace")
        static let DropWorkSpace = Temp.appendingPathComponent("DropWorkSpace")
        static let SaveStateWorkSpace = Temp.appendingPathComponent("SaveStateWorkSpace")
        static let ZipWorkSpace = Temp.appendingPathComponent("ZipWorkSpace")
        static let Realm = Library.appendingPathComponent("Realm")
        static let RealmFilePath = Realm.appendingPathComponent("default.realm")
        static let Resource = Library.appendingPathComponent("System.bundle")
        static let Log = Library.appendingPathComponent("XCGLogger")
        static var ThreeDSWorkSpace: String {
            if Settings.defalut.iCloudSyncEnable, let url = SyncManager.iCloudUrl() {
                return url.appendingPathComponent("3DS").path
            }
            return Data.appendingPathComponent("3DS")
        }
        static var ThreeDS = Library.appendingPathComponent("3DS")
        static var ThreeDSSystemData = ThreeDS.appendingPathComponent("sysdata")
        static var ThreeDSStateLoad = ThreeDS.appendingPathComponent("states")
//        static var ThreeDSCIA = ThreeDSWorkSpace.appending("/sdmc/Nintendo 3DS/00000000000000000000000000000000/00000000000000000000000000000000/title/00040000")
//        static var ThreeDSCIAGame = ThreeDSGame.appendingPathComponent("00040000")
//        static var ThreeDSCIADLC = ThreeDSGame.appendingPathComponent("0004000e")
//        static var ThreeDSCIAUpdate = ThreeDSGame.appendingPathComponent("0004008C")
    }
    
    struct DefaultKey {
        static let HasShowPrivacyAlert = "HasShowPrivacyAlert"
        static let AppGroupName = "group.aoshuang.ManicEmu"
        static let AppGroupIsPremiumKey = "AppGroupIsPremiumKey"
        static let HasShowCheatCodeWarning = "HasShowCheatCodeWarning"
        static let HadSavedSnapshot = "HadSavedSnapshot"
        static let ShowRequestReviewDate = "ShowRequestReviewDate"
        static let SystemCoreVersion = "SystemCoreVersion"
        static let HasShow3DSPlayAlert = "HasShow3DSPlayAlert"
        static let HasShow3DSNotSupportAlert = "HasShow3DSNotSupportAlert"
    }
    
    struct Font {
        enum Size { case s, m, l}
        
        
        
        
        
        
        static func title(size: Size = .l, weight: UIFont.Weight = .bold) -> UIFont {
            switch size {
            case .s:
                UIFont.systemFont(ofSize: 17, weight: weight)
            case .m:
                UIFont.systemFont(ofSize: 18, weight: weight)
            case .l:
                UIFont.systemFont(ofSize: 24, weight: weight)
            }
        }
        
        
        
        
        
        
        static func body(size: Size = .s, weight: UIFont.Weight = .regular) -> UIFont {
            switch size {
            case .s:
                UIFont.systemFont(ofSize: 13, weight: weight)
            case .m:
                UIFont.systemFont(ofSize: 14, weight: weight)
            case .l:
                UIFont.systemFont(ofSize: 15, weight: weight)
            }
        }
        
        
        
        
        
        
        static func caption(size: Size = .m, weight: UIFont.Weight = .regular) -> UIFont {
            switch size {
            case .s:
                UIFont.systemFont(ofSize: 8, weight: weight)
            case .m:
                UIFont.systemFont(ofSize: 10, weight: weight)
            case .l:
                UIFont.systemFont(ofSize: 12, weight: weight)
            }
        }
    }
    
    struct Strings {
        static let SupportEmail = "support@manicemu.site"
        static let MemberKeyChainKey = "MemberKeyChainKey"
        static let PurchaseInfoKey = "PurchaseInfoKey"
        static let OAuthCallbackHost = "manicemu-oauth"
        static let OAuthGoogleDriveCallbackHost = "com.googleusercontent.apps.177622908853-bkjvno7a5v14obn3rn70s264afrll6p7"
        static let OAuthOneDriveCallbackHost = "msauth.com.aoshuang.manicemu"
        static let TimeFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        static let FileNameTimeFormat = "yyyy-MM-dd_HH-mm-ss-SSS"
        static let PlayPurchaseAlertIdentifier = "PlayPurchaseAlertIdentifier"
    }
    
    enum Config {
        static let AppName: String = value(forKey: "CFBundleDisplayName")
        static let AppVersion: String = value(forKey: "CFBundleShortVersionString")
        static let AppIdentifier: String = value(forKey: "CFBundleIdentifier")
        static func value<T>(forKey key: String) -> T {
            guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? T else {
                fatalError("Invalid value or undefined key")
            }
            return value
        }
    }
    
    struct Numbers {
        
        static let GameFunctionButtonCount = 4
        
        static let GameSnapshotScaleRatio = 5.0
        
        static let AutoSaveGameDuration = 60
        
        static var AutoSaveGameCount: Int {
            PurchaseManager.isMember ? 50 : 3
        }
        
        static var NonMemberManualSaveGameCount = 3
        
        static let RandomGameLimit = 10
        
        static let NonMemberCheatCodeCount = 3
        
        static let LongAnimationDuration = 1.0
    }
    
    struct NotificationName {
        
        static let PurchaseSuccess = NSNotification.Name(rawValue: "PurchaseSuccess")
        
        static let HomeSelectionChange = NSNotification.Name(rawValue: "HomeSelectionChange")
        
        static let MembershipChange = NSNotification.Name(rawValue: "MembershipChange")
        
        static let ProductsUpdate = NSNotification.Name(rawValue: "ProductsUpdate")
        
        static let StartPlayGame = NSNotification.Name(rawValue: "StartPlayGame")
        
        static let StopPlayGame = NSNotification.Name(rawValue: "StopPlayGame")
    }
    
    struct URLs {
        static let ManicEMU = "https://manicemu.site/"
//        static let ManicEMU = "http://10.10.10.20:4000/"
        static let AppReview = URL(string: "itms-apps://itunes.apple.com/app/id6743335790?action=write-review")!
        static let AppStoreUrl = URL(string: "https://apps.apple.com/app/id6743335790")!
        static let TermsOfUse = URL(string: ManicEMU + "terms-of-use")!
        static let PrivacyPolicy = URL(string: ManicEMU + "privacy-policy")!
        static let PaymentTerms = URL(string: ManicEMU + "Payment-Terms")!
        static var FAQ: URL {
            Locale.prefersCN ? URL(string: ManicEMU + "FAQ-CN")! : URL(string: ManicEMU + "FAQ-EN")!
        }
        static var GameImportGuide: URL {
            Locale.prefersCN ? URL(string: ManicEMU + "Game-Import-Guide-CN")! : URL(string: ManicEMU + "Game-Import-Guide-EN")!
        }
        static var SkinUsageGuide: URL {
            Locale.prefersCN ? URL(string: ManicEMU + "Skin-Usage-Guide-CN")! : URL(string: ManicEMU + "Skin-Usage-Guide-EN")!
        }
        static var ControllerUsageGuide: URL {
            Locale.prefersCN ? URL(string: ManicEMU + "Controller-Usage-Guide-CN")! : URL(string: ManicEMU + "Controller-Usage-Guide-EN")!
        }
        static var CheatCodesGuide: URL {
            Locale.prefersCN ? URL(string: ManicEMU + "Cheat-Codes-Guide-CN")! : URL(string: ManicEMU + "Cheat-Codes-Guide-EN")!
        }
        static var AirPlayUsageGuide: URL {
            Locale.prefersCN ? URL(string: ManicEMU + "AirPlay-Usage-Guide-CN")! : URL(string: ManicEMU + "AirPlay-Usage-Guide-EN")!
        }
        static var JoinChanel: URL {
            Locale.prefersCN ? URL(string: "https://pd.qq.com/s/7i1g6jf5k")! : URL(string: "https://t.me/+R56rb3Sa9hM0YjEx")!
        }
    }
}
