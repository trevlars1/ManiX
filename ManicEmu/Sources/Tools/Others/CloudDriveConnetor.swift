//
//  CloudDriveConnetor.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2025/1/22.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
import CloudServiceKit
import RealmSwift

class CloudDriveConnetor {
    static let shard = CloudDriveConnetor()
    private var currentConnector: CloudServiceConnector?
    
    private init(){}
    
    
    private func genConnector(for type: ImportServiceType) -> CloudServiceConnector? {
        let connector: CloudServiceConnector
        let cllbackUrl = Constants.Strings.OAuthCallbackHost
        switch type {
        case .googledrive:
            connector = GoogleDriveConnector(appId: Constants.Cipher.GoogleDriveAppId, appSecret: "", callbackUrl: Constants.Strings.OAuthGoogleDriveCallbackHost + "://")
        case .dropbox:
            connector = DropboxConnector(appId: Constants.Cipher.DropboxAppKey, appSecret: Constants.Cipher.DropboxAppSecret, callbackUrl: cllbackUrl + "://dropbox", responseType: "token")
        case .onedrive:
            connector = OneDriveConnector(appId: Constants.Cipher.OneDriveAppId, appSecret: "", callbackUrl: Constants.Strings.OAuthOneDriveCallbackHost + "://auth")
        case .baiduyun:
            connector = BaiduPanConnector(appId: Constants.Cipher.BaiduYunAppKey, appSecret: Constants.Cipher.BaiduYunSecretKey, callbackUrl: cllbackUrl + "://baiduyun")
        case .aliyun:
            connector = AliyunDriveConnector(appId: Constants.Cipher.AliYunAppId, appSecret: Constants.Cipher.AliYunSecrectKey, callbackUrl: cllbackUrl + "://aliyun")
        default:
            return nil
        }
        
        return connector
    }
    
    func connect(service: ImportService) {
        
        currentConnector = genConnector(for: service.type)
        guard let connector = currentConnector else { return }
        guard let topViewController = topViewController() else { return }
        connector.connect(viewController: topViewController) { [weak self] connectResult in
            switch connectResult {
            case .success(let connectSuccess):
                UIView.makeLoading()
                
                let credential = connectSuccess.credential
                
                let storeService = ImportService.genCloudService(type: service.type, token: credential.oauthToken, refreshToken: credential.oauthRefreshToken)
                
                let group = DispatchGroup()
                var aliyunDriveId: String? = nil
                
                if storeService.type == .aliyun, let provider = storeService.cloudDriveProvider as? AliyunDriveServiceProvider {
                    group.enter()
                    provider.getDriveInfo { driveInfoResult in
                        switch driveInfoResult {
                        case .success(let driveInfoSuccess):
                            aliyunDriveId = driveInfoSuccess.defaultDriveId
                        case .failure(_):
                            UIView.hideLoading()
                            UIView.makeToast(message: R.string.localizable.importAliyunNotGetDriveId())
                        }
                        group.leave()
                    }
                }
                
                group.notify(queue: DispatchQueue.main) {
                    if storeService.type == .aliyun {
                        
                        if aliyunDriveId == nil {
                            return
                        } else {
                            storeService.host = aliyunDriveId
                        }
                    }
                    
                    
                    storeService.cloudDriveProvider?.getCurrentUserInfo(completion: { userResult in
                        switch userResult {
                        case .success(let userSuccess):
                            
                            storeService.detail = userSuccess.username
                            storeService.extras = userSuccess.json.jsonString()
                            
                        case .failure(_):
                            
                            self?.currentConnector = nil
                            return
                        }
                        
                        ImportService.change { realm in
                            realm.add(storeService)
                        }
                        UIView.hideLoading()
                        UIView.makeToast(message: R.string.localizable.toastConnectCloudDriveSuccess(storeService.title))
                        self?.currentConnector = nil
                    })
                }
            case .failure(_):
                
                UIView.makeAlert(title: R.string.localizable.errorConnectCloudDrive(),
                                 detail: R.string.localizable.reasonConncetCloudDriveFail())
                self?.currentConnector = nil
            }
        }
    }
    
    func renewToken(service: ImportService, provider: CloudServiceProvider, completion: (()->Void)? = nil) {
        guard let refreshToken = service.refreshToken else {
            completion?()
            return
        }
        currentConnector = genConnector(for: service.type)
        if service.type == .baiduyun {
            
            provider.refreshAccessTokenHandler = { [weak self] callback in
                guard let self = self else { return }
                
                self.currentConnector?.renewToken(with: refreshToken, completion: { [weak self] result in
                    guard let self = self else { return }
                    switch result {
                    case .success(let token):
                        
                        
                        DispatchQueue.main.async {
                            ImportService.change { realm in
                                service.token = token.credential.oauthToken
                                if !token.credential.oauthRefreshToken.isEmpty {
                                    service.refreshToken = token.credential.oauthRefreshToken
                                }
                            }
                        }
                        let credential = URLCredential(user: "user", password: token.credential.oauthToken, persistence: .permanent)
                        callback?(.success(credential))
                    case .failure(let error):
                        
                        callback?(.failure(error))
                    }
                    self.currentConnector = nil
                })
            }
            DispatchQueue.main.asyncAfter(delay: 0.35) {
                completion?()
            }
        } else if service.type == .googledrive || service.type == .dropbox || service.type == .onedrive || service.type == .aliyun {
            
            
            currentConnector?.renewToken(with: refreshToken) { result in
                switch result {
                case .success(let token):
                    
                    
                    DispatchQueue.main.async {
                        ImportService.change { realm in
                            service.token = token.credential.oauthToken
                            if !token.credential.oauthRefreshToken.isEmpty {
                                service.refreshToken = token.credential.oauthRefreshToken
                            }
                        }
                    }
                    let credential = URLCredential(user: "user", password: token.credential.oauthToken, persistence: .permanent)
                    provider.credential = credential
                case .failure(_): break
                    
                }
                completion?()
            }
        }
    }
}
