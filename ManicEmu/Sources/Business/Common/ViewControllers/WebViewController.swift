//
//  WebViewController.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2025/3/9.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import WebKit
import MessageUI

class WebViewController: BaseViewController {
    static var isShow = false
    
    private let url: URL
    private lazy var webView: WKWebView = {
        let view = WKWebView(frame: CGRect.zero)
        view.navigationDelegate = self
        view.isOpaque = false
        view.backgroundColor = Constants.Color.Background
        view.scrollView.backgroundColor = Constants.Color.Background
        view.load(URLRequest(url: url))
        return view
    }()
    
    private let showClose: Bool
    
    var didTapEmail: ((UIViewController)->Void)? = nil
    
    var didClose: (()->Void)? = nil
    
    deinit {
        webView.navigationDelegate = nil
    }

    init(url: URL = URL(string: Constants.URLs.ManicEMU)!, showClose: Bool = true, isShow: Bool? = nil) {
        self.url = url
        self.showClose = showClose
        if let isShow = isShow {
            Self.isShow = isShow
        }
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Constants.Color.Background
        view.addSubview(webView)
        webView.snp.makeConstraints { make in
            make.leading.bottom.trailing.equalTo(view)
            make.top.equalTo(view).offset(Constants.Size.ContentSpaceMid)
        }
        if showClose {
            addCloseButton(makeConstraints:  { make in
                make.size.equalTo(Constants.Size.IconSizeMid)
                make.top.equalToSuperview().offset(Constants.Size.ContentSpaceMin)
                make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMax-Constants.Size.ContentSpaceUltraTiny)
            })
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        Self.isShow = false
        didClose?()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        UIView.makeLoading(timeout: 3)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        UIView.hideLoading()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) {
        UIView.hideLoading()
        UIView.makeToast(message: R.string.localizable.lodingFailedTitle())
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: any Error) {
        UIView.hideLoading()
        UIView.makeToast(message: R.string.localizable.lodingFailedTitle())
    }
}
