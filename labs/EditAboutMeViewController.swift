//
//  EditAboutMeViewController.swift
//  labs
//
//  Created by Jungho Bang on 2015. 9. 23..
//  Copyright © 2015년 dropbeat. All rights reserved.
//

import UIKit

class EditAboutMeViewController: UITableViewController, ACEExpandableTableViewDelegate {

    var aboutMeText: String = ""
    var cellHeight: CGFloat = 50
    
    private var isSubmitting = false

    override func viewDidLoad() {
        super.viewDidLoad()
        let account = Account.getCachedAccount()!
        self.aboutMeText = account.user!.aboutMe
    }
    
    func tableView(tableView: UITableView!, updatedText text: String!, atIndexPath indexPath: NSIndexPath!) {
        self.aboutMeText = text
    }
    
    @IBAction func saveAction(sender: AnyObject) {
        self.doSubmit()
    }
    
    func doSubmit () {
        if isSubmitting {
            return
        }
        let newAboutMe = self.aboutMeText
        
        if let account = Account.getCachedAccount() {
            if newAboutMe == account.user!.aboutMe {
                return
            }
        }
        isSubmitting = true
        
        let progressHud = ViewUtils.showProgress(self, message: "")
        Requests.changeAboutMe(newAboutMe, respCb: { (req:NSURLRequest, res:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
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
            
            progressHud.mode = MBProgressHUDMode.CustomView
            progressHud.customView = UIImageView(image: UIImage(named:"37x-Checkmark"))
            progressHud.hide(true, afterDelay: 1)
            let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1.0 * Double(NSEC_PER_SEC)));
            dispatch_after(popTime, dispatch_get_main_queue(), {() -> Void in
                Account.getCachedAccount()!.user!.aboutMe = newAboutMe
                self.performSegueWithIdentifier("unwindFromEditAboutMe", sender: nil)
            })
        })
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.expandableTextCellWithId("cellId")
        cell.textView.placeholder = "about me"
        cell.text = self.aboutMeText
        
        return cell
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return max(self.cellHeight, 50)
    }
    
    func tableView(tableView: UITableView!, updatedHeight height: CGFloat, atIndexPath indexPath: NSIndexPath!) {
        self.cellHeight = height
    }
}
