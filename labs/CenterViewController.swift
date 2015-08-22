//
//  CenterViewController.swift
//  labs
//
//  Created by vulpes on 2015. 5. 15..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

enum MenuType {
    case FEED
    case CHANNEL
    case SEARCH
    case PROFILE
    case PLAYER
}

class CenterViewController: PlayerViewController, UITabBarDelegate{
    
    static let TAB_FEED = 1
    static let TAB_CHANNEL = 2
//    static let TAB_SEARCH = 3
    static let TAB_PROFILE = 4
    static let TAB_PLAYER = 5
    
    @IBOutlet weak var containerFrame: UIView!
    @IBOutlet weak var containerTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var containerTopPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerTopPaddingPlaceholderHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var tabBarBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var tabBarHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var playerViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var menuBtn: UIButton!
    @IBOutlet weak var hideBtn: UIButton!
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var tabBar: UITabBar!
    
    var currentMenu:MenuType = MenuType.FEED
    var isPlayerVisible:Bool = false
    
    private var activeViewController: UIViewController? {
        didSet {
            removeInactiveViewController(oldValue)
            updateActiveViewController()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        hideBtn.layer.cornerRadius = 3.0
        hideBtn.layer.borderWidth = 1
        hideBtn.layer.borderColor = UIColor(netHex: 0x4f525a).CGColor
        
        menuBtn.layer.cornerRadius = 3.0
        menuBtn.layer.borderWidth = 1
        menuBtn.layer.borderColor = UIColor(netHex: 0x4f525a).CGColor
    
        initConstaints()
        
        // set first item
        let firstTab:UITabBarItem = tabBar.items![menuTypeToTabIdx(currentMenu)] as! UITabBarItem
        tabBar.selectedItem = firstTab
        onMenuSelected(currentMenu, forceUpdate:true)
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        loadSharedTrackIfExist()
        loadSharedPlaylistIfExist()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = "CenterViewScreen"
        
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "loadSharedTrackIfExist", name: NotifyKey.trackShare, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "loadSharedPlaylistIfExist", name: NotifyKey.playlistShare, object: nil)
        setNeedsStatusBarAppearanceUpdate()
    }
    
    func loadSharedTrackIfExist() {
        var appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        if appDelegate.sharedTrackUid == nil {
            return
        }
        
        let progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Loading..", comment:""))
        Requests.getSharedTrack(appDelegate.sharedTrackUid!, respCb: {
                (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            
            progressHud.hide(true)
            var success:Bool = true
            var track:Track?
            
            if error != nil || result == nil {
                success = false
            } else {
                let parser = Parser()
                track = parser.parseSharedTrack(result!)
                if track == nil {
                    success = false
                }
            }
            
            if !success {
                ViewUtils.showNoticeAlert(
                    self,
                    title: NSLocalizedString("Failed to load", comment:""),
                    message: NSLocalizedString("Failed to load shared track", comment:""),
                    btnText: NSLocalizedString("Confirm", comment:""),
                    callback: nil)
                return
            }
            
            var params: [String: AnyObject] = [
                "track": track!,
            ]
            NSNotificationCenter.defaultCenter().postNotificationName(
                NotifyKey.playerPlay, object: params)
        })
        appDelegate.sharedTrackUid = nil
    }
    
    func loadSharedPlaylistIfExist() {
        var appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        if appDelegate.sharedPlaylistUid == nil {
            return
        }
        
        let progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Loading..", comment:""))
        Requests.getSharedPlaylist(appDelegate.sharedPlaylistUid!, respCb: {
                (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            
            var success:Bool = true
            var playlist:Playlist?
            
            if error != nil || result == nil {
                success = false
            } else {
                let parser = Parser()
                playlist = parser.parseSharedPlaylist(result!)
                if playlist == nil {
                    success = false
                }
            }
            
            if !success {
                ViewUtils.showNoticeAlert(
                    self,
                    title: NSLocalizedString("Failed to load", comment:""),
                    message: NSLocalizedString("Failed to load shared playlist", comment:""),
                    btnText: NSLocalizedString("Confirm", comment:""),
                    callback: nil)
                progressHud.hide(true)
                return
            }
            
            playlist!.type = PlaylistType.SHARED
            progressHud.hide(true)
            self.performSegueWithIdentifier("PlaylistSegue", sender: playlist)
        })
        appDelegate.sharedPlaylistUid = nil
    }
    
    func initConstaints() {
//        let statusBarHeight = UIApplication.sharedApplication().statusBarFrame.size.height
        let statusBarHeight:CGFloat = 20.0
        containerHeightConstraint.constant = self.view.bounds.size.height
            - tabBarHeightConstraint.constant
        
        containerTopPaddingConstraint.constant = -statusBarHeight
        containerTopPaddingPlaceholderHeightConstraint.constant = statusBarHeight
        
        playerViewHeightConstraint.constant = self.view.bounds.size.height
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.None)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.trackShare, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.playlistShare, object: nil)
    }
    
