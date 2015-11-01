//
//  EmailSubmitViewController.swift
//  labs
//
//  Created by Jungho Bang on 2015. 9. 9..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

//
//  FBEmailSubmitViewController.swift
//  labs
//
//  Created by vulpes on 2015. 8. 23..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

protocol FBEmailSubmitViewControllerDelegate {
    func onAfterEmailUpdate()
}

class FBEmailSubmitViewController: BaseViewController, UITextFieldDelegate, UIScrollViewDelegate {
    
    @IBOutlet weak var scrollInnerWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollView: TPKeyboardAvoidingCollectionView!
    @IBOutlet weak var submitBtn: UIButton!
    @IBOutlet weak var emailErrorView: UILabel!
    @IBOutlet weak var emailInputView: UITextField!
    
    private var isSubmitting = false
    var delegate:FBEmailSubmitViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        submitBtn.layer.borderWidth = 1
        submitBtn.layer.borderColor = UIColor.dropbeatColor().CGColor
        submitBtn.layer.cornerRadius = 3.0
        
        scrollInnerWidthConstraint.constant = view.bounds.width
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = "FBEmailSubmitViewScreen"
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        doSubmit()
        return true
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        scrollView.contentOffset = CGPointMake(0, scrollView.contentOffset.y)
    }
    
    @IBAction func onTapped(sender: AnyObject) {
        emailInputView.endEditing(true)
    }
    
    @IBAction func onSubmitBtnClicked(sender: AnyObject) {
        doSubmit()
    }
    
    func doSubmit() {
        emailInputView.endEditing(true)
        if isSubmitting {
            return
        }
        let email = emailInputView.text
        emailErrorView.hidden = true
        if email!.characters.count == 0 {
            emailErrorView.hidden = false
            emailErrorView.text = NSLocalizedString("Required Field", comment:"")
        } else if !Utils.isValidEmail(email!) {
            emailErrorView.hidden = false
            emailErrorView.text = NSLocalizedString("Invalid email format", comment:"")
        } else if email!.indexOf("@dropbeat.net") > -1 {
            emailErrorView.hidden = false
            emailErrorView.text = NSLocalizedString("Invalid email domain", comment:"")
        }
        
        if !emailErrorView.hidden {
            return
        }
        isSubmitting = true
        let progressHud = ViewUtils.showProgress(self, message: "")
        Requests.userChangeEmail(email!) {(result, error) -> Void in
            self.isSubmitting = false
            if error != nil || result == nil {
                progressHud.hide(true)
                self.showErrorAlert(error)
                return
            }
            if !(result!["success"].bool ?? false) {
                progressHud.hide(true)
                self.emailErrorView.text = NSLocalizedString("Email already exist", comment:"")
                self.emailErrorView.hidden = false
                return
            }
            
            Account.getCachedAccount()!.user!.email = email!
            
            progressHud.mode = MBProgressHUDMode.CustomView
            progressHud.customView = UIImageView(image: UIImage(named:"37x-Checkmark"))
            progressHud.hide(true, afterDelay: 1)
            
            let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1.0 * Double(NSEC_PER_SEC)));
            dispatch_after(popTime, dispatch_get_main_queue(), {() -> Void in
                self.delegate?.onAfterEmailUpdate()
            })
        }
    }
    
    func showErrorAlert(error:NSError?) {
        var message:String!
        if (error != nil && error!.domain == NSURLErrorDomain &&
            error!.code == NSURLErrorNotConnectedToInternet) {
                message = NSLocalizedString("Internet is not connected", comment:"")
        } else {
            message = NSLocalizedString("Failed to set email", comment:"")
        }
        
        ViewUtils.showConfirmAlert(self,
            title: NSLocalizedString("Failed to submit", comment:""),
            message: message,
            positiveBtnText: NSLocalizedString("Retry", comment:""),
            positiveBtnCallback: { () -> Void in
                self.doSubmit()
        })
        return
    }
}