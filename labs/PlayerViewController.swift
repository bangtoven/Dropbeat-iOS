//
//  PlayerViewController.swift
//  labs
//
//  Created by vulpes on 2015. 7. 29..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit
import MediaPlayer
import AVFoundation

class PlayerViewController: BaseViewController, UIActionSheetDelegate {

    @IBOutlet weak var playerTitleHeightConstaint: NSLayoutConstraint!
    
    @IBOutlet weak var coverView: UIView!
    @IBOutlet weak var loadingView: UIImageView!
    @IBOutlet weak var progressBar: UISlider!
    
    @IBOutlet weak var playerTitle: UILabel!
    @IBOutlet weak var playerStatus: UILabel!
    
    @IBOutlet weak var shareBtn: UIButton!
    @IBOutlet weak var repeatBtn: UIButton!
    @IBOutlet weak var shuffleBtn: UIButton!
    @IBOutlet weak var totalTextView: UILabel!
    @IBOutlet weak var progressTextView: UILabel!
    @IBOutlet weak var nextBtn: UIButton!
    @IBOutlet weak var prevBtn: UIButton!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var pauseBtn: UIButton!
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var qualityBtn: UIButton!
    @IBOutlet weak var coverBgImageView: UIImageView!
    @IBOutlet weak var playlistBtn: UIButton!
    
    static var observerAttached: Bool = false
    static var sharedInstance:PlayerViewController?
    
    var audioPlayerControl: XCDYouTubeVideoPlayerViewController = XCDYouTubeVideoPlayerViewController()
    
    var remoteProgressTimer: NSTimer?
    
    var isProgressUpdatable = true
    var prevShuffleBtnState:Int?
    var prevRepeatBtnState:Int?
    
    var bgTaskId:UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    var removedId:UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    
    // Used only for video playback recovery.
    var shouldPlayMusic: Bool = false
    var prevResolveReq:Request? = nil
    var forceStopPlayer = false
    var playingInfoDisplayDuration = false
    var hookingBackground: Bool = false
    
    var actionSheetTargetTrack:Track?
    var lastPlaybackBeforeSwitch:Double?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (PlayerViewController.observerAttached == false) {
            PlayerViewController.sharedInstance = self
            asignObservers()
        }
        
        audioPlayerControl.presentInView(videoView)
        if UIScreen.mainScreen().bounds.height == 480 {
            resizeViewUnder4in()
        }
    }
    
    func resizeViewUnder4in() {
        playerTitleHeightConstaint.constant = 28
        let heightConstraint = NSLayoutConstraint(item: coverView,
            attribute: NSLayoutAttribute.Height,
            relatedBy: NSLayoutRelation.Equal,
            toItem: nil,
            attribute: NSLayoutAttribute.NotAnAttribute,
            multiplier: 1.0,
            constant: 200)
        coverView.addConstraint(heightConstraint)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = "PlayerViewScreen"
    
        self.navigationController?.navigationBarHidden = true
        updateExtraViews()
        updateCoverView()
        updateNextPrevBtn()
        audioPlayerControl.view.frame = CGRectMake(0, 0, videoView.frame.width, videoView.frame.height)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
        updatePlayView()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        resignFirstResponder()
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override func animationDidStop(anim: CAAnimation!, finished flag: Bool) {
        if (flag && (PlayerContext.playState == PlayState.LOADING ||
                PlayerContext.playState == PlayState.SWITCHING ||
                PlayerContext.playState == PlayState.BUFFERING)) {
            loadingView.rotate360Degrees(duration: 0.7, completionDelegate: self)
        }
    }
    
    func sender() {}
    
    
    func asignObservers () {
        PlayerViewController.observerAttached = true
        // Used for playlistView bottom controller update.
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "sender", name: NotifyKey.updatePlaylistView, object: nil)
        
        // Used for track list play / nonplay ui update
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "sender", name: NotifyKey.updatePlay, object: nil)
        
        // Observe remote input.
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "remotePlay:", name: NotifyKey.playerPlay, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "handleStop", name: NotifyKey.playerStop, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "remotePrev", name: NotifyKey.playerPrev, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "remotePause", name: NotifyKey.playerPause, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "remoteNext", name: NotifyKey.playerNext, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "remoteSeek:", name: NotifyKey.playerSeek, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "repeatStateUpdated", name: NotifyKey.updateRepeatState, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "shuffleStateUpdated", name: NotifyKey.updateShuffleState, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "qualityStateUpdated", name: NotifyKey.updateQualityState, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "networkStatusUpdated", name: NotifyKey.networkStatusChanged, object: nil)
        
        
        // Observe internal player.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "MPMoviePlayerContentPreloadDidFinish:",
            name: "MPMoviePlayerContentPreloadDidFinishNotification", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "MPMoviePlayerLoadStateDidChange:",
            name: MPMoviePlayerLoadStateDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "MPMoviePlayerPlaybackStateDidChange:",
            name: MPMoviePlayerPlaybackStateDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "MPMoviePlayerPlaybackDidFinish:",
            name: MPMoviePlayerPlaybackDidFinishNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "MPMoviePlayerTimedMetadataUpdated:",
            name: MPMoviePlayerTimedMetadataUpdatedNotification, object: nil)
        
        // For video background playback
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "backgroundHook",
            name: UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "appWillEnterForeground",
            name: UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    func resignObservers() {
        PlayerViewController.observerAttached = false
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.updatePlaylistView, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.updatePlay, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.playerStop, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.playerPlay, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.playerPrev, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.playerPause, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.playerNext, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.playerSeek, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.updateRepeatState, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.updateShuffleState, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.updateQualityState, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.networkStatusChanged, object: nil)
        
        
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "MPMoviePlayerContentPreloadDidFinishNotification", object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: MPMoviePlayerLoadStateDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: MPMoviePlayerPlaybackStateDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: MPMoviePlayerPlaybackDidFinishNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: MPMoviePlayerTimedMetadataUpdatedNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillEnterForegroundNotification, object: nil)
        
        handleStop()
    }
    
    func actionSheet(actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int) {
        if buttonIndex < 2 && actionSheetTargetTrack == nil {
            ViewUtils.showToast(self, message: "No track selected")
            return
        }
        
        switch(buttonIndex) {
        case 0:
            onAddToPlaylistBtnClicked(actionSheetTargetTrack!)
            break
        case 1:
            onTrackShareBtnClicked(actionSheetTargetTrack!)
            break
        default:
            break
        }
        actionSheetTargetTrack = nil
    }

    func backgroundHook () {
        if (PlayerContext.currentTrack != nil) {
            // Check whether it is video and stopped when it entered into background.
            if (hookingBackground) {
                return
            }
            if (PlayerContext.currentTrack!.type == "youtube" &&
                    PlayerContext.playState == PlayState.PAUSED && shouldPlayMusic) {
                hookingBackground = true
                
                startBackgroundTask()
                triggerBackgroundPlay(100)
            }
        }
    }
    
    func appWillEnterForeground () {
        updateExtraViews()
        updatePlayView()
        updateCoverView()
        updateNextPrevBtn()
    }
    
    func triggerBackgroundPlay(retry:Int) {
        var popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.1 * Double(NSEC_PER_SEC)))
        dispatch_after(popTime, dispatch_get_main_queue()) {
            if (!self.shouldPlayMusic || PlayerContext.playState != PlayState.PAUSED) {
                self.hookingBackground = false
                return
            }
            if (PlayerContext.playState == PlayState.PAUSED) {
                self.handlePlay(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId, force:false)
                self.triggerBackgroundPlay(retry - 1)
            } else {
                self.hookingBackground = false
            }
        }
    }
    
    func updateExtraViews() {
        updateStatusView()
        updateProgressView()
        updateRepeatView()
        updateShuffleView()
        updateQualityView()
        updatePlayerPlaylistBtn()
    }
    
    func updateNextPrevBtn() {
        if PlayerContext.pickNextTrack() != nil {
            nextBtn.enabled = true
            nextBtn.setImage(UIImage(named:"ic_forward.png"), forState: UIControlState.Normal)
        } else {
            nextBtn.enabled = false
            nextBtn.setImage(UIImage(named:"ic_forward_gray.png"), forState: UIControlState.Normal)
        }
        
        if PlayerContext.pickPrevTrack() != nil {
            prevBtn.enabled = true
            prevBtn.setImage(UIImage(named:"ic_rewind.png"), forState: UIControlState.Normal)
        } else {
            prevBtn.enabled = false
            prevBtn.setImage(UIImage(named:"ic_rewind_gray.png"), forState: UIControlState.Normal)
        }
    }
    
    // XXX : hacky solution for hide video controls
    // This code should be well tested before release
    func showMPMoviePlayerControls(show:Bool) {
        let player = audioPlayerControl.moviePlayer
        player.controlStyle = show ? MPMovieControlStyle.Embedded : MPMovieControlStyle.None
        if SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO("8") {
            var subViewObjs = player.backgroundView.superview?.superview?.subviews
            if subViewObjs == nil {
                return
            }
            if let subViews = subViewObjs as? [UIView] {
                for subView:UIView in subViews {
                    if subView.isKindOfClass(NSClassFromString("MPVideoPlaybackOverlayView")) {
                        subView.backgroundColor = UIColor.clearColor()
                        subView.alpha = show ? 1.0 : 0.0
                        subView.hidden = show ? false : true
                    }
                }
            }
        }
    }
    
    func updateCoverView() {
        var track = PlayerContext.currentTrack
        if track == nil || PlayerContext.playState == PlayState.STOPPED {
            videoView.hidden = true
            coverImageView.hidden = false
            coverBgImageView.image = UIImage(named: "player_bg.png")
            coverImageView.image = UIImage(named: "default_cover_big.png")
        } else if track!.type == "youtube" {
            videoView.hidden = false
            audioPlayerControl.view.hidden = false
            audioPlayerControl.view.frame = CGRectMake(0, 0, videoView.frame.width, videoView.frame.height)
            audioPlayerControl.presentInView(videoView)
            showMPMoviePlayerControls(false)
            coverImageView.hidden = true
            
            
            if track!.hasHqThumbnail {
                coverBgImageView.sd_setImageWithURL(NSURL(string: track!.thumbnailUrl!),
                        placeholderImage: UIImage(named: "player_bg.png"), completed: {
                        (image: UIImage!, error: NSError!, cacheType:SDImageCacheType, imageURL: NSURL!) -> Void in
                    if (error != nil) {
                        self.coverBgImageView.image = UIImage(named: "player_bg.png")
                    }
                })
            } else {
                coverBgImageView.image = UIImage(named: "player_bg.png")!
            }
        } else {
            videoView.hidden = true
            coverImageView.hidden = false
            coverBgImageView.image = UIImage(named: "player_bg.png")
            if track!.hasHqThumbnail {
                coverImageView.sd_setImageWithURL(NSURL(string: track!.thumbnailUrl!),
                        placeholderImage: UIImage(named: "default_cover_big.png"), completed: {
                        (image: UIImage!, error: NSError!, cacheType:SDImageCacheType, imageURL: NSURL!) -> Void in
                    if (error != nil) {
                        self.coverImageView.image = UIImage(named: "default_cover_big.png")
                    }
                })
            } else {
                coverImageView.image = UIImage(named: "default_cover_big.png")!
            }
        }
    }
    
    func updatePlayerPlaylistBtn () {
        if PlayerContext.currentPlaylistId == nil {
            playlistBtn.setImage(UIImage(named:"ic_list_gray.png"), forState: UIControlState.Normal)
            playlistBtn.enabled = false
        } else {
            playlistBtn.setImage(UIImage(named:"ic_list.png"), forState: UIControlState.Normal)
            playlistBtn.enabled = true
        }
    }
    
    func updatePlayView() {
        if (PlayerContext.playState == PlayState.LOADING ||
                PlayerContext.playState == PlayState.SWITCHING ||
                PlayerContext.playState == PlayState.BUFFERING) {
            playBtn.hidden = true
            pauseBtn.hidden = true
            loadingView.hidden = false
            loadingView.rotate360Degrees(duration: 0.7, completionDelegate: self)
        } else if (PlayerContext.playState == PlayState.PAUSED) {
            playBtn.hidden = false
            pauseBtn.hidden = true
            loadingView.hidden = true
        } else if (PlayerContext.playState == PlayState.PLAYING) {
            playBtn.hidden = true
            pauseBtn.hidden = false
            loadingView.hidden = true
        } else if (PlayerContext.playState == PlayState.STOPPED) {
            playBtn.hidden = false
            pauseBtn.hidden = true
            loadingView.hidden = true
        }
    }
    
    func updateShuffleView() {
        if (prevShuffleBtnState == PlayerContext.shuffleState) {
            return
        }
        prevShuffleBtnState = PlayerContext.shuffleState
        if (PlayerContext.shuffleState == ShuffleState.NOT_SHUFFLE) {
            shuffleBtn.setImage(UIImage(named: "ic_shuffle_gray.png"), forState: UIControlState.Normal)
        } else {
            shuffleBtn.setImage(UIImage(named: "ic_shuffle.png"), forState: UIControlState.Normal)
        }
    }
    
    func updateRepeatView() {
        if (prevRepeatBtnState != nil &&
            prevRepeatBtnState == PlayerContext.repeatState) {
                return
        }
        prevRepeatBtnState = PlayerContext.repeatState
        switch(PlayerContext.repeatState) {
        case RepeatState.NOT_REPEAT:
            var image:UIImage = UIImage(named: "ic_repeat_gray.png")!
            repeatBtn.setImage(image, forState: UIControlState.Normal)
            break
        case RepeatState.REPEAT_ONE:
            repeatBtn.setImage(UIImage(named: "ic_repeat_one.png"), forState: UIControlState.Normal)
            break
        case RepeatState.REPEAT_PLAYLIST:
            repeatBtn.setImage(UIImage(named: "ic_repeat.png"), forState: UIControlState.Normal)
            break
        default:
            break
        }
    }
    
    func updateStatusView() {
        let defaultText = "CHOOSE TRACK"
        if (PlayerContext.playState == PlayState.LOADING ||
                PlayerContext.playState == PlayState.SWITCHING) {
            playerStatus.text = "LOADING"
            playerTitle.text = PlayerContext.currentTrack?.title ?? defaultText
        } else if (PlayerContext.playState == PlayState.PAUSED) {
            playerStatus.text = "PAUSED"
            playerTitle.text = PlayerContext.currentTrack?.title ?? defaultText
        } else if (PlayerContext.playState == PlayState.PLAYING) {
            playerStatus.text = "PLAYING"
            playerTitle.text = PlayerContext.currentTrack?.title ?? defaultText
        } else if (PlayerContext.playState == PlayState.STOPPED) {
            playerStatus.text = "READY"
            playerTitle.text = defaultText
        } else if (PlayerContext.playState == PlayState.BUFFERING) {
            playerStatus.text = "BUFFERING"
            playerTitle.text = PlayerContext.currentTrack?.title ?? defaultText
        }
    }
    
    func updateQualityView() {
        switch(PlayerContext.qualityState) {
        case QualityState.LQ:
            var image:UIImage = UIImage(named: "ic_hq_off")!
            qualityBtn.setImage(image, forState: UIControlState.Normal)
            break
        case QualityState.HQ:
            var image:UIImage = UIImage(named: "ic_hq_on")!
            qualityBtn.setImage(image, forState: UIControlState.Normal)
            break
        default:
            break
        }
    }

    func updateProgressView() {
        if (PlayerContext.playState == PlayState.PLAYING && !isProgressUpdatable) {
            return
        }
        var total:Float = Float(PlayerContext.correctDuration ?? 0)
        var curr:Float = Float(PlayerContext.currentPlaybackTime ?? 0)
        if (total == 0) {
            progressBar.value = 0
            progressBar.enabled = false
        } else {
            progressBar.value = (curr * 100) / total
            var state = PlayerContext.playState
            if (PlayerContext.playState == PlayState.PLAYING) {
                progressBar.enabled = true
            } else {
                progressBar.enabled = false
            }
            progressTextView.text = getTimeFormatText(PlayerContext.currentPlaybackTime ?? 0)
            totalTextView.text = getTimeFormatText(PlayerContext.correctDuration ?? 0)
        }
    }
    
    func getTimeFormatText(time:NSTimeInterval) -> String {
        let ti = Int(time)
        let seconds = ti % 60
        let minutes = ti / 60
        var text = minutes < 10 ? "0\(minutes):" : "\(String(minutes)):"
        text += seconds < 10 ? "0\(seconds)" : String(seconds)
        return text
    }
    
    func updateProgress () {
        var currentTrack :Track? = PlayerContext.currentTrack
        if (currentTrack == nil) {
            return
        }
        if (audioPlayerControl.moviePlayer.duration == 0.0) {
            // Audio meta has not been loaded.
            return
        }
        
        // Youtube duration hack.
        if (currentTrack?.type == "youtube") {
            if (PlayerContext.correctDuration == nil) {
                PlayerContext.correctDuration = audioPlayerControl.moviePlayer.duration
            }

            if (audioPlayerControl.moviePlayer.duration != PlayerContext.correctDuration) {
                // To find a end of the track that has corrected duration.
                // - This is hacky way to prevent repeatedly gain pause / play event from player
                // player gain repeatedly pasuse / play event after correntDuration
                if (audioPlayerControl.moviePlayer.currentPlaybackTime >= PlayerContext.correctDuration!) {
                    if (PlayerContext.repeatState == RepeatState.REPEAT_ONE) {
                        handleSeek(0)
                    } else {
                        if remoteProgressTimer != nil {
                            remoteProgressTimer?.invalidate()
                            remoteProgressTimer = nil
                        }
                        if (audioPlayerControl.moviePlayer.playbackState != MPMoviePlaybackState.Stopped) {
                            self.forceStopPlayer = true
                            audioPlayerControl.moviePlayer.stop()
                        }
                    }
                    return
                }
            }

            if (PlayerContext.correctDuration == -1.0) {
                // URL has no duration info.
                PlayerContext.correctDuration = audioPlayerControl.moviePlayer.duration / 2.0
            } else {
                var buffer :Double = audioPlayerControl.moviePlayer.duration * 0.75
                if (buffer <= PlayerContext.correctDuration) {
                    // Cannot sure if it's wrong. So, let's return back original value.
                    PlayerContext.correctDuration = audioPlayerControl.moviePlayer.duration
                }
            }
        } else {
            PlayerContext.correctDuration = audioPlayerControl.moviePlayer.duration
        }
        PlayerContext.currentPlaybackTime = audioPlayerControl.moviePlayer.currentPlaybackTime
        
        // update playinginfo duration
        if (!self.playingInfoDisplayDuration) {
            self.updatePlayStateView(PlayerContext.playState)
        }
        // Update custom progress
        updateProgressView()
    }
    
    func MPMoviePlayerLoadStateDidChange (noti: NSNotification) {
        if (audioPlayerControl.moviePlayer.loadState.rawValue & MPMovieLoadState.Playable.rawValue) != 0 {
            println("load state = playable")
        }
        if (audioPlayerControl.moviePlayer.loadState.rawValue & MPMovieLoadState.PlaythroughOK.rawValue != 0) {
            println("load state = playthroughOk")
        }
        if (audioPlayerControl.moviePlayer.loadState.rawValue & MPMovieLoadState.allZeros.rawValue != 0) {
            println("load state = allzeros")
        }
        if (audioPlayerControl.moviePlayer.loadState.rawValue & MPMovieLoadState.Stalled.rawValue != 0) {
            println("load state = Stalled")
        }
        if (audioPlayerControl.moviePlayer.loadState.rawValue & MPMovieLoadState.Playable.rawValue != 0 &&
                audioPlayerControl.moviePlayer.loadState.rawValue & MPMovieLoadState.Stalled.rawValue != 0) {
            startBackgroundTask()
            updatePlayState(PlayState.BUFFERING)
            return
        }
        if (audioPlayerControl.moviePlayer.loadState.rawValue & MPMovieLoadState.Playable.rawValue != 0) {
            if ((PlayerContext.playState == PlayState.SWITCHING ||
                PlayerContext.playState == PlayState.PLAYING) &&
                    lastPlaybackBeforeSwitch != nil &&
                    lastPlaybackBeforeSwitch > 0) {
                audioPlayerControl.moviePlayer.currentPlaybackTime = lastPlaybackBeforeSwitch!
                lastPlaybackBeforeSwitch = nil
            }
            audioPlayerControl.moviePlayer.play()
            return
        }
        
        if (audioPlayerControl.moviePlayer.loadState.rawValue & MPMovieLoadState.allZeros.rawValue != 0) {
            // If youtube which has double duration length will be get here
            // when it play over original duration (:1/2) length
            if (PlayerContext.currentTrack != nil &&
                PlayerContext.currentTrack!.type == "youtube" &&
                PlayerContext.correctDuration != nil){
                if (audioPlayerControl.moviePlayer.currentPlaybackTime >= PlayerContext.correctDuration! - 1) {
                    if (PlayerContext.repeatState == RepeatState.REPEAT_ONE) {
                        handleSeek(0)
                    } else if (audioPlayerControl.moviePlayer.playbackState != MPMoviePlaybackState.Stopped) {
                        if remoteProgressTimer != nil {
                            remoteProgressTimer?.invalidate()
                            remoteProgressTimer = nil
                        }
                        if (audioPlayerControl.moviePlayer.playbackState != MPMoviePlaybackState.Stopped) {
                            self.forceStopPlayer = true
                            audioPlayerControl.moviePlayer.stop()
                        }
                    }
                }
            }
        }
    }
    
    func MPMoviePlayerPlaybackStateDidChange (noti: NSNotification) {
        println("changed! \(audioPlayerControl.moviePlayer.playbackState.rawValue)")
        
        if (forceStopPlayer && (
                audioPlayerControl.moviePlayer.playbackState == MPMoviePlaybackState.Paused ||
                audioPlayerControl.moviePlayer.playbackState == MPMoviePlaybackState.Playing)) {
            return
        }
        
        if (audioPlayerControl.moviePlayer.playbackState == MPMoviePlaybackState.Playing) {
            updatePlayState(PlayState.PLAYING)
            // Periodic timer for progress update.
            if remoteProgressTimer == nil {
                remoteProgressTimer = NSTimer.scheduledTimerWithTimeInterval(
                    0.5, target: self, selector: Selector("updateProgress"), userInfo: nil, repeats: true)
            }
        } else if (audioPlayerControl.moviePlayer.playbackState == MPMoviePlaybackState.Stopped) {
            if remoteProgressTimer != nil {
                remoteProgressTimer?.invalidate()
                remoteProgressTimer = nil
            }
        } else if (audioPlayerControl.moviePlayer.playbackState == MPMoviePlaybackState.Paused) {
            if ((audioPlayerControl.moviePlayer.loadState.rawValue & MPMovieLoadState.Playable.rawValue != 0 &&
                audioPlayerControl.moviePlayer.loadState.rawValue & MPMovieLoadState.Stalled.rawValue != 0) ||
                PlayerContext.playState == PlayState.SWITCHING ||
                PlayerContext.playState == PlayState.BUFFERING) {
                // buffering
                return
            }
            updatePlayState(PlayState.PAUSED)
            if remoteProgressTimer != nil {
                remoteProgressTimer?.invalidate()
                remoteProgressTimer = nil
            }
        } else if (audioPlayerControl.moviePlayer.playbackState == MPMoviePlaybackState.Interrupted) {
            shouldPlayMusic = false
            updatePlayState(PlayState.PAUSED)
            if remoteProgressTimer != nil {
                remoteProgressTimer?.invalidate()
                remoteProgressTimer = nil
            }
        } else if (audioPlayerControl.moviePlayer.playbackState == MPMoviePlaybackState.SeekingForward) {
            if remoteProgressTimer != nil {
                remoteProgressTimer?.invalidate()
                remoteProgressTimer = nil
            }
            updatePlayState(PlayState.BUFFERING)
        } else if (audioPlayerControl.moviePlayer.playbackState == MPMoviePlaybackState.SeekingBackward) {
            if remoteProgressTimer != nil {
                remoteProgressTimer?.invalidate()
                remoteProgressTimer = nil
            }
            updatePlayState(PlayState.BUFFERING)
        }
    }
    
    func MPMoviePlayerContentPreloadDidFinish (noti:NSNotification) {
        var userInfo = noti.userInfo as? [String:AnyObject]
        if (userInfo != nil) {
            var reason:NSError? = userInfo!["error"] as? NSError
            if (reason != nil) {
                var errMsg = "This track is not streamable"
                ViewUtils.showNoticeAlert(self, title: "Failed to play",
                    message: errMsg)
                handleStop()
            }
        }
        println("preload finished")
    }
    
    
    func MPMoviePlayerPlaybackDidFinish (noti: NSNotification) {
        var userInfo = noti.userInfo as? [String:AnyObject]
        if (userInfo != nil) {
            var resultValue:NSNumber? = userInfo![MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] as? NSNumber
            if (resultValue != nil) {
                var reason = Int(resultValue!)
                if (reason == MPMovieFinishReason.PlaybackError.rawValue) {
                    // Finished with error
                    var err:NSError? = userInfo!["error"] as? NSError
                    var errMsg = "This track is not streamable "
                    ViewUtils.showNoticeAlert(self, title: "Failed to play",
                        message: errMsg)
                    handleStop()
                    return
                }
            }
        }
        if (self.audioPlayerControl.moviePlayer.contentURL == nil) {
            return
        }
        
        println("fin!!!!")
        var success :Bool = handleNext(false)
        if (!success) {
            handleStop()
        }
    }
    
    func MPMoviePlayerTimedMetadataUpdated(noti: NSNotification) {
        println("time meta updated")
    }
    
    func playParam(track: Track, playlistId: String) -> Dictionary<String, AnyObject> {
        var params: Dictionary<String, AnyObject> = [
            "track": track,
            "playlistId": playlistId
        ]
        return params
    }
    
    @IBAction func onMenuBtnClicked(sender: AnyObject) {
        actionSheetTargetTrack = PlayerContext.currentTrack
        var actionSheet = UIActionSheet()
        actionSheet.addButtonWithTitle("Add to playlist")
        actionSheet.addButtonWithTitle("Share")
        actionSheet.addButtonWithTitle("Cancel")
        actionSheet.cancelButtonIndex = 2
        actionSheet.showInView(self.view)
        actionSheet.delegate = self
    }
    
    @IBAction func playBtnClicked(sender: UIButton?) {
        println("play!")
        if (PlayerContext.currentTrack != nil) {
            var playlistId :String? = PlayerContext.currentPlaylistId
            handlePlay(PlayerContext.currentTrack!, playlistId: playlistId, force:true)
        }
    }
    
    @IBAction func onNextBtnClicked(sender: UIButton) {
        handleNext(true)
    }
    
    @IBAction func onPrevBtnClicked(sender: UIButton) {
        handlePrev(true)
    }
    
    @IBAction func onRepeatBtnClicked(sender: UIButton) {
        PlayerContext.changeRepeatState()
        updateNextPrevBtn()
        repeatStateUpdated()
    }
    
    @IBAction func onShuffleBtnClicked(sender: UIButton) {
        PlayerContext.changeShuffleState()
        updateNextPrevBtn()
        shuffleStateUpdated()
    }
    
    @IBAction func onQualityBtnClicked(sender: UIButton) {
        onQualityBtnClicked(sender, forceChange: false)
    }
    
    func onQualityBtnClicked(sender: UIButton, forceChange:Bool) {
        var appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        var networkStatus = appDelegate.networkStatus
        if (PlayerContext.playState == PlayState.SWITCHING) {
            return
        }
        //  we should confirm here for data usage
        if (!forceChange &&
            networkStatus == NetworkStatus.OTHER &&
            PlayerContext.qualityState == QualityState.LQ) {
                ViewUtils.showConfirmAlert(self, title: "Data usage warning",
                    message: "Streaming music in High Quality can use significant network data",
                    positiveBtnText: "Proceed", positiveBtnCallback: { () -> Void in
                        self.onQualityBtnClicked(sender, forceChange:true)
                    }, negativeBtnText: "Cancel", negativeBtnCallback: { () -> Void in
                        return
                })
                return
        }
        appDelegate.futureQuality = nil
        PlayerContext.changeQualityState()
        NSNotificationCenter.defaultCenter().postNotificationName(
            NotifyKey.updateQualityState, object: nil)
    }
    
    func onTrackShareBtnClicked(track:Track) {
        let progressHud = ViewUtils.showProgress(self, message: "Loading..")
        track.shareTrack("player", afterShare: { (error, uid) -> Void in
            progressHud.hide(false)
            if error != nil {
                if (error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    ViewUtils.showConfirmAlert(self, title: "Failed to share",
                        message: "Internet is not connected.",
                        positiveBtnText: "Retry", positiveBtnCallback: { () -> Void in
                            self.onTrackShareBtnClicked(track)
                        }, negativeBtnText: "Cancel", negativeBtnCallback: nil)
                    return
                }
                ViewUtils.showConfirmAlert(self, title: "Failed to share",
                    message: "Failed to share track",
                    positiveBtnText: "Retry", positiveBtnCallback: { () -> Void in
                        self.onTrackShareBtnClicked(track)
                    }, negativeBtnText: "Cancel", negativeBtnCallback: nil)
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
                activityController.popoverPresentationController?.sourceView = self.shareBtn
            }
            self.presentViewController(activityController, animated:true, completion: nil)
        })
    }
    
    func onAddToPlaylistBtnClicked(track:Track) {
        if (Account.getCachedAccount() == nil) {
            var appDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            var centerViewController = appDelegate.centerContainer!
            centerViewController.showSigninView()
            return
        }
        performSegueWithIdentifier("PlaylistSelectSegue", sender: track)
    }
    
    @IBAction func onTrackShareBtnClicked(sender: UIButton) {
        if PlayerContext.currentTrack == nil {
            ViewUtils.showToast(self, message: "No track selected")
            return
        }
        onTrackShareBtnClicked(PlayerContext.currentTrack!)
    }
    
    @IBAction func onPlaylistBtnClicked(sender: UIButton) {
        // this will be handle on CenterViewController
        if PlayerContext.currentPlaylistId == nil {
            return
        }
        
        var playlist = PlayerContext.getPlaylist(PlayerContext.currentPlaylistId)
        if playlist != nil {
            performSegueWithIdentifier("PlaylistSegue", sender: playlist)
        }
    }
    
    @IBAction func pauseBtnClicked(sender: UIButton?) {
        handlePause(true)
    }
    
    @IBAction func onProgressValueChanged(sender: UISlider) {
        handleSeek(sender.value)
    }
    
    @IBAction func onProgressDown(sender: UISlider) {
        isProgressUpdatable = false
    }
    
    @IBAction func onProgressUpInside(sender: UISlider) {
        onProgressUp(sender)
    }
    
    @IBAction func onProgressUpOutside(sender: UISlider) {
        onProgressUp(sender)
    }
    
    func onProgressUp(sender:UISlider) {
        // update progress after 1 sec
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC)))
        dispatch_after(time, dispatch_get_main_queue()) {
            self.isProgressUpdatable = true
        }
    }
    
    func remotePlay(noti: NSNotification) {
        var params = noti.object as! Dictionary<String, AnyObject>
        var track = params["track"] as! Track?
        var playlistId:String?
        if params["playlistId"] == nil {
            playlistId = nil
        } else {
            playlistId = params["playlistId"] as? String
        }
        handlePlay(track, playlistId: playlistId, force:true)
    }
    
    func remoteSeek(noti: NSNotification) {
        var params = noti.object as! Dictionary<String, AnyObject>
        var value = params["value"] as? Float ?? 0
        handleSeek(value)
    }
    
    func remotePause() {
        handlePause(true)
    }
    
    func remoteNext() {
        handleNext(true)
    }
    
    func remotePrev() {
        handlePrev(true)
    }
    
    func repeatStateUpdated() {
        if PlayerContext.repeatState == RepeatState.REPEAT_ONE {
            audioPlayerControl.moviePlayer.repeatMode = MPMovieRepeatMode.One
        } else {
            audioPlayerControl.moviePlayer.repeatMode = MPMovieRepeatMode.None
        }
        updateRepeatView()
    }
    
    func shuffleStateUpdated() {
        updateShuffleView()
    }
    
    func qualityStateUpdated() {
        if (PlayerContext.playState == PlayState.PAUSED ||
            PlayerContext.playState == PlayState.SWITCHING ||
            PlayerContext.playState == PlayState.STOPPED ||
            PlayerContext.currentTrack == nil) {
                return
        }
        startBackgroundTask()
        switchPlayerWithQuality(PlayerContext.currentTrack!, qualityState: PlayerContext.qualityState)
    }
    
    func networkStatusUpdated() {
        if (PlayerContext.playState == PlayState.STOPPED) {
            updateQualityView()
        }
    }
    
    func handlePlay(track: Track?, playlistId: String?, force:Bool) {
        println("handle play")
        // Fetch stream urls.
        if track == nil {
            return
        }
        
        forceStopPlayer = false
        
        if (track != nil) {
            var params: Dictionary<String, AnyObject> = [
                "track": track!
            ]
            if playlistId != nil {
                params["playlistId"] = playlistId!
            }
            
            NSNotificationCenter.defaultCenter().postNotificationName(
                NotifyKey.updatePlay, object: params)
        }
        
        if PlayerContext.currentTrack != nil && PlayerContext.currentTrack!.id == track!.id {
            if PlayerContext.playState == PlayState.LOADING ||
                PlayerContext.playState == PlayState.BUFFERING ||
                PlayerContext.playState == PlayState.SWITCHING {
                return
            }
            if audioPlayerControl.moviePlayer.playbackState == MPMoviePlaybackState.Paused ||
                audioPlayerControl.moviePlayer.playbackState == MPMoviePlaybackState.Interrupted {
                // Resume
                if force {
                    shouldPlayMusic = true
                }
                updatePlayStateView(PlayState.PLAYING)
                playAudioPlayer()
                return
            } else if audioPlayerControl.moviePlayer.playbackState == MPMoviePlaybackState.Playing {
                // Same music is clicked when it is being played.
                return
            }
            // In case of repeating one track.
        }
        
        if force {
            shouldPlayMusic = true
        }
        
        PlayerContext.currentTrack = track
        var closureTrack :Track? = track
        
        if playlistId != nil {
            var playlist :Playlist? = PlayerContext.getPlaylist(playlistId)
            if playlist == nil {
                PlayerContext.currentPlaylistId = nil
                PlayerContext.currentTrackIdx = -1
            } else {
                PlayerContext.currentPlaylistId = playlistId
                PlayerContext.currentTrackIdx = -1
                for (idx: Int, t: Track) in enumerate(playlist!.tracks) {
                    if t.id == track!.id {
                        PlayerContext.currentTrackIdx = idx
                        break
                    }
                }
            }
        } else {
            PlayerContext.currentPlaylistId = nil
            PlayerContext.currentTrackIdx = -1
        }
        
        // Init correct duration.
        PlayerContext.correctDuration = nil
        
        // Indicate loading status.
        updatePlayState(PlayState.LOADING)
        updatePlayerPlaylistBtn()
        updateNextPrevBtn()
        
        // Log to us
        Requests.logPlay(track!.title)
        
        // Log to GA
        let tracker = GAI.sharedInstance().defaultTracker
        let event = GAIDictionaryBuilder.createEventWithCategory(
                "player-play-from-ios",
                action: "play-\(track!.type)",
                label: track!.title,
                value: 0
            ).build()
        tracker.send(event as [NSObject: AnyObject]!)
        
        self.activateAudioSession()
        switchPlayerWithQuality(track!, qualityState: PlayerContext.qualityState, isInitial: true)
    }
    
    func switchPlayerWithQuality(track:Track, qualityState: Int, isInitial: Bool = false) {
        
        if !isInitial {
            lastPlaybackBeforeSwitch = audioPlayerControl.moviePlayer.currentPlaybackTime
        } else {
            lastPlaybackBeforeSwitch = nil
        }
        PlayerContext.correctDuration = nil
       
        audioPlayerControl.moviePlayer.contentURL = nil
        audioPlayerControl.videoIdentifier = nil
        shouldPlayMusic = true
        audioPlayerControl.moviePlayer.stop()

        if (isInitial) {
            PlayerContext.currentPlaybackTime = 0
            PlayerContext.correctDuration = nil
        } else {
            updatePlayState(PlayState.SWITCHING)
        }
        
        if (PlayerContext.qualityState == QualityState.LQ) {
            var qualities = [AnyObject]()
            qualities.append(XCDYouTubeVideoQuality.Small240.rawValue)
            qualities.append(XCDYouTubeVideoQuality.Medium360.rawValue)
            audioPlayerControl.preferredVideoQualities = qualities
        } else {
            audioPlayerControl.preferredVideoQualities = nil
        }
        
        if (track.type == "youtube") {
            audioPlayerControl.videoIdentifier = track.id
        } else {
            let url = resolveLocal(track.id, track.type)
            if (url == nil) {
                ViewUtils.showNoticeAlert(self, title: "Failed to play",
                    message: "Unsupported track type")
                // XXX: Cannot play.
                handleStop()
                return
            }
            audioPlayerControl.moviePlayer.contentURL = NSURL(string:url!)
            audioPlayerControl.videoIdentifier = nil
        }
        
        if (PlayerContext.repeatState == RepeatState.REPEAT_ONE) {
            audioPlayerControl.moviePlayer.repeatMode = MPMovieRepeatMode.One
        } else {
            audioPlayerControl.moviePlayer.repeatMode = MPMovieRepeatMode.None
        }
        
        // NOTE:
        // Not start play here 
        // audioPlayerControl.moviePlayer.play will be called on MPMoviePlayerLoadStateDidChange func
        // receive Playable or PlaythroughOK
        // see http://macromeez.tumblr.com/post/91330737652/continuous-background-media-playback-on-ios-using
        
        println("prepare to play")
        audioPlayerControl.moviePlayer.prepareToPlay()
        audioPlayerControl.moviePlayer.scalingMode = .AspectFill
        audioPlayerControl.moviePlayer.controlStyle = .Fullscreen
        audioPlayerControl.moviePlayer.view.userInteractionEnabled = false
        updateCoverView()
    }
    
    func handlePause(force:Bool) {
        if force {
            shouldPlayMusic = false
        }
        if (audioPlayerControl.moviePlayer.playbackState == MPMoviePlaybackState.Playing) {
            pauseAudioPlayer()
            updatePlayStateView(PlayState.PAUSED)
        }
    }
    
    func handleNext(force:Bool) -> Bool{
        println("handleNext")
        if remoteProgressTimer != nil {
            remoteProgressTimer?.invalidate()
            remoteProgressTimer = nil
        }
        
        var track: Track? = PlayerContext.pickNextTrack()
        if (track == nil) {
            println("track null")
            return false;
        }
        
        handlePlay(track, playlistId: PlayerContext.currentPlaylistId, force: force)
        return true;
    }
    
    func handlePrev(force:Bool) -> Bool {
        println("handlePrev")
        if remoteProgressTimer != nil {
            remoteProgressTimer?.invalidate()
            remoteProgressTimer = nil
        }
        
        var track: Track? = PlayerContext.pickPrevTrack()
        if (track == nil) {
            return false;
        }
        
        handlePlay(track, playlistId: PlayerContext.currentPlaylistId, force: force)
        return true;
    }
    
    func handleStop() {
        shouldPlayMusic = false
        PlayerContext.currentPlaylistId = nil
        PlayerContext.currentTrack = nil
        PlayerContext.currentTrackIdx = -1
        PlayerContext.correctDuration = nil
        videoView.hidden = true
        audioPlayerControl.videoIdentifier = nil
        audioPlayerControl.moviePlayer.contentURL = nil
        if (audioPlayerControl.moviePlayer.playbackState != MPMoviePlaybackState.Stopped) {
            audioPlayerControl.moviePlayer.stop()
        }
        updatePlayState(PlayState.STOPPED)
        updateCoverView()
        deactivateAudioSession()
    }
    
    func handleSeek(value:Float) {
        if (PlayerContext.playState != PlayState.PLAYING) {
            return
        }
        let duration = PlayerContext.correctDuration ?? 0
        var newPlaybackTime:Double = (duration * Double(value)) / 100
        
        // - 1 is hacky way to prevent player exceed correct duration
        // player gain repeatedly pasuse / play event after correntDuration
        if (newPlaybackTime >= duration && duration > 0) {
            newPlaybackTime = duration - 1
        }
        audioPlayerControl.moviePlayer.currentPlaybackTime = newPlaybackTime
    }
    
    func playAudioPlayer() {
        audioPlayerControl.moviePlayer.play()
    }
    
    func pauseAudioPlayer() {
        audioPlayerControl.moviePlayer.pause()
    }
    
    func updatePlayState(playingState: Int) {
        println("playstate updated:\(playingState)")
        PlayerContext.playState = playingState
        updatePlayStateView(playingState)
    }
    
    var playingStateImageOperation:SDWebImageOperation?
    
    func updatePlayStateView(playingState:Int) {
        var track: Track? = PlayerContext.currentTrack
        var playingInfoCenter:AnyClass! = NSClassFromString("MPNowPlayingInfoCenter")
        if (playingInfoCenter != nil && track != nil) {
            playingStateImageOperation?.cancel()
            
            let manager:SDWebImageManager = SDWebImageManager.sharedManager()
            if track!.hasHqThumbnail {
                if !manager.cachedImageExistsForURL(NSURL(string:track!.thumbnailUrl!)) {
                    updatePlayingInfoCenter(playingState, image: UIImage(named:"default_cover_big")!)
                }
                
                playingStateImageOperation = manager.downloadImageWithURL(
                    NSURL(string: track!.thumbnailUrl!),
                    options: SDWebImageOptions.ContinueInBackground,
                    progress: { (receivedSize:Int, expectedSize:Int) -> Void in
                        
                    },
                    completed: {
                        (image:UIImage!, error:NSError!, cacheType:SDImageCacheType, finished:Bool, imageUrl:NSURL!) -> Void in
                        var thumbImage = image
                        if error != nil {
                            thumbImage = UIImage(named:"default_cover_big")!
                        }
                        self.updatePlayingInfoCenter(playingState, image: thumbImage)
                    })
                
            } else {
                updatePlayingInfoCenter(playingState, image: UIImage(named:"default_cover_big")!)
            }
        }
        updateExtraViews()
        updatePlayView()
    }
    
    func updatePlayingInfoCenter(playingState:Int, image:UIImage) {
        var track: Track? = PlayerContext.currentTrack
        if track == nil {
            return
        }
        
        var trackInfo:NSMutableDictionary = NSMutableDictionary()
        var albumArt:MPMediaItemArtwork = MPMediaItemArtwork(image: image)
        trackInfo[MPMediaItemPropertyTitle] = track!.title
        
        var stateText:String?
        var rate:Float?
        switch(playingState) {
            case PlayState.LOADING:
                stateText = "LOADING.."
                rate = 0.0
                break
            case PlayState.SWITCHING:
                stateText = "LOADING.."
                rate = 0.0
                break
            case PlayState.PAUSED:
                stateText = "PAUSED"
                rate = 0
                break
            case PlayState.STOPPED:
                stateText = "READY"
                rate = 0
                break
            case PlayState.PLAYING:
                stateText = "PLAYING"
                rate = 1.0
                break
            case PlayState.BUFFERING:
                stateText = "BUFFERING"
                rate = 1.0
                break
            default:
                stateText = ""
        }
        trackInfo[MPMediaItemPropertyArtist] = stateText
        trackInfo[MPMediaItemPropertyArtwork] = albumArt
        
        let duration = PlayerContext.correctDuration ?? 0
        var currentPlayback:NSTimeInterval?
        if audioPlayerControl.moviePlayer.currentPlaybackTime.isNaN {
            currentPlayback = 0
        } else {
            currentPlayback = audioPlayerControl.moviePlayer.currentPlaybackTime ?? 0
        }
        playingInfoDisplayDuration = duration > 0 && currentPlayback >= 0
        
        trackInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentPlayback
        trackInfo[MPMediaItemPropertyPlaybackDuration] = duration
        trackInfo[MPNowPlayingInfoPropertyPlaybackRate] = rate
        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = trackInfo as [NSObject : AnyObject]
    }
    
    func activateAudioSession() {
        // Init audioSession
        var sharedInstance:AVAudioSession = AVAudioSession.sharedInstance()
        var audioSessionError:NSError?
        if (!sharedInstance.setCategory(AVAudioSessionCategoryPlayback, error: &audioSessionError)) {
            println("Audio session error \(audioSessionError) \(audioSessionError?.userInfo)")
        }
        sharedInstance.setActive(true, error: nil)
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        startBackgroundTask()
    }
    
    func deactivateAudioSession() {
        // Init audioSession
        var sharedInstance:AVAudioSession = AVAudioSession.sharedInstance()
        sharedInstance.setActive(false, error: nil)
        UIApplication.sharedApplication().endReceivingRemoteControlEvents()
        stopBackgroundTask()
    }
    
    func startBackgroundTask() {
        // register background task
        let sharedApplication = UIApplication.sharedApplication()
        var prevBgTaskId = bgTaskId
        bgTaskId = sharedApplication.beginBackgroundTaskWithExpirationHandler({ () -> Void in
            sharedApplication.endBackgroundTask(self.bgTaskId)
            self.bgTaskId = UIBackgroundTaskInvalid
            println("expired background task")
        })
        if (prevBgTaskId != UIBackgroundTaskInvalid) {
            sharedApplication.endBackgroundTask(prevBgTaskId)
        }
    }
    
    // We will not stop background task for ios7
    // ios call this function with forceStop only when music stopped
    func stopBackgroundTask() {
        let sharedApplication = UIApplication.sharedApplication()
        if (bgTaskId != UIBackgroundTaskInvalid) {
            sharedApplication.endBackgroundTask(bgTaskId)
            bgTaskId = UIBackgroundTaskInvalid
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "PlaylistSegue" {
            let playlistVC:PlaylistViewController = segue.destinationViewController as! PlaylistViewController
            playlistVC.currentPlaylist = sender as! Playlist
            playlistVC.fromPlayer = true
        } else if segue.identifier == "PlaylistSelectSegue" {
            let playlistSelectVC:PlaylistSelectViewController = segue.destinationViewController as! PlaylistSelectViewController
            playlistSelectVC.targetTrack = sender as? Track
            playlistSelectVC.fromSection = "feed"
            playlistSelectVC.caller = self
        }
    }
}
