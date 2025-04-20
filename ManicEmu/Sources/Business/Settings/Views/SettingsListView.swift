//
//  SettingsListView.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2025/2/28.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import UIKit
import RealmSwift
import MessageUI

class SettingsListView: BaseView {
    
    private var topBlurView: UIView = {
        let view = UIView()
        view.makeBlur(blurColor: Constants.Color.Background)
        return view
    }()
    
    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        view.backgroundColor = .clear
        view.contentInsetAdjustmentBehavior = .never
        view.register(cellWithClass: SettingsItemCollectionViewCell.self)
        view.register(cellWithClass: MembershipCollectionViewCell.self)
        view.register(supplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withClass: TitleBackgroundColorHaderCollectionReusableView.self)
        view.register(supplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withClass: SettingsListFooterCollectionReusableView.self)
        view.showsVerticalScrollIndicator = false
        view.dataSource = self
        view.delegate = self
        view.contentInset = UIEdgeInsets(top: Constants.Size.ContentInsetTop + Constants.Size.ItemHeightMid, left: 0, bottom: Constants.Size.ContentInsetBottom + Constants.Size.HomeTabBarSize.height + Constants.Size.ContentSpaceMax, right: 0)
        return view
    }()
    
    enum SectionIndex: Int, CaseIterable {
        case general = 1, advance, support, others
        var title: String {
            switch self {
            case .general:
                R.string.localizable.generalSettingTitle()
            case .advance:
                R.string.localizable.advanceSettingTitle()
            case .support:
                R.string.localizable.supportSettingTitle()
            case .others:
                R.string.localizable.othersSettingTitle()
            }
        }
    }
    
    private var settingsUpdateToken: NotificationToken? = nil
    private lazy var items: [SectionIndex: [SettingItem]] = {
        var datas = [SectionIndex: [SettingItem]]()
        
        settingsUpdateToken = Settings.defalut.observe(keyPaths: [\Settings.quickGame, \Settings.airPlay, \Settings.language]) { [weak self] change in
            guard let self = self else { return }
            switch change {
            case .change(let object, let properties):
                
                for property in properties {
                    if let newvalue = property.newValue {
                        for sectionIndex in SectionIndex.allCases {
                            var stopIter = false
                            if let itemArray = self.items[sectionIndex] {
                                for (itemIndex, item) in itemArray.enumerated() {
                                    if item.type.rawValue == property.name {
                                        stopIter = true
                                        var newItem = item
                                        if item.type == .language {
                                            if let language = property.newValue as? String {
                                                newItem.arrowDetail = Locale.getSystemLanguageDisplayName(preferredLanguage: language)
                                            }
                                        } else {
                                            if let isOn = property.newValue as? Bool {
                                                newItem.isOn = isOn
                                            }
                                        }
                                        self.items[sectionIndex]?[itemIndex] = newItem
                                        break
                                    }
                                }
                            }
                            if stopIter {
                                break
                            }
                        }
                    }
                    
                }
            default:
                break
            }
        }
        for section in SectionIndex.allCases {
            if section == .general {
                datas[section] = [SettingItem(type: .quickGame, isOn: Settings.defalut.quickGame)]
            } else if section == .advance {
                datas[section] = [SettingItem(type: .airPlay, isOn: Settings.defalut.airPlay),
                                  SettingItem(type: .iCloud, isOn: Settings.defalut.iCloudSyncEnable)
//                                  SettingItem(type: .AppIcon),
//                                  SettingItem(type: .widget)
                ]
            } else if section == .support {
                datas[section] = [SettingItem(type: .FAQ),
                                  SettingItem(type: .feedback),
                                  SettingItem(type: .shareApp),
                                  SettingItem(type: .community)]
            } else if section == .others {
                datas[section] = [SettingItem(type: .clearCache, arrowDetail: CacheManager.totleSize),
                                  SettingItem(type: .language, arrowDetail: Locale.getSystemLanguageDisplayName(preferredLanguage: Settings.defalut.language)),
                                  SettingItem(type: .userAgreement),
                                  SettingItem(type: .privacyPolicy)]
            }
        }
        return datas
    }()
    
    private let MembershipViewHeight = 130.0
    
    private var membershipNotification: Any? = nil
    
    var didTapDetail: ((UIViewController)->Void)? = nil
    
    deinit {
        if let membershipNotification = membershipNotification {
            NotificationCenter.default.removeObserver(membershipNotification)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        addSubview(topBlurView)
        topBlurView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
            make.height.equalTo(Constants.Size.ContentInsetTop + Constants.Size.ItemHeightMid)
        }
        
        let headerTitleLabel = UILabel()
        headerTitleLabel.textAlignment = .center
        headerTitleLabel.text = R.string.localizable.tabbarTitleSettings()
        headerTitleLabel.textColor = Constants.Color.LabelPrimary
        headerTitleLabel.font = Constants.Font.title(size: .s, weight: .semibold)
        topBlurView.addSubview(headerTitleLabel)
        headerTitleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(Constants.Size.ContentInsetTop)
            make.height.equalTo(Constants.Size.ItemHeightMid)
        }
        
        membershipNotification = NotificationCenter.default.addObserver(forName: Constants.NotificationName.MembershipChange, object: nil, queue: .main) { [weak self] notification in
            self?.collectionView.reloadData()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { [weak self] sectionIndex, env in
            guard let self = self else { return nil }
            
            let lastSectionIndex = SectionIndex.allCases.last!.rawValue
            
            
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                 heightDimension: .fractionalHeight(1)))
            
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(sectionIndex == 0 ? self.MembershipViewHeight : Constants.Size.ItemHeightMax)), subitems: [item])
            group.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                            leading: Constants.Size.ContentSpaceMid,
                                                            bottom: 0,
                                                            trailing: Constants.Size.ContentSpaceMid)
            
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: sectionIndex == 0 ? Constants.Size.ContentSpaceMin : 0, leading: 0, bottom: Constants.Size.ContentSpaceMin, trailing: 0)
            
            if sectionIndex > 0 {
                
                let headerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                                                heightDimension: .absolute(44)),
                                                                             elementKind: UICollectionView.elementKindSectionHeader,
                                                                             alignment: .top)
                headerItem.pinToVisibleBounds = true
                section.boundarySupplementaryItems = [headerItem]
                if sectionIndex == lastSectionIndex {
                    section.decorationItems = [NSCollectionLayoutDecorationItem.background(elementKind: String(describing: SettingsBottomDecorationCollectionReusableView.self))]
                } else {
                    section.decorationItems = [NSCollectionLayoutDecorationItem.background(elementKind: String(describing: SettingsDecorationCollectionReusableView.self))]
                }
            }
            
            if sectionIndex == lastSectionIndex {
                let footerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                                                heightDimension: .absolute(338)),
                                                                             elementKind: UICollectionView.elementKindSectionFooter,
                                                                             alignment: .bottom)
                section.boundarySupplementaryItems.append(footerItem)
            }
            
            return section
        }
        layout.register(SettingsDecorationCollectionReusableView.self, forDecorationViewOfKind: String(describing: SettingsDecorationCollectionReusableView.self))
        layout.register(SettingsBottomDecorationCollectionReusableView.self, forDecorationViewOfKind: String(describing: SettingsBottomDecorationCollectionReusableView.self))
        return layout
    }
    
    class SettingsDecorationCollectionReusableView: UICollectionReusableView {
        var backgroundView: UIView = {
            let view = UIView()
            view.layerCornerRadius = Constants.Size.CornerRadiusMax
            view.backgroundColor = Constants.Color.BackgroundPrimary
            return view
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            addSubview(backgroundView)
            backgroundView.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(Constants.Size.ItemHeightMin)
                make.bottom.equalToSuperview().offset(-Constants.Size.ContentSpaceMin)
                make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    class SettingsBottomDecorationCollectionReusableView: UICollectionReusableView {
        var backgroundView: UIView = {
            let view = UIView()
            view.layerCornerRadius = Constants.Size.CornerRadiusMax
            view.backgroundColor = Constants.Color.BackgroundPrimary
            return view
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            addSubview(backgroundView)
            backgroundView.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(Constants.Size.ItemHeightMin)
                make.bottom.equalToSuperview().offset(-Constants.Size.ContentSpaceMin-326)
                make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

extension SettingsListView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return items.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return items[SectionIndex(rawValue: section)!]!.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withClass: MembershipCollectionViewCell.self, for: indexPath)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withClass: SettingsItemCollectionViewCell.self, for: indexPath)
            let item = items[SectionIndex(rawValue: indexPath.section)!]![indexPath.row]
            cell.setData(item: item)
            cell.switchButton.onChange(handler: nil)
            cell.switchButton.onDisableTap(handler: nil)
            if item.type == .quickGame {
                cell.switchButton.onChange { value in
                    
                    Settings.change { _ in
                        Settings.defalut.quickGame = value
                    }
                }
            } else if item.type == .airPlay {
                cell.switchButton.onChange { value in
                    
                    Settings.change { _ in
                        Settings.defalut.airPlay = value
                    }
                }
                cell.switchButton.onDisableTap {
                    topViewController()?.present(PurchaseViewController(featuresType: .airplay), animated: true)
                }
            } else if item.type == .iCloud {
                cell.switchButton.onChange { [weak cell] value in
                    
                    if value {
                        UIView.makeAlert(title: R.string.localizable.iCloudTipsTitle(),
                                         detail: R.string.localizable.iCloudTipsDetail(),
                                         confirmTitle: R.string.localizable.iCloudConfirm(), cancelAction: { [weak cell] in
                            cell?.switchButton.setOn(false)
                        }, confirmAction: {
                            Settings.defalut.iCloudSyncEnable = value
                            if value, let iCloudServiceEnable = SyncManager.shared.iCloudServiceEnable, !iCloudServiceEnable {
                                
                                UIView.makeAlert(title: R.string.localizable.iCloudDisableTitle(), detail: R.string.localizable.iCloudDisableDetail(), cancelTitle: R.string.localizable.confirmTitle())
                            }
                        })
                    } else {
                        Settings.defalut.iCloudSyncEnable = value
                    }
                }
                cell.switchButton.onDisableTap {
                    topViewController()?.present(PurchaseViewController(featuresType: .iCloud), animated: true)
                }
            } else {
                cell.switchButton.onChange { value in }
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withClass: TitleBackgroundColorHaderCollectionReusableView.self, for: indexPath)
            header.titleLabel.font = Constants.Font.body(size: .l, weight: .semibold)
            header.titleLabel.text = SectionIndex(rawValue: indexPath.section)?.title
            return header
        } else {
            let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withClass: SettingsListFooterCollectionReusableView.self, for: indexPath)
            return footer
        }
    }
}

