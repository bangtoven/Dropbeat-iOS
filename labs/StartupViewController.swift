//
//  StartupViewController.swift
//  labs
//
//  Created by vulpes on 2015. 5. 20..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit
import MMDrawerController
import SwiftyJSON
import MBProgressHUD
import Raygun4iOS

class StartupViewController: UIViewController {

    var progressHud:MBProgressHUD?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        self.progressHud = ViewUtils.showProgress(self, message: "Initializing..")
        
        Account.getAccountWithCompletionHandler({(account:Account?, error:NSError?) -> Void in
            if (error != nil) {
                println("failed to get account due to \(error!.description)")
            }
            var appDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            appDelegate.account = account
            
            if (account != nil) {
                let email:String = account!.user!.email
                Raygun.sharedReporter().identify(email)
            }
            self.fetchUserInfo()
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "DrawerSegue") {
            var drawerController:MMDrawerController = segue.destinationViewController as! MMDrawerController
            drawerController.openDrawerGestureModeMask = MMOpenDrawerGestureMode.PanningCenterView
            drawerController.closeDrawerGestureModeMask = MMCloseDrawerGestureMode.PanningCenterView
            drawerController.setDrawerVisualStateBlock({ (drawerController:MMDrawerController!, drawerSide:MMDrawerSide, percentVisible:CGFloat) -> Void in
                var block:MMDrawerControllerDrawerVisualStateBlock
                block = MMSparkDrawerVisualStateManager.sharedMaanger.drawerVisualStateBlockForDrawerSide(drawerSide)
                block(drawerController, drawerSide, percentVisible)
            })
        
            var appDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            appDelegate.centerContainer = drawerController
        }
    }
    
    func fetchUserInfo() {
        let callback = { (error:NSError?) -> Void in
            self.progressHud?.hide(true)
            self.showMainController()
        }
        if (Account.getCachedAccount() != nil) {
            loadPlaylist(callback)
        } else {
            loadInitialPlaylist(callback)
        }
    }
    
    func loadPlaylist(callback:(error:NSError?) -> Void) {
        Requests.fetchAllPlaylists({ (request:NSURLRequest, response:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            if (error != nil || result == nil) {
                ViewUtils.showNoticeAlert(self, title: "Failed to fetch playlists", message: error!.description)
                callback(error: error)
                return
            }
            let playlists = Parser().parsePlaylists(result!).reverse()
            if (playlists.count == 0) {
                ViewUtils.showNoticeAlert(self, title: "Failed to fetch playlists", message: "At least one playlist should exist")
                callback(error: error)
                return
            }
            PlayerContext.playlists.removeAll(keepCapacity: false)
            for playlist in playlists {
                PlayerContext.playlists.append(playlist)
            }
            PlaylistViewController.updateCurrentPlaylist()
            callback(error:nil)
        })
    }
    
    func loadInitialPlaylist(callback:(error:NSError?) -> Void) {
        Requests.fetchInitialPlaylist({ (request:NSURLRequest, response:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            if (error != nil || result == nil) {
                ViewUtils.showNoticeAlert(self, title: "Failed to fetch playlists", message: error!.description)
                callback(error: error)
                return
            }
            
            let json = JSON(result!)
            let playlistJson = json["playlist"]
            var playlists = [Playlist]()
            playlists.append(Playlist.fromJson(playlistJson.rawValue))
            
            PlayerContext.playlists.removeAll(keepCapacity: false)
            for playlist in playlists {
                PlayerContext.playlists.append(playlist)
            }
            PlaylistViewController.updateCurrentPlaylist()
            callback(error:nil)
        })
    }
    
    func showMainController() {
        performSegueWithIdentifier("DrawerSegue", sender: self)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
