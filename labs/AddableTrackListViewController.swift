//
//  PlayableViewController.swift
//  labs
//
//  Created by vulpes on 2015. 8. 24..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import Foundation

// MARK: - Drop play extension

enum DropPlayState {
    case Ready
    case Playing
    case Loading
}

extension AddableTrackListViewController: STKAudioPlayerDelegate {
    
    func playDropOfTrack(track: Track) -> Bool {
        guard let streamUrl = track.drop?.streamUrl else {
            return false
        }
        
        if self.dropPlayer == nil {
            self.dropPlayer = STKAudioPlayer()
            self.dropPlayer?.delegate = self
        }
        
        self.dropPlayCurrentTrack = track
        self.updateDropPlayState(.Loading)
        
        self.dropPlayer?.play(streamUrl, withQueueItemId: track.title)
        
        return true
    }
    
    func pauseDrop() {
        if let prevTrack = self.dropPlayCurrentTrack,
            prevIndexPath = self.dropPlayCellIndexPath,
            cell = trackTableView.cellForRowAtIndexPath(prevIndexPath) as? AddableTrackTableViewCell {
                self.dropPlayState = .Ready
                self.setDropButtonForCellWithTrack(cell, track: prevTrack)
        }
        
        self.dropPlayCellIndexPath = nil
        self.dropPlayCurrentTrack = nil
        
        self.dropPlayer?.pause()

        self.dropPlayer?.dispose()
        self.dropPlayer?.delegate = nil
        self.dropPlayer = nil
    }

    func onTrackDropBtnClicked(sender: AddableTrackTableViewCell) {
        if let selectedIndexPath = trackTableView.indexPathForSelectedRow {
            trackTableView.deselectRowAtIndexPath(selectedIndexPath, animated: false)
        }
        
        guard let indexPath = trackTableView.indexPathForCell(sender) else {
            return
        }
        
        let track = tracks[indexPath.row]
        if let currentTrack = self.dropPlayCurrentTrack
            where currentTrack.id == track.id {
                if self.dropPlayState != .Playing {
                    return
                }
                self.updateDropPlayState(.Ready)
                return
        }
        
        self.pauseDrop()

        self.dropPlayCellIndexPath = indexPath
        guard self.playDropOfTrack(track) else {
            return
        }
        
        DropbeatPlayer.defaultPlayer.pause()
        if let main = self.tabBarController as? MainTabBarController
            where main.popupPresentationState == .Closed {
                main.hidePopupPlayer()
        }
        
        // Log to us
        Requests.logPlayDrop(track)
        
        // Log to GA
        let tracker = GAI.sharedInstance().defaultTracker
        let event = GAIDictionaryBuilder.createEventWithCategory(
            "player-play-from-drop",
            action: "play-\(track.drop!.type)",
            label: track.title,
            value: 0
            ).build()
        var eventDict = [NSObject: AnyObject]()
        for (key,value) in event {
            eventDict[key as! NSObject] = value
        }
        tracker.send(eventDict)
    }
    
    func audioPlayer(audioPlayer: STKAudioPlayer!, didStartPlayingQueueItemId queueItemId: NSObject!) {
        print("Drop play start: \(queueItemId)")
    }
    
    func audioPlayer(audioPlayer: STKAudioPlayer!, didFinishBufferingSourceWithQueueItemId queueItemId: NSObject!) {
        print("Drop play ready: \(queueItemId)")
    }
    
    func audioPlayer(audioPlayer: STKAudioPlayer!, stateChanged state: STKAudioPlayerState, previousState: STKAudioPlayerState) {
        print("Drop play STATE: \(state.rawValue)")
        switch state {
        case .Running, .Buffering:
            self.updateDropPlayState(.Loading)
        case .Playing:
            self.updateDropPlayState(.Playing)
        default:
            break
        }
    }
    
    func audioPlayer(audioPlayer: STKAudioPlayer!, didFinishPlayingQueueItemId queueItemId: NSObject!, withReason stopReason: STKAudioPlayerStopReason, andProgress progress: Double, andDuration duration: Double) {
        print("Drop play finish: \(queueItemId)")
        
        self.updateDropPlayState(.Ready)
    }
    
    func audioPlayer(audioPlayer: STKAudioPlayer!, unexpectedError errorCode: STKAudioPlayerErrorCode) {
        print("Drop play ERROR: \(errorCode.rawValue)")
        
        ViewUtils.showToast(self, message: NSLocalizedString("Failed to play", comment:""))
    }
    
