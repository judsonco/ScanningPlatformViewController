//
//  Created by Judson Stephenson on 7/09/19.
//  Copyright © 2019 Judson Stephenson. All rights reserved.
//

import UIKit
import WebKit
import Dispatch;
import CaptuvoManager;
import BarcodeLoginController;

open class ScanningPlatformViewController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate {
    var barcodeView = BarcodeLoginController.shared()

    @IBOutlet public weak var webView: WKWebView!
    @IBOutlet public weak var activityIndicator: UIActivityIndicatorView!
    
    open var defaultURL = URL(string: "https://judson.biz/shop/Inventory/jwarehouse/index.php")!
    open var loginPath = "/admin/login";

    public static var sharedCaptuvoManager = CaptuvoManager.sharedManager;
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        let request = URLRequest(url: defaultURL)
        
        webView.configuration.userContentController.add(
            self,
            name: "callbackHandler"
        )
        webView.navigationDelegate = self
        webView.load(request)
        
        let manager = CaptuvoManager.sharedManager;
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(decoderDataReceived(_:)), name: CaptuvoManager.decoderDataReceivedNotification, object: manager)
        
        barcodeView.successfulScanHandler = { barcode in
            return self.loginWithCode(barcode)
        }
    }
    
    @objc func decoderDataReceived(_ notification: Notification) {
        if let data = notification.userInfo?["data"] as? String {
            DispatchQueue.main.async {
                self.webView.evaluateJavaScript("onNativeScan('" + data + "')", completionHandler: nil)
            }
        }
    }
    
    func loginWithCode(_ code:String)
    {
        DispatchQueue.main.async {
            self.webView.evaluateJavaScript("onNativeDetected('" + code + "')", completionHandler: nil)
        }
    }
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage)
    {
        if(message.name == "callbackHandler") {
            if(message.body as? String == "qr-init"){
                self.present(barcodeView, animated:true)
            }
        }
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Swift.Void)
    {
        if(self.webView.url?.relativePath == loginPath && self.webView.url?.query?.contains("url=") != true){
            decisionHandler(.cancel)
            self.webView.load(URLRequest(url: self.defaultURL))
            return
        }
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView,didStart navigation: WKNavigation!) {
        activityIndicator.startAnimating()
    }
    
    public func webView(_ webView: WKWebView,didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
    }
    
    public func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Swift.Void) {
        if challenge.protectionSpace.host == "staging.judson.biz" {
            let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
