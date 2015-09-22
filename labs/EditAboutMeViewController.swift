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
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func tableView(tableView: UITableView!, updatedText text: String!, atIndexPath indexPath: NSIndexPath!) {
        self.aboutMeText = text
    }
    
    @IBAction func saveAction(sender: AnyObject) {
        self.performSegueWithIdentifier("unwindFromEditAboutMe", sender: nil)
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
        
        return cell
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return max(self.cellHeight, 50)
    }
    
    func tableView(tableView: UITableView!, updatedHeight height: CGFloat, atIndexPath indexPath: NSIndexPath!) {
        self.cellHeight = height
    }
}
