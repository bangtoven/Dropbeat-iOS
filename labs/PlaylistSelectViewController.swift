//
//  PlaylistSelectViewController.swift
//  labs
//
//  Created by vulpes on 2015. 7. 31..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class PlaylistSelectViewController: PlaylistListTableViewController {
    
    override var showCurrentPlaylist: Bool {
        get {
            return false
        }
    }
    
    var targetTrack:Track?
    var fromSection:String = "unknown"
    var caller:UIViewController?
    
    @IBAction func onBackBtnClicked(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if identifier == "PlaylistSegue" {
        }
        return false
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let playlist = playlists[indexPath.row]
        addToPlaylist(playlist)
    }
    
    func addToPlaylist(playlist:Playlist) {
        if playlist.dummy == false {
            print("this is not dummy playlist. let's start adding")
            
            var hasAlready = false
            for track in playlist.tracks {
                if track.id == targetTrack!.id {
                    hasAlready = true
                    break
                }
            }
            if hasAlready {
                ViewUtils.showToast(self, message: NSLocalizedString("Already in Playlist", comment:""))
                if tableView.indexPathForSelectedRow != nil {
                    tableView.deselectRowAtIndexPath(tableView.indexPathForSelectedRow!, animated: false)
                }
                return
            }
            let progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Saving..", comment:""))
            playlist.addTrack(targetTrack!, section: fromSection) { (error) -> Void in
                progressHud.hide(true)
                if error != nil {
                    var message:String?
                    if (error != nil && error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                            message = NSLocalizedString("Internet is not connected. Please try again.", comment:"")
                    } else {
                        message = NSLocalizedString("Failed to add track to playlist", comment:"")
                    }
                    ViewUtils.showNoticeAlert(self,
                        title: NSLocalizedString("Failed to add", comment:""),
                        message: message!, btnText: NSLocalizedString("Confirm", comment:""), callback: nil)
                    return
                }
                ViewUtils.showToast(self.caller!, message: NSLocalizedString("Track added", comment:""))
                self.dismissViewControllerAnimated(true, completion: nil)
            }
        } else {
            print("this is a dummy playlist. let's start to load.")
            
            Requests.getPlaylist(playlist.id, respCb: {
                (request:NSURLRequest, response:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
                if error != nil {
                    var message:String?
                    if (error != nil && error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                            message = NSLocalizedString("Internet is not connected. Please try again.", comment:"")
                    } else {
                        message = NSLocalizedString("Failed to add track to playlist", comment:"")
                    }
                    ViewUtils.showNoticeAlert(self,
                        title: NSLocalizedString("Failed to add", comment:""),
                        message: message!, btnText: NSLocalizedString("Confirm", comment:""), callback: nil)
                    return
                }
                
                var res = JSON(result!)
                if !res["success"].boolValue {
                    ViewUtils.showNoticeAlert(self,
                        title: NSLocalizedString("Failed to fetch", comment:""),
                        message: NSLocalizedString("Failed to fetch playlist", comment:""),
                        btnText: NSLocalizedString("Confirm", comment:""))
                    return
                }
                
                let playlist:Playlist? = Playlist.parsePlaylist(res.rawValue, key: "playlist")
                
                if (playlist == nil) {
                    ViewUtils.showNoticeAlert(self,
                        title: NSLocalizedString("Failed to fetch", comment:""),
                        message: NSLocalizedString("Failed to fetch playlist", comment:""),
                        btnText: NSLocalizedString("Confirm", comment:""))
                    return
                }
                
                playlist?.dummy = false
                self.addToPlaylist(playlist!)
            })
        }
    }
}
