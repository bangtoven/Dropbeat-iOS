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

enum DropPlayStatus {
    case Ready
    case Playing
    case Loading
}

class DropPlayerContext {
    var playStatus = DropPlayStatus.Ready
    var currentTrack: Track?
    var sectionName:String?
}

class AddableTrackListViewController: BaseViewController, AddableTrackCellDelegate, UIActionSheetDelegate {
    
    static let DROP_TIMEOUT:NSTimeInterval = 20
    
    @IBOutlet weak var trackTableView: UITableView!
    
    var tracks:[Track] = [Track]()
    var actionSheetTargetTrack:Track?
    var dropPlayer:AVPlayer?
    var dropPlayableItem:AVPlayerItem?
    var dropPlayerContext:DropPlayerContext = DropPlayerContext()
    var dropPlayTimer:NSTimer?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = "PlayableViewScreen"
        
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "updatePlay:", name: NotifyKey.updatePlay, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "sender", name: NotifyKey.playerPlay, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "appWillEnterForeground",
            name: UIApplicationWillEnterForegroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "appDidEnterBackground",
            name: UIApplicationDidEnterBackgroundNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "sender", name:NotifyKey.playerPause , object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "receivePlaybackStarted:", name:"PlaybackStartedNotification", object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "onDropFinished:", name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)
        
        updatePlay(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId)
    }
    
    func sender () {}
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.updatePlay, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.playerPlay, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name:NotifyKey.playerPause , object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name:"PlaybackStartedNotification", object: nil)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillEnterForegroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(
            self, name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)
        
        updateDropPlayStatus(DropPlayStatus.Ready)
    }
    
    func appWillEnterForeground() {
        updatePlay(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId)
    }
    
    func appDidEnterBackground() {
        updateDropPlayStatus(DropPlayStatus.Ready)
    }
    
    func updatePlaylist(forceUpdate:Bool) {
        if !forceUpdate &&
                (getPlaylistId() == nil || getPlaylistName() == nil ||
                    PlayerContext.currentPlaylistId != getPlaylistId()) {
            return
        }
        
        var playlist:Playlist!
        if PlayerContext.externalPlaylist != nil &&
                PlayerContext.externalPlaylist!.id == getPlaylistId() {
            playlist = PlayerContext.externalPlaylist!
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
            PlayerContext.externalPlaylist = playlist
        }
        
        if PlayerContext.currentPlaylistId == playlist.id {
            if PlayerContext.currentTrack == nil {
                PlayerContext.currentTrackIdx = -1
            } else {
                PlayerContext.currentTrackIdx = playlist.getTrackIdx(PlayerContext.currentTrack!)
            }
        }
        return
    }
    
    func onTrackPlayBtnClicked(track:Track) {
        var playlistId:String?
        if tracks.count == 0 || getPlaylistId() == nil{
            playlistId = nil
        } else {
            updatePlaylist(true)
            playlistId = PlayerContext.externalPlaylist!.id
        }
        var params: [String: AnyObject] = [
            "track": track,
        ]
        if playlistId != nil {
            params["playlistId"] = playlistId
        }
        params["section"] = getSectionName()
        NSNotificationCenter.defaultCenter().postNotificationName(
            NotifyKey.playerPlay, object: params)
    }
    
    func onTrackShareBtnClicked(track:Track) {
        let progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Loading..", comment:""))
        var section = getSectionName()
        track.shareTrack(section, afterShare: { (error, uid) -> Void in
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
    
    func onTrackLikeBtnClicked(track:Track) {
        if (Account.getCachedAccount() == nil) {
            NeedAuthViewController.showNeedAuthViewController(self)
            return
        }
        let progressHud = ViewUtils.showProgress(self, message: nil)
        if track.isLiked {
            track.doUnlike({ (error) -> Void in
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
    
    func onTrackAddBtnClicked(track:Track) {
        if (Account.getCachedAccount() == nil) {
            NeedAuthViewController.showNeedAuthViewController(self)
            return
        }
        performSegueWithIdentifier("PlaylistSelectSegue", sender: track)
    }
    
    func onTrackDropBtnClicked(sender: AddableTrackTableViewCell) {
        let indexPath:NSIndexPath? = trackTableView.indexPathForCell(sender)
        if indexPath == nil {
            return
        }
        let track = tracks[indexPath!.row]
        if track.drop == nil {
            return
        }
        
        if dropPlayerContext.currentTrack != nil &&
            dropPlayerContext.currentTrack!.id == track.id &&
            dropPlayerContext.sectionName == getSectionName() {
                
            if dropPlayerContext.playStatus != DropPlayStatus.Playing {
                return
            }
            self.updateDropPlayStatus(DropPlayStatus.Ready)
                
            NSNotificationCenter.defaultCenter().postNotificationName(NotifyKey.resumePlay, object: nil)

            return
        }
        
        var url:NSURL!
        if let urlString = resolveLocal(track.drop!.dref, track.drop!.type) {
            url = NSURL(string:urlString)
        } else {
            return
        }
        
        dropPlayer?.pause()
        dropPlayer?.removeObserver(self, forKeyPath: "status")
        dropPlayTimer?.invalidate()
        
        let noti = NSNotification(name: NotifyKey.playerPause, object: nil)
        NSNotificationCenter.defaultCenter().postNotification(noti)
        
        var sharedInstance:AVAudioSession = AVAudioSession.sharedInstance()
        var audioSessionError:NSError?
        if (!sharedInstance.setCategory(AVAudioSessionCategoryPlayback, error: &audioSessionError)) {
            println("Audio session error \(audioSessionError) \(audioSessionError?.userInfo)")
        }
        
        sharedInstance.setActive(true, error: nil)
        dropPlayableItem = AVPlayerItem(URL: url)
        
        dropPlayer = AVPlayer(playerItem: dropPlayableItem!)
        
        var selectedIndexPath = trackTableView.indexPathForSelectedRow()
        if selectedIndexPath != nil {
            trackTableView.deselectRowAtIndexPath(selectedIndexPath!, animated: false)
        }
        dropPlayerContext.currentTrack = track
        dropPlayerContext.sectionName = getSectionName()
        self.updateDropPlayStatus(DropPlayStatus.Loading)
        
        let player = dropPlayer!
        let kvoOption = NSKeyValueObservingOptions(0)
        player.addObserver(self, forKeyPath: "status", options: kvoOption, context: nil)
        
        
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
        tracker.send(event as [NSObject: AnyObject]!)
    }
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        if object as? NSObject != dropPlayer ||
            keyPath != "status" || dropPlayer == nil {
            return
        }
        
        if dropPlayer!.status == AVPlayerStatus.ReadyToPlay {
            let playDrop = { () -> Void in
                self.dropPlayer?.play()
                self.updateDropPlayStatus(DropPlayStatus.Playing)
                self.dropPlayTimer = NSTimer.scheduledTimerWithTimeInterval(
                    AddableTrackListViewController.DROP_TIMEOUT,
                    target: self, selector: "onDropFinished", userInfo: nil, repeats: false)
            }
            
            if let when = dropPlayerContext.currentTrack!.drop!.when {
                let fWhen = Float64(when)
                let targetTime = CMTimeMakeWithSeconds(fWhen, 600)
                dropPlayer?.seekToTime(targetTime, completionHandler: { (Bool) -> Void in
                    playDrop()
                })
            } else {
                playDrop()
            }
        } else if dropPlayer!.status == AVPlayerStatus.Failed {
            updateDropPlayStatus(DropPlayStatus.Ready)
            ViewUtils.showToast(self, message: NSLocalizedString("Failed to play", comment:""))
        }
    }
    
    func onDropFinished(noti:NSNotification) {
        onDropFinished()
    }
    
    func onDropFinished() {
        NSNotificationCenter.defaultCenter().postNotificationName(NotifyKey.resumePlay, object: nil)

        updateDropPlayStatus(DropPlayStatus.Ready)
    }
    
    func onTrackMenuBtnClicked(sender: AddableTrackTableViewCell) {
        let indexPath:NSIndexPath? = trackTableView.indexPathForCell(sender)
        if indexPath == nil {
            return
        }
        let track = tracks[indexPath!.row]
        actionSheetTargetTrack = track
        
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
        
        var appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        actionSheet.showFromTabBar(appDelegate.centerContainer!.tabBar)
    }
    
    func actionSheet(actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int) {
        var track:Track? = actionSheetTargetTrack
        var foundIdx = -1
        if track != nil {
            for (idx, t)  in enumerate(tracks) {
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
        
        onTrackActionSheetClicked(actionSheetTargetTrack!, buttonIndex: buttonIndex)
        actionSheetTargetTrack = nil
    }
    
    func updatePlay(noti: NSNotification) {
        updateDropPlayStatus(DropPlayStatus.Ready)
        
        var params = noti.object as! Dictionary<String, AnyObject>
        var track = params["track"] as! Track
        var playlistId:String? = params["playlistId"] as? String
        
        updatePlay(track, playlistId: playlistId)
    }
    
    func updatePlay(track:Track?, playlistId: String?) {
        if track == nil {
            return
        }
        var indexPath = trackTableView.indexPathForSelectedRow()
        if indexPath != nil {
            var preSelectedTrack = tracks[indexPath!.row]
            if preSelectedTrack.id != track!.id ||
                (playlistId != nil && playlistId!.toInt() >= 0) {
                trackTableView.deselectRowAtIndexPath(indexPath!, animated: false)
            }
        }
        
        
        if playlistId == nil || playlistId != getPlaylistId() {
            return
        }
        
        for (idx, t) in enumerate(tracks) {
            if (t.id == track!.id) {
                trackTableView.selectRowAtIndexPath(NSIndexPath(forRow: idx, inSection: 0),
                    animated: false, scrollPosition: UITableViewScrollPosition.None)
                break
            }
        }
    }
    
    func releaseDropPlayer() {
        dropPlayer?.pause()
        dropPlayer?.removeObserver(self, forKeyPath: "status")
        dropPlayer = nil
    }
    
    func updateDropPlayStatus(status:DropPlayStatus) {
        if status == DropPlayStatus.Ready {
            releaseDropPlayer()
            dropPlayerContext.currentTrack = nil
            dropPlayTimer?.invalidate()
            dropPlayTimer = nil
        }
        dropPlayerContext.playStatus = status
        trackTableView.reloadData()
    }

    //////////////////////////
    // METHODS MAY OVERRIDE //
    //////////////////////////
    
    func getTrackActionSheetTitleAtPosition(track: Track, index: Int) -> String {
        switch(index) {
        case 0:
            return track.isLiked ? NSLocalizedString("Liked", comment:"") :
                NSLocalizedString("Like", comment:"")
        case 1:
            return NSLocalizedString("Add to playlist", comment:"")
        case 2:
            return NSLocalizedString("Share", comment:"")
        case 3:
            return NSLocalizedString("Cancel", comment:"")
        default:
            return ""
        }
    }
    
    func getTrackActionSheetCount(track: Track) -> Int {
        return 4
    }
    
    func getTrackActionSheetCancelButtonIndex(track: Track) -> Int {
        return 3
    }
    
    func onTrackActionSheetClicked(targetTrack: Track, buttonIndex: Int) {
        switch(buttonIndex) {
        case 0:
            onTrackLikeBtnClicked(targetTrack)
        case 1:
            onTrackAddBtnClicked(targetTrack)
            break
        case 2:
            onTrackShareBtnClicked(targetTrack)
            break
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
