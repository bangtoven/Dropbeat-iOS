//
//  CenterViewController.swift
//  labs
//
//  Created by vulpes on 2015. 5. 15..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

enum MenuType : Int {
    case FEED = 0
    case CHANNEL
    case SEARCH
    case PLAYLIST
    case PROFILE
    case TEST
}

class CenterViewController: _PlayerViewController, UITabBarDelegate{
    
    @IBOutlet weak var hidePlayerButton: UIButton!
    
    @IBOutlet weak var containerFrame: UIView!
    
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
        
        hidePlayerButton.layer.cornerRadius = 10.0
    
        initConstaints()
        
        // set first item
        let firstTab:UITabBarItem = tabBar.items![0]
        tabBar.selectedItem = firstTab
        onMenuSelected(currentMenu, forceUpdate:true)
        
        if Account.getCachedAccount() == nil {
            var newItems = self.tabBar.items
            newItems?.removeAtIndex(MenuType.PLAYLIST.rawValue)
            self.tabBar.setItems(newItems, animated: true)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        loadAppLinkRequest()
        
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.None)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = "CenterViewScreen"
        
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "loadAppLinkRequest", name: NotifyKey.fromAppLink, object: nil)
    }
    
    func loadAppLinkRequest() {
        guard let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate,
                        param = appDelegate.appLink else {
            print("no app link param.")
            return
        }
        
        switch param {
        case .USER(let userResource):
            let uvc = UIStoryboard(name: "Profile", bundle: nil).instantiateViewControllerWithIdentifier("UserViewController") as! UserViewController
            uvc.resource = userResource
            if let navController = self.activeViewController as? UINavigationController {
                self.hidePlayerView()
                navController.pushViewController(uvc, animated: true)
            }
        case .USER_TRACK(user: let userResource, track: let trackResource):
            let uvc = UIStoryboard(name: "Profile", bundle: nil).instantiateViewControllerWithIdentifier("UserViewController") as! UserViewController
            uvc.resource = userResource
            if let navController = self.activeViewController as? UINavigationController {
                navController.pushViewController(uvc, animated: true)
            }
            
            DropbeatTrack.resolve(userResource, track: trackResource) {
                (track, error) -> Void in
                
                if error != nil {
                    ViewUtils.showNoticeAlert(
                        self,
                        title: NSLocalizedString("Failed to load", comment:""),
                        message: NSLocalizedString("Failed to load shared track", comment:""),
                        btnText: NSLocalizedString("Confirm", comment:""),
                        callback: nil)
                    return
                }
                
                let params: [String: AnyObject] = [
                    "track": track!,
                    "section": "app-link"
                ]
                self.showPlayerView()
//                NSNotificationCenter.defaultCenter().postNotificationName(
//                    NotifyKey.playerPlay, object: params)
                DropbeatPlayer.defaultPlayer.play(track!)
            }
        case .SHARED_TRACK(let uid):
            Requests.getSharedTrack(uid, respCb: {
                (req, resp, result, error) -> Void in
                
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
                
                let params: [String: AnyObject] = [
                    "track": track!,
                    "section": "shared_track"
                ]
                self.showPlayerView()
//                NSNotificationCenter.defaultCenter().postNotificationName(
//                    NotifyKey.playerPlay, object: params)
                DropbeatPlayer.defaultPlayer.play(track!)
            })
        case .SHARED_PLAYLIST(let uid):
            Requests.getSharedPlaylist(uid, respCb: {
                (req, resp, result, error) -> Void in
                
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
                    return
                }
                
                playlist!.type = PlaylistType.SHARED
                self.performSegueWithIdentifier("PlaylistSegue", sender: playlist)
            })
        }
        
        
        appDelegate.appLink = nil
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.fromAppLink, object: nil)
    }
    
    func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem) {
        if let menuType = MenuType(rawValue: item.tag) {
            onMenuSelected(menuType)
        }
    }
    
    func onMenuSelected(type:MenuType, forceUpdate:Bool=false) {
        if !forceUpdate && currentMenu == type {
            return
        }
        switch(type) {
        case .FEED:
            activeViewController = UIStoryboard(name: "Feed", bundle: nil).instantiateInitialViewController()
        case .CHANNEL:
            activeViewController = UIStoryboard(name: "Explore", bundle: nil).instantiateInitialViewController()
        case .SEARCH:
            activeViewController = UIStoryboard(name: "Main", bundle: nil)
                .instantiateViewControllerWithIdentifier("SearchNavigationController")
        case .PROFILE:
            if Account.getCachedAccount() == nil {
                activeViewController = UIStoryboard(name: "Settings", bundle: nil).instantiateInitialViewController()
            } else {
                activeViewController = UIStoryboard(name: "Profile", bundle: nil).instantiateInitialViewController()
            }
        case .PLAYLIST:
            activeViewController = UIStoryboard(name: "Playlist", bundle: nil).instantiateInitialViewController()
        case .TEST:
            let pvc = UIStoryboard(name: "Main", bundle: nil)
                .instantiateViewControllerWithIdentifier("PlayerViewController")
            self.presentViewController(pvc, animated: true, completion: nil)
        }
        
        currentMenu = type
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
    
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
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
            
            if self.isPlayerVisible == false {
                self.containerBottomConstraint.constant = self.tabBarContainerView.frame.height
            }
            self.view.layoutIfNeeded()
            
            }) { (Bool) -> Void in
        }
        
        self.isTabBarPlayerVisible = visible
    }
    
    override func updatePlayView() {
        super.updatePlayView()
        
        switch DropbeatPlayer.defaultPlayer.playState {
        case .LOADING, .SWITCHING, .BUFFERING:
            showTabBarPlayer(true)
            self.loadingIndicator.hidden = false
            self.playPauseButton.hidden = true
            self.trackInfoLabel.textColor = UIColor.lightGrayColor()
        case .PAUSED:
            showTabBarPlayer(true)
            self.loadingIndicator.hidden = true
            self.playPauseButton.hidden = false
            self.playPauseButton.setImage(UIImage(named: "ic_play_purple"), forState: UIControlState.Normal)
            self.trackInfoLabel.textColor = UIColor.darkGrayColor()
        case .PLAYING:
            showTabBarPlayer(true)
            self.loadingIndicator.hidden = true
            self.playPauseButton.hidden = false
            self.playPauseButton.setImage(UIImage(named: "ic_pause_purple"), forState: UIControlState.Normal)
            self.trackInfoLabel.textColor = UIColor.darkGrayColor()
        case .STOPPED:
            showTabBarPlayer(false)
            self.loadingIndicator.hidden = true
            self.trackInfoLabel.textColor = UIColor.lightGrayColor()
        }
    }
    
    override func updateStatusView() {
        super.updateStatusView()
        
        let defaultText = NSLocalizedString("CHOOSE TRACK", comment:"")
        if (DropbeatPlayer.defaultPlayer.playState == PlayState.STOPPED) {
            self.trackInfoLabel.text = defaultText
        } else {
            self.trackInfoLabel.text = DropbeatPlayer.defaultPlayer.currentTrack?.title ?? defaultText
        }
    }
    
    override func updateProgressView() {
        if isPlayerVisible {
            super.updateProgressView()
        } else {
            self.tabBarProgressBar.progress = super.progressSliderBar.value / 100.0
        }
    }
    
    @IBAction func playPauseBtnClicked(sender: UIButton) {
        if (DropbeatPlayer.defaultPlayer.playState == PlayState.PAUSED) {
            super.playBtnClicked(sender)
        } else if (DropbeatPlayer.defaultPlayer.playState == PlayState.PLAYING) {
            super.pauseBtnClicked(sender)
        }
    }
    
    @IBAction func showPlayerBtnClicked(sender: UIButton) {
        DropbeatPlayer.defaultPlayer.stop()
//        showPlayerView()
    }
    
    @IBAction func showListBtnClicked(sender: UIButton) {
        var playlist:Playlist?
        if DropbeatPlayer.defaultPlayer.currentPlaylistId != nil {
            playlist = DropbeatPlayer.defaultPlayer.getPlaylist(DropbeatPlayer.defaultPlayer.currentPlaylistId)
        }
        if playlist == nil {
            ViewUtils.showToast(self,
                message: NSLocalizedString("Failed to find playlist", comment:""))
            return
        }
        performSegueWithIdentifier("PlaylistSegue", sender: playlist)
    }
    
    func showPlayerView() {
        if self.isPlayerVisible == true {
            return
        }
        
        isPlayerVisible = true
        
        self.playerView.hidden = false
        self.playerView.alpha = 0.0
        
        UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: { () -> Void in

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
        if self.isPlayerVisible == false {
            return
        }
        
        isPlayerVisible = false

        UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: { () -> Void in

            self.containerBottomConstraint.constant = self.tabBarContainerView.frame.height
            self.containerTopConstraint.constant = 0
            
            self.tabBarBottomConstraint.constant = 0
            self.tabBarContainerView.alpha = 1.0
            self.view.layoutIfNeeded()
            
            self.playerView.alpha = 0.0
        }) { (Bool) -> Void in
            self.playerView.hidden = true
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
