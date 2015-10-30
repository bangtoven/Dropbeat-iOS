//
//  PlaylistViewController.swift
//  labs
//
//  Created by vulpes on 2015. 5. 18..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class PlaylistViewController: BaseViewController {

    @IBOutlet weak var playlistTableView: UITableView!

    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var toolbarTopConstraint: NSLayoutConstraint!

    @IBOutlet weak var deleteRowBarButton: UIBarButtonItem!
    @IBOutlet var checkAllBarButton: UIBarButtonItem!
    @IBOutlet var importBarButton: UIBarButtonItem!
    @IBOutlet var shareBarButton: UIBarButtonItem!
    
    var currentPlaylist:Playlist!
    private var tracks:[Track] { return self.currentPlaylist.tracks }
    private var reordered = false
    
    // MARK: - methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.screenName = "PlaylistViewScreen"
        
        self.toolbarTopConstraint.constant = -44
        self.toolbar.hidden = true
        self.toolbar.setBackgroundImage(UIImage(named: "toolbar_background"), forToolbarPosition: .Any, barMetrics: .Default)
        
        self.playlistTableView.allowsMultipleSelectionDuringEditing = true
        loadPlaylist()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "trackChanged", name: DropbeatPlayerTrackChangedNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: DropbeatPlayerTrackChangedNotification, object: nil)
    }
    
    func trackChanged() {
        guard let track = DropbeatPlayer.defaultPlayer.currentTrack,
            playlistId = DropbeatPlayer.defaultPlayer.currentPlaylist?.id else {
                return
        }
        
        if self.editing {
            return
        }
        
        let indexPath = playlistTableView.indexPathForSelectedRow
        if (indexPath != nil) {
            let preSelectedTrack:Track = tracks[indexPath!.row]
            if (preSelectedTrack.id != track.id ||
                playlistId != currentPlaylist!.id) {
                    playlistTableView.deselectRowAtIndexPath(indexPath!, animated: false)
            }
        }
        
        if playlistId != currentPlaylist!.id {
            return
        }
        
        for (idx, t) in currentPlaylist!.tracks.enumerate() {
            if (t.id == track.id) {
                playlistTableView.selectRowAtIndexPath(NSIndexPath(forRow: idx, inSection: 0),
                    animated: true, scrollPosition: UITableViewScrollPosition.None)
                break
            }
        }
    }
    
    func loadPlaylist() {
        if self.editing {
            self.setEditing(false, animated: true)
        }
        
        self.title = currentPlaylist.name
        
        switch currentPlaylist.type {
        case .USER:
            self.navigationItem.rightBarButtonItems = [self.editButtonItem(), self.shareBarButton]
        case .SHARED:
            self.navigationItem.rightBarButtonItem = self.importBarButton
        case .EXTERNAL:
            self.navigationItem.rightBarButtonItems = nil
        }
        
        if currentPlaylist.type != .USER {
            self.playlistTableView.reloadData()
            self.trackChanged()
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
            
            self.currentPlaylist = Playlist.parsePlaylist(res["playlist"])
            
            self.playlistTableView.reloadData()
            self.trackChanged()
        })
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let insets = UIEdgeInsetsMake(0, 0, 44, 0)
        playlistTableView.contentInset = insets
    }
}

// MARK: - table view
extension PlaylistViewController : UITableViewDelegate, UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tracks.count
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var title: String {
            if self.tracks.count == 0 {
                return NSLocalizedString("Empty playlist", comment:"")
            } else {
                return NSString.localizedStringWithFormat(
                    NSLocalizedString("%d tracks", comment: ""), currentPlaylist!.tracks.count) as String
            }
        }
        
        return "  " + title
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:PlaylistTrackTableViewCell = tableView.dequeueReusableCellWithIdentifier(
            "PlaylistTrackTableViewCell", forIndexPath: indexPath) as! PlaylistTrackTableViewCell
        
        guard indexPath.row < tracks.count else {
            print("Index out of bounds in playlist view.")
            return cell
        }
        
        let track = tracks[indexPath.row]
        cell.trackTitle.text = track.title

        cell.titleLeftMargin.constant = editing ? 2 : 40
        cell.titleRightMargin.constant = editing ? 8 : 40
        cell.icon.hidden = editing
        cell.menuBtn.hidden = editing

        if self.editing {
            cell.setSelected(false, animated: false)
        } else if (currentPlaylist.id == DropbeatPlayer.defaultPlayer.currentPlaylist?.id &&
            DropbeatPlayer.defaultPlayer.currentTrack != nil &&
            DropbeatPlayer.defaultPlayer.currentTrack!.id == track.id) {
                cell.setSelected(true, animated: false)
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if tableView.editing {
            self.onSelectedRowsChanged()
        } else {
            DropbeatPlayer.defaultPlayer.currentPlaylist = currentPlaylist
            DropbeatPlayer.defaultPlayer.play(tracks[indexPath.row])
        }
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        if tableView.editing {
            self.onSelectedRowsChanged()
        }
    }
}

