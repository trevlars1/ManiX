//
//  GameInfoCoverView.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2025/2/14.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import UIKit
import IceCream

class GameInfoCoverView: BaseView {
    var maskTopView: UIView = {
        let view = UIView()
        view.backgroundColor = Constants.Color.BackgroundPrimary
        view.alpha = 0
        view.isUserInteractionEnabled = false
        return view
    }()
    
    private var backgroundGradientView: UIView = {
        let view = GradientView()
        view.setupGradient(colors: [.clear, Constants.Color.BackgroundPrimary], locations: [0.0, 1.0], direction: .topToBottom)
        return view
    }()
    
    private var coverContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = Constants.Size.CornerRadiusMax
        view.makeShadow(ofColor: Constants.Color.BackgroundPrimary, radius: 30)
        return view
    }()
    
    private var coverImageView: UIImageView = {
        let view = UIImageView()
        view.layerCornerRadius = Constants.Size.CornerRadiusMax
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    lazy var editCoverButton: ContextMenuButton = {
        let view = ContextMenuButton(image: UIImage(symbol: .ellipsis), menu: generateMenu())
        view.layerCornerRadius = Constants.Size.IconSizeMid.height/2
        view.backgroundColor = Constants.Color.BackgroundSecondary
        return view
    }()
    
    private var game: Game
    
    private let CoverImageSize = UIDevice.isPhone ? 236.0 : 200.0
    
    var didCoverUpdate: ((UIImage?) -> Void)? = nil
    
    private lazy var coverUpdation: (UIImage?) -> Void = { [weak self] image in
        guard let self = self else { return }
        guard let image = image else { return }
        if let scaledImage = image.scaled(toSize: .init(self.CoverImageSize)) {
            self.coverImageView.image = scaledImage
            self.backgroundGradientView.backgroundColor = image.dominantBackground
            self.didCoverUpdate?(scaledImage)
        }
        let data = image.jpegData(compressionQuality: 0.7)
        guard let data = data else { return }
        Game.change(action: { realm in
            self.game.gameCover?.deleteAndClean(realm: realm)
            self.game.gameCover = CreamAsset.create(objectID: self.game.id, propName: "gameCover", data: data)
        })
    }
    
    init(game: Game) {
        self.game = game
        super.init(frame: .zero)
        backgroundColor = Constants.Color.BackgroundPrimary
        
        let gameCover = UIImage.tryDataImageOrPlaceholder(tryData: game.gameCover?.storedData())
        
        addSubview(backgroundGradientView)
        backgroundGradientView.backgroundColor = gameCover.dominantBackground
        backgroundGradientView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
            make.height.equalTo(378)
            make.bottom.equalToSuperview()
        }
        
        addSubview(coverContainerView)
        coverContainerView.snp.makeConstraints { make in
            make.size.equalTo(CoverImageSize)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(Constants.Size.ItemHeightMin)
        }
        
        coverContainerView.addSubview(coverImageView)
        coverImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        coverImageView.image = gameCover.scaled(toSize: CGSize(CoverImageSize))
        
        addSubview(editCoverButton)
        editCoverButton.snp.makeConstraints { make in
            make.size.equalTo(Constants.Size.IconSizeMid)
            make.top.trailing.equalTo(coverContainerView).inset(Constants.Size.ContentSpaceMin)
        }
        
        addSubview(maskTopView)
        maskTopView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func generateMenu() -> UIMenu {
        
        let titles = [R.string.localizable.readyEditCoverTakePhoto(),
                          R.string.localizable.readyEditCoverAlbum(),
                          R.string.localizable.readyEditCoverFile()/*, R.string.localizable.readyEditCoverSearch()*/]
        let symbols: [SFSymbol] = [.camera, .photoOnRectangleAngled, .folder, .magnifyingglass]
        var actions: [UIMenuElement] = []
        for (index, title) in titles.enumerated() {
            let action = UIAction(title: title, image: .symbolImage(symbols[index])) { [weak self] _ in
                guard let self = self else { return }
                if index == 0 {
                    
                    ImageFetcher.capture(completion: self.coverUpdation)
                } else if index == 1 {
                    
                    ImageFetcher.pick(completion: self.coverUpdation)
                } else if index == 2 {
                    
                    ImageFetcher.file(completion: self.coverUpdation)
                } else if index == 3 {
                    
                }
            }
            actions.append(action)
        }

        return UIMenu(children: actions)
    }
}
