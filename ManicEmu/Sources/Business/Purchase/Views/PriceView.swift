//
//  PriceView.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2025/3/15.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import StoreKit

class PriceView: UIView {
    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        view.backgroundColor = .clear
        view.contentInsetAdjustmentBehavior = .never
        view.register(cellWithClass: PriceItemCollectionCell.self)
        view.register(supplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withClass: PurchaseButtonReusableView.self)
        view.showsVerticalScrollIndicator = false
        view.dataSource = self
        view.delegate = self
        view.contentInset = UIEdgeInsets(top: Constants.Size.ContentSpaceHuge , left: 0, bottom: Constants.Size.ContentInsetBottom, right: 0)
        return view
    }()
    
    private weak var purchaseButtonView: PurchaseButtonReusableView? = nil
    

    private var products = [Product]() {
        didSet {
            self.collectionView.reloadData()
        }
    }
    
    private var selectedProduct: Product? = nil
    
    var needToClosePurchaseView: (()->Void)? = nil
    
    deinit {
        Log.debug("\(String(describing: Self.self)) deinit")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        Log.debug("\(String(describing: Self.self)) init")
        
        UIView.makeLoading()
        
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, env in
            
            
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                 heightDimension: .fractionalHeight(1)))
            
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(Constants.Size.ItemHeightHuge)), subitems: [item])
            group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: Constants.Size.ContentSpaceHuge, bottom: 0, trailing: Constants.Size.ContentSpaceHuge)
            
            
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = Constants.Size.ContentSpaceMid
            let footerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                                            heightDimension: .absolute(129)),
                                                                         elementKind: UICollectionView.elementKindSectionFooter,
                                                                         alignment: .bottom)
            section.boundarySupplementaryItems.append(footerItem)
            
            return section
        }
        return layout
    }
}

extension PriceView: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return products.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withClass: PriceItemCollectionCell.self, for: indexPath)
        let product = products[indexPath.row]
        cell.setData(product: product, isSelected: selectedProduct?.id == product.id)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withClass: PurchaseButtonReusableView.self, for: indexPath)
        if let selectedProduct = self.selectedProduct {
            let info = selectedProduct.purchaseDisplayInfo
            footer.setData(title: info.title, descripton: info.detail, enable: info.enable)
        }
        footer.buttonContainer.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            
            if let product = self.selectedProduct {
                
            }
        }
        purchaseButtonView = footer
        return footer
    }
}

extension PriceView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedProduct = products[indexPath.row]
        if let purchaseDisplayInfo = selectedProduct?.purchaseDisplayInfo {
            purchaseButtonView?.setData(title: purchaseDisplayInfo.title, descripton: purchaseDisplayInfo.detail, enable: purchaseDisplayInfo.enable)
        }
    }
}