// MARK: Edit
extension PlaylistViewController {
    override func setEditing(editing: Bool, animated: Bool) {
        guard currentPlaylist.type == .USER else {
            return
        }
        
        if self.editing == true && editing == false {
            if reordered {
                self.updateReorderedTracks()
            }
        }
        
        super.setEditing(editing, animated: animated)
        
        // navigation item
        self.navigationItem.leftBarButtonItem = editing ? self.checkAllBarButton : nil
        self.navigationItem.rightBarButtonItems = editing ? [self.editButtonItem()] : [self.editButtonItem(), self.shareBarButton]
        
        // toolbar animation
        let duration = animated ? 0.2 : 0
        let navBar = self.navigationController?.navigationBar
        if editing {
            navBar?.translucent = false
            navBar?.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
            navBar?.shadowImage = UIImage()
            
            self.toolbar.hidden = false
            self.toolbarTopConstraint.constant = 0
            UIView.animateWithDuration(duration, animations: { () -> Void in
                self.view.layoutIfNeeded()
            })
        } else {
            self.toolbarTopConstraint.constant = -44
            UIView.animateWithDuration(duration, animations: { () -> Void in
                self.view.layoutIfNeeded()
                }, completion: { (finished) -> Void in
                    self.toolbar.hidden = true
                    navBar?.shadowImage = nil
                    navBar?.setBackgroundImage(nil, forBarMetrics: UIBarMetrics.Default)
            })
        }
        
        // table view
        self.playlistTableView.setEditing(editing, animated: false)
        self.playlistTableView.reloadData()
    }
    
