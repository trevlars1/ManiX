
//
//  AppDelegate.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2024/12/25.
//  Copyright © 2024 Manic EMU. All rights reserved.
//

import UIKit
import UniformTypeIdentifiers
import ManicEmuCore
import IceCream
import CloudKit
import StableID
#if DEBUG
import FLEX
import ShowTouches

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)
        if motion == .motionShake {
            if FLEXManager.shared.isHidden {
                FLEXManager.shared.showExplorer()
            } else {
                FLEXManager.shared.hideExplorer()
            }
            UIWindow.startShowingTouches()
        }
    }
}
#endif

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    static var orientation: UIInterfaceOrientationMask = UIDevice.isPad ? .all : .portrait {
        didSet {
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }
    
    weak var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        StableID.configure(idGenerator: StableIDGenerator())
        
        LogSetup()
        
        System.allCores.forEach { ManicEmu.register($0) }
        
        let apmConfig = UMAPMConfig.default()
        apmConfig.crashAndBlockMonitorEnable = true
        apmConfig.javaScriptBridgeEnable = false
        apmConfig.launchMonitorEnable = false
        apmConfig.logCollectEnable = false
        apmConfig.memMonitorEnable = false
        apmConfig.networkEnable = false
        apmConfig.oomMonitorEnable = false
        apmConfig.pageMonitorEnable = false
        apmConfig.logCollectEnable = false
        apmConfig.logCollectUserId = StableID.id
        UMCrashConfigure.setAPMConfig(apmConfig)
        MobClick.profileSignIn(withPUID: StableID.id)
        MobClick.setAutoPageEnabled(true)
        UMConfigure.initWithAppkey(Constants.Cipher.UMAppKey, channel: nil);
        
        ExternalGameControllerUtils.shared.startDetecting()
        
        CacheManager.clear()

        NotificationCenter.default.addObserver(forName: Constants.NotificationName.MembershipChange, object: nil, queue: .main) { _ in
            ExternalGameControllerUtils.shared.forceSetPlayerIndex = PurchaseManager.isMember ? 0 : nil
        }

        application.registerForRemoteNotifications()
        return true
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        var isWindowExternal = false
        if #available(iOS 16.0, *) {
            if connectingSceneSession.role == .windowExternalDisplayNonInteractive {
                isWindowExternal = true
            }
        } else {
            if connectingSceneSession.role == .windowExternalDisplay {
                isWindowExternal = true
            }
        }
        if isWindowExternal {
            return UISceneConfiguration(name: "External Configuration", sessionRole: connectingSceneSession.role)
        } else {
            return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        }
    }

    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        let manager = DownloadManager.shared.sessionManager
        if manager.identifier == identifier {
            manager.completionHandler = completionHandler
        }
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientation
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        if let dict = userInfo as? [String: NSObject],
            let notification = CKNotification(fromRemoteNotificationDictionary: dict),
            let subscriptionID = notification.subscriptionID, IceCreamSubscription.allIDs.contains(subscriptionID) {
            NotificationCenter.default.post(name: Notifications.cloudKitDataDidChangeRemotely.name, object: nil, userInfo: userInfo)
            completionHandler(.newData)
        }
    }
}
