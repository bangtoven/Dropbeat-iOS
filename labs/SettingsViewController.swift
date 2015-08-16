//
//  SettingsViewController.swift
//  labs
//
//  Created by vulpes on 2015. 5. 15..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {

    @IBOutlet weak var signoutBtn: UIButton!
    @IBOutlet weak var signinBtn: UIButton!
    @IBOutlet weak var versionView: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if Account.getCachedAccount() != nil {
            signinBtn.hidden = true
            signoutBtn.hidden = false
        } else {
            signinBtn.hidden = false
            signoutBtn.hidden = true
        }
        
        var signinBgImage = UIImage(named: "facebook_btn_bg.png")
        signinBgImage = signinBgImage!.resizableImageWithCapInsets(UIEdgeInsetsMake(14, 14, 14, 14))
        signinBtn.setBackgroundImage(signinBgImage, forState: UIControlState.Normal)
        
        let verObject: AnyObject? = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"]
        versionView.text = verObject as? String

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "sender", name: NotifyKey.appSignout, object: nil)
        if tableView.indexPathForSelectedRow() != nil {
            tableView.deselectRowAtIndexPath(tableView.indexPathForSelectedRow()!, animated: false)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.appSignout, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func sender() {
    }
    
    @IBAction func onSignoutBtnClicked(sender: UIButton) {
        ViewUtils.showConfirmAlert(self,
            title: NSLocalizedString("Are you sure?", comment:""),
            message: NSLocalizedString("Are you sure you want to sign out?", comment:""),
                positiveBtnText: NSLocalizedString("Sign out", comment:""), positiveBtnCallback: { () -> Void in
            NSNotificationCenter.defaultCenter().postNotificationName(NotifyKey.appSignout, object: nil)
            Account.signout()
        })
    }
    
    
    @IBAction func onSigninBtnClicked(sender: AnyObject) {
        var appDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        var centerViewController = appDelegate.centerContainer!
        centerViewController.showSigninView()
    }
}
