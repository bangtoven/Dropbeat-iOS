//
//  PlaylistSelectViewController.swift
//  labs
//
//  Created by vulpes on 2015. 7. 31..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class PlaylistSelectViewController: PlaylistListTableViewController {
    
    override var showCurrentPlaylist: Bool { return false }
    
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
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        cell.accessoryType = .None
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let playlist = playlists[indexPath.row]
        addToPlaylist(playlist)
    }
    
    func addToPlaylist(playlist:Playlist) {
        let progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Saving..", comment:""))
        playlist.addTrack(targetTrack!, section: fromSection) { (error) -> Void in
            progressHud.hide(true)
            if error != nil {
                if (error!.domain == PlaylistErrorDomain &&
                    error!.code == PlaylistAlreadyContainsTrackError) {
                        ViewUtils.showToast(self, message: NSLocalizedString("Already in Playlist", comment:""))
                        if let indexPath = self.tableView.indexPathForSelectedRow {
                            self.tableView.deselectRowAtIndexPath(indexPath, animated: false)
                        }
                    return
                } else {
                    var message:String?
                    if (error!.domain == NSURLErrorDomain &&
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
            }
            
            ViewUtils.showToast(self.caller!, message: NSLocalizedString("Track added", comment:""))
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
}