    func updateDropPlayState(state:DropPlayState) {
        if state == self.dropPlayState {
            return
        }
        
        self.dropPlayState = state
        if let track = self.dropPlayCurrentTrack,
            indexPath = self.dropPlayCellIndexPath,
            cell = trackTableView.cellForRowAtIndexPath(indexPath) as? AddableTrackTableViewCell {
            self.setDropButtonForCellWithTrack(cell, track: track)
        }

        if state == .Ready {
            if let main = self.tabBarController as? MainTabBarController
                where DropbeatPlayer.defaultPlayer.currentTrack != nil {
                    main.showPopupPlayer()
                    self.updateSelectedTrackCell()
            }
            
            self.pauseDrop()
        }
    }
    
    func setDropButtonForCellWithTrack(cell:AddableTrackTableViewCell, track: Track) {
        cell.dropBtn.hidden = (track.drop == nil)
        
        if cell.dropBtn.hidden == false {
            var dropBtnImageName = "ic_drop"
            if self.dropPlayCurrentTrack?.id == track.id {
                switch(self.dropPlayState) {
                case .Playing:
                    dropBtnImageName = "ic_drop_pause"
                case .Loading:
                    dropBtnImageName = "ic_drop_loading"
                default:
                    break
                }
            }
            dropBtnImageName = (self.needsBigSizeDropButton == false) ? "\(dropBtnImageName)_small" : dropBtnImageName
            
            cell.dropBtn.setImage(UIImage(named: dropBtnImageName), forState: UIControlState.Normal)
        }
    }
}

// MARK:

class AddableTrackListViewController: GAITrackedViewController, AddableTrackCellDelegate, UIActionSheetDelegate {
    
    @IBOutlet weak var trackTableView: UITableView!
    
    var tracks:[Track] = [Track]()
    var selectedTrack:Track?
    
    var needsBigSizeDropButton = false
    
