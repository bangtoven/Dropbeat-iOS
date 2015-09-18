//
//  NickNameViewController.swift
//  labs
//
//  Created by Jungho Bang on 2015. 9. 9..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class NicknameViewController: BaseViewController, UITextFieldDelegate, UIScrollViewDelegate {
    
    @IBOutlet weak var scrollInnerViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollInnerView: UIView!
    @IBOutlet weak var scrollView: TPKeyboardAvoidingScrollView!
    @IBOutlet weak var submitBtn: UIButton!
    @IBOutlet weak var closeBtn: UIBarButtonItem!
    @IBOutlet weak var headerViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var headerView: UINavigationBar!
    @IBOutlet weak var nicknameInputView: UITextField!
    @IBOutlet weak var nicknameErrorView: UILabel!
    
    private var isSubmitting = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.navigationController != nil {
            headerView.hidden = true
            headerViewConstraint.constant = 0
        } else {
            headerView.hidden = false
        }
        let account = Account.getCachedAccount()!
        
        nicknameInputView.text = account.user!.nickname
        
        submitBtn.layer.cornerRadius = 3.0
        submitBtn.layer.borderColor = UIColor.dropbeatColor().CGColor
        submitBtn.layer.borderWidth = 1
        
        scrollInnerViewWidthConstraint.constant = view.bounds.width
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = "NicknameEditViewScreen"
    }
    
    override func viewDidAppear(animated: Bool) {
        nicknameInputView.becomeFirstResponder()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        scrollView.contentOffset = CGPointMake(0, scrollView.contentOffset.y)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        doSubmit()
        return true
    }
    
    @IBAction func onTapped(sender: AnyObject) {
        nicknameInputView.endEditing(true)
    }
    
    @IBAction func onSubmitBtnClicked(sender: AnyObject) {
        doSubmit()
    }
    
    @IBAction func onCloseBtnClicked(sender: AnyObject) {
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func doSubmit() {
        nicknameInputView.endEditing(true)
        if isSubmitting {
            return
        }
        let newNickname = nicknameInputView.text
        
        if let account = Account.getCachedAccount() {
            if newNickname == account.user!.nickname {
                nicknameErrorView.hidden = true
                return
            }
        }
        if !isValid(newNickname) {
            return
        }
        
        nicknameErrorView.hidden = true
        isSubmitting = true
        
        let progressHud = ViewUtils.showProgress(self, message: "")
        Requests.changeNickname(newNickname, respCb: { (req:NSURLRequest, res:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            if error != nil || result == nil {
                progressHud.hide(true)
                self.isSubmitting = false
                if (error != nil && error!.domain == NSURLErrorDomain &&
                    error!.code == NSURLErrorNotConnectedToInternet) {
                        
                        ViewUtils.showConfirmAlert(self,
                            title: NSLocalizedString("Failed to change", comment:""),
                            message: NSLocalizedString("Internet is not connected", comment:""),
                            positiveBtnText: NSLocalizedString("Retry", comment: ""),
                            positiveBtnCallback: { () -> Void in
                                self.doSubmit()
                        })
                        return
                }
                
                ViewUtils.showNoticeAlert(self,
                    title: NSLocalizedString("Failed to change", comment:""),
                    message: NSLocalizedString("Failed to change nickname", comment:""))
                return
            }
            
            let json = JSON(result!)
            if !(json["success"].bool ?? false) {
                self.isSubmitting = false
                progressHud.hide(true)
                self.nicknameErrorView.hidden = false
                self.nicknameErrorView.text = NSLocalizedString("Nickname already exists", comment:"")
                return
            }
            
            progressHud.mode = MBProgressHUDMode.CustomView
            progressHud.customView = UIImageView(image: UIImage(named:"37x-Checkmark"))
            progressHud.hide(true, afterDelay: 1)
            let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1.0 * Double(NSEC_PER_SEC)));
            dispatch_after(popTime, dispatch_get_main_queue(), {() -> Void in
                Account.getCachedAccount()!.user!.nickname = newNickname
                self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
            })
        })
    }
    
    func isValid(nickname:String) -> Bool {
        if count(nickname) == 0 {
            nicknameErrorView.text = NSLocalizedString("Required Field", comment:"")
            nicknameErrorView.hidden = false
            return false
        }
        if count(nickname) > 25 {
            nicknameErrorView.text = NSString.localizedStringWithFormat(
                NSLocalizedString("Must be less than %d characters long", comment:""), 25) as String
            nicknameErrorView.hidden = false
            return false
        }
        return true
    }
    
}
