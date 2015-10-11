//
//  MainTabBarController.swift
//  labs
//
//  Created by 방정호 on 2015. 10. 11..
//  Copyright © 2015년 dropbeat. All rights reserved.
//

import UIKit

class MainTabBarController: UITabBarController, UITabBarControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.delegate = self
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
    }
    
    func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
        if viewController == self.viewControllers?.last && Account.getCachedAccount() == nil {
            NeedAuthViewController.showNeedAuthViewController(self)
            return false
        }
        return true
    }
    
    func hidePlayerView() {
        
    }
    
    func showPlayerView() {
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "loadAppLinkRequest", name: NotifyKey.fromAppLink, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        loadAppLinkRequest()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.fromAppLink, object: nil)
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
                self.hidePlayerView()
                navController.pushViewController(uvc, animated: true)
            }
        case .USER_TRACK(user: let userResource, track: let trackResource):
            let uvc = UIStoryboard(name: "Profile", bundle: nil).instantiateViewControllerWithIdentifier("UserViewController") as! UserViewController
            uvc.resource = userResource
            if let navController = self.selectedViewController as? UINavigationController {
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
                
                self.showPlayerView()
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
                
                self.showPlayerView()
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
