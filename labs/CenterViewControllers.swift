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
}

class CenterViewController: PlayerViewController, UITabBarDelegate{
    
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
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
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
            
            let params: [String: AnyObject] = [
                "track": track!,
                "section": "shared_track"
            ]
            NSNotificationCenter.defaultCenter().postNotificationName(
                NotifyKey.playerPlay, object: params)
        })
        appDelegate.sharedTrackUid = nil
    }
    
    func loadSharedPlaylistIfExist() {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
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
    
    override func remotePause() {
        super.remotePause()
        showTabBarPlayer(false)
    }
    
    override func resumePlay() {
        super.resumePlay()
        if (PlayerContext.currentTrack != nil) {
//            print("resume with current track. show tab bar player")
            showTabBarPlayer(true)
//            super.playBtnClicked(nil)
        }
//        else {
//            println("resume without current track")
//        }
    }
    
    override func updatePlayView() {
        super.updatePlayView()
        
        if (PlayerContext.playState == PlayState.LOADING ||
            PlayerContext.playState == PlayState.SWITCHING ||
            PlayerContext.playState == PlayState.BUFFERING) {
                showTabBarPlayer(true)
                self.loadingIndicator.hidden = false
                self.playPauseButton.hidden = true
                self.trackInfoLabel.textColor = UIColor.lightGrayColor()
        } else if (PlayerContext.playState == PlayState.PAUSED) {
            showTabBarPlayer(true)
            self.loadingIndicator.hidden = true
            self.playPauseButton.hidden = false
            self.playPauseButton.setImage(UIImage(named: "ic_play_purple"), forState: UIControlState.Normal)
            self.trackInfoLabel.textColor = UIColor.darkGrayColor()
        } else if (PlayerContext.playState == PlayState.PLAYING) {
            showTabBarPlayer(true)
            self.loadingIndicator.hidden = true
            self.playPauseButton.hidden = false
            self.playPauseButton.setImage(UIImage(named: "ic_pause_purple"), forState: UIControlState.Normal)
            self.trackInfoLabel.textColor = UIColor.darkGrayColor()
        } else if (PlayerContext.playState == PlayState.STOPPED) {
            showTabBarPlayer(false)
            self.loadingIndicator.hidden = true
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
        
        self.playerView.hidden = false
        self.playerView.alpha = 0.0
//        self.playerView.layer.transform = CATransform3DConcat(CATransform3DMakeScale(1.0, 1.0, 1.0), CATransform3DMakeTranslation(0, 0, 0))
        
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
        isPlayerVisible = false
//        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.Default, animated: true)

        UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: { () -> Void in

            self.containerBottomConstraint.constant = self.tabBarContainerView.frame.height
            self.containerTopConstraint.constant = 0
            
            self.tabBarBottomConstraint.constant = 0
            self.tabBarContainerView.alpha = 1.0
            self.view.layoutIfNeeded()
            
//            self.playerView.layer.transform = CATransform3DConcat(CATransform3DMakeScale(0.5, 0.5, 1.0), CATransform3DMakeTranslation(0, self.containerView.frame.size.height, 0))
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
