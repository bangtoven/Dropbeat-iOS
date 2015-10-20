//
//  FacebookPageViewController.swift
//  labs
//
//  Created by 방정호 on 2015. 10. 20..
//  Copyright © 2015년 dropbeat. All rights reserved.
//

import UIKit

extension NSURL {
    func isSamePage(url: NSURL?) -> Bool {
        if url == nil {
            return false
        }
        
        var absoluteUrlString = url!.absoluteString
        let index = absoluteUrlString.indexOf("#")
        if index != -1 {
            absoluteUrlString = absoluteUrlString.subString(0, length: index)
        }
        
        return absoluteUrlString == self.absoluteString
    }
}

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
        if self.url.isSamePage(request.URL) && (self.url.isSamePage(webView.request?.URL) == false) {
            print("Reload root page.")
            self.didUpdateContentOffset = false
        }
        
        let contentOffset = Int(webView.stringByEvaluatingJavaScriptFromString("window.scrollY") ?? "0")!
        if contentOffset != 0 {
            self.lastContentOffset = contentOffset
        }
        
        if request.URL?.scheme == "dropbeat" {
            print("loading!!!")
            self.loadingAppLink = true
        }
        return true
    }
    
    private var lastContentOffset = 0
    private var didUpdateContentOffset = false
    private var updateContentOffsetTimer: NSTimer?
    private var updateContentOffsetTryCount = 0
    
    func webViewDidFinishLoad(webView: UIWebView) {
        self.title = webView.stringByEvaluatingJavaScriptFromString("document.title")
        
        if self.didUpdateContentOffset != true {
            if self.updateContentOffsetTimer == nil {
                self.updateContentOffsetTimer = NSTimer(
                    timeInterval: 0.5,
                    target: self,
                    selector: "updateContentOffset",
                    userInfo: nil,
                    repeats: true)
                NSRunLoop.currentRunLoop().addTimer(updateContentOffsetTimer!, forMode: NSRunLoopCommonModes)
            }
        } else {
            self.progressHud?.hide(true)
        }
        
        if self.loadingAppLink && webView.request?.URL?.host == "dropbeat.net" {
            self.webView.goBack()
            self.loadingAppLink = false
        }
    }
    
    func updateContentOffset() {
        self.updateContentOffsetTryCount++
        
        if self.updateContentOffsetTryCount > 10 {
            print("Tried too many times.")
        }
        else if self.lastContentOffset == 0 {
            let article = self.webView.stringByEvaluatingJavaScriptFromString("document.getElementsByTagName('article')[0].id")
            
            if article != nil && article!.isEmpty == false {
                print("Update offset try count: \(self.updateContentOffsetTryCount)")
                self.webView.stringByEvaluatingJavaScriptFromString("location.href = '#\(article!)'")
            } else {
                let offsetString = "document.body.scrollHeight"
                print("scroll to: \(offsetString)")
                webView.stringByEvaluatingJavaScriptFromString("window.scrollTo(0,\(offsetString))")
                return // try again
            }
        } else {
            let offsetString = String(lastContentOffset)
            print("scroll to: \(offsetString)")
            webView.stringByEvaluatingJavaScriptFromString("window.scrollTo(0,\(offsetString))")
            
            let contentOffset = Int(webView.stringByEvaluatingJavaScriptFromString("window.scrollY") ?? "0")!
            if contentOffset == self.lastContentOffset {
                print("Update offset try count: \(self.updateContentOffsetTryCount)")
            } else {
                return // try again
            }
        }
        
        self.webView.hidden = false
        self.updateContentOffsetTimer?.invalidate()
        self.updateContentOffsetTimer = nil
        self.updateContentOffsetTryCount = 0
        self.didUpdateContentOffset = true
        self.progressHud?.hide(true)
    }
}
