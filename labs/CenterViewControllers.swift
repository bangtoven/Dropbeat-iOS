//
//  CenterViewController.swift
//  labs
//
//  Created by vulpes on 2015. 5. 15..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

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
    static let TAB_SEARCH = 3
    static let TAB_PROFILE = 4
    static let TAB_PLAYER = 5
    
    @IBOutlet weak var containerFrame: UIView!
    
    @IBOutlet weak var menuBtn: UIButton!
    @IBOutlet weak var hideBtn: UIButton!
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var tabBar: UITabBar!
    
    private var currentMenu:MenuType = MenuType.FEED
    private var isPlayerVisible:Bool = false
    
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
        
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.None)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = "CenterViewScreen"
        
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "loadSharedTrackIfExist", name: NotifyKey.trackShare, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "loadSharedPlaylistIfExist", name: NotifyKey.playlistShare, object: nil)
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

                track = Track.parseSharedTrack(result!)
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
                "section": "shared_track"
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
                playlist = Playlist.parseSharedPlaylist(result!)
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
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.trackShare, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.playlistShare, object: nil)
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
        switch(type) {
        case .FEED:
            activeViewController = UIStoryboard(name: "Feed", bundle: nil).instantiateInitialViewController() as? UIViewController
            break
        case .CHANNEL:
            activeViewController = UIStoryboard(name: "Channel", bundle: nil).instantiateInitialViewController() as? UIViewController
            break
        case .SEARCH:
            activeViewController = UIStoryboard(name: "Main", bundle: nil)
                .instantiateViewControllerWithIdentifier("SearchNavigationController")
                as? UIViewController
            break
        case .PROFILE:
            if Account.getCachedAccount() == nil {
                activeViewController = UIStoryboard(name: "Settings", bundle: nil).instantiateInitialViewController() as? UIViewController
            } else {
                activeViewController = UIStoryboard(name: "Profile", bundle: nil).instantiateInitialViewController() as? UIViewController
            }
            break
        case .PLAYER:
            activeViewController = UIStoryboard(name: "Playground", bundle: nil).instantiateInitialViewController() as? UIViewController
//            showTabBarPlayer(!self.isTabBarPlayerVisible)
//            showPlayerView()
//            let lastTab:UITabBarItem = tabBar.items![menuTypeToTabIdx(currentMenu)] as! UITabBarItem
//            tabBar.selectedItem = lastTab
            break
        default:
            break
        }
//        if type != MenuType.PLAYER {
            currentMenu = type
//        }
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
        case CenterViewController.TAB_SEARCH:
            menuType = MenuType.SEARCH
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
        case .SEARCH:
            return 2
        case .PROFILE:
            return 3
        case .PLAYER:
            return 4
        default:
            return 0
        }
    }
    