extension SettingsListView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            topViewController()?.present(PurchaseViewController(), animated: true)
        } else {
            let item = items[SectionIndex(rawValue: indexPath.section)!]![indexPath.row]
            switch item.type {
            case .FAQ:
                let vc = WebViewController(url: Constants.URLs.FAQ, showClose: UIDevice.isPhone)
                if UIDevice.isPad {
                    didTapDetail?(vc)
                } else {
                    topViewController()?.present(vc, animated: true)
                }
            case .feedback:
                if MFMailComposeViewController.canSendMail() {
                    UIView.makeLoading()
                    let mailController = MFMailComposeViewController()
                    mailController.setToRecipients([Constants.Strings.SupportEmail])
                    mailController.mailComposeDelegate = self
                    topViewController(appController: true)?.present(mailController, animated: true)
                } else {
                    UIView.makeToast(message: R.string.localizable.noEmailSetting())
                }
            case .shareApp:
                ShareManager.shareApp()
            case .community:
                UIApplication.shared.open(Constants.URLs.JoinChanel)
            case .clearCache:
                UIView.makeLoading()
                CacheManager.clear { [weak self] in
                    self?.collectionView.reloadData()
                    UIView.hideLoading()
                }
            case .language:
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            case .userAgreement:
                let vc = WebViewController(url: Constants.URLs.TermsOfUse, showClose: UIDevice.isPhone)
                if UIDevice.isPad {
                    didTapDetail?(vc)
                } else {
                    topViewController()?.present(vc, animated: true)
                }
                
            case .privacyPolicy:
                let vc = WebViewController(url: Constants.URLs.PrivacyPolicy, showClose: UIDevice.isPhone)
                if UIDevice.isPad {
                    didTapDetail?(vc)
                } else {
                    topViewController()?.present(vc, animated: true)
                }
            default:
                break
            }
        }
    }
}

extension SettingsListView: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: (any Error)?) {
        switch result {
        case .sent:
            UIView.makeToast(message: R.string.localizable.sendEmailSuccess())
            controller.dismiss(animated: true)
        case .failed:
            var errorMsg = ""
            if let error = error {
                errorMsg += "\n" + error.localizedDescription
            }
            UIView.makeToast(message: R.string.localizable.sendEmailFailed(errorMsg))
        default:
            controller.dismiss(animated: true)
        }
    
    }
}
