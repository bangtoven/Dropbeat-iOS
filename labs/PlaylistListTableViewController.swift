//
//  PlaylistListTableViewController.swift
//  labs
//
//  Created by Jungho Bang on 2015. 9. 23..
//  Copyright © 2015년 dropbeat. All rights reserved.
//

import UIKit

class PlaylistTableViewCell: UITableViewCell {
    
    @IBOutlet weak var nameView: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        let selectedBgView = UIView(frame: self.bounds)
        selectedBgView.autoresizingMask = [UIViewAutoresizing.FlexibleHeight, UIViewAutoresizing.FlexibleWidth]
        selectedBgView.backgroundColor = UIColor(netHex: 0xdddddd)
        self.selectedBackgroundView = selectedBgView
    }
}

class PlaylistListTableViewController: UITableViewController {

    var playlists:[Playlist] = [Playlist]()
    var showCurrentPlaylist: Bool {
        get {
            if let current = DropbeatPlayer.defaultPlayer.currentPlaylist {
                return !self.playlists.contains({$0.id == current.id})
            } else {
                return false
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:" ", style:.Plain, target:nil, action:nil)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        self.loadPlaylists()
        
        if tableView.indexPathForSelectedRow != nil {
            tableView.deselectRowAtIndexPath(tableView.indexPathForSelectedRow!, animated: false)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "PlaylistSegue" {
            let indexPath = tableView.indexPathForSelectedRow!
            var playlist: Playlist
            if self.showCurrentPlaylist {
                if indexPath.section == 0 {
                    playlist = DropbeatPlayer.defaultPlayer.currentPlaylist!
                } else {
                    playlist = playlists[indexPath.row]
                }
            } else {
                playlist = playlists[indexPath.row]
            }
            let playlistVC = segue.destinationViewController as! PlaylistViewController
            playlistVC.currentPlaylist = playlist
        }
    }
    
    @IBAction func onCreatePlaylistBtnClicked(sender: AnyObject) {
        ViewUtils.showTextInputAlert(
            self, title: NSLocalizedString("Create new playlist", comment:""),
            message: NSLocalizedString("Type new playlist name", comment:""),
            placeholder: NSLocalizedString("Playlist 01", comment:""),
            positiveBtnText: NSLocalizedString("Create", comment:""),
            positiveBtnCallback: { (result) -> Void in
                if (result.characters.count == 0) {
                    return
                }
                let progressHud = ViewUtils.showProgress(self,
                    message: NSLocalizedString("Creating playlist..", comment:""))
                Requests.createPlaylist(result, respCb: {
                    (request:NSURLRequest, response:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
                    progressHud.hide(true)
                    if (error != nil) {
                        var message:String?
                        if (error != nil && error!.domain == NSURLErrorDomain &&
                            error!.code == NSURLErrorNotConnectedToInternet) {
                                message = NSLocalizedString("Internet is not connected", comment:"")
                        }
                        if (message == nil) {
                            message = NSLocalizedString("Failed to create playlist", comment:"")
                        }
                        ViewUtils.showNoticeAlert(self,
                            title: NSLocalizedString("Failed to create", comment:""),
                            message: message!)
                        return
                    }
                    self.loadPlaylists()
                })
        })
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.showCurrentPlaylist ? 2 : 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.showCurrentPlaylist {
            if section == 0 {
                return 1
            } else {
                return playlists.count
            }
        } else {
            return playlists.count
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var playlist: Playlist
        
        if self.showCurrentPlaylist {
            if indexPath.section == 0 {
                playlist = DropbeatPlayer.defaultPlayer.currentPlaylist!
            } else {
                playlist = playlists[indexPath.row]
            }
        } else {
            playlist = playlists[indexPath.row]
        }
        
        let cell:PlaylistTableViewCell = tableView.dequeueReusableCellWithIdentifier(
            "PlaylistTableViewCell", forIndexPath: indexPath) as! PlaylistTableViewCell
        cell.nameView.text = playlist.name
        if playlist.id == DropbeatPlayer.defaultPlayer.currentPlaylist?.id {
            cell.setSelected(true, animated: false)
        }
        return cell
    }
    
    func loadPlaylists() {
        let progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Loading..", comment:""))
        Playlist.fetchAllPlaylists { (playlists, error) -> Void in
            progressHud.hide(true)
            if error != nil || playlists == nil {
                ViewUtils.showConfirmAlert(self, title: NSLocalizedString("Failed to fetch", comment:""),
                    message: NSLocalizedString("Failed to fetch playlists.", comment:""),
                    positiveBtnText: NSLocalizedString("Retry", comment:""), positiveBtnCallback: { () -> Void in
                        self.loadPlaylists()
                    }, negativeBtnText: NSLocalizedString("Cancel", comment:""))
                return
            }
            
            self.playlists = playlists!
            self.tableView.reloadData()
        }
    }
}