    @IBAction func toggleSelectAll(sender: UIBarButtonItem) {
        if let count = playlistTableView.indexPathsForSelectedRows?.count where count == tracks.count {
            for i in 0..<tracks.count {
                let indexPath = NSIndexPath(forRow: i, inSection: 0)
                playlistTableView.deselectRowAtIndexPath(indexPath, animated: false)
            }
        } else {
            for i in 0..<tracks.count {
                let indexPath = NSIndexPath(forRow: i, inSection: 0)
                playlistTableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: .None)
            }
        }
        self.onSelectedRowsChanged()
    }
    
    func onSelectedRowsChanged() {
        let count = playlistTableView.indexPathsForSelectedRows?.count ?? 0
        
        deleteRowBarButton.enabled = (count != 0)
        
        checkAllBarButton.image = (count == tracks.count) ?
            UIImage(named: "ic_check_all_filled") :
            UIImage(named: "ic_check_all")
    }
    
    @IBAction func onDeleteTrackBtnClicked(sender: UIBarButtonItem) {
        for indexPath in playlistTableView.indexPathsForSelectedRows ?? [] {
            let trackToDelete = tracks[indexPath.row]
            if trackToDelete.id == DropbeatPlayer.defaultPlayer.currentTrack?.id {
                DropbeatPlayer.defaultPlayer.stop()
            }
        }
        
        var newTracks : [Track] {
            var newTracks = [Track]()
            for row in 0..<tracks.count {
                let indexPath = NSIndexPath(forRow: row, inSection: 0)
                let cell = playlistTableView.cellForRowAtIndexPath(indexPath)
                if cell?.selected == false {
                    newTracks.append(tracks[row])
                }
            }
            return newTracks
        }
        
        let progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Deleting..", comment:""))
        currentPlaylist.setTracks(newTracks) { (error) -> Void in
            progressHud.hide(true)
            if error != nil {
                var message = NSLocalizedString("Failed to delete track", comment:"")
                if (error!.domain == NSURLErrorDomain &&
                    error!.code == NSURLErrorNotConnectedToInternet) {
                        message =  NSLocalizedString("Internet is not connected.", comment:"")
                }
                
                ViewUtils.showConfirmAlert(self, title: NSLocalizedString("Failed to delete", comment:""),
                    message: message,
                    positiveBtnText: NSLocalizedString("Retry", comment:""), positiveBtnCallback: { () -> Void in
                        self.onDeleteTrackBtnClicked(sender)
                    }, negativeBtnText: NSLocalizedString("Cancel", comment:""), negativeBtnCallback: nil)
                return
            }
            
            self.loadPlaylist()
        }
    }
    
    @IBAction func onRenamePlaylistBtnClicked(sender: UIBarButtonItem) {
        let targetPlaylist = currentPlaylist!
        
        ViewUtils.showTextInputAlert(
            self, title: NSLocalizedString("Change playlist name", comment:""),
            message: NSLocalizedString("Type new playlist name", comment:""),
            placeholder: NSLocalizedString("Playlist name", comment:""),
            text: targetPlaylist.name,
            positiveBtnText: NSLocalizedString("Change", comment:""),
            positiveBtnCallback: { (newName) -> Void in
                if (newName.characters.count == 0) {
                    return
                }
                
                let progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Changing..", comment:""))
                
                Requests.changePlaylistName(
                    targetPlaylist.id, name: newName, respCb: {
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
                        
                        self.currentPlaylist.name = newName
                        self.loadPlaylist()
                })
        })
    }
    
    @IBAction func onDeletePlaylistBtnClicked(sender: UIBarButtonItem) {
        let playlists = Playlist.allPlaylists
        if (playlists.count == 1) {
            ViewUtils.showNoticeAlert(self,
                title: NSLocalizedString("Failed to delete", comment:""),
                message: NSLocalizedString("At least one playlist should exist", comment:""))
            return
        }
        let removePlaylist = currentPlaylist!
        let confirmMessage = NSString.localizedStringWithFormat(
            NSLocalizedString("Are you sure you want to delete '%@' playlist with %d tracks?", comment:""),
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
                    if DropbeatPlayer.defaultPlayer.currentPlaylist?.id == removePlaylist.id {
                        
                        DropbeatPlayer.defaultPlayer.shuffleState = ShuffleState.NOT_SHUFFLE
                        DropbeatPlayer.defaultPlayer.stop()
                        
                    }
                    
                    self.editing = false
                    self.navigationController?.popViewControllerAnimated(true)
                })
        })
    }
}

// MARK: Reorder 
extension PlaylistViewController {
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return currentPlaylist.type == .USER
    }
    
    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        reordered = true
        
        let t = currentPlaylist.tracks.removeAtIndex(sourceIndexPath.row)
        currentPlaylist.tracks.insert(t, atIndex: destinationIndexPath.row)
    }
    
    @IBAction func reverseTracksOrder(sender: AnyObject) {
        reordered = true
        currentPlaylist.tracks = tracks.reverse()
        playlistTableView.reloadData()
    }
    
    func updateReorderedTracks() {
        guard reordered else {
            return
        }
        
        let progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Deleting..", comment:""))
        currentPlaylist.setTracks(tracks) { (error) -> Void in
            progressHud.hide(true)
            if error != nil {
                var message = NSLocalizedString("Failed to delete track", comment:"")
                if (error!.domain == NSURLErrorDomain &&
                    error!.code == NSURLErrorNotConnectedToInternet) {
                        message =  NSLocalizedString("Internet is not connected.", comment:"")
                }
                
                ViewUtils.showConfirmAlert(self, title: NSLocalizedString("Failed to delete", comment:""),
                    message: message,
                    positiveBtnText: NSLocalizedString("Retry", comment:""), positiveBtnCallback: { () -> Void in
                        self.updateReorderedTracks()
                    }, negativeBtnText: NSLocalizedString("Cancel", comment:""), negativeBtnCallback:{ () -> Void in
                        self.reordered = false
                })
                return
            }
            
            self.reordered = false
            self.loadPlaylist()
        }
    }
}

// MARK: Actions on playlist

extension PlaylistViewController {
    
    @IBAction func onImportBtnClicked(sender: AnyObject) {
        if (Account.getCachedAccount() == nil) {
            NeedAuthViewController.showNeedAuthViewController(self)
            return
        }
        
        let progressHud = ViewUtils.showProgress(self, message: nil)
        Playlist.importPlaylist(self.currentPlaylist) { (playlist, error) -> Void in
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
            
            self.currentPlaylist = playlist
            self.loadPlaylist()
        }
    }
    