    override func remotePlay(noti: NSNotification) {
        super.remotePlay(noti)
        showPlayerView()
    }
    
    func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem!) {
        let menuType:MenuType? = tabTagToMenuType(item.tag)
        if menuType != nil {
            onMenuSelected(menuType!)
        }
    }
    
    func onMenuSelected(type:MenuType, forceUpdate:Bool=false) {
        if !forceUpdate && currentMenu == type {
            return
        }
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        switch(type) {
        case .FEED:
            activeViewController = mainStoryboard
                .instantiateViewControllerWithIdentifier("FeedNavigationController")
                as? UIViewController
            break
        case .CHANNEL:
            activeViewController = mainStoryboard
                .instantiateViewControllerWithIdentifier("ChannelNavigationController")
                as? UIViewController
            break
        case .SEARCH:
            activeViewController = mainStoryboard
                .instantiateViewControllerWithIdentifier("SearchNavigationController")
                as? UIViewController
            break
        case .PROFILE:
            if Account.getCachedAccount() == nil {
//                performSegueWithIdentifier("need_auth", sender: nil)
//                let lastTab:UITabBarItem = tabBar.items![menuTypeToTabIdx(currentMenu)] as! UITabBarItem
//                tabBar.selectedItem = lastTab
//                break
                activeViewController = mainStoryboard
                    .instantiateViewControllerWithIdentifier("SettingsNavigationController")
                    as? UIViewController
            } else {
                activeViewController = mainStoryboard
                    .instantiateViewControllerWithIdentifier("ProfileNavigationController")
                    as? UIViewController
            }
            break
        case .PLAYER:
            showPlayerView()
            let lastTab:UITabBarItem = tabBar.items![menuTypeToTabIdx(currentMenu)] as! UITabBarItem
            tabBar.selectedItem = lastTab
            break
        default:
            break
        }
        if type != MenuType.PLAYER {
            currentMenu = type
        }
    }
    
    func tabTagToMenuType (tag:Int) -> MenuType? {
        var menuType:MenuType?
        switch(tag) {
        case CenterViewController.TAB_FEED:
            menuType = MenuType.FEED
            break
        case CenterViewController.TAB_CHANNEL:
            menuType = MenuType.CHANNEL
            break
        case CenterViewController.TAB_PROFILE:
            menuType = MenuType.PROFILE
            break
        case CenterViewController.TAB_PLAYER:
            menuType = MenuType.PLAYER
            break
        default:
            break
        }
        return menuType
    }
    
    func menuTypeToTabIdx (type:MenuType) -> Int {
        var idx : Int
        switch(type) {
        case .FEED:
            return 0
        case .CHANNEL:
            return 1
        case .PROFILE:
            return 2
        case .PLAYER:
            return 3
        default:
            return 0
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return isPlayerVisible
    }
    
    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return UIStatusBarAnimation.None
    }
    
    func showPlayerView() {
        isPlayerVisible = true
        setNeedsStatusBarAppearanceUpdate()
        self.view.layoutIfNeeded()
        UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: { () -> Void in
            self.containerTopConstraint.constant = 3 - self.containerHeightConstraint.constant
            self.tabBarBottomConstraint.constant = -1 * self.tabBarHeightConstraint.constant
            self.tabBar.alpha = 0.0
            self.view.layoutIfNeeded()
        }) { (Bool) -> Void in
        }
    }
    
    func hidePlayerView() {
        self.view.layoutIfNeeded()
        
        isPlayerVisible = false
        setNeedsStatusBarAppearanceUpdate()
        UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: { () -> Void in
//            let statusBarHeight = UIApplication.sharedApplication().statusBarFrame.size.height
            let statusBarHeight:CGFloat = 20.0
            self.containerTopConstraint.constant = -1 * statusBarHeight
            self.tabBarBottomConstraint.constant = 0
            self.tabBar.alpha = 1.0
            self.view.layoutIfNeeded()
        }) { (Bool) -> Void in
        }
    }
    
    func showSigninView() {
        performSegueWithIdentifier("need_auth", sender: nil)
    }
    
    private func removeInactiveViewController(inactiveViewController:UIViewController?) {
        if let inactiveVC = inactiveViewController {
            inactiveVC.willMoveToParentViewController(nil)
            inactiveVC.view.removeFromSuperview()
            inactiveVC.removeFromParentViewController()
        }
    }
    
    private func updateActiveViewController() {
        if let activeVC = activeViewController {
            // call before adding child view controller's view as subview
            addChildViewController(activeVC)
            
            activeVC.view.frame = containerFrame.bounds
            containerFrame.addSubview(activeVC.view)
            
            // call before adding child view controller's view as subview
            activeVC.didMoveToParentViewController(self)
        }
    }
    
    @IBAction func onHidePlayerViewBtnClicked(sender: AnyObject) {
        hidePlayerView()
    }
}
