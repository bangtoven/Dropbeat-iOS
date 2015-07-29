//
//  SettingsViewController.swift
//  labs
//
//  Created by vulpes on 2015. 5. 15..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {

    @IBOutlet weak var versionView: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let verObject: AnyObject? = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"]
        versionView.text = verObject as? String

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
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
        ViewUtils.showConfirmAlert(self, title: "Are you sure?", message: "Are you sure you want to sign out?",
                positiveBtnText: "Sign out", positiveBtnCallback: { () -> Void in
            NSNotificationCenter.defaultCenter().postNotificationName(NotifyKey.appSignout, object: nil)
            Account.signout()
        })
    }
    
}