    private var dropPlayer: STKAudioPlayer?
    private var dropPlayState = DropPlayState.Ready
    private var dropPlayCurrentTrack: Track?
    private var dropPlayCellIndexPath: NSIndexPath?
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = "PlayableViewScreen"
        
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "trackChanged", name: DropbeatPlayerTrackChangedNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "appWillEnterForeground",
            name: UIApplicationWillEnterForegroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "appDidEnterBackground",
            name: UIApplicationDidEnterBackgroundNotification, object: nil)
        
        trackChanged()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: DropbeatPlayerTrackChangedNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillEnterForegroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidEnterBackgroundNotification, object: nil)

        updateDropPlayState(DropPlayState.Ready)
    }
    
    func appWillEnterForeground() {
        trackChanged()
    }
    
    func appDidEnterBackground() {
        updateDropPlayState(DropPlayState.Ready)
    }
    
    func updatePlaylist(forceUpdate:Bool) {
        if !forceUpdate &&
                (getPlaylistId() == nil || getPlaylistName() == nil ||
                    DropbeatPlayer.defaultPlayer.currentPlaylist?.id != getPlaylistId()) {
            return
        }
        
        var playlist:Playlist!
        if DropbeatPlayer.defaultPlayer.currentPlaylist != nil &&
                DropbeatPlayer.defaultPlayer.currentPlaylist?.id == getPlaylistId() {
            playlist = DropbeatPlayer.defaultPlayer.currentPlaylist!
            playlist.tracks.removeAll(keepCapacity: false)
            for track in tracks {
                playlist.tracks.append(track)
            }
        } else {
            playlist = Playlist(
                    id: getPlaylistId()!,
                    name: getPlaylistName()!,
                    tracks: tracks)
            playlist.type = PlaylistType.EXTERNAL
            DropbeatPlayer.defaultPlayer.currentPlaylist = playlist
        }
        
        return
    }
    
    func onTrackPlayBtnClicked(track:Track) {
        var playlistId:String?
        if tracks.count == 0 || getPlaylistId() == nil{
            playlistId = nil
        } else {
            updatePlaylist(true)
            playlistId = DropbeatPlayer.defaultPlayer.currentPlaylist?.id
        }
        var params: [String: AnyObject] = [
            "track": track,
        ]
        if playlistId != nil {
            params["playlistId"] = playlistId
        }
        params["section"] = getSectionName()
        
        // TODO: playlist???
        DropbeatPlayer.defaultPlayer.play(track)
    }
    
    func onTrackRepostAction(track:Track) {
        let progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Loading..", comment:""))
        track.repostTrack { (data, error) -> Void in
            if error != nil {
                progressHud.hide(true)
                if error!.domain == DropbeatRequestErrorDomain {
                    ViewUtils.showToast(self, message: NSLocalizedString("Already reposted.", comment:""))
                } else {
                    var message = error!.localizedDescription
                    if (error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                            message = NSLocalizedString("Internet is not connected.", comment:"")
                    }
                    ViewUtils.showConfirmAlert(self, title: NSLocalizedString("Failed to repost", comment:""),
                        message: message,
                        positiveBtnText: NSLocalizedString("Retry", comment:""), positiveBtnCallback: { () -> Void in
                            self.onTrackRepostAction(track)
                    })
                }
                return
            }
            
            progressHud.mode = MBProgressHUDMode.CustomView
            progressHud.customView = UIImageView(image: UIImage(named:"37x-Checkmark"))
            progressHud.hide(true, afterDelay: 1)
        }
        return
    }
    
    func onTrackShareBtnClicked(track:Track) {
        let progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Loading..", comment:""))
        let section = getSectionName()
        track.shareTrack(section) { (error, sharedURL) -> Void in
            progressHud.hide(true)
            if error != nil {
                if (error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    ViewUtils.showConfirmAlert(self, title: NSLocalizedString("Failed to share", comment:""),
                        message: NSLocalizedString("Internet is not connected.", comment:""),
                        positiveBtnText: NSLocalizedString("Retry", comment:""), positiveBtnCallback: { () -> Void in
                            self.onTrackShareBtnClicked(track)
                        }, negativeBtnText: NSLocalizedString("Cancel", comment:""), negativeBtnCallback: nil)
                    return
                }
                ViewUtils.showConfirmAlert(self, title: NSLocalizedString("Failed to share", comment:""),
                    message: NSLocalizedString("Failed to share track", comment:""),
                    positiveBtnText: NSLocalizedString("Retry", comment:""), positiveBtnCallback: { () -> Void in
                        self.onTrackShareBtnClicked(track)
                    }, negativeBtnText: NSLocalizedString("Cancel", comment:""), negativeBtnCallback: nil)
                return
            }
            
            self.showActivityViewControllerWithShareURL(sharedURL!, string: track.title)
        }
    }
    
    func onTrackLikeBtnClicked(track:Track, onSuccess:(Void->Void)? = nil) {
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
                        message: NSLocalizedString("Failed to save dislike info.", comment:""),
                        positiveBtnText:  NSLocalizedString("Retry", comment: ""),
                        positiveBtnCallback: { () -> Void in
                            self.onTrackLikeBtnClicked(track)
                    })
                    return
                }
                
                onSuccess?()
                
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
                
                onSuccess?()
                
                progressHud.mode = MBProgressHUDMode.CustomView
                progressHud.customView = UIImageView(image: UIImage(named:"ic_hud_like"))
                progressHud.hide(true, afterDelay: 1)
            }
        }
    }
    
    func onTrackAddBtnClicked(track:Track) {
        if (Account.getCachedAccount() == nil) {
            NeedAuthViewController.showNeedAuthViewController(self)
            return
        }
        performSegueWithIdentifier("PlaylistSelectSegue", sender: track)
    }
    
    func onTrackMenuBtnClicked(sender: AddableTrackTableViewCell) {
        let indexPath:NSIndexPath? = trackTableView.indexPathForCell(sender)
        if indexPath == nil {
            return
        }
        let track = tracks[indexPath!.row]
        selectedTrack = track
        
        let actionSheet = UIActionSheet()
        let actionSheetItemCount = getTrackActionSheetCount(track)
        for idx in 0..<actionSheetItemCount {
            actionSheet.addButtonWithTitle(getTrackActionSheetTitleAtPosition(track, index: idx))
        }
        let cancelBtnIdx = getTrackActionSheetCancelButtonIndex(track)
        if cancelBtnIdx > -1 {
            actionSheet.cancelButtonIndex = cancelBtnIdx
        }
        
        let destructiveBtnIdx = getTrackActionSheetDestructiveButtonIndex(track)
        if destructiveBtnIdx > -1 {
            actionSheet.destructiveButtonIndex = destructiveBtnIdx
        }
        actionSheet.delegate = self
        
        actionSheet.showFromTabBar((self.tabBarController?.tabBar)!)
//        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
//        actionSheet.showFromTabBar(appDelegate.centerContainer!.tabBar)
    }
    
    func actionSheet(actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int) {
        let track:Track? = selectedTrack
        var foundIdx = -1
        if track != nil {
            for (idx, t)  in tracks.enumerate() {
                if t.id == track!.id {
                    foundIdx = idx
                    break
                }
            }
        }
        if track == nil || foundIdx == -1 {
            ViewUtils.showToast(self, message: NSLocalizedString("Track is not in list", comment:""))
            return
        }
        
        onTrackActionSheetClicked(selectedTrack!, buttonIndex: buttonIndex)
        selectedTrack = nil
    }
    
    func trackChanged() {
        updateDropPlayState(DropPlayState.Ready)
        
        self.updateSelectedTrackCell()
    }
    
    private func updateSelectedTrackCell() {
        guard let track = DropbeatPlayer.defaultPlayer.currentTrack else {
            return
        }
        
        let indexPath = trackTableView.indexPathForSelectedRow
        if indexPath != nil {
            let preSelectedTrack = tracks[indexPath!.row]
            if preSelectedTrack.id != track.id {
                trackTableView.deselectRowAtIndexPath(indexPath!, animated: false)
            }
        }
        
        for (idx, t) in tracks.enumerate() {
            if (t.id == track.id) {
                trackTableView.selectRowAtIndexPath(NSIndexPath(forRow: idx, inSection: trackTableView.numberOfSections-1),
                    animated: false, scrollPosition: UITableViewScrollPosition.None)
                break
            }
        }
    }

    //////////////////////////
    // METHODS MAY OVERRIDE //
    //////////////////////////
    
    func getTrackActionSheetTitleAtPosition(track: Track, index: Int) -> String {
        switch(index) {
        case 0:
            return track.isLiked ? NSLocalizedString("Unlike", comment:"") :
                NSLocalizedString("Like", comment:"")
        case 1:
            return NSLocalizedString("Add to playlist", comment:"")
        case 2:
            return NSLocalizedString("Repost", comment:"")
        case 3:
            return NSLocalizedString("Share", comment:"")
        case 4:
            return NSLocalizedString("Cancel", comment:"")
        default:
            return ""
        }
    }
    
    func getTrackActionSheetCount(track: Track) -> Int {
        return 5
    }
    
    func getTrackActionSheetCancelButtonIndex(track: Track) -> Int {
        return 4
    }
    
    func onTrackActionSheetClicked(targetTrack: Track, buttonIndex: Int) {
        switch(buttonIndex) {
        case 0:
            onTrackLikeBtnClicked(targetTrack)
        case 1:
            onTrackAddBtnClicked(targetTrack)
        case 2:
            onTrackRepostAction(targetTrack)
        case 3:
            onTrackShareBtnClicked(targetTrack)
        default:
            break
        }
    }
    
    func getTrackActionSheetDestructiveButtonIndex(track:Track) -> Int {
        return -1
    }
    
    ////////////////////////////////////
    // METHODS SHOULD BE IMPLEMENTED  //
    ////////////////////////////////////
    
    func getPlaylistId() -> String? {
        return nil
    }
    
    func getPlaylistName() -> String? {
        return nil
    }
    
    func getSectionName() -> String {
        return ""
    }
}

