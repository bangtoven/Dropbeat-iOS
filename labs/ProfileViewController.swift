//
//  ProfileViewController.swift
//  labs
//
//  Created by vulpes on 2015. 7. 29..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class ProfileViewController: BaseViewController,
        UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var profileView: UIImageView!
    @IBOutlet weak var nameView: UILabel!
    @IBOutlet weak var emailView: UILabel!
    
    var playlists:[Playlist] = [Playlist]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let account = Account.getCachedAccount()!
        nameView.text = "\(account.user!.firstName) \(account.user!.lastName)"
        emailView.text = account.user!.email
        
        let profileUrl = "https://graph.facebook.com/\(account.user!.fbId)/picture?type=large"
        profileView.sd_setImageWithURL(NSURL(string:profileUrl),
            placeholderImage: UIImage(named: "default_profile.png"))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = "PlaylistViewScreen"
        
        playlists.removeAll(keepCapacity: false)
        for playlist in PlayerContext.playlists {
            playlists.append(playlist)
        }
        tableView.reloadData()
        
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "appWillEnterForeground", name: UIApplicationWillEnterForegroundNotification, object: nil)
        
        if tableView.indexPathForSelectedRow() != nil {
            tableView.deselectRowAtIndexPath(tableView.indexPathForSelectedRow()!, animated: false)
        }
        loadPlaylist()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "PlaylistSegue" {
            let playlist = playlists[tableView.indexPathForSelectedRow()!.row]
            let playlistVC = segue.destinationViewController as! PlaylistViewController
            playlistVC.currentPlaylist = playlist
        }
    }
    
    @IBAction func onCreatePlaylistBtnClicked(sender: AnyObject) {
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
                    self.loadPlaylist()
                })
            })
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let playlist = playlists[indexPath.row]
        var cell:PlaylistSelectTableViewCell = tableView.dequeueReusableCellWithIdentifier(
                "PlaylistSelectTableViewCell", forIndexPath: indexPath) as! PlaylistSelectTableViewCell
        cell.nameView.text = playlist.name
        if playlist.id == PlayerContext.currentPlaylistId {
            cell.setSelected(true, animated: false)
        }
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playlists.count
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
    
    func appWillEnterForeground () {
        loadPlaylist()
    }
    
    func loadPlaylist() {
        let progressHud = ViewUtils.showProgress(self, message: "Loading playlists..")
        Requests.fetchAllPlaylists({ (request:NSURLRequest, response:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            progressHud.hide(true)
            if (error != nil || result == nil) {
                ViewUtils.showConfirmAlert(self, title: "Failed to fetch", message: "Failed to fetch playlists.",
                    positiveBtnText: "Retry", positiveBtnCallback: { () -> Void in
                    self.loadPlaylist()
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
}
