//
//  EditProfileViewController.swift
//  labs
//
//  Created by Jungho Bang on 2015. 10. 1..
//  Copyright © 2015년 dropbeat. All rights reserved.
//

import UIKit

class EditProfileViewController: UITableViewController, ACEExpandableTableViewDelegate {

    var cellHeight: CGFloat = 50

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:" ", style:.Plain, target:nil, action:nil)

    }
    
    @IBAction func saveAction(sender: AnyObject) {
        self.performSegueWithIdentifier("unwindFromEditProfile", sender: sender)
    }
    
    @IBAction func unwindFromEditFavoriteGenres(sender: UIStoryboardSegue) {
        print("unwindFromEditFavoriteGenres")
    }
    
    func tableView(tableView: UITableView!, updatedText text: String!, atIndexPath indexPath: NSIndexPath!) {
        print("\(indexPath.section): \(text)")
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
            return cell
        case 1:
            let cell = tableView.expandableTextCellWithId("cellId")
            cell.textView.placeholder = "About me"
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
        return max(self.cellHeight, 50)
    }
    
    func tableView(tableView: UITableView!, updatedHeight height: CGFloat, atIndexPath indexPath: NSIndexPath!) {
        self.cellHeight = height
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
