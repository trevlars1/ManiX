//
//  PurchaseViewController.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2025/3/15.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

class PurchaseViewController: BaseViewController {
    
    private lazy var purchaseView: PurchaseView = {
        let view = PurchaseView(featuresType: featuresType)
        view.didTapClose = {[weak self] in
            self?.dismiss(animated: true)
        }
        return view
    }()
    
    var featuresType: FeaturesType
    
    init(featuresType: FeaturesType = .advance) {
        self.featuresType = featuresType
        super.init(nibName: nil, bundle: nil)
        
        isModalInPresentation = true
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(purchaseView)
        purchaseView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
