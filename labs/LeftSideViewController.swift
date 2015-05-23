//
//  LeftSideViewController.swift
//  labs
//
//  Created by vulpes on 2015. 5. 15..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//
import UIKit
import MMDrawerController

enum MenuType:Int{
    case FEED
    case SEARCH
    case SETTINGS
}

class MenuItem {
    var name:String
    var iconName:String
    var type:MenuType
    
    init(name:String, iconName:String, type:MenuType) {
        self.name = name
        self.iconName = iconName
        self.type = type
    }
}

class LeftSideViewController: UIViewController, UITableViewDataSource, UITableViewDelegate{
    var currentMenu:MenuItem?
    var menuItems:Array<MenuItem>?
    
    private let authMenuItems = [
        MenuItem(name: "FEED", iconName: "home-100.png", type: MenuType.FEED),
        MenuItem(name: "SEARCH", iconName: "search-100.png", type: MenuType.SEARCH),
        MenuItem(name: "SETTINGS", iconName: "settings-100.png", type: MenuType.SETTINGS),
    ]
    
    private let nonauthMenuItems = [
        MenuItem(name: "FEED", iconName: "home-100.png", type: MenuType.FEED),
        MenuItem(name: "SEARCH", iconName: "search-100.png", type: MenuType.SEARCH),
        MenuItem(name: "SETTINGS", iconName: "settings-100.png", type: MenuType.SETTINGS),
    ]
    
    
    
    @IBOutlet weak var accountView: UIView!
    @IBOutlet weak var signinBtn: UIButton!
    @IBOutlet weak var accountPhotoView: UIImageView!
    @IBOutlet weak var accountEmailView: UILabel!
    @IBOutlet weak var nameView: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.navigationBar.translucent = false
        
        let appDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        if (appDelegate.account != nil) {
            menuItems = authMenuItems
            accountView.hidden = false
            signinBtn.hidden = true
            let account = appDelegate.account!
            nameView.text = "\(account.user!.firstName) \(account.user!.lastName)"
            accountEmailView.text = appDelegate.account!.user!.email
            let profileUrl = "https://graph.facebook.com/\(appDelegate.account!.user!.fbId)/picture?type=small"
            let profileData = NSData(contentsOfURL: NSURL(string: profileUrl)!)
            if (profileData == nil) {
                accountPhotoView.image = UIImage(named: "default_profile.png")
            } else {
                accountPhotoView.image = UIImage(data: profileData!)
            }
        } else {
            menuItems = nonauthMenuItems
            accountView.hidden = true
            signinBtn.hidden = false
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func tableView(tableView: UITableView,
            numberOfRowsInSection section: Int) -> Int {
        return menuItems!.count
    }
    
    func tableView(tableView: UITableView,
            cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(
                    "SideMenuCell", forIndexPath: indexPath) as! SideMenuTableViewCell
        let menuItem = menuItems![indexPath.row]
        cell.menuItemIcon.image = UIImage(named: menuItem.iconName)
        cell.menuItemLabel.text = menuItem.name
                
        if (currentMenu == nil) {
            tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: UITableViewScrollPosition.None)
            tableView.delegate?.tableView!(tableView, didSelectRowAtIndexPath: indexPath)
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        currentMenu = menuItems![indexPath.row]
        let drawerContainer = self.mm_drawerController
        var centerViewController = drawerContainer.centerViewController as! CenterViewController
        centerViewController.onMenuSelected(currentMenu!.type)
        drawerContainer!.toggleDrawerSide(MMDrawerSide.Left, animated: true, completion: nil)
    }
    
    @IBAction func onSigninBtnClicked(sender: AnyObject) {
        var appDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        var centerViewController = appDelegate.centerContainer!.centerViewController as! CenterViewController
        centerViewController.showSigninView()
    }
}
