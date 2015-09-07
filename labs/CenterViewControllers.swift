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
    @IBOutlet weak var progressSliderBar: UISlider!
    
    @IBOutlet weak var playerTitle: UILabel!
    @IBOutlet weak var playerStatus: UILabel!
    
    @IBOutlet weak var likeProgIndicator: UIActivityIndicatorView!
    @IBOutlet weak var likeBtn: UIButton!
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
    //    @IBOutlet weak var playlistBtn: UIButton!
    
    static var observerAttached: Bool = false
    static var sharedInstance:PlayerViewController?
    
    private var audioPlayerControl: XCDYouTubeVideoPlayerViewController = XCDYouTubeVideoPlayerViewController()
    
    private var remoteProgressTimer: NSTimer?
    private var bufferingTimer: NSTimer?
    
    private var isProgressUpdatable = true
    private var prevShuffleBtnState:Int?
    private var prevRepeatBtnState:Int?
    
    private var bgTaskId:UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    private var removedId:UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    
    // Used only for video playback recovery.
    private var shouldPlayMusic: Bool = false
    private var prevResolveReq:Request? = nil
    private var forceStopPlayer = false
    private var playingInfoDisplayDuration = false
    private var hookingBackground: Bool = false
    
    private var actionSheetTargetTrack:Track?
    private var actionSheetIncludePlaylist = false
    private var lastPlaybackBeforeSwitch:Double?
    private var prevQualityState:Int?
    
// MARK: Methods
    
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
        updateLikeBtn()
        audioPlayerControl.view.frame = CGRectMake(0, 0, videoView.frame.width, videoView.frame.height)
        
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "onLikeUpdated", name: NotifyKey.likeUpdated, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
        updatePlayView()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        resignFirstResponder()
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.likeUpdated, object: nil)
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
    
//    func sender() {}
    
    
    func asignObservers () {
        PlayerViewController.observerAttached = true
//        // Used for track list play / nonplay ui update
        
        // Observe remote input.
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "resumePlay", name: NotifyKey.resumePlay, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "handleUpdatePlay:", name: NotifyKey.updatePlay, object: nil)
        
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
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.updatePlay, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.resumePlay, object: nil)

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
            ViewUtils.showToast(self, message: NSLocalizedString("No track selected", comment:""))
            return
        }
        var idx = buttonIndex
        if !actionSheetIncludePlaylist {
            idx += 1
        }
        switch(idx) {
        case 0:
            var playlist:Playlist?
            if PlayerContext.currentPlaylistId != nil {
                playlist = PlayerContext.getPlaylist(PlayerContext.currentPlaylistId)
            }
            if playlist == nil {
                ViewUtils.showToast(self,
                    message: NSLocalizedString("Failed to find playlist", comment:""))
                return
            }
            performSegueWithIdentifier("PlaylistSegue", sender: playlist)
            break
        case 1:
            onAddToPlaylistBtnClicked(actionSheetTargetTrack!)
            break
        case 2:
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
        updateLikeBtn()
    }
    
    func triggerBackgroundPlay(retry:Int) {
        var popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.1 * Double(NSEC_PER_SEC)))
        dispatch_after(popTime, dispatch_get_main_queue()) {
            println("poll background play")
            if (!self.shouldPlayMusic || PlayerContext.playState != PlayState.PAUSED) {
                println("stop polling")
                self.hookingBackground = false
                return
            }
            if (PlayerContext.playState == PlayState.PAUSED) {
                println("play state is paused, try play")
                self.handlePlay(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId,
                    section: PlayerContext.playingSection, force:false)
                self.triggerBackgroundPlay(retry - 1)
            } else {
                println("play state is not paused. stop polling")
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
        //        updatePlayerPlaylistBtn()
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
    
    //    func updatePlayerPlaylistBtn () {
    //        if PlayerContext.currentPlaylistId == nil {
    //            playlistBtn.setImage(UIImage(named:"ic_list_gray.png"), forState: UIControlState.Normal)
    //            playlistBtn.enabled = false
    //        } else {
    //            playlistBtn.setImage(UIImage(named:"ic_list.png"), forState: UIControlState.Normal)
    //            playlistBtn.enabled = true
    //        }
    //    }
    
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
        let defaultText = NSLocalizedString("CHOOSE TRACK", comment:"")
        if (PlayerContext.playState == PlayState.LOADING ||
            PlayerContext.playState == PlayState.SWITCHING) {
                playerStatus.text = NSLocalizedString("LOADING", comment:"")
                playerTitle.text = PlayerContext.currentTrack?.title ?? defaultText
        } else if (PlayerContext.playState == PlayState.PAUSED) {
            playerStatus.text = NSLocalizedString("PAUSED", comment:"")
            playerTitle.text = PlayerContext.currentTrack?.title ?? defaultText
        } else if (PlayerContext.playState == PlayState.PLAYING) {
            playerStatus.text = NSLocalizedString("PLAYING", comment:"")
            playerTitle.text = PlayerContext.currentTrack?.title ?? defaultText
        } else if (PlayerContext.playState == PlayState.STOPPED) {
            playerStatus.text = NSLocalizedString("READY", comment:"")
            playerTitle.text = defaultText
        } else if (PlayerContext.playState == PlayState.BUFFERING) {
            playerStatus.text = NSLocalizedString("BUFFERING", comment:"")
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
            progressSliderBar.enabled = false
        } else {
            if (progressSliderBar.enabled) {
                progressSliderBar.value = (curr * 100) / total
            }
            
            var state = PlayerContext.playState
            if (PlayerContext.playState == PlayState.PLAYING) {
                progressSliderBar.enabled = true
            } else {
                progressSliderBar.enabled = false
            }
            progressTextView.text = getTimeFormatText(PlayerContext.currentPlaybackTime ?? 0)
            totalTextView.text = getTimeFormatText(PlayerContext.correctDuration ?? 0)
        }
    }
    
    func updateLikeBtn() {
        if PlayerContext.currentTrack?.isLiked ?? false {
            likeBtn.setImage(UIImage(named:"ic_player_heart_fill_btn.png"),
                forState: UIControlState.Normal)
        } else {
            likeBtn.setImage(UIImage(named:"ic_player_heart_btn.png"),
                forState: UIControlState.Normal)
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
                println("update state to buffering")
                if bufferingTimer == nil {
                    bufferingTimer = NSTimer.scheduledTimerWithTimeInterval(
                        0.5, target: self, selector: Selector("checkBufferState"), userInfo: nil, repeats: true)
                }
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
            if bufferingTimer == nil {
                bufferingTimer = NSTimer.scheduledTimerWithTimeInterval(
                    0.5, target: self, selector: Selector("checkBufferState"), userInfo: nil, repeats: true)
            }
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
    
    func checkBufferState() {
        if PlayerContext.playState != PlayState.BUFFERING &&
            PlayerContext.playState != PlayState.LOADING &&
            PlayerContext.playState != PlayState.SWITCHING {
                println("invalidate buffering timer")
                bufferingTimer?.invalidate()
                bufferingTimer = nil
                return
        }
        var currTime = audioPlayerControl.moviePlayer.currentPlaybackTime
        var playableTime = audioPlayerControl.moviePlayer.playableDuration
        var duration = audioPlayerControl.moviePlayer.duration
        if duration == 0 {
            return
        }
        
        // Buffer should be more than 3sec
        if playableTime - currTime > 3 || playableTime >= duration {
            bufferingTimer?.invalidate()
            bufferingTimer = nil
            audioPlayerControl.moviePlayer.play()
            println("play audio from buffer timer")
        } else {
            println("curr buffering state  = \(playableTime - currTime)")
        }
    }
    
    func MPMoviePlayerPlaybackStateDidChange (noti: NSNotification) {
        if (audioPlayerControl.moviePlayer.playbackState == MPMoviePlaybackState.Playing) {
            println("changed! playing")
        } else if (audioPlayerControl.moviePlayer.playbackState == MPMoviePlaybackState.Stopped) {
            println("changed! stopped")
        } else if (audioPlayerControl.moviePlayer.playbackState == MPMoviePlaybackState.Paused) {
            println("changed! paused")
        } else if (audioPlayerControl.moviePlayer.playbackState == MPMoviePlaybackState.Interrupted) {
            println("changed! interrupted")
        } else if (audioPlayerControl.moviePlayer.playbackState == MPMoviePlaybackState.SeekingForward) {
            println("changed! seekingForward")
        } else if (audioPlayerControl.moviePlayer.playbackState == MPMoviePlaybackState.SeekingBackward) {
            println("changed! seekingBackward")
        }
        
        if (forceStopPlayer && (
            audioPlayerControl.moviePlayer.playbackState == MPMoviePlaybackState.Paused ||
                audioPlayerControl.moviePlayer.playbackState == MPMoviePlaybackState.Playing)) {
                    return
        }
        
        if (audioPlayerControl.moviePlayer.playbackState == MPMoviePlaybackState.Playing) {
            updatePlayState(PlayState.PLAYING)
            println("update state to playing")
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
            println("update state to buffering")
        } else if (audioPlayerControl.moviePlayer.playbackState == MPMoviePlaybackState.SeekingBackward) {
            if remoteProgressTimer != nil {
                remoteProgressTimer?.invalidate()
                remoteProgressTimer = nil
            }
            updatePlayState(PlayState.BUFFERING)
            println("update state to buffering")
        }
    }
    
    func MPMoviePlayerContentPreloadDidFinish (noti:NSNotification) {
        var userInfo = noti.userInfo as? [String:AnyObject]
        if (userInfo != nil) {
            var reason:NSError? = userInfo!["error"] as? NSError
            if (reason != nil) {
                var errMsg = NSLocalizedString("This track is not streamable", comment:"")
                ViewUtils.showNoticeAlert(self, title: NSLocalizedString("Failed to play", comment:""),
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
                    var errMsg = NSLocalizedString("This track is not streamable", comment:"")
                    ViewUtils.showNoticeAlert(self, title: NSLocalizedString("Failed to play", comment:""),
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
        var success :Bool = handleNext(shouldPlayMusic)
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
    
    @IBAction func onLikeBtnClicked(sender: AnyObject) {
        if !likeProgIndicator.hidden {
            return
        }
        if PlayerContext.currentTrack == nil {
            ViewUtils.showToast(self, message: NSLocalizedString("No track selected", comment:""))
            return
        }
        if (Account.getCachedAccount() == nil) {
            performSegueWithIdentifier("need_auth", sender: nil)
            return
        }
        if PlayerContext.currentTrack!.isLiked {
            doUnlike(PlayerContext.currentTrack!)
        } else {
            doLike(PlayerContext.currentTrack!)
        }
    }
    
    func doLike(track:Track) {
        likeBtn.hidden = true
        likeProgIndicator.startAnimating()
        track.doLike({(error:NSError?) -> Void in
            self.likeProgIndicator.stopAnimating()
            self.likeBtn.hidden = false
            if error != nil {
                ViewUtils.showConfirmAlert(self,
                    title: NSLocalizedString("Failed to save", comment: ""),
                    message: NSLocalizedString("Failed to save like info.", comment: ""),
                    positiveBtnText: NSLocalizedString("Retry", comment:""),
                    positiveBtnCallback: { () -> Void in
                        self.doLike(track)
                })
                return
            }
        })
    }
    
    func doUnlike(track:Track) {
        if !likeProgIndicator.hidden {
            return
        }
        
        likeBtn.hidden = true
        likeProgIndicator.startAnimating()
        track.doUnlike({(error:NSError?) -> Void in
            self.likeProgIndicator.stopAnimating()
            self.likeBtn.hidden = false
            if error != nil {
                ViewUtils.showConfirmAlert(self,
                    title: NSLocalizedString("Failed to save", comment: ""),
                    message: NSLocalizedString("Failed to save unlike info.", comment: ""),
                    positiveBtnText: NSLocalizedString("Retry", comment:""),
                    positiveBtnCallback: { () -> Void in
                        self.doLike(track)
                })
                return
            }
        })
    }
    
    @IBAction func onMenuBtnClicked(sender: AnyObject) {
        actionSheetTargetTrack = PlayerContext.currentTrack
        actionSheetIncludePlaylist = PlayerContext.currentPlaylistId != nil
        var actionSheet = UIActionSheet()
        if actionSheetIncludePlaylist {
            actionSheet.addButtonWithTitle(NSLocalizedString("Open current playlist", comment:""))
            actionSheet.cancelButtonIndex = 3
        } else {
            actionSheet.cancelButtonIndex = 2
        }
        actionSheet.addButtonWithTitle(NSLocalizedString("Add to playlist", comment:""))
        actionSheet.addButtonWithTitle(NSLocalizedString("Share", comment:""))
        actionSheet.addButtonWithTitle(NSLocalizedString("Cancel", comment:""))
        actionSheet.showInView(self.view)
        actionSheet.delegate = self
    }
    
    @IBAction func playBtnClicked(sender: UIButton?) {
        if (PlayerContext.currentTrack != nil) {
            println("play!")
            var playlistId :String? = PlayerContext.currentPlaylistId
            handlePlay(PlayerContext.currentTrack!, playlistId: playlistId, section: "player", force:true)
        }
    }
    
    @IBAction func pauseBtnClicked(sender: UIButton?) {
        handlePause(true)
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
                ViewUtils.showConfirmAlert(self, title: NSLocalizedString("Data usage warning", comment:""),
                    message: NSLocalizedString("Streaming music in High Quality can use significant network data", comment:""),
                    positiveBtnText: NSLocalizedString("Proceed", comment:""), positiveBtnCallback: { () -> Void in
                        self.onQualityBtnClicked(sender, forceChange:true)
                    }, negativeBtnText: NSLocalizedString("Cancel", comment:""), negativeBtnCallback: { () -> Void in
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
        let progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Loading..", comment:""))
        track.shareTrack("player", afterShare: { (error, uid) -> Void in
            progressHud.hide(true)
            if error != nil {
                if (error!.domain == NSURLErrorDomain &&
                    error!.code == NSURLErrorNotConnectedToInternet) {
                        ViewUtils.showConfirmAlert(self, title: NSLocalizedString("Failed to share", comment:""),
                            message: NSLocalizedString("Internet is not connected", comment:""),
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
                activityController.popoverPresentationController?.sourceView = self.shareBtn
            }
            self.presentViewController(activityController, animated:true, completion: nil)
        })
    }
    
    func onAddToPlaylistBtnClicked(track:Track) {
        if (Account.getCachedAccount() == nil) {
            performSegueWithIdentifier("need_auth", sender: nil)
            return
        }
        performSegueWithIdentifier("PlaylistSelectSegue", sender: track)
    }
    
    @IBAction func onTrackShareBtnClicked(sender: UIButton) {
        if PlayerContext.currentTrack == nil {
            ViewUtils.showToast(self, message: NSLocalizedString("No track selected", comment:""))
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
    
    func onLikeUpdated() {
        updateLikeBtn()
    }
    
    func onProgressUp(sender:UISlider) {
        // update progress after 1 sec
//        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC)))
//        dispatch_after(time, dispatch_get_main_queue()) {
            self.isProgressUpdatable = true
//        }
    }
    
// MARK: Notification Handling
    
    func resumePlay () {
//        if (self.manuallyPaused == false) {
//            self.playBtnClicked(nil)
//        }
//        println("try to resume")
    }
    
    func remotePause() {
        handlePause(true)
    }
    
    func handleUpdatePlay(noti: NSNotification) {
        println("make time label to 00:00")
        progressSliderBar.value = 0
        progressTextView.text = getTimeFormatText(0)
        totalTextView.text = getTimeFormatText(0)
    }
    
    func remotePlay(noti: NSNotification) {
        var params = noti.object as! Dictionary<String, AnyObject>
        var track = params["track"] as? Track
        var playlistId:String?
        if params["playlistId"] == nil {
            playlistId = nil
        } else {
            playlistId = params["playlistId"] as? String
        }
        let section = params["section"] as? String
        handlePlay(track, playlistId: playlistId, section: section, force:true)
    }
    
    func remoteSeek(noti: NSNotification) {
        var params = noti.object as! Dictionary<String, AnyObject>
        var value = params["value"] as? Float ?? 0
        handleSeek(value)
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
                updateQualityView()
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
    
    func handlePlay(track: Track?, playlistId: String?, section:String?, force:Bool) {
        println("handle play")
        // Fetch stream urls.
        if track == nil {
            return
        }
        
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
                    shouldPlayMusic = force
                    if prevQualityState != PlayerContext.qualityState {
                        startBackgroundTask()
                        switchPlayerWithQuality(PlayerContext.currentTrack!, qualityState: PlayerContext.qualityState)
                    } else {
                        updatePlayStateView(PlayState.PLAYING)
                        playAudioPlayer()
                    }
                    return
            } else if audioPlayerControl.moviePlayer.playbackState == MPMoviePlaybackState.Playing {
                // Same music is clicked when it is being played.
                return
            }
            // In case of repeating one track.
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
        updateNextPrevBtn()
        updateLikeBtn()
        
        // Log to us
        Requests.logPlay(track!)
        
        var playSection = section ?? "uknown"
        
        // Log to GA
        let tracker = GAI.sharedInstance().defaultTracker
        let event = GAIDictionaryBuilder.createEventWithCategory(
            "player-play-from-\(playSection)",
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
        
        prevQualityState = PlayerContext.qualityState
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
                ViewUtils.showNoticeAlert(self, title: NSLocalizedString("Failed to play", comment:""),
                    message: NSLocalizedString("Unsupported track type", comment:""))
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
        
        handlePlay(track, playlistId: PlayerContext.currentPlaylistId,
            section: PlayerContext.playingSection, force: force)
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
        
        handlePlay(track, playlistId: PlayerContext.currentPlaylistId,
            section: PlayerContext.playingSection, force: force)
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
        
        // To prevent slider to go back where it was
        progressSliderBar.enabled = false

        audioPlayerControl.moviePlayer.currentPlaybackTime = newPlaybackTime
        
        // Manually enable the slider before the timer does for us
        updateProgressView()
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
        updateLikeBtn()
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
        var rate:Float!
        switch(playingState) {
        case PlayState.LOADING:
            stateText = NSLocalizedString("LOADING..", comment:"")
            rate = 0.0
            break
        case PlayState.SWITCHING:
            stateText = NSLocalizedString("LOADING..", comment:"")
            rate = 1.0
            break
        case PlayState.PAUSED:
            stateText = NSLocalizedString("PAUSED", comment:"")
            rate = 0.0
            break
        case PlayState.STOPPED:
            stateText = NSLocalizedString("READY", comment:"")
            rate = 0.0
            break
        case PlayState.PLAYING:
            stateText = NSLocalizedString("PLAYING", comment:"")
            rate = 1.0
            break
        case PlayState.BUFFERING:
            stateText = NSLocalizedString("BUFFERING", comment:"")
            rate = 1.0
            break
        default:
            stateText = ""
            rate = 0.0
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


//
//  CenterViewController.swift
//  labs
//
//  Created by vulpes on 2015. 5. 15..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

enum MenuType {
    case FEED
    case CHANNEL
    case SEARCH
    case PROFILE
    case PLAYER
}

class CenterViewController: PlayerViewController, UITabBarDelegate{
    
    static let TAB_FEED = 1
    static let TAB_CHANNEL = 2
    static let TAB_SEARCH = 3
    static let TAB_PROFILE = 4
    static let TAB_PLAYER = 5
    
    @IBOutlet weak var containerFrame: UIView!
    
    @IBOutlet weak var menuBtn: UIButton!
    @IBOutlet weak var hideBtn: UIButton!
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var tabBar: UITabBar!
    
    private var currentMenu:MenuType = MenuType.FEED
    private var isPlayerVisible:Bool = false
    
    private var activeViewController: UIViewController? {
        didSet {
            removeInactiveViewController(oldValue)
            updateActiveViewController()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hideBtn.layer.cornerRadius = 3.0
        hideBtn.layer.borderWidth = 1
        hideBtn.layer.borderColor = UIColor(netHex: 0x4f525a).CGColor
        
        menuBtn.layer.cornerRadius = 3.0
        menuBtn.layer.borderWidth = 1
        menuBtn.layer.borderColor = UIColor(netHex: 0x4f525a).CGColor
    
        initConstaints()
        
        // set first item
        let firstTab:UITabBarItem = tabBar.items![menuTypeToTabIdx(currentMenu)] as! UITabBarItem
        tabBar.selectedItem = firstTab
        onMenuSelected(currentMenu, forceUpdate:true)
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        loadSharedTrackIfExist()
        loadSharedPlaylistIfExist()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = "CenterViewScreen"
        
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "loadSharedTrackIfExist", name: NotifyKey.trackShare, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "loadSharedPlaylistIfExist", name: NotifyKey.playlistShare, object: nil)
        setNeedsStatusBarAppearanceUpdate()
    }
    
    func loadSharedTrackIfExist() {
        var appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        if appDelegate.sharedTrackUid == nil {
            return
        }
        
        let progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Loading..", comment:""))
        Requests.getSharedTrack(appDelegate.sharedTrackUid!, respCb: {
                (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            
            progressHud.hide(true)
            var success:Bool = true
            var track:Track?
            
            if error != nil || result == nil {
                success = false
            } else {
                let parser = Parser()
                track = parser.parseSharedTrack(result!)
                if track == nil {
                    success = false
                }
            }
            
            if !success {
                ViewUtils.showNoticeAlert(
                    self,
                    title: NSLocalizedString("Failed to load", comment:""),
                    message: NSLocalizedString("Failed to load shared track", comment:""),
                    btnText: NSLocalizedString("Confirm", comment:""),
                    callback: nil)
                return
            }
            
            var params: [String: AnyObject] = [
                "track": track!,
                "section": "shared_track"
            ]
            NSNotificationCenter.defaultCenter().postNotificationName(
                NotifyKey.playerPlay, object: params)
        })
        appDelegate.sharedTrackUid = nil
    }
    
    func loadSharedPlaylistIfExist() {
        var appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        if appDelegate.sharedPlaylistUid == nil {
            return
        }
        
        let progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Loading..", comment:""))
        Requests.getSharedPlaylist(appDelegate.sharedPlaylistUid!, respCb: {
                (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            
            var success:Bool = true
            var playlist:Playlist?
            
            if error != nil || result == nil {
                success = false
            } else {
                let parser = Parser()
                playlist = parser.parseSharedPlaylist(result!)
                if playlist == nil {
                    success = false
                }
            }
            
            if !success {
                ViewUtils.showNoticeAlert(
                    self,
                    title: NSLocalizedString("Failed to load", comment:""),
                    message: NSLocalizedString("Failed to load shared playlist", comment:""),
                    btnText: NSLocalizedString("Confirm", comment:""),
                    callback: nil)
                progressHud.hide(true)
                return
            }
            
            playlist!.type = PlaylistType.SHARED
            progressHud.hide(true)
            self.performSegueWithIdentifier("PlaylistSegue", sender: playlist)
        })
        appDelegate.sharedPlaylistUid = nil
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.None)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.trackShare, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.playlistShare, object: nil)
    }
    
    func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem!) {
        let menuType:MenuType? = tabTagToMenuType(item.tag)
        if menuType != nil {
            onMenuSelected(menuType!)
        }
    }
    
    func onMenuSelected(type:MenuType, forceUpdate:Bool=false) {
        if !forceUpdate && currentMenu == type {
            return
        }
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        switch(type) {
        case .FEED:
            activeViewController = mainStoryboard
                .instantiateViewControllerWithIdentifier("FeedNavigationController")
                as? UIViewController
            break
        case .CHANNEL:
            activeViewController = mainStoryboard
                .instantiateViewControllerWithIdentifier("ChannelNavigationController")
                as? UIViewController
            break
        case .SEARCH:
            activeViewController = mainStoryboard
                .instantiateViewControllerWithIdentifier("SearchNavigationController")
                as? UIViewController
            break
        case .PROFILE:
            if Account.getCachedAccount() == nil {
//                performSegueWithIdentifier("need_auth", sender: nil)
//                let lastTab:UITabBarItem = tabBar.items![menuTypeToTabIdx(currentMenu)] as! UITabBarItem
//                tabBar.selectedItem = lastTab
//                break
                activeViewController = mainStoryboard
                    .instantiateViewControllerWithIdentifier("SettingsNavigationController")
                    as? UIViewController
            } else {
                activeViewController = mainStoryboard
                    .instantiateViewControllerWithIdentifier("ProfileNavigationController")
                    as? UIViewController
            }
            break
        case .PLAYER:
            showTabBarPlayer(!self.isTabBarPlayerVisible)
//            showPlayerView()
//            let lastTab:UITabBarItem = tabBar.items![menuTypeToTabIdx(currentMenu)] as! UITabBarItem
//            tabBar.selectedItem = lastTab
            break
        default:
            break
        }
        if type != MenuType.PLAYER {
            currentMenu = type
        }
    }
    
    func tabTagToMenuType (tag:Int) -> MenuType? {
        var menuType:MenuType?
        switch(tag) {
        case CenterViewController.TAB_FEED:
            menuType = MenuType.FEED
            break
        case CenterViewController.TAB_CHANNEL:
            menuType = MenuType.CHANNEL
            break
        case CenterViewController.TAB_SEARCH:
            menuType = MenuType.SEARCH
            break
        case CenterViewController.TAB_PROFILE:
            menuType = MenuType.PROFILE
            break
        case CenterViewController.TAB_PLAYER:
            menuType = MenuType.PLAYER
            break
        default:
            break
        }
        return menuType
    }
    
    func menuTypeToTabIdx (type:MenuType) -> Int {
        var idx : Int
        switch(type) {
        case .FEED:
            return 0
        case .CHANNEL:
            return 1
        case .SEARCH:
            return 2
        case .PROFILE:
            return 3
        case .PLAYER:
            return 4
        default:
            return 0
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return isPlayerVisible
    }
    
    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return UIStatusBarAnimation.None
    }
    
// MARK: PlayerView Show/Hide Layout
    @IBOutlet weak var containerTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var tabBarContainerView: UIView!
    @IBOutlet weak var tabBarTopInsetConstraint: NSLayoutConstraint!
    @IBOutlet weak var tabBarBottomConstraint: NSLayoutConstraint!

    @IBOutlet weak var tabBarBorder: UIView!
    @IBOutlet weak var tabBarBorderHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var tabBarProgressBar: UIProgressView!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var trackInfoLabel: UILabel!
    
    func initConstaints() {
        self.tabBarTopInsetConstraint.constant = 0
        self.view.layoutIfNeeded()
        
        let statusBarHeight = UIApplication.sharedApplication().statusBarFrame.size.height
        self.containerTopConstraint.constant = -statusBarHeight
        self.containerBottomConstraint.constant = self.tabBarContainerView.frame.height
    }
    
    private var isTabBarPlayerVisible:Bool = false
    
    func showTabBarPlayer(visible:Bool) {
        if (visible == self.isTabBarPlayerVisible) {
            return
        }
        
        UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: { () -> Void in
            
            if (visible) {
                self.tabBarTopInsetConstraint.constant = 41
                self.tabBarBorderHeightConstraint.constant = 0.5
                self.tabBarBorder.backgroundColor = UIColor.lightGrayColor()
            }
            else {
                self.tabBarTopInsetConstraint.constant = 0
                self.tabBarBorderHeightConstraint.constant = 2
                self.tabBarBorder.backgroundColor = UIColor(red: 122/255.0, green: 29/255.0, blue: 236/255.0, alpha: 1.0)
            }
            self.view.layoutIfNeeded()
            
            self.containerBottomConstraint.constant = self.tabBarContainerView.frame.height
            self.view.layoutIfNeeded()
            
            }) { (Bool) -> Void in
        }
        
        self.isTabBarPlayerVisible = visible
    }
    
    override func updatePlayView() {
        super.updatePlayView()
        
        if (PlayerContext.playState == PlayState.LOADING ||
            PlayerContext.playState == PlayState.SWITCHING ||
            PlayerContext.playState == PlayState.BUFFERING) {
                showTabBarPlayer(true)
                self.playPauseButton.enabled = false
                self.playPauseButton.setImage(UIImage(named: "ic_play_purple.png"), forState: UIControlState.Normal)
        } else if (PlayerContext.playState == PlayState.PAUSED) {
            showTabBarPlayer(true)
            self.playPauseButton.enabled = true
            self.playPauseButton.setImage(UIImage(named: "ic_play_purple.png"), forState: UIControlState.Normal)
        } else if (PlayerContext.playState == PlayState.PLAYING) {
            showTabBarPlayer(true)
            self.playPauseButton.enabled = true
            self.playPauseButton.setImage(UIImage(named: "ic_pause_purple.png"), forState: UIControlState.Normal)
        } else if (PlayerContext.playState == PlayState.STOPPED) {
            showTabBarPlayer(false)
            self.playPauseButton.enabled = false
        }
    }
    
    override func updateStatusView() {
        super.updateStatusView()
        
        let defaultText = NSLocalizedString("CHOOSE TRACK", comment:"")
        if (PlayerContext.playState == PlayState.LOADING ||
            PlayerContext.playState == PlayState.SWITCHING) {
                self.trackInfoLabel.text = PlayerContext.currentTrack?.title ?? defaultText
        } else if (PlayerContext.playState == PlayState.PAUSED) {
            self.trackInfoLabel.text = PlayerContext.currentTrack?.title ?? defaultText
        } else if (PlayerContext.playState == PlayState.PLAYING) {
            self.trackInfoLabel.text = PlayerContext.currentTrack?.title ?? defaultText
        } else if (PlayerContext.playState == PlayState.STOPPED) {
            self.trackInfoLabel.text = defaultText
        } else if (PlayerContext.playState == PlayState.BUFFERING) {
            self.trackInfoLabel.text = PlayerContext.currentTrack?.title ?? defaultText
        }
    }
    
    override func updateProgressView() {
        super.updateProgressView()
        self.tabBarProgressBar.progress = super.progressSliderBar.value / 100.0
    }
    
    @IBAction func playPauseBtnClicked(sender: UIButton) {
        if (PlayerContext.playState == PlayState.PAUSED) {
            super.playBtnClicked(sender)
        } else if (PlayerContext.playState == PlayState.PLAYING) {
            super.pauseBtnClicked(sender)
        }
    }
    
    @IBAction func showPlayerBtnClicked(sender: UIButton) {
        showPlayerView()
    }
    
    func showPlayerView() {
        isPlayerVisible = true
        setNeedsStatusBarAppearanceUpdate()
        self.view.layoutIfNeeded()
        UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: { () -> Void in
//            self.containerTopConstraint.constant = 3 - self.containerHeightConstraint.constant

            let statusBarHeight:CGFloat = 20.0
            let height = self.containerView.frame.size.height
            var offset = height - statusBarHeight
            
            self.containerTopConstraint.constant -= offset
            self.containerBottomConstraint.constant += offset

            self.tabBarBottomConstraint.constant = -1 * self.tabBarContainerView.frame.height
            self.tabBarContainerView.alpha = 0.0
            self.view.layoutIfNeeded()
        }) { (Bool) -> Void in
        }
    }
    
    func hidePlayerView() {
        self.view.layoutIfNeeded()
        
        isPlayerVisible = false
        setNeedsStatusBarAppearanceUpdate()
        UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: { () -> Void in

            let statusBarHeight:CGFloat = 20.0
            self.containerBottomConstraint.constant = self.tabBarContainerView.frame.height
            self.containerTopConstraint.constant = -1 * statusBarHeight
            
            self.tabBarBottomConstraint.constant = 0
            self.tabBarContainerView.alpha = 1.0
            self.view.layoutIfNeeded()
        }) { (Bool) -> Void in
        }
    }
    
    func showSigninView() {
        performSegueWithIdentifier("need_auth", sender: nil)
    }
    
    private func removeInactiveViewController(inactiveViewController:UIViewController?) {
        if let inactiveVC = inactiveViewController {
            inactiveVC.willMoveToParentViewController(nil)
            inactiveVC.view.removeFromSuperview()
            inactiveVC.removeFromParentViewController()
        }
    }
    
    private func updateActiveViewController() {
        if let activeVC = activeViewController {
            // call before adding child view controller's view as subview
            addChildViewController(activeVC)
            
            activeVC.view.frame = containerFrame.bounds
            containerFrame.addSubview(activeVC.view)
            
            // call before adding child view controller's view as subview
            activeVC.didMoveToParentViewController(self)
        }
    }
    
    @IBAction func onHidePlayerViewBtnClicked(sender: AnyObject) {
        hidePlayerView()
    }
}
