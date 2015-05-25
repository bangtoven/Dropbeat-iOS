//
//  LeftSideViewController.swift
//  labs
//
//  Created by vulpes on 2015. 5. 15..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//
import UIKit

enum MenuType:Int{
    case FEED
    case SEARCH
    case SETTINGS
}

class MenuItem {
    var name:String
    var iconName:String
    var hightlightIconName:String
    var type:MenuType
    
    init(name:String, iconName:String, hightlightIconName:String, type:MenuType) {
        self.name = name
        self.iconName = iconName
        self.hightlightIconName = hightlightIconName
        self.type = type
    }
}

class LeftSideViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate{
    var currentMenu:MenuItem?
    var menuItems:Array<MenuItem>?
    
    private let authMenuItems = [
        MenuItem(name: "FEED", iconName: "home-100.png", hightlightIconName: "home-100-hi.png", type: MenuType.FEED),
        MenuItem(name: "SEARCH", iconName: "search-100.png", hightlightIconName: "search-100-hi.png", type: MenuType.SEARCH),
        MenuItem(name: "SETTINGS", iconName: "settings-100.png", hightlightIconName: "settings-100-hi.png", type: MenuType.SETTINGS),
    ]
    
    private let nonauthMenuItems = [
        MenuItem(name: "FEED", iconName: "home-100.png", hightlightIconName: "home-100-hi.png", type: MenuType.FEED),
        MenuItem(name: "SEARCH", iconName: "search-100.png", hightlightIconName: "search-100-hi.png", type: MenuType.SEARCH),
        MenuItem(name: "SETTINGS", iconName: "settings-100.png", hightlightIconName: "settings-100-hi.png", type: MenuType.SETTINGS),
    ]
    
    
    
    @IBOutlet weak var accountView: UIView!
    @IBOutlet weak var signinBtn: UIButton!
    @IBOutlet weak var accountPhotoView: UIImageView!
    @IBOutlet weak var accountEmailView: UILabel!
    @IBOutlet weak var nameView: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        if (appDelegate.account != nil) {
            menuItems = authMenuItems
            accountView.hidden = false
            signinBtn.hidden = true
            let account = appDelegate.account!
            nameView.text = "\(account.user!.firstName) \(account.user!.lastName)"
            accountEmailView.text = appDelegate.account!.user!.email
            
            let profileUrl = "https://graph.facebook.com/\(appDelegate.account!.user!.fbId)/picture?type=small"
            accountPhotoView.sd_setImageWithURL(NSURL(string:profileUrl),
                placeholderImage: UIImage(named: "default_profile.png"))
        } else {
            menuItems = nonauthMenuItems
            accountView.hidden = true
            signinBtn.hidden = false
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = "leftSideScreen"
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
        cell.menuItemIcon.highlightedImage = UIImage(named: menuItem.hightlightIconName)
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
        drawerContainer.closeDrawerAnimated(true, completion: nil)
//        drawerContainer!.toggleDrawerSide(MMDrawerSide.Left, animated: true, completion: nil)
    }
    
    @IBAction func onSigninBtnClicked(sender: AnyObject) {
        var appDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        var centerViewController = appDelegate.centerContainer!.centerViewController as! CenterViewController
        centerViewController.showSigninView()
    }
}