    @IBAction func onSharePlaylistBtnClicked(sender: UIBarButtonItem) {
        let progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Loading..", comment:""))
        Requests.sharePlaylist(currentPlaylist!, respCb: {
            (req, resp, result, error) -> Void in
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
                    
                    activityController.popoverPresentationController?.sourceView = self.view
                    self.presentViewController(activityController, animated:true, completion: nil)
            } else {
                ViewUtils.showNoticeAlert(self,
                    title: NSLocalizedString("Failed to share", comment:""),
                    message: message)
            }
        })
    }
}

// MARK: Actions on track
extension PlaylistViewController {
    
    @IBAction func onMenuBtnClicked(sender: UIButton) {
        let indexPath = playlistTableView.indexPathOfCellContains(sender)
        
        let selectedTrack = tracks[indexPath!.row]
        
        let actionSheet = UIAlertController(title: selectedTrack.title, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        if currentPlaylist.type != PlaylistType.USER {
            let title = selectedTrack.isLiked ?
                NSLocalizedString("Unlike", comment:"") :
                NSLocalizedString("Like", comment:"")
            actionSheet.addAction(UIAlertAction(
                title: title,
                style: .Default,
                handler: { (action) -> Void in
                    self.onTrackLikeBtnClicked(selectedTrack)
            }))
        }
        
        actionSheet.addAction(UIAlertAction(
            title: NSLocalizedString("Share", comment:""),
            style: .Default,
            handler: { (action) -> Void in
                self.onShareTrackBtnClicked(selectedTrack)
        }))
        
        actionSheet.addAction(UIAlertAction(
            title: NSLocalizedString("Add to other playlist", comment:""),
            style: .Default,
            handler: { (action) -> Void in
                self.onAddToOtherPlaylistBtnClicked(selectedTrack)
        }))
        
        actionSheet.addAction(UIAlertAction(
            title: NSLocalizedString("Cancel", comment:""),
            style: .Cancel,
            handler: nil))
        
        self.presentViewController(actionSheet, animated: true, completion: nil)
    }
    
    func onTrackLikeBtnClicked(track:Track) {
        if (Account.getCachedAccount() == nil) {
            NeedAuthViewController.showNeedAuthViewController(self)
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
                    if error!.domain == NeedAuthViewController.NeedAuthErrorDomain {
                        NeedAuthViewController.showNeedAuthViewController(self)
                    }
                    
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
            activityController.popoverPresentationController?.sourceView = self.view
            self.presentViewController(activityController, animated:true, completion: nil)
        }
    }
    
    func onAddToOtherPlaylistBtnClicked(track: Track) {
        if (Account.getCachedAccount() == nil) {
            NeedAuthViewController.showNeedAuthViewController(self)
            return
        }
        performSegueWithIdentifier("PlaylistSelectSegue", sender: track)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "PlaylistSelectSegue" {
            let playlistSelectVC:PlaylistSelectViewController = segue.destinationViewController as! PlaylistSelectViewController
            playlistSelectVC.targetTrack = sender as? Track
            playlistSelectVC.fromSection = "playlist"
            playlistSelectVC.caller = self
        }
    }
}

// MARK: -

class BeforePlaylistNavigationController: UINavigationController {
    weak var currentPlaylist:Playlist!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationBar.tintColor = UIColor.dropbeatColor()
        
        let pvc = self.topViewController as! PlaylistViewController
        pvc.currentPlaylist = currentPlaylist
        pvc.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: "doneBarButtonAction:")
    }
    
    func doneBarButtonAction(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}

class PlaylistTrackTableViewCell: UITableViewCell {
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var titleLeftMargin: NSLayoutConstraint!
    @IBOutlet weak var titleRightMargin: NSLayoutConstraint!
    @IBOutlet weak var trackTitle: UILabel!
    @IBOutlet weak var menuBtn: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        let selectedBgView = UIView(frame: self.bounds)
        selectedBgView.autoresizingMask = [UIViewAutoresizing.FlexibleHeight, UIViewAutoresizing.FlexibleWidth]
        selectedBgView.backgroundColor = UIColor(netHex: 0xdddddd)
        self.selectedBackgroundView = selectedBgView
    }
}