//
//  MainTabBarController.swift
//  labs
//
//  Created by 방정호 on 2015. 10. 11..
//  Copyright © 2015년 dropbeat. All rights reserved.
//

import UIKit
import LNPopupController

//class PopupBarFrameUpdateNavigationController: UINavigationController {
//    
//    override func viewDidAppear(animated: Bool) {
//        super.viewDidAppear(animated)
//        
//        self.updateContentFrame()
//    }
//    
//    func updateContentFrame() {
//        guard let tbc = self.tabBarController else {
//            return
//        }
//        
//        var newHeight = tbc.view.frame.height
//        if tbc.popupPresentationState == .Closed {
//            newHeight -= tbc.popupBar.frame.height
//        }
//        
//        if newHeight != self.view.frame.height {
//            print("update height: \(self.view.frame.height) -> \(newHeight)")
//            self.view.frame.size.height = newHeight
//            self.view.setNeedsLayout()
//        }
//    }
//    
//}

extension UITableViewController {
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let insets = UIEdgeInsetsMake(topLayoutGuide.length, 0, 44, 0)
        tableView.contentInset = insets
    }
}

extension AddableTrackListViewController {
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let insets = UIEdgeInsetsMake(topLayoutGuide.length, 0, 44, 0)
        trackTableView.contentInset = insets
    }
}

class MainTabBarController: UITabBarController {

    var playerView: PlayerViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tabBar.tintColor = UIColor.dropbeatColor()
        self.view.tintColor = UIColor.dropbeatColor()

        let navBar = UINavigationBar.appearance()
        navBar.barTintColor = UIColor.whiteColor()
        navBar.tintColor = nil
        navBar.shadowImage = nil
        navBar.setBackgroundImage(nil, forBarMetrics: UIBarMetrics.Default)
        navBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.blackColor()]

        if Account.getCachedAccount() == nil {
            var exceptPlaylistTab = self.viewControllers
            exceptPlaylistTab?.removeAtIndex(3)
            self.setViewControllers(exceptPlaylistTab, animated: true)
        }
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "loadAppLinkRequest", name: NotifyKey.fromAppLink, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "playerStateChanged:",
            name: DropbeatPlayerStateChangedNotification,
            object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.fromAppLink, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name: DropbeatPlayerStateChangedNotification,
            object: nil)
    }
    
    func playerStateChanged(noti: NSNotification) {
        if let state = STKAudioPlayerState(rawValue: noti.object as! UInt) {
            
            if self.popupPresentationState == .Open || self.popupPresentationState == .Transitioning {
                return
            }
            
            switch state {
            case .Running, .Buffering, .Paused, .Playing:
                self.showPopupPlayer()
            case .Error:
                let errMsg = NSLocalizedString("This track is not streamable", comment:"")
                ViewUtils.showToast(self, message: errMsg)
                fallthrough
            default:
                self.hidePopupPlayer()
            }
        }
    }
    
    func showPopupPlayer() {
        if self.popupPresentationState == .Hidden  {
            if self.playerView == nil {
                let pvc = self.storyboard?.instantiateViewControllerWithIdentifier("PlayerViewController") as! PlayerViewController
                pvc.main = self
                self.playerView = pvc
            }
            
            self.tabBar.backgroundImage = UIImage(named: "tabbar_bg")
            self.presentPopupBarWithContentViewController(self.playerView!, animated: true) {
//                for vc in self.viewControllers! {
//                    if let navCon = vc as? PopupBarFrameUpdateNavigationController {
//                        navCon.updateContentFrame()
//                    }
//                }
            }
        }
    }
    
    func hidePopupPlayer() {
        if self.popupPresentationState == .Closed {
            self.tabBar.backgroundImage = UIImage(named: "tabbar_bg_with_bar")
            self.dismissPopupBarAnimated(true) {
//                for vc in self.viewControllers! {
//                    if let navCon = vc as? PopupBarFrameUpdateNavigationController {
//                        navCon.updateContentFrame()
//                    }
//                }
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        loadAppLinkRequest()
    }

    func loadAppLinkRequest() {
        guard let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate,
            param = appDelegate.appLink else {
                print("no app link param.")
                return
        }
        
        switch param {
        case .USER(let userResource):
            if let navController = self.selectedViewController as? UINavigationController {
                if let currentUserView = navController.topViewController as? UserViewController
                    where currentUserView.resource == userResource {
                    print("same user")
                } else {
                    let uvc = UIStoryboard(name: "Profile", bundle: nil).instantiateViewControllerWithIdentifier("UserViewController") as! UserViewController
                    uvc.resource = userResource
                    navController.pushViewController(uvc, animated: true)
                }
                self.closePopupAnimated(true, completion: nil)
            }
        case .USER_TRACK(user: let userResource, track: let trackResource):
            if let navController = self.selectedViewController as? UINavigationController {
                if let currentUserView = navController.topViewController as? UserViewController
                    where currentUserView.resource == userResource {
                        print("same user")
                } else {
                    let uvc = UIStoryboard(name: "Profile", bundle: nil).instantiateViewControllerWithIdentifier("UserViewController") as! UserViewController
                    uvc.resource = userResource
                    navController.pushViewController(uvc, animated: true)
                }
                self.closePopupAnimated(true, completion: nil)
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
                
                let playlist = Playlist(id: track!.user!.name, name: track!.user!.name, tracks: [track!])
                playlist.type = .SHARED
                DropbeatPlayer.defaultPlayer.currentPlaylist = playlist
                DropbeatPlayer.defaultPlayer.play(track!)
                self.showPopupPlayer()
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
                
                let playlist = Playlist(id: track!.title, name: track!.title, tracks: [track!])
                playlist.type = .SHARED
                DropbeatPlayer.defaultPlayer.currentPlaylist = playlist
                DropbeatPlayer.defaultPlayer.play(track!)
                self.showPopupPlayer()
                self.openPopupAnimated(true, completion: nil)
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
    
    func showAuthViewController() {
        NeedAuthViewController.showNeedAuthViewController(self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        print(segue.identifier)

        if segue.identifier == "PlaylistSegue" {
            let playlistVC = segue.destinationViewController as! BeforePlaylistNavigationController
            playlistVC.currentPlaylist = sender as! Playlist
        } else if segue.identifier == "PlaylistSelectSegue" {
            let playlistSelectVC = segue.destinationViewController as! PlaylistSelectViewController
            playlistSelectVC.targetTrack = sender as? Track
            playlistSelectVC.fromSection = "player"
            playlistSelectVC.caller = self
        }
    }
    
}
