//
//  PlaylistSelectTableViewCell.swift
//  labs
//
//  Created by vulpes on 2015. 5. 21..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class PlaylistSelectTableViewCell: UITableViewCell {
    
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

//
//  PlaylistSelectViewController.swift
//  labs
//
//  Created by vulpes on 2015. 7. 31..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

class PlaylistSelectViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    private var playlists:[Playlist] = [Playlist]()
    var targetTrack:Track?
    var fromSection:String = "unknown"
    var caller:UIViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        playlists.removeAll(keepCapacity: false)
        for playlist in DropbeatPlayer.defaultPlayer.playlists {
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
            self, title: NSLocalizedString("Create new playlist", comment:""),
            message: NSLocalizedString("Type new playlist name", comment:""),
            placeholder: NSLocalizedString("Playlist 01", comment:""),
            positiveBtnText: NSLocalizedString("Create", comment:""),
            positiveBtnCallback: { (result) -> Void in
                if (result.characters.count == 0) {
                    return
                }
                let progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Creating playlist..", comment:""))
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
                            message = NSLocalizedString("Failed to create", comment:"")
                        }
                        ViewUtils.showNoticeAlert(self, title:
                            NSLocalizedString("Failed to create playlist", comment:""), message: message!)
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
        let playlist = playlists[indexPath.row]
        addToPlaylist(playlist)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:PlaylistSelectTableViewCell = tableView.dequeueReusableCellWithIdentifier(
            "PlaylistSelectTableViewCell", forIndexPath: indexPath) as! PlaylistSelectTableViewCell
        let playlist = playlists[indexPath.row]
        cell.nameView.text = playlist.name
        return cell
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if tableView.respondsToSelector("separatorInset") {
            tableView.separatorInset = UIEdgeInsetsMake(0, 8, 0, 8)
        }
        
        if #available(iOS 8.0, *) {
            tableView.layoutMargins = UIEdgeInsetsZero
        }
        
        if #available(iOS 8.0, *) {
            cell.layoutMargins = UIEdgeInsetsZero
        }
    }
    
    func loadPlaylists() {
        let progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Loading playlists..", comment:""))
        Requests.fetchPlaylistList({ (request:NSURLRequest, response:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            progressHud.hide(true)
            if (error != nil || result == nil) {
                ViewUtils.showConfirmAlert(self, title: NSLocalizedString("Failed to fetch", comment:""),
                    message: NSLocalizedString("Failed to fetch playlists.", comment:""),
                    positiveBtnText: NSLocalizedString("Retry", comment:""), positiveBtnCallback: { () -> Void in
                        self.loadPlaylists()
                    }, negativeBtnText: NSLocalizedString("Cancel", comment:""))
                return
            }
            let playlists = Array(Playlist.parsePlaylists(result!).reverse())
            if (playlists.count == 0) {
                ViewUtils.showNoticeAlert(self,
                    title: NSLocalizedString("Failed to fetch playlists", comment:""),
                    message: error!.description)
                return
            }
            DropbeatPlayer.defaultPlayer.playlists.removeAll(keepCapacity: false)
            self.playlists.removeAll(keepCapacity: false)
            for playlist in playlists {
                DropbeatPlayer.defaultPlayer.playlists.append(playlist)
                self.playlists.append(playlist)
            }
            self.tableView.reloadData()
        })
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
