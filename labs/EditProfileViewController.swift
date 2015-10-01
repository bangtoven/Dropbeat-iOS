//
//  EditProfileViewController.swift
//  labs
//
//  Created by Jungho Bang on 2015. 10. 1..
//  Copyright © 2015년 dropbeat. All rights reserved.
//

import UIKit

enum ProfileDataType: Int {
    case NICKNAME = 0
    case ABOUT_ME
    case FAVORITE_GENRE
}

class EditProfileViewController: UITableViewController, ACEExpandableTableViewDelegate, UIActionSheetDelegate {

    var nickname: String!
    var aboutMe: String!
    
    @IBOutlet weak var saveBarButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:" ", style:.Plain, target:nil, action:nil)
        
        self.saveBarButton.enabled = false

        let account = Account.getCachedAccount()?.user
        self.nickname = account!.nickname
        self.aboutMe = account!.aboutMe
    }
    
    // MARK: - save changes
    
    private var isSubmitting = false
    
    @IBAction func saveAction(sender: UIBarButtonItem) {
        self.view.endEditing(true)
        
        if isSubmitting == false {
            syncProfileData()
        }
    }
    
    func syncProfileData() {
        let account = Account.getCachedAccount()?.user
        if self.nickname != account!.nickname {
            self.submitNickname()
        } else if self.aboutMe != account!.aboutMe {
            self.submitAboutMe()
        } else {
            self.performSegueWithIdentifier("unwindFromEditProfile", sender: nil)
        }
    }
    
    private var progressHud: MBProgressHUD!
    
    func submitNickname() {
        let newNickname = self.nickname
        if newNickname.characters.count == 0 {
            ViewUtils.showNoticeAlert(self,
                title: NSLocalizedString("Failed to change", comment:""),
                message: NSLocalizedString("Required Field", comment:""))
            return
        }
        if newNickname.characters.count > 25 {
            ViewUtils.showNoticeAlert(self,
                title: NSLocalizedString("Failed to change", comment:""),
                message:  NSString.localizedStringWithFormat(
                    NSLocalizedString("Must be less than %d characters long", comment:""), 25) as String)
            return
        }
        
        self.isSubmitting = true
        self.progressHud = ViewUtils.showProgress(self, message: "Nickname")
        
        Requests.changeNickname(newNickname, respCb: self.responseHandlerWith(
            onSuccess: {
                Account.getCachedAccount()!.user!.nickname = newNickname
            }, onFailure: {
                ViewUtils.showNoticeAlert(self,
                    title: NSLocalizedString("Failed to change", comment:""),
                    message: NSLocalizedString("Nickname already exists", comment:""))
        }))
    }
    
    func submitAboutMe () {
        let newAboutMe = self.aboutMe
        
        self.isSubmitting = true
        self.progressHud = ViewUtils.showProgress(self, message: "About me")

        Requests.changeAboutMe(newAboutMe, respCb: self.responseHandlerWith(
            onSuccess: {
                Account.getCachedAccount()!.user!.aboutMe = newAboutMe
        }))
    }
    
    private func responseHandlerWith(onSuccess onSuccess:(Void->Void), onFailure:(Void->Void)? = nil)
        -> RespCallback {
            return { (req:NSURLRequest, res:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
                
                if error != nil || result == nil {
                    self.progressHud.hide(true)
                    self.isSubmitting = false
                    if (error!.domain == NSURLErrorDomain && error!.code == NSURLErrorNotConnectedToInternet) {
                        ViewUtils.showConfirmAlert(self,
                            title: NSLocalizedString("Failed to change", comment:""),
                            message: NSLocalizedString("Internet is not connected", comment:""))
                    } else {
                        ViewUtils.showNoticeAlert(self,
                            title: NSLocalizedString("Failed to change", comment:""),
                            message: NSLocalizedString("Failed to change", comment:""))
                    }
                    return
                }
                
                if !(JSON(result!)["success"].bool ?? false) {
                    self.progressHud.hide(true)
                    self.isSubmitting = false
                    onFailure?()
                    return
                }
                
                self.progressHud.mode = MBProgressHUDMode.CustomView
                self.progressHud.customView = UIImageView(image: UIImage(named:"37x-Checkmark"))
                self.progressHud.hide(true, afterDelay: 1)
                self.isSubmitting = false
                let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1.0 * Double(NSEC_PER_SEC)));
                dispatch_after(popTime, dispatch_get_main_queue(), {() -> Void in
                    
                    onSuccess()
                    self.syncProfileData()
                    
                })
            }
    }
    
    // MARK: - cancel changes
    
    @IBAction func cancelAction(sender: UIBarButtonItem) {
        self.view.endEditing(true)
        
        let account = Account.getCachedAccount()?.user
        if self.nickname == account!.nickname && self.aboutMe == account!.aboutMe {
            self.navigationController?.popViewControllerAnimated(true)
        } else {
            UIActionSheet(
                title: NSLocalizedString("Your changes will be lost if you don’t save them.", comment:""),
                delegate: self,
                cancelButtonTitle: NSLocalizedString("Cancel", comment:""),
                destructiveButtonTitle: NSLocalizedString("Don't save", comment:"")
            ).showFromBarButtonItem(sender, animated: true)
        }
    }
    
    func actionSheet(actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int) {
        switch buttonIndex {
        case actionSheet.destructiveButtonIndex:
            self.navigationController?.popViewControllerAnimated(true)
        default:
            break
        }
    }
    
    // MARK: - contents
    
    func tableView(tableView: UITableView!, updatedText text: String!, atIndexPath indexPath: NSIndexPath!) {
        switch ProfileDataType(rawValue: indexPath.section)! {
        case .NICKNAME:
            if text.length <= 25 {
                self.nickname = text
            } else {
                self.nickname = text.subString(0, length: 25)
            }
        case .ABOUT_ME:
            self.aboutMe = text
        case .FAVORITE_GENRE:
            break
        }
        
        let account = Account.getCachedAccount()?.user
        if self.nickname != account!.nickname || self.aboutMe != account!.aboutMe {
            self.saveBarButton.enabled = true
        }
    }

    @IBAction func unwindFromEditFavoriteGenres(sender: UIStoryboardSegue) {
        self.saveBarButton.enabled = true
        self.tableView.reloadData()
    }
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch ProfileDataType(rawValue: section)! {
        case .NICKNAME:
            return "Nickname"
        case .ABOUT_ME:
            return "About me"
        case .FAVORITE_GENRE:
            return "Favorite genres"
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch ProfileDataType(rawValue: indexPath.section)! {
        case .NICKNAME:
            let cell = tableView.expandableTextCellWithId("cellId")
            cell.textView.placeholder = "Nickname"
            cell.text = self.nickname
            return cell
        case .ABOUT_ME:
            let cell = tableView.expandableTextCellWithId("cellId")
            cell.textView.placeholder = "About me"
            cell.text = self.aboutMe
            return cell
        case .FAVORITE_GENRE:
            let cell = tableView.dequeueReusableCellWithIdentifier("normalCell", forIndexPath: indexPath)
            cell.textLabel?.textColor = UIColor.grayColor()
            cell.textLabel?.text = NSString.localizedStringWithFormat(
                NSLocalizedString("%d genre is selected", comment:""), Account.getCachedAccount()?.favoriteGenreIds.count ?? 0) as String
            return cell
        }
        
    }
    
    var aboutMeCellHeight: CGFloat = 50
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == ProfileDataType.ABOUT_ME.rawValue {
            return max(self.aboutMeCellHeight, 50)
        } else {
            return 50
        }
    }
    
    func tableView(tableView: UITableView!, updatedHeight height: CGFloat, atIndexPath indexPath: NSIndexPath!) {
        if indexPath.section == ProfileDataType.ABOUT_ME.rawValue {
            self.aboutMeCellHeight = height
        }
    }
}