// MARK: PlayerView Show/Hide Layout
    @IBOutlet weak var containerTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var tabBarContainerView: UIView!
    @IBOutlet weak var tabBarTopInsetConstraint: NSLayoutConstraint!
    @IBOutlet weak var tabBarBottomConstraint: NSLayoutConstraint!

    @IBOutlet weak var tabBarBorder: UIView!
    @IBOutlet weak var tabBarBorderHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var tabBarProgressBar: UIProgressView!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var trackInfoLabel: UILabel!
    
    func initConstaints() {
        self.tabBarTopInsetConstraint.constant = 0
        self.view.layoutIfNeeded()
        
        self.containerTopConstraint.constant = 0
        self.containerBottomConstraint.constant = self.tabBarContainerView.frame.height
    }
    
    private var isTabBarPlayerVisible:Bool = false
    
    func showTabBarPlayer(visible:Bool) {
        if (visible == self.isTabBarPlayerVisible) {
            return
        }
        
        UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: { () -> Void in
            
            if (visible) {
                self.tabBarTopInsetConstraint.constant = 41
                self.tabBarBorderHeightConstraint.constant = 0.5
                self.tabBarBorder.backgroundColor = UIColor.lightGrayColor()
            }
            else {
                self.tabBarTopInsetConstraint.constant = 0
                self.tabBarBorderHeightConstraint.constant = 2
                self.tabBarBorder.backgroundColor = UIColor(red: 122/255.0, green: 29/255.0, blue: 236/255.0, alpha: 1.0)
            }
            self.view.layoutIfNeeded()
            
            self.containerBottomConstraint.constant = self.tabBarContainerView.frame.height
            self.view.layoutIfNeeded()
            
            }) { (Bool) -> Void in
        }
        
        self.isTabBarPlayerVisible = visible
    }
    
    override func remotePause() {
        super.remotePause()
        showTabBarPlayer(false)
    }
    
    override func resumePlay() {
        super.resumePlay()
        if (PlayerContext.currentTrack != nil) {
            println("resume with current track. show tab bar player")
            showTabBarPlayer(true)
            super.playBtnClicked(nil)
        }
        else {
            println("resume without current track")
        }
    }
    
    override func updatePlayView() {
        super.updatePlayView()
        
        if (PlayerContext.playState == PlayState.LOADING ||
            PlayerContext.playState == PlayState.SWITCHING ||
            PlayerContext.playState == PlayState.BUFFERING) {
                showTabBarPlayer(true)
                self.playPauseButton.enabled = false
                self.playPauseButton.setImage(UIImage(named: "ic_play_purple.png"), forState: UIControlState.Normal)
                self.trackInfoLabel.textColor = UIColor.lightGrayColor()
        } else if (PlayerContext.playState == PlayState.PAUSED) {
            showTabBarPlayer(true)
            self.playPauseButton.enabled = true
            self.playPauseButton.setImage(UIImage(named: "ic_play_purple.png"), forState: UIControlState.Normal)
            self.trackInfoLabel.textColor = UIColor.darkGrayColor()
        } else if (PlayerContext.playState == PlayState.PLAYING) {
            showTabBarPlayer(true)
            self.playPauseButton.enabled = true
            self.playPauseButton.setImage(UIImage(named: "ic_pause_purple.png"), forState: UIControlState.Normal)
            self.trackInfoLabel.textColor = UIColor.darkGrayColor()
        } else if (PlayerContext.playState == PlayState.STOPPED) {
            showTabBarPlayer(false)
            self.playPauseButton.enabled = false
            self.trackInfoLabel.textColor = UIColor.lightGrayColor()
        }
    }
    
    override func updateStatusView() {
        super.updateStatusView()
        
        let defaultText = NSLocalizedString("CHOOSE TRACK", comment:"")
        if (PlayerContext.playState == PlayState.STOPPED) {
            self.trackInfoLabel.text = defaultText
        } else {
            self.trackInfoLabel.text = PlayerContext.currentTrack?.title ?? defaultText
        }
    }
    
    override func updateProgressView() {
        super.updateProgressView()
        self.tabBarProgressBar.progress = super.progressSliderBar.value / 100.0
    }
    
    @IBAction func playPauseBtnClicked(sender: UIButton) {
        if (PlayerContext.playState == PlayState.PAUSED) {
            super.playBtnClicked(sender)
        } else if (PlayerContext.playState == PlayState.PLAYING) {
            super.pauseBtnClicked(sender)
        }
    }
    
    @IBAction func showPlayerBtnClicked(sender: UIButton) {
        showPlayerView()
    }
    
    @IBAction func showListBtnClicked(sender: UIButton) {
        var playlist:Playlist?
        if PlayerContext.currentPlaylistId != nil {
            playlist = PlayerContext.getPlaylist(PlayerContext.currentPlaylistId)
        }
        if playlist == nil {
            ViewUtils.showToast(self,
                message: NSLocalizedString("Failed to find playlist", comment:""))
            return
        }
        performSegueWithIdentifier("PlaylistSegue", sender: playlist)
    }
    
    func showPlayerView() {
        isPlayerVisible = true
//        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: true)
        
        UIView.animateWithDuration(0.5, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: { () -> Void in

            let height = self.containerView.frame.size.height
            self.containerTopConstraint.constant -= height
            self.containerBottomConstraint.constant += height

            self.tabBarBottomConstraint.constant = -1 * self.tabBarContainerView.frame.height
            self.tabBarContainerView.alpha = 0.0
            self.view.layoutIfNeeded()
            
            self.playerView.alpha = 1.0
        }) { (Bool) -> Void in
        }
    }
    
    func hidePlayerView() {
        isPlayerVisible = false
//        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.Default, animated: true)

        UIView.animateWithDuration(0.5, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: { () -> Void in

            self.containerBottomConstraint.constant = self.tabBarContainerView.frame.height
            self.containerTopConstraint.constant = 0
            
            self.tabBarBottomConstraint.constant = 0
            self.tabBarContainerView.alpha = 1.0
            self.view.layoutIfNeeded()
            
            self.playerView.alpha = 0.0
        }) { (Bool) -> Void in
        }
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
