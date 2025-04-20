//
//  SideMenuShowStyle.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2023/5/30.
//  Copyright © 2023 Manic EMU. All rights reserved.
//

import UIKit
import SideMenu

class SideMenuShowStyle: SideMenuPresentationStyle {
    
    private class CoverView: UIView {
        override init(frame: CGRect) {
            super.init(frame: frame)
            self.backgroundColor = .black.withAlphaComponent(0.7)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    private var coverView = CoverView()

    required init() {
        super.init()
        
        backgroundColor = .black
        
        menuStartAlpha = 1
        
        menuOnTop = false
        
        menuTranslateFactor = -1
        
        menuScaleFactor = 1
        
        onTopShadowColor = .black
        
        onTopShadowRadius = 5
        
        onTopShadowOpacity = 0
        
        onTopShadowOffset = .zero
        
        presentingEndAlpha = 1
        
        presentingTranslateFactor = 1-(Constants.Size.WindowWidth*(1-0.879))/2/Constants.Size.WindowWidth
        
        presentingScaleFactor = 0.879
        
//        presentingParallaxStrength = CGSize(width: 100, height: 100)
    }
    
    override func presentationTransitionWillBegin(to presentedViewController: UIViewController, from presentingViewController: UIViewController) {
        if let duration = (presentedViewController as? SideMenuNavigationController)?.presentDuration {
            coverView.removeFromSuperview()
            coverView.alpha = 0
            presentingViewController.view.addSubview(coverView)
            coverView.snp.makeConstraints { make in
                make.edges.equalTo(presentingViewController.view)
            }
            UIView.animate(withDuration: duration) {
                presentingViewController.view.layerCornerRadius = 36
                self.coverView.alpha = 1
            }
        }
    }
    
    override func presentationTransitionDidEnd(to presentedViewController: UIViewController, from presentingViewController: UIViewController, _ completed: Bool) {
        if completed {
            self.coverView.alpha = 1
        }
    }
    
    override func dismissalTransitionWillBegin(to presentedViewController: UIViewController, from presentingViewController: UIViewController) {
        if let duration = (presentedViewController as? SideMenuNavigationController)?.dismissDuration {
            UIView.animate(withDuration: duration) {
                presentingViewController.view.layerCornerRadius = 0
                self.coverView.alpha = 0
            }
        }
    }
    
    override func dismissalTransitionDidEnd(to presentedViewController: UIViewController, from presentingViewController: UIViewController, _ completed: Bool) {
        if completed {
            self.coverView.removeFromSuperview()
        }
    }
    
}
