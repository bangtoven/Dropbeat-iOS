//
//  EditProfileViewController.swift
//  labs
//
//  Created by Jungho Bang on 2015. 10. 1..
//  Copyright © 2015년 dropbeat. All rights reserved.
//

import UIKit

class EditProfileViewController: UITableViewController, ACEExpandableTableViewDelegate, UIActionSheetDelegate {

    var aboutMeCellHeight: CGFloat = 44

    var nickname: String!
    var aboutMe: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:" ", style:.Plain, target:nil, action:nil)

        let account = Account.getCachedAccount()!
        self.nickname = account.user!.nickname
        self.aboutMe = account.user!.aboutMe
    }
    
    @IBAction func cancelAction(sender: UIBarButtonItem) {
        UIActionSheet(title: "걍 다 취소하려구?", delegate: self, cancelButtonTitle: "기다료봐", destructiveButtonTitle: "걍 다 꺼져").showFromBarButtonItem(sender, animated: true)
    }
    
    func actionSheet(actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int) {
        switch buttonIndex {
        case actionSheet.destructiveButtonIndex:
            self.navigationController?.popViewControllerAnimated(true)
        default:
            break
        }
    }
    
    @IBAction func saveAction(sender: UIBarButtonItem) {
        self.performSegueWithIdentifier("unwindFromEditProfile", sender: sender)
    }
    
    @IBAction func unwindFromEditFavoriteGenres(sender: UIStoryboardSegue) {
        print("unwindFromEditFavoriteGenres")
    }
    
    func tableView(tableView: UITableView!, updatedText text: String!, atIndexPath indexPath: NSIndexPath!) {
        switch indexPath.section {
        case 0:
            if text.length <= 25 {
                self.nickname = text
            } else {
                self.nickname = text.subString(0, length: 25)
            }
        case 1:
            self.aboutMe = text
        default:
            break
        }
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Nickname"
        case 1:
            return "About me"
        case 2:
            return "Favorite genres"
        default:
            return ""
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.expandableTextCellWithId("cellId")
            cell.textView.placeholder = "Nickname"
            cell.text = self.nickname
            return cell
        case 1:
            let cell = tableView.expandableTextCellWithId("cellId")
            cell.textView.placeholder = "About me"
            cell.text = self.aboutMe
            return cell
        case 2:
            let cell = tableView.dequeueReusableCellWithIdentifier("normalCell", forIndexPath: indexPath)
            return cell
        default:
            let cell = tableView.dequeueReusableCellWithIdentifier("normalCell", forIndexPath: indexPath)
            // Configure the cell...
            return cell
        }
        
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 1 {
            return max(self.aboutMeCellHeight, 44)
        } else {
            return 44
        }
    }
    
    func tableView(tableView: UITableView!, updatedHeight height: CGFloat, atIndexPath indexPath: NSIndexPath!) {
        if indexPath.section == 1 {
            self.aboutMeCellHeight = height
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
