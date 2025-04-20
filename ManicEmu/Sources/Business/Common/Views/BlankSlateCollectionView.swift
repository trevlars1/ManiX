//
//  BlankSlateCollectionView.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2025/2/16.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import UIKit
import BlankSlate

class BlankSlateCollectionView: UICollectionView {
    
    var blankSlateView: UIView? = nil
    
    deinit {
        Log.debug("\(String(describing: Self.self)) deinit")
    }

    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        Log.debug("\(String(describing: Self.self)) init")
        self.bs.setDataSourceAndDelegate(self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension BlankSlateCollectionView: BlankSlate.DataSource {
    func customView(forBlankSlate view: UIView) -> UIView? {
        return blankSlateView
    }
    
    func layout(forBlankSlate view: UIView, for element: BlankSlate.Element) -> BlankSlate.Layout {
        .init(edgeInsets: .zero, height: Constants.Size.WindowHeight)
    }
    
}

extension BlankSlateCollectionView: BlankSlate.Delegate {
    
}
