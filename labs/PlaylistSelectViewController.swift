//
//  PlaylistSelectViewController.swift
//  labs
//
//  Created by vulpes on 2015. 7. 31..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class PlaylistSelectViewController: BaseViewController,
        UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var frameHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    var playlists:[Playlist] = [Playlist]()
    var targetTrack:Track?
    var fromSection:String = "unknown"
    var caller:UIViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        frameHeightConstraint.constant = self.view.bounds.height - 20
        playlists.removeAll(keepCapacity: false)
        for playlist in PlayerContext.playlists {
            playlists.append(playlist)
        }
        tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = "PlaylistSelectScreen"
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "appWillEnterForeground", name: UIApplicationWillEnterForegroundNotification, object: nil)
        
        loadPlaylists()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    @IBAction func onBackBtnClicked(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func onCreatePlaylistBtnClicked(sender: UIButton) {
        ViewUtils.showTextInputAlert(
            self, title: "Create new playlist", message: "Type new playlist name", placeholder: "Playlist 01",
            positiveBtnText: "Create",
            positiveBtnCallback: { (result) -> Void in
                if (count(result) == 0) {
                    return
                }
                let progressHud = ViewUtils.showProgress(self, message: "Creating playlist..")
                Requests.createPlaylist(result, respCb: {
                        (request:NSURLRequest, response:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
                    progressHud.hide(false)
                    if (error != nil) {
                        progressHud.hide(true)
                        var message:String?
                        if (error != nil && error!.domain == NSURLErrorDomain &&
                                error!.code == NSURLErrorNotConnectedToInternet) {
                            message = "Internet is not connected"
                        }
                        if (message == nil) {
                            message = "undefined error (\(error!.domain),\(error!.code))"
                        }
                        ViewUtils.showNoticeAlert(self, title: "Failed to create playlist", message: message!)
                        return
                    }
                    self.loadPlaylists()
                })
            })
    }
    
    func appWillEnterForeground () {
        loadPlaylists()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.playlists.count
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var playlist = playlists[indexPath.row]
        addToPlaylist(playlist)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell:PlaylistSelectTableViewCell = tableView.dequeueReusableCellWithIdentifier(
                "PlaylistSelectTableViewCell", forIndexPath: indexPath) as! PlaylistSelectTableViewCell
        let playlist = playlists[indexPath.row]
        cell.nameView.text = playlist.name
        let trackCount = playlist.tracks.count
        switch(trackCount) {
        case 0:
            cell.trackCount.text = "\(trackCount) track"
        case 1:
            cell.trackCount.text = "\(trackCount) track"
            break
        default:
            cell.trackCount.text = "\(trackCount) tracks"
            break
        }
        return cell
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if tableView.respondsToSelector("separatorInset") {
            tableView.separatorInset = UIEdgeInsetsMake(0, 8, 0, 8)
        }
        
        if tableView.respondsToSelector("layoutMargins") {
            tableView.layoutMargins = UIEdgeInsetsZero
        }
        
        if cell.respondsToSelector("layoutMargins") {
            cell.layoutMargins = UIEdgeInsetsZero
        }
    }
    
    func loadPlaylists() {
        let progressHud = ViewUtils.showProgress(self, message: "Loading playlists..")
        Requests.fetchAllPlaylists({ (request:NSURLRequest, response:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            progressHud.hide(true)
            if (error != nil || result == nil) {
                ViewUtils.showConfirmAlert(self, title: "Failed to fetch", message: "Failed to fetch playlists.",
                    positiveBtnText: "Retry", positiveBtnCallback: { () -> Void in
                    self.loadPlaylists()
                }, negativeBtnText: "Cancel")
                return
            }
            let playlists = Parser().parsePlaylists(result!).reverse()
            if (playlists.count == 0) {
                ViewUtils.showNoticeAlert(self, title: "Failed to fetch playlists", message: error!.description)
                return
            }
            PlayerContext.playlists.removeAll(keepCapacity: false)
            self.playlists.removeAll(keepCapacity: false)
            for playlist in playlists {
                PlayerContext.playlists.append(playlist)
                self.playlists.append(playlist)
            }
            self.tableView.reloadData()
        })
    }
    
    func addToPlaylist(playlist:Playlist) {
        var hasAlready = false
        for track in playlist.tracks {
            if track.id == targetTrack!.id {
                hasAlready = true
                break
            }
        }
        if hasAlready {
            ViewUtils.showToast(self, message: "Already in Playlist")
            if tableView.indexPathForSelectedRow() != nil {
                tableView.deselectRowAtIndexPath(tableView.indexPathForSelectedRow()!, animated: false)
            }
            return
        }
        let progressHud = ViewUtils.showProgress(self, message: "Saving..")
        targetTrack!.addToPlaylist(playlist, section: fromSection) { (error) -> Void in
            progressHud.hide(false)
            if error != nil {
                var message:String?
                if (error != nil && error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    message = "Internet is not connected. Please try again."
                } else {
                    message = "Failed to add track to playlist"
                }
                ViewUtils.showNoticeAlert(self, title: "Failed to add", message: message!, btnText: "Confirm", callback: nil)
                return
            }
            ViewUtils.showToast(self.caller!, message: "Track added")
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
}
