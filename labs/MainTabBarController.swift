//
//  MainTabBarController.swift
//  labs
//
//  Created by 방정호 on 2015. 10. 11..
//  Copyright © 2015년 dropbeat. All rights reserved.
//

import UIKit
import LNPopupController

class MainTabBarController: UITabBarController {

    var playerView: PlayerViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tabBar.tintColor = UIColor.dropbeatColor()
        
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
        
        self.popupBar.translucent = false
        self.popupBar.tintColor = UIColor.dropbeatColor()
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
        if self.playerView == nil {
            let pvc = self.storyboard?.instantiateViewControllerWithIdentifier("PlayerViewController") as! PlayerViewController
            pvc.main = self
            self.playerView = pvc
        }

        if self.popupPresentationState != .Closed {
            self.tabBar.backgroundImage = UIImage(named: "tabbar_bg")
            self.presentPopupBarWithContentViewController(self.playerView!, animated: true, completion: nil)
        }
    }
    
    func hidePopupPlayer() {
        self.tabBar.backgroundImage = UIImage(named: "tabbar_bg_with_bar")
        self.dismissPopupBarAnimated(true, completion: nil)
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
            let uvc = UIStoryboard(name: "Profile", bundle: nil).instantiateViewControllerWithIdentifier("UserViewController") as! UserViewController
            uvc.resource = userResource
            if let navController = self.selectedViewController as? UINavigationController {
                self.closePopupAnimated(true, completion: nil)
                navController.pushViewController(uvc, animated: true)
            }
        case .USER_TRACK(user: let userResource, track: let trackResource):
            let uvc = UIStoryboard(name: "Profile", bundle: nil).instantiateViewControllerWithIdentifier("UserViewController") as! UserViewController
            uvc.resource = userResource
            if let navController = self.selectedViewController as? UINavigationController {
                self.closePopupAnimated(true, completion: nil)
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "PlaylistSegue" {
            let playlistVC = segue.destinationViewController as! PlaylistViewController
            playlistVC.currentPlaylist = sender as! Playlist
            playlistVC.fromPlayer = true
        }
    }
    
    
    
    // mayby useful later??
    
    private func removeInactiveViewController(inactiveViewController:UIViewController?) {
        if let inactiveVC = inactiveViewController {
            inactiveVC.willMoveToParentViewController(nil)
            inactiveVC.view.removeFromSuperview()
            inactiveVC.removeFromParentViewController()
        }
    }
}
