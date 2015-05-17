//
//  LeftSideViewController.swift
//  labs
//
//  Created by vulpes on 2015. 5. 15..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//
import UIKit
import MMDrawerController

class LeftSideViewController: UIViewController, UITableViewDataSource, UITableViewDelegate{
    
    static let MENU_FEED = 0;
    static let MENU_SEARCH = 1;
    static let MENU_SETTINGS = 2;
    
    var nonAuthMeuItems:[String] = ["Feed", "Search", "Settings"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func tableView(tableView: UITableView,
            numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(tableView: UITableView,
            cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(
                    "SideMenuCell", forIndexPath: indexPath) as! SideMenuTableViewCell
        cell.menuItemLabel.text = nonAuthMeuItems[indexPath.row]
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var appDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        var centerNav:UINavigationController = appDelegate.centerContainer!.centerViewController as! UINavigationController
        var centerViewController:CenterViewController = centerNav.visibleViewController as! CenterViewController
        centerViewController.onMenuSelected(indexPath.row)
        appDelegate.centerContainer!.toggleDrawerSide(MMDrawerSide.Left, animated: true, completion: nil)
    }
}
