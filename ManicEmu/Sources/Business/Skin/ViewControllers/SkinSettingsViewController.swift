//
//  SkinSettingsViewController.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2025/1/25.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import UIKit
import ManicEmuCore

class SkinSettingsViewController: BaseViewController {
    
    private lazy var skinSettingsView: SkinSettingsView = {
        let view = SkinSettingsView(game: game, gameType: gameType)
        view.didTapClose = {[weak self] in
            self?.dismiss(animated: true)
        }
        return view
    }()
    
    private let game: Game?
    private let gameType: GameType?
    
    
    
    
    
    init(game: Game? = nil, gameType: GameType? = nil) {
        self.game = game
        self.gameType = gameType
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(skinSettingsView)
        skinSettingsView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
