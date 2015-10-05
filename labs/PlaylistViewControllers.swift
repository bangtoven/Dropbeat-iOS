//
//  PlaylistViewController.swift
//  labs
//
//  Created by vulpes on 2015. 5. 18..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

protocol PlaylistTableViewDelegate {
    func onMenuBtnClicked(sender:PlaylistTableViewCell)
}

class PlaylistTableViewCell: UITableViewCell {
    
    var delegate:PlaylistTableViewDelegate?
    
    @IBOutlet weak var menuBtn: UIButton!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var trackTitle: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        let selectedBgView = UIView(frame: self.bounds)
        selectedBgView.autoresizingMask = [UIViewAutoresizing.FlexibleHeight, UIViewAutoresizing.FlexibleWidth]
        selectedBgView.backgroundColor = UIColor(netHex: 0xdddddd)
        self.selectedBackgroundView = selectedBgView
    }
    
    @IBAction func onMenuBtnClicked(sender: UIButton) {
        delegate?.onMenuBtnClicked(self)
    }
    
}

class PlaylistViewController: BaseViewController,
        UITableViewDelegate, UITableViewDataSource, PlaylistTableViewDelegate, UIActionSheetDelegate{
    
    @IBOutlet weak var likeBtn: UIButton!
    @IBOutlet weak var playlistMenuBtn: UIButton!
    @IBOutlet weak var playPlaylistBtn: UIButton!
    @IBOutlet weak var playlistTableView: UITableView!
    @IBOutlet weak var playlistTrackCountView: UILabel!
    @IBOutlet weak var playlistNameView: UILabel!
    @IBOutlet weak var fakeNavigationBar: UINavigationBar!
    @IBOutlet weak var fakeNavigationBarHeightConstraint: NSLayoutConstraint!
    
    private var tracks:[Track] = [Track]()
    private var playlistActionSheet:UIActionSheet?
    private var menuSelectedTrack:Track?
    private var isLiked = false
    var currentPlaylist:Playlist!
    var fromPlayer:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if fromPlayer {
            fakeNavigationBar.hidden = false
        } else {
            fakeNavigationBar.hidden = true
            fakeNavigationBarHeightConstraint.constant = 0
        }
        
        if currentPlaylist.type == PlaylistType.EXTERNAL ||
                currentPlaylist.type == PlaylistType.SHARED {
            playlistMenuBtn.hidden = true
            playPlaylistBtn.hidden = true
                    
            if currentPlaylist.type == PlaylistType.SHARED {
                likeBtn.hidden = false
                updateLikeBtn()
            }
        } else {
            playlistMenuBtn.hidden = false
            playPlaylistBtn.hidden = false
            likeBtn.hidden = true
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = "PlaylistViewScreen"
        
        updatePlaylistInfo()
        if currentPlaylist != nil {
            tracks.removeAll(keepCapacity: false)
            for track in currentPlaylist!.tracks {
                tracks.append(track)
            }
            playlistTableView.reloadData()
        }
        
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "sender", name: NotifyKey.playerStop, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "sender", name: NotifyKey.playerPlay, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "sender", name: NotifyKey.updateShuffleState, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "updatePlayTrack:", name: NotifyKey.updatePlay, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "appWillEnterForeground",
            name: UIApplicationWillEnterForegroundNotification, object: nil)
        
        loadPlaylist()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.playerStop, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.playerPlay, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.updateShuffleState, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.updatePlay, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    func updatePlaylistInfo() {
        self.title = currentPlaylist!.name
        self.fakeNavigationBar.items?.last?.title = self.title
        
        playlistNameView.text = currentPlaylist!.name
        switch(currentPlaylist!.tracks.count) {
        case 0:
            playlistTrackCountView.text = NSLocalizedString("Empty playlist", comment:"")
            break
        default:
            playlistTrackCountView.text = NSString.localizedStringWithFormat(
                NSLocalizedString("%d tracks", comment: ""), currentPlaylist!.tracks.count) as String
            break
        }
    }
    
    func appWillEnterForeground () {
        loadPlaylist()
    }
    
    func sender() {}
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentPlaylist!.tracks.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let track:Track = tracks[indexPath.row]
        let cell:PlaylistTableViewCell = tableView.dequeueReusableCellWithIdentifier(
                "PlaylistTableViewCell", forIndexPath: indexPath) as! PlaylistTableViewCell
        if (currentPlaylist!.id == PlayerContext.currentPlaylistId &&
                PlayerContext.currentTrack != nil &&
                PlayerContext.currentTrack!.id == track.id) {
            cell.setSelected(true, animated: false)
        }
        cell.trackTitle.text = track.title
        cell.delegate = self
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let selectedTrack: Track = tracks[indexPath.row] as Track
        onPlayTrackBtnClicked(selectedTrack)
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if tableView.respondsToSelector("separatorInset") {
            tableView.separatorInset = UIEdgeInsetsZero
        }
        
        if #available(iOS 8.0, *) {
            tableView.layoutMargins = UIEdgeInsetsZero
        }
        
        if #available(iOS 8.0, *) {
            cell.layoutMargins = UIEdgeInsetsZero
        }
    }
    
    func loadPlaylist() {
        let currPlaylist = currentPlaylist!
        if currPlaylist.type != PlaylistType.USER {
            
            self.tracks.removeAll(keepCapacity: false)
            for track:Track in currPlaylist.tracks {
                self.tracks.append(track)
            }
            self.playlistTableView.reloadData()
            
            self.updatePlaylistInfo()
            self.updatePlayTrack(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId)
            return
        }
        
        let progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Loading playlist..", comment:""))
        Requests.getPlaylist(currentPlaylist!.id, respCb: {
                (request:NSURLRequest, response:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            progressHud.hide(true)
            if (error != nil || result == nil) {
                if (error != nil && error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    let message = NSLocalizedString("Internet is not connected. Please try again.", comment:"")
                    ViewUtils.showConfirmAlert(self,
                        title: NSLocalizedString("Failed to fetch", comment:""),
                        message: message,
                        positiveBtnText: NSLocalizedString("Retry", comment:""),
                        positiveBtnCallback: { () -> Void in
                            self.loadPlaylist()
                    }, negativeBtnText: NSLocalizedString("Cancel", comment:""), negativeBtnCallback: nil)
                    return
                }
                ViewUtils.showNoticeAlert(self,
                    title: NSLocalizedString("Failed to fetch", comment:""),
                    message: NSLocalizedString("Failed to fetch playlist", comment:""),
                    btnText: NSLocalizedString("Confirm", comment:""))
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
            
            let original = self.currentPlaylist!
            original.name = playlist!.name
            original.tracks.removeAll(keepCapacity: false)
            self.tracks.removeAll(keepCapacity: false)
            for track:Track in playlist!.tracks {
                original.tracks.append(track)
                self.tracks.append(track)
            }
            
            self.updatePlaylistInfo()
            self.playlistTableView.reloadData()
            self.updatePlayTrack(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId)
        })
    }
    
    @IBAction func onPlayPlaylistBtnClicked(sender: AnyObject) {
        if tracks.count == 0 {
            ViewUtils.showToast(self, message: NSLocalizedString("Playlist empty", comment:""))
            return
        }
        
        let selectedTrack: Track = tracks[0] as Track
        
        PlayerContext.shuffleState = ShuffleState.NOT_SHUFFLE
        
        if currentPlaylist.type != PlaylistType.USER {
            PlayerContext.externalPlaylist = currentPlaylist
        }
        
        var section:String!
        switch (currentPlaylist.type) {
        case .SHARED:
            section = "shared_playlist"
            break
        case .USER:
            section = "base"
            break
        case .EXTERNAL:
            section = currentPlaylist.id
            break
        }
        
        let params: Dictionary<String, AnyObject> = [
            "track": selectedTrack,
            "playlistId": currentPlaylist!.id,
            "section": section
        ]
        
        NSNotificationCenter.defaultCenter().postNotificationName(
            NotifyKey.playerPlay, object: params)
        NSNotificationCenter.defaultCenter().postNotificationName(
            NotifyKey.updateShuffleState, object: nil)
    }
    
    @IBAction func onPlaylistMenuBtnClicked(sender: AnyObject) {
        playlistActionSheet = UIActionSheet()
        playlistActionSheet!.addButtonWithTitle(NSLocalizedString("Shuffle Play", comment:""))
        playlistActionSheet!.addButtonWithTitle(NSLocalizedString("Share", comment:""))
        playlistActionSheet!.addButtonWithTitle(NSLocalizedString("Rename", comment:""))
        playlistActionSheet!.addButtonWithTitle(NSLocalizedString("Delete", comment:""))
        playlistActionSheet!.addButtonWithTitle(NSLocalizedString("Cancel", comment:""))
        playlistActionSheet!.destructiveButtonIndex = 3
        playlistActionSheet!.cancelButtonIndex = 4
        
        if fromPlayer {
            playlistActionSheet!.showInView(self.view)
        } else {
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            
            playlistActionSheet!.showFromTabBar(appDelegate.centerContainer!.tabBar)
        }
        playlistActionSheet!.delegate = self
    }
    
    func actionSheet(actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int) {
        if actionSheet == playlistActionSheet {
            switch(buttonIndex) {
            case 0:
                onShufflePlayPlaylistBtnClicked()
                break
            case 1:
                onSharePlaylistBtnClicked()
                break
            case 2:
                onRenamePlaylistBtnClicked()
                break
            case 3:
                onDeletePlaylistBtnClicked()
                break
            default:
                break
            }
            return
        } else {
            let track = menuSelectedTrack
            var foundIdx = -1
            if track != nil {
                for (idx, track) in tracks.enumerate() {
                    if track.id == track.id {
                        foundIdx = idx
                        break
                    }
                }
            }
            if foundIdx == -1 {
                ViewUtils.showToast(self, message: NSLocalizedString("Track is not in playlist", comment:""))
                return
            }
            
            var idx = buttonIndex
            if currentPlaylist.type == PlaylistType.USER {
                idx += 1
            }
            
            switch(idx) {
            case 0:
                onTrackLikeBtnClicked(menuSelectedTrack!)
                break
            case 1:
                onShareTrackBtnClicked(menuSelectedTrack!)
                break
            case 2:
                onTrackAddToOtherPlaylistBtnClicked(menuSelectedTrack!)
                break
            case 3:
                if currentPlaylist.type == PlaylistType.USER {
                    onDeleteTrackBtnClicked(menuSelectedTrack!)
                }
                break
            default:
                break
            }
        }
        if actionSheet != playlistActionSheet {
            menuSelectedTrack = nil
        }
    }
    
    func onTrackLikeBtnClicked(track:Track) {
        if (Account.getCachedAccount() == nil) {
            showSignin()
            return
        }
        let progressHud = ViewUtils.showProgress(self, message: nil)
        if track.isLiked {
            Like.unlikeTrack(track) { (error) -> Void in
                if error != nil {
                    progressHud.hide(true)
                    ViewUtils.showConfirmAlert(self,
                        title: NSLocalizedString("Failed to save", comment: ""),
                        message: NSLocalizedString("Failed to save unlike info.", comment:""),
                        positiveBtnText:  NSLocalizedString("Retry", comment: ""),
                        positiveBtnCallback: { () -> Void in
                            self.onTrackLikeBtnClicked(track)
                    })
                    return
                }
                progressHud.mode = MBProgressHUDMode.CustomView
                progressHud.customView = UIImageView(image: UIImage(named:"ic_hud_unlike"))
                progressHud.hide(true, afterDelay: 1)
                
            }
        } else {
            Like.likeTrack(track) { (error) -> Void in
                if error != nil {
                    progressHud.hide(true)
                    ViewUtils.showConfirmAlert(self,
                        title: NSLocalizedString("Failed to save", comment: ""),
                        message: NSLocalizedString("Failed to save like info.", comment:""),
                        positiveBtnText:  NSLocalizedString("Retry", comment: ""),
                        positiveBtnCallback: { () -> Void in
                            self.onTrackLikeBtnClicked(track)
                    })
                    return
                }
                progressHud.mode = MBProgressHUDMode.CustomView
                progressHud.customView = UIImageView(image: UIImage(named:"ic_hud_like"))
                progressHud.hide(true, afterDelay: 1)
            }
        }
    }
    
    func onPlayTrackBtnClicked(track: Track) {
        if currentPlaylist.type != PlaylistType.USER {
            PlayerContext.externalPlaylist = currentPlaylist
        }
        var section:String!
        switch (currentPlaylist.type) {
        case .SHARED:
            section = "shared_playlist"
            break
        case .USER:
            section = "base"
            break
        case .EXTERNAL:
            section = currentPlaylist.id
            break
        }
        let params: Dictionary<String, AnyObject> = [
            "track": track,
            "playlistId": currentPlaylist!.id,
            "section": section
        ]
        
        NSNotificationCenter.defaultCenter().postNotificationName(
            NotifyKey.playerPlay, object: params)
        
        if fromPlayer {
            dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func onShareTrackBtnClicked(track: Track) {
        let progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Loading..", comment:""))
        track.shareTrack("playlist") { (error, sharedURL) -> Void in
            progressHud.hide(true)
            if error != nil {
                if (error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    ViewUtils.showConfirmAlert(self,
                        title: NSLocalizedString("Failed to share", comment:""),
                        message: NSLocalizedString("Internet is not connected.", comment:""),
                        positiveBtnText: NSLocalizedString("Retry", comment:""),
                        positiveBtnCallback: { () -> Void in
                            self.onShareTrackBtnClicked(track)
                        }, negativeBtnText: NSLocalizedString("Cancel", comment:""), negativeBtnCallback: nil)
                    return
                }
                ViewUtils.showConfirmAlert(self, title: NSLocalizedString("Failed to share", comment:""),
                    message: NSLocalizedString("Failed to share track", comment:""),
                    positiveBtnText: NSLocalizedString("Retry", comment:""),
                    positiveBtnCallback: { () -> Void in
                        self.onShareTrackBtnClicked(track)
                    }, negativeBtnText: NSLocalizedString("Cancel", comment:""), negativeBtnCallback: nil)
                return
            }
            
            let items:[AnyObject] = [track.title, sharedURL!]
            
            let activityController = UIActivityViewController(
                    activityItems: items, applicationActivities: nil)
            activityController.excludedActivityTypes = [
                    UIActivityTypePrint,
                    UIActivityTypeSaveToCameraRoll,
                    UIActivityTypeAirDrop,
                    UIActivityTypeAssignToContact
                ]
            if #available(iOS 8.0, *) {
                activityController.popoverPresentationController?.sourceView = self.view
            }
            self.presentViewController(activityController, animated:true, completion: nil)
        }
    }
    
    func onTrackAddToOtherPlaylistBtnClicked(track: Track) {
        if (Account.getCachedAccount() == nil) {
            showSignin()
            return
        }
        performSegueWithIdentifier("PlaylistSelectSegue", sender: track)
    }
    
    func onDeleteTrackBtnClicked(track:Track) {
        let progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Deleting..", comment:""))
        currentPlaylist!.deleteTrack(track, afterDelete: { (error) -> Void in
            progressHud.hide(true)
            if error != nil {
                if (error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    ViewUtils.showConfirmAlert(self,
                        title: NSLocalizedString("Failed to delete", comment:""),
                        message: NSLocalizedString("Internet is not connected.", comment:""),
                        positiveBtnText: NSLocalizedString("Retry", comment:""),
                        positiveBtnCallback: { () -> Void in
                            self.onDeleteTrackBtnClicked(track)
                        }, negativeBtnText: NSLocalizedString("Cancel", comment:""), negativeBtnCallback: nil)
                    return
                }
                ViewUtils.showConfirmAlert(self, title: NSLocalizedString("Failed to delete", comment:""),
                    message: NSLocalizedString("Failed to delete track", comment:""),
                    positiveBtnText: NSLocalizedString("Retry", comment:""), positiveBtnCallback: { () -> Void in
                        self.onDeleteTrackBtnClicked(track)
                    }, negativeBtnText: NSLocalizedString("Cancel", comment:""), negativeBtnCallback: nil)
                return
            }
            self.loadPlaylist()
        })
    }
    
    func onShufflePlayPlaylistBtnClicked() {
        if tracks.count == 0 {
            ViewUtils.showToast(self, message: NSLocalizedString("Playlist empty", comment:""))
            return
        }
        
        let randomIndex = Int(arc4random_uniform(UInt32(tracks.count)))
        let selectedTrack: Track = tracks[randomIndex] as Track
        
        PlayerContext.shuffleState = ShuffleState.SHUFFLE
        
        if currentPlaylist.type != PlaylistType.USER {
            PlayerContext.externalPlaylist = currentPlaylist
        }
        var section:String!
        switch (currentPlaylist.type) {
        case .SHARED:
            section = "shared_playlist"
            break
        case .USER:
            section = "base"
            break
        case .EXTERNAL:
            section = currentPlaylist.id
            break
        }
        
        let params: Dictionary<String, AnyObject> = [
            "track": selectedTrack,
            "playlistId": currentPlaylist!.id,
            "section": section
        ]
        
        NSNotificationCenter.defaultCenter().postNotificationName(
            NotifyKey.playerPlay, object: params)
        NSNotificationCenter.defaultCenter().postNotificationName(
            NotifyKey.updateShuffleState, object: nil)
    }
    
    func onSharePlaylistBtnClicked() {
        let progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Loading..", comment:""))
        Requests.sharePlaylist(currentPlaylist!, respCb: {
                (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            progressHud.hide(true)
            var message:String = NSLocalizedString("Failed to share playlist.", comment:"")
            var success = true
            if error != nil || result == nil {
                if (error != nil && error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    message = NSLocalizedString("Internet is not connected", comment:"")
                }
                success = false
            }
            
            if !success {
                ViewUtils.showNoticeAlert(self,
                    title: NSLocalizedString("Failed to share", comment:""),
                    message: message)
                return
            }
            
            var json = JSON(result!)
        
            if ((json["success"].bool ?? false) &&
                    json["obj"].dictionary != nil && json["obj"]["uid"].string != nil) {
                    
                let uid = json["obj"]["uid"].string
                let url = "http://dropbeat.net/?playlist=\(uid!)"
                        
                let items:[AnyObject] = [self.currentPlaylist!.name, url]
                
                let activityController = UIActivityViewController(
                        activityItems: items, applicationActivities: nil)
                activityController.excludedActivityTypes = [
                        UIActivityTypePrint,
                        UIActivityTypeSaveToCameraRoll,
                        UIActivityTypeAirDrop,
                        UIActivityTypeAssignToContact
                    ]
                if #available(iOS 8.0, *) {
                    activityController.popoverPresentationController?.sourceView = self.view
                }
                self.presentViewController(activityController, animated:true, completion: nil)
            } else {
                ViewUtils.showNoticeAlert(self,
                    title: NSLocalizedString("Failed to share", comment:""),
                    message: message)
            }
        })
    }
    
    func onDeletePlaylistBtnClicked() {
        let playlists = PlayerContext.playlists
        if (playlists.count == 1) {
            ViewUtils.showNoticeAlert(self,
                title: NSLocalizedString("Failed to delete", comment:""),
                message: NSLocalizedString("At least one playlist should exist", comment:""))
            return
        }
        let removePlaylist = currentPlaylist!
        let confirmMessage = NSString.localizedStringWithFormat(
                NSLocalizedString("Are you sure you want do delete '%@' playlist with %d tracks?", comment:""),
                removePlaylist.name, removePlaylist.tracks.count) as String
        
        ViewUtils.showConfirmAlert(
            self, title: NSLocalizedString("Are you sure?", comment:""),
            message: confirmMessage,
            positiveBtnText: NSLocalizedString("Delete", comment:""), positiveBtnCallback: {
                
                let progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Deleting..", comment:""))
                
                Requests.deletePlaylist(removePlaylist.id, respCb: {
                        (request:NSURLRequest, response: NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
                    
                    progressHud.hide(true)
                    if (error != nil || result == nil) {
                        var message:String?
                        if (error != nil && error!.domain == NSURLErrorDomain &&
                                error!.code == NSURLErrorNotConnectedToInternet) {
                            message = NSLocalizedString("Internet is not connected", comment:"")
                        }
                        if (message == nil) {
                            message = NSLocalizedString("Failed to update playlist", comment:"")
                        }
                        ViewUtils.showNoticeAlert(self, title: NSLocalizedString("Failed to delete", comment:""),
                            message: message!)
                        return
                    }
                    let res = result as! NSDictionary
                    let success:Bool = res.objectForKey("success") as! Bool? ?? false
                    if (!success) {
                        let message = "Failed to update playlist"
                        ViewUtils.showNoticeAlert(self,
                            title: NSLocalizedString("Failed to delete", comment:""), message: message)
                        return
                    }
                    if PlayerContext.currentPlaylistId == removePlaylist.id {
                        NSNotificationCenter.defaultCenter().postNotificationName(
                            NotifyKey.playerStop, object: nil)
                        PlayerContext.shuffleState = ShuffleState.NOT_SHUFFLE
                        NSNotificationCenter.defaultCenter().postNotificationName(
                            NotifyKey.updateShuffleState, object: nil)
                    }
                    
                    self.navigationController!.popViewControllerAnimated(true)
                })
            })
    }
    
    func onRenamePlaylistBtnClicked() {
        let targetPlaylist = currentPlaylist!
        
        ViewUtils.showTextInputAlert(
            self, title: NSLocalizedString("Change playlist name", comment:""),
            message: NSLocalizedString("Type new playlist name", comment:""),
            placeholder: NSLocalizedString("Playlist 01", comment:""),
            positiveBtnText: NSLocalizedString("Change", comment:""),
            positiveBtnCallback: { (result) -> Void in
                if (result.characters.count == 0) {
                    return
                }
                
                let progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Changing..", comment:""))
                
                Requests.changePlaylistName(
                    targetPlaylist.id, name: result, respCb: {
                        (request:NSURLRequest, response:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
                    progressHud.hide(true)
                    if (error != nil) {
                        var message:String?
                        if (error != nil && error!.domain == NSURLErrorDomain &&
                                error!.code == NSURLErrorNotConnectedToInternet) {
                            message = NSLocalizedString("Internet is not connected", comment:"")
                        }
                        if (message == nil) {
                            message = NSLocalizedString("Failed to rename playlist", comment:"")
                        }
                        ViewUtils.showNoticeAlert(self, title: NSLocalizedString("Failed to change", comment:""), message: message!)
                        return
                    }
                        
                    self.loadPlaylist()
                })
            })
    }
    
    func onMenuBtnClicked(sender: PlaylistTableViewCell) {
        let indexPath:NSIndexPath = playlistTableView.indexPathForCell(sender)!
        menuSelectedTrack = tracks[indexPath.row]
        
        let actionSheet = UIActionSheet()
        
        if currentPlaylist.type != PlaylistType.USER {
            if menuSelectedTrack!.isLiked {
                actionSheet.addButtonWithTitle(NSLocalizedString("Unike", comment:""))
            } else {
                actionSheet.addButtonWithTitle(NSLocalizedString("Like", comment:""))
            }
        }
        actionSheet.addButtonWithTitle(NSLocalizedString("Share", comment:""))
        actionSheet.addButtonWithTitle(NSLocalizedString("Add to other playlist", comment:""))
        
        if currentPlaylist.type == PlaylistType.USER {
            actionSheet.addButtonWithTitle(NSLocalizedString("Delete", comment:""))
        }
        
        actionSheet.addButtonWithTitle(NSLocalizedString("Cancel", comment:""))
        
        if currentPlaylist.type == PlaylistType.USER {
            actionSheet.destructiveButtonIndex = 2
        }
        actionSheet.cancelButtonIndex = 3
        if fromPlayer {
            actionSheet.showInView(self.view)
        } else {
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            
            actionSheet.showFromTabBar(appDelegate.centerContainer!.tabBar)
        }
        actionSheet.delegate = self
    }
    
    func updatePlayTrack(noti: NSNotification) {
        var params = noti.object as! Dictionary<String, AnyObject>
        let track = params["track"] as! Track
        let playlistId:String? = params["playlistId"] as? String
        updatePlayTrack(track, playlistId: playlistId)
    }
    
    func updatePlayTrack(track:Track?, playlistId:String?) {
        let indexPath = playlistTableView.indexPathForSelectedRow
        if (indexPath != nil) {
            let preSelectedTrack:Track = tracks[indexPath!.row]
            if (preSelectedTrack.id != track!.id ||
                (playlistId == nil && playlistId != currentPlaylist!.id)) {
                playlistTableView.deselectRowAtIndexPath(indexPath!, animated: false)
            }
        }
        
        if (playlistId == nil || playlistId != currentPlaylist!.id) {
            return
        }
        
        for (idx, t) in currentPlaylist!.tracks.enumerate() {
            if (t.id == track!.id) {
                playlistTableView.selectRowAtIndexPath(NSIndexPath(forRow: idx, inSection: 0),
                    animated: true, scrollPosition: UITableViewScrollPosition.None)
                break
            }
        }
    }
    
    func importPlaylist(callback: (playlist:Playlist?, error:NSError?) -> Void) {
        Requests.createPlaylist(currentPlaylist.name) {
            (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            if (error != nil || result == nil) {
                callback(playlist:nil, error: error != nil ? error :
                    NSError(domain: "importPlaylist", code: 0, userInfo: nil))
                return
            }
            
            let importedPlaylist:Playlist? = Playlist.parsePlaylist(result!)
            if importedPlaylist == nil {
                callback(playlist:nil, error: NSError(domain: "importPlaylist", code: 0, userInfo: nil))
                return
            }
            for track in self.currentPlaylist.tracks {
                importedPlaylist!.tracks.append(track)
            }
            
            var data = [[String:AnyObject]]()
            for t in self.currentPlaylist.tracks {
                data.append(["title": t.title, "id": t.id, "type": t.type.rawValue])
            }
            
            Requests.setPlaylist(importedPlaylist!.id, data: data, respCb: {
                    (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
                if (result == nil || error != nil || !(JSON(result!)["success"].bool ?? false)) {
                    Requests.deletePlaylist(importedPlaylist!.id, respCb: Requests.EMPTY_RESPONSE_CALLBACK)
                    callback(playlist:nil, error: NSError(domain: "importPlaylist", code: 0, userInfo: ["message":"Failed to save playlist"]))
                    return
                }
                callback(playlist:importedPlaylist, error:nil)
            })
        }
    }
    
    @IBAction func onFakeBackBtnClicked(sender: AnyObject) {
        if fromPlayer {
            dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    @IBAction func onLikeBtnClicked(sender: AnyObject) {
        if (Account.getCachedAccount() == nil) {
            showSignin()
            return
        }
        if isLiked {
            return
        }
        let progressHud = ViewUtils.showProgress(self, message: nil)
        importPlaylist { (playlist, error) -> Void in
            progressHud.hide(true)
            if error != nil {
                var message:String?
                if (error != nil && error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    message = "Internet is not connected"
                }
                if (message == nil) {
                    message = "Failed to save playlist"
                }
                ViewUtils.showNoticeAlert(self, title: "Failed to save", message: message!)
                return
            }
            self.isLiked = true
            self.updateLikeBtn()
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "PlaylistSelectSegue" {
            let playlistSelectVC:PlaylistSelectViewController = segue.destinationViewController as! PlaylistSelectViewController
            playlistSelectVC.targetTrack = sender as? Track
            playlistSelectVC.fromSection = "playlist"
            playlistSelectVC.caller = self
        }
    }
    
    func showSignin() {
        NeedAuthViewController.showNeedAuthViewController(self)
    }
    
    func updateLikeBtn() {
        if isLiked {
            likeBtn.setImage(UIImage(named:"ic_heart_fill_btn_big"), forState: UIControlState.Normal)
        } else {
            likeBtn.setImage(UIImage(named:"ic_heart_btn_big"), forState: UIControlState.Normal)
        }
    }
}
