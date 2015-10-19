//
//  FacebookPageViewController.swift
//  labs
//
//  Created by 방정호 on 2015. 10. 20..
//  Copyright © 2015년 dropbeat. All rights reserved.
//

import UIKit

class FacebookPageViewController: UIViewController, UIWebViewDelegate {

    @IBOutlet weak var webView: UIWebView!
    var url: NSURL!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = " "
        
        self.webView.hidden = true
        self.webView.loadRequest(NSURLRequest(URL: self.url))
        self.webView.delegate = self
    }
    
    @IBAction func back(sender: UIBarButtonItem) {
        if self.webView.canGoBack {
            self.webView.goBack()
        } else {
            self.navigationController?.popViewControllerAnimated(true)
        }
    }

    private var progressHud:MBProgressHUD?
    
    func webViewDidStartLoad(webView: UIWebView) {
        self.progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Loading..", comment:""))
    }
    
    private var loadingAppLink = false
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if request.URL?.scheme == "dropbeat" {
            print("loading!!!")
            self.loadingAppLink = true
        }
        return true
    }
    
    private var contentsStartingOffset: CGFloat?
    private var updateContentOffsetTimer: NSTimer?
    private var updateContentOffsetTryCount = 0
    
    func webViewDidFinishLoad(webView: UIWebView) {
        self.title = webView.stringByEvaluatingJavaScriptFromString("document.title")
        
        if self.contentsStartingOffset == nil {
            self.contentsStartingOffset = webView.scrollView.contentSize.height - 44
            if self.contentsStartingOffset < 830 {
                self.contentsStartingOffset = 830
            }
            
            self.updateContentOffsetTimer = NSTimer(
                timeInterval: 0.5,
                target: self,
                selector: "updateContentOffset",
                userInfo: nil,
                repeats: true)
            NSRunLoop.currentRunLoop().addTimer(updateContentOffsetTimer!, forMode: NSRunLoopCommonModes)
        } else {
            self.progressHud?.hide(true)
        }
        
        if self.loadingAppLink && webView.request?.URL?.host == "dropbeat.net" {
            self.contentsStartingOffset = nil
            self.webView.goBack()
            self.loadingAppLink = false
        }
    }
    
    func updateContentOffset() {
        self.updateContentOffsetTryCount++

        self.webView.stringByEvaluatingJavaScriptFromString("window.scrollTo(0,\(self.contentsStartingOffset!))")
        let offset = Float(self.webView.stringByEvaluatingJavaScriptFromString("window.scrollY") ?? "0")
        if self.updateContentOffsetTryCount == 10 || abs(offset! - Float(self.contentsStartingOffset!)) < 10 {
            print("Update offset try count: \(self.updateContentOffsetTryCount)")
            self.updateContentOffsetTimer?.invalidate()
            self.updateContentOffsetTimer = nil
            self.updateContentOffsetTryCount = 0
            
            self.webView.hidden = false
            self.progressHud?.hide(true)
        }
    }
    
}