// MARK: - AddableTrackTableViewCell

protocol AddableTrackCellDelegate {
    func onTrackMenuBtnClicked(sender:AddableTrackTableViewCell)
    func onTrackDropBtnClicked(sender:AddableTrackTableViewCell)
}

class AddableTrackTableViewCell: UITableViewCell {
    
    var delegate:AddableTrackCellDelegate?
    
    @IBOutlet weak var filterView: UIView!
    @IBOutlet weak var nameView: UILabel!
    @IBOutlet weak var thumbView: UIImageView!
    @IBOutlet weak var dropBtn: UIButton!
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let selectedBgView = UIView(frame: self.bounds)
        selectedBgView.autoresizingMask = [UIViewAutoresizing.FlexibleHeight, UIViewAutoresizing.FlexibleWidth]
        selectedBgView.backgroundColor = UIColor(netHex: 0xffffff)
        self.selectedBackgroundView = selectedBgView
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
        if(selected) {
            filterView.hidden = false
            filterView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.4)
        } else {
            filterView.hidden = true
        }
    }
    
    @IBAction func onMenuBtnClicked(sender: UIButton) {
        delegate?.onTrackMenuBtnClicked(self)
    }
    
    @IBAction func onDropBtnClicked(sender: AnyObject) {
        delegate?.onTrackDropBtnClicked(self)
    }
}