//
//  ExternalSceneDelegate.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2025/3/9.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
import RealmSwift

class ExternalSceneDelegate: UIResponder, UIWindowSceneDelegate {
    static var isAirPlaying = false
    var window: UIWindow?
    private var settingsUpdateToken: Any? = nil
    private var membershipNotification: Any? = nil
    private var startPlayGameNotification: Any? = nil
    private var stopPlayGameNotification: Any? = nil
    static weak var airPlayViewController: AirPlayViewController?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let windowScene = scene as? UIWindowScene {
            ExternalSceneDelegate.isAirPlaying = true
            window = UIWindow(windowScene: windowScene)
            window?.tintColor = Constants.Color.Red
            let airPlayViewController = AirPlayViewController()
            window?.rootViewController = airPlayViewController
            ExternalSceneDelegate.airPlayViewController = airPlayViewController
            window?.makeKeyAndVisible()
            updateScene()
            settingsUpdateToken = Settings.defalut.observe(keyPaths: [\Settings.airPlay]) { [weak self] change in
                guard let self = self else { return }
                switch change {
                case .change(_, _):
                    
                    self.updateScene()
                default:
                    break
                }
            }
            
            membershipNotification = NotificationCenter.default.addObserver(forName: Constants.NotificationName.MembershipChange, object: nil, queue: .main) { [weak self] notification in
                self?.updateScene()
            }

            startPlayGameNotification = NotificationCenter.default.addObserver(forName: Constants.NotificationName.StartPlayGame, object: nil, queue: .main) { [weak self] notification in
                self?.updateScene()
            }

            stopPlayGameNotification = NotificationCenter.default.addObserver(forName: Constants.NotificationName.StopPlayGame, object: nil, queue: .main) { [weak self] notification in
                self?.updateScene()
            }
        }
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        window?.isHidden = true
        window?.removeFromSuperview()
        window = nil
        settingsUpdateToken = nil
        if let membershipNotification = membershipNotification {
            NotificationCenter.default.removeObserver(membershipNotification)
        }
        if let startPlayGameNotification = startPlayGameNotification {
            NotificationCenter.default.removeObserver(startPlayGameNotification)
        }
        if let stopPlayGameNotification = stopPlayGameNotification {
            NotificationCenter.default.removeObserver(stopPlayGameNotification)
        }
        membershipNotification = nil
        ExternalSceneDelegate.isAirPlaying = false
    }
    
    private func updateScene() {
        if PurchaseManager.isMember, Settings.defalut.airPlay, PlayViewController.isGaming, PlayViewController.playingGameType != ._3ds {
            window?.isHidden = false
        } else {
            window?.isHidden = true
        }
    }
}
