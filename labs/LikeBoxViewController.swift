//
//  LikeBoxViewController.swift
//  labs
//
//  Created by vulpes on 2015. 8. 21..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class LikeBoxViewController: BaseViewController,
        UITableViewDelegate, UITableViewDataSource, PlaylistTableViewDelegate,
        UIActionSheetDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tracksCountView: UILabel!
    @IBOutlet weak var shuffleBtn: UIButton!
    
    
    private var tracks:[Track] = [Track]()
    private var menuSelectedTrack:Track?
    private var refreshControl:UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        shuffleBtn.layer.cornerRadius = 3.0
        shuffleBtn.layer.borderWidth = 1
        shuffleBtn.layer.borderColor = UIColor(netHex:0xcccccc).CGColor
        
        refreshControl = UIRefreshControl()
        refreshControl.tintColor = UIColor(netHex:0xc380fc)
        refreshControl.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.ValueChanged)
        
        let refreshControlTitle = NSAttributedString(
            string: NSLocalizedString("Pull to refresh", comment: ""),
            attributes: [NSForegroundColorAttributeName: UIColor(netHex: 0x909090)])
        refreshControl.attributedTitle = refreshControlTitle
        tableView.insertSubview(refreshControl, atIndex: 0)
        
        
        let account = Account.getCachedAccount()!
        if account.likes.count > 0 {
            for i in reverse(0...account.likes.count - 1) {
                let like = account.likes[i]
                self.tracks.append(like.track)
            }
        }
        tracksCountView.text = NSString.localizedStringWithFormat(
            NSLocalizedString("%d tracks", comment:""), account.likes.count) as String
        self.tableView.reloadData()
        self.updatePlayTrack(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = "LikeBoxViewScreen"
        
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
        
        refresh()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.playerStop, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.playerPlay, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.updateShuffleState, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.updatePlay, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    @IBAction func onShuffleBtnClicked(sender: AnyObject) {
        if tracks.count == 0 {
            ViewUtils.showToast(self, message: NSLocalizedString("Like list empty", comment:""))
            return
        }
        
        let randomIndex = Int(arc4random_uniform(UInt32(tracks.count)))
        var selectedTrack: Track = tracks[randomIndex] as Track
        
        PlayerContext.shuffleState = ShuffleState.SHUFFLE
        PlayerContext.externalPlaylist = Playlist(
            id: getPlaylistId(),
            name: getPlaylistName(),
            tracks: tracks
        )
        
        
        var params: Dictionary<String, AnyObject> = [
            "track": selectedTrack,
            "playlistId": getPlaylistId()
        ]
        
        NSNotificationCenter.defaultCenter().postNotificationName(
            NotifyKey.playerPlay, object: params)
        NSNotificationCenter.defaultCenter().postNotificationName(
            NotifyKey.updateShuffleState, object: nil)
    }
    
    func onMenuBtnClicked(sender: PlaylistTableViewCell) {
        
        let indexPath:NSIndexPath = tableView.indexPathForCell(sender)!
        menuSelectedTrack = tracks[indexPath.row]
        
        let actionSheet = UIActionSheet()
        
        actionSheet.addButtonWithTitle(NSLocalizedString("Share", comment:""))
        actionSheet.addButtonWithTitle(NSLocalizedString("Add to playlist", comment:""))
        actionSheet.addButtonWithTitle(NSLocalizedString("Delete", comment:""))
        
        actionSheet.addButtonWithTitle(NSLocalizedString("Cancel", comment:""))
        
        actionSheet.destructiveButtonIndex = 2
        actionSheet.cancelButtonIndex = 3
        actionSheet.showInView(self.view)
        actionSheet.delegate = self
    }
    
    func actionSheet(actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int) {
        let track = menuSelectedTrack
        var foundIdx = -1
        if track != nil {
            for (idx, track) in enumerate(tracks) {
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
        
        switch(buttonIndex) {
        case 0:
            onShareTrackBtnClicked(menuSelectedTrack!)
            break
        case 1:
            onTrackAddToOtherPlaylistBtnClicked(menuSelectedTrack!)
            break
        case 2:
            doDislike(menuSelectedTrack!)
            break
        default:
            break
        }
        menuSelectedTrack = nil
    }
    
    func getPlaylistId() -> String {
        return "like_box"
    }
    
    func getPlaylistName() -> String {
        return "Like box"
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var selectedTrack: Track = tracks[indexPath.row] as Track
        onPlayTrackBtnClicked(selectedTrack)
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if tableView.respondsToSelector("separatorInset") {
            tableView.separatorInset = UIEdgeInsetsZero
        }
        
        if tableView.respondsToSelector("layoutMargins") {
            tableView.layoutMargins = UIEdgeInsetsZero
        }
        
        if cell.respondsToSelector("layoutMargins") {
            cell.layoutMargins = UIEdgeInsetsZero
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let track:Track = tracks[indexPath.row]
        var cell:PlaylistTableViewCell = tableView.dequeueReusableCellWithIdentifier(
                "PlaylistTableViewCell", forIndexPath: indexPath) as! PlaylistTableViewCell
        if (getPlaylistId() == PlayerContext.currentPlaylistId &&
                PlayerContext.currentTrack != nil &&
                PlayerContext.currentTrack!.id == track.id) {
            cell.setSelected(true, animated: false)
        }
        cell.trackTitle.text = track.title
        cell.delegate = self
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return count(tracks)
    }
    
    func updatePlayTrack(noti: NSNotification) {
        var params = noti.object as! Dictionary<String, AnyObject>
        var track = params["track"] as! Track
        var playlistId:String? = params["playlistId"] as? String
        updatePlayTrack(track, playlistId: playlistId)
    }
    
    func updatePlayTrack(track:Track?, playlistId:String?) {
        var indexPath = tableView.indexPathForSelectedRow()
        if (indexPath != nil) {
            var preSelectedTrack:Track = tracks[indexPath!.row]
            if (preSelectedTrack.id != track!.id ||
                (playlistId == nil && playlistId != getPlaylistId())) {
                tableView.deselectRowAtIndexPath(indexPath!, animated: false)
            }
        }
        
        if (playlistId == nil || playlistId != getPlaylistId()) {
            return
        }
        
        for (idx, t) in enumerate(tracks) {
            if (t.id == track!.id) {
                tableView.selectRowAtIndexPath(NSIndexPath(forRow: idx, inSection: 0),
                    animated: true, scrollPosition: UITableViewScrollPosition.None)
                break
            }
        }
    }
    
    func sender() {}
    
    func appWillEnterForeground () {
        refresh()
    }
    
    func refresh() {
        let account = Account.getCachedAccount()!
        
        var progressHud:MBProgressHUD?
        if !refreshControl.refreshing {
            progressHud = ViewUtils.showProgress(self, message: "")
        }
        account.syncLikeInfo { (error) -> Void in
            progressHud?.hide(true)
            self.refreshControl.endRefreshing()
            if error != nil {
                ViewUtils.showNoticeAlert(self,
                    title: NSLocalizedString("Failed to load", comment:""),
                    message: NSLocalizedString("Failed to load like box", comment: ""))
                return
            }
            self.tracks.removeAll(keepCapacity: false)
            if account.likes.count > 0 {
                for i in reverse(0...account.likes.count - 1) {
                    let like = account.likes[i]
                    self.tracks.append(like.track)
                }
            }
            self.tableView.reloadData()
            self.updatePlayTrack(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId)
        }
    }
    
    func onTrackLikeBtnClicked(track:Track) {
        let progressHud = ViewUtils.showProgress(self, message: nil)
        if track.isLiked {
            track.doUnlike({ (error) -> Void in
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
                progressHud.customView = UIImageView(image: UIImage(named:"ic_hud_unlike.png"))
                progressHud.hide(true, afterDelay: 1)
                
            })
        } else {
            track.doLike({ (error) -> Void in
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
                progressHud.customView = UIImageView(image: UIImage(named:"ic_hud_like.png"))
                progressHud.hide(true, afterDelay: 1)
            })
        }
    }
    
    func onPlayTrackBtnClicked(track: Track) {
        PlayerContext.externalPlaylist = Playlist(
            id: getPlaylistId(),
            name: getPlaylistName(),
            tracks: tracks)
        
        var params: Dictionary<String, AnyObject> = [
            "track": track,
            "playlistId": getPlaylistId()
        ]
        
        NSNotificationCenter.defaultCenter().postNotificationName(
            NotifyKey.playerPlay, object: params)
    }
    
    func onShareTrackBtnClicked(track: Track) {
        let progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Loading..", comment:""))
        track.shareTrack("playlist", afterShare: { (error, uid) -> Void in
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
            let shareUrl = "http://dropbeat.net/?track=" + uid!
            let shareTitle = track.title
            
            var items:[AnyObject] = [shareTitle, shareUrl]
            
            let activityController = UIActivityViewController(
                    activityItems: items, applicationActivities: nil)
            activityController.excludedActivityTypes = [
                    UIActivityTypePrint,
                    UIActivityTypeSaveToCameraRoll,
                    UIActivityTypeAirDrop,
                    UIActivityTypeAssignToContact
                ]
            if activityController.respondsToSelector("popoverPresentationController:") {
                activityController.popoverPresentationController?.sourceView = self.view
            }
            self.presentViewController(activityController, animated:true, completion: nil)
        })
    }
    
    func onTrackAddToOtherPlaylistBtnClicked(track: Track) {
        performSegueWithIdentifier("PlaylistSelectSegue", sender: track)
    }
    
    func doDislike(track:Track) {
        if !track.isLiked {
            return
        }
        let progressHud = ViewUtils.showProgress(self, message: "")
        track.doUnlike({ (error) -> Void in
            if error != nil {
                progressHud.hide(true)
                ViewUtils.showConfirmAlert(self,
                    title: NSLocalizedString("Failed to save", comment: ""),
                    message: NSLocalizedString("Failed to save dislike info.", comment:""),
                    positiveBtnText:  NSLocalizedString("Retry", comment: ""),
                    positiveBtnCallback: { () -> Void in
                        self.doDislike(track)
                })
                return
            }
            progressHud.mode = MBProgressHUDMode.CustomView
            progressHud.customView = UIImageView(image: UIImage(named:"ic_hud_unlike.png"))
            progressHud.hide(true, afterDelay: 1)
            self.refresh()
        })
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "PlaylistSelectSegue" {
            let playlistSelectVC:PlaylistSelectViewController = segue.destinationViewController as! PlaylistSelectViewController
            playlistSelectVC.targetTrack = sender as? Track
            playlistSelectVC.fromSection = "playlist"
            playlistSelectVC.caller = self
        }
    }
    
    @IBAction func onCloseBtn(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
