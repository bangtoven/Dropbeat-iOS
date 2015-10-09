//
//  _PlayerViewController.swift
//  labs
//
//  Created by vulpes on 2015. 7. 29..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit
import MediaPlayer
import AVFoundation

class XCDYouTubeVideoPlayerViewController: MPMoviePlayerViewController {
    var videoIdentifier:String!
    var preferredVideoQualities:[AnyObject]!
    func presentInView(v:UIView){}
}

class _PlayerViewController: BaseViewController {
    
    @IBOutlet weak var playerTitleHeightConstaint: NSLayoutConstraint!
    
    @IBOutlet weak var coverView: UIView!
    @IBOutlet weak var loadingView: UIImageView!
    @IBOutlet weak var progressSliderBar: UISlider!
    
    @IBOutlet weak var playerTitle: MarqueeLabel!
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
    static var sharedInstance:_PlayerViewController?
    
    private var audioPlayerControl: XCDYouTubeVideoPlayerViewController = XCDYouTubeVideoPlayerViewController()
    
    private var remoteProgressTimer: NSTimer?
    private var bufferingTimer: NSTimer?
    
    private var isProgressUpdatable = true
//    private var prevShuffleBtnState:ShuffleState?
//    private var prevRepeatBtnState:RepeatState?
    
    private var bgTaskId:UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    private var removedId:UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    
    // Used only for video playback recovery.
    private var shouldPlayMusic: Bool = false 
    private var prevResolveReq:Request? = nil
    private var forceStopPlayer = false
    private var playingInfoDisplayDuration = false
    private var hookingBackground: Bool = false
    
    private var lastPlaybackBeforeSwitch:Double?
    private var prevQualityState:QualityState?
    
    // MARK: Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (_PlayerViewController.observerAttached == false) {
            _PlayerViewController.sharedInstance = self
            asignObservers()
        }
        
        audioPlayerControl.presentInView(videoView)
        if UIScreen.mainScreen().bounds.height == 480 {
            resizeViewUnder4in()
        }
        
        
        
//        let newTimer = createDispatchTimer(1 * NSEC_PER_SEC, leeway: (1 * NSEC_PER_SEC) / 10, queue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
//            print("called!")
//        }
//        dispatch_resume(newTimer)
    }
    
//    func createDispatchTimer(interval: UInt64, leeway: UInt64, queue: dispatch_queue_t, block: dispatch_block_t) -> dispatch_source_t {
//        let timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
//        if (timer != nil) {
//            dispatch_source_set_timer(timer, dispatch_walltime(nil, 0), interval, leeway);
//            dispatch_source_set_event_handler(timer, block);
//            dispatch_resume(timer);
//        }
//        return timer
//    }
    
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
    
    override func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        if (flag && (DropbeatPlayer.defaultPlayer.playState == PlayState.LOADING ||
            DropbeatPlayer.defaultPlayer.playState == PlayState.SWITCHING ||
            DropbeatPlayer.defaultPlayer.playState == PlayState.BUFFERING)) {
                loadingView.rotate360Degrees(0.7, completionDelegate: self)
        }
    }
    
    func asignObservers () {
        _PlayerViewController.observerAttached = true
        //        // Used for track list play / nonplay ui update
        
        // Observe remote input.
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "handleUpdatePlay:", name: NotifyKey.updatePlay, object: nil)
        
//        NSNotificationCenter.defaultCenter().addObserver(
//            self, selector: "remotePlay:", name: NotifyKey.playerPlay, object: nil)
//        NSNotificationCenter.defaultCenter().addObserver(
//            self, selector: "handleStop", name: NotifyKey.playerStop, object: nil)
//        NSNotificationCenter.defaultCenter().addObserver(
//            self, selector: "remotePrev", name: NotifyKey.playerPrev, object: nil)
//        NSNotificationCenter.defaultCenter().addObserver(
//            self, selector: "remotePause", name: NotifyKey.playerPause, object: nil)
//        NSNotificationCenter.defaultCenter().addObserver(
//            self, selector: "remoteNext", name: NotifyKey.playerNext, object: nil)
//        NSNotificationCenter.defaultCenter().addObserver(
//            self, selector: "remoteSeek:", name: NotifyKey.playerSeek, object: nil)
//        NSNotificationCenter.defaultCenter().addObserver(
//            self, selector: "repeatStateUpdated", name: NotifyKey.updateRepeatState, object: nil)
//        NSNotificationCenter.defaultCenter().addObserver(
//            self, selector: "shuffleStateUpdated", name: NotifyKey.updateShuffleState, object: nil)
//        NSNotificationCenter.defaultCenter().addObserver(
//            self, selector: "qualityStateUpdated", name: NotifyKey.updateQualityState, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "networkStatusUpdated", name: NotifyKey.networkStatusChanged, object: nil)
        
        
        
        // Observe internal player.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "MPMoviePlayerLoadStateDidChange:",
            name: MPMoviePlayerLoadStateDidChangeNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "MPMoviePlayerPlaybackStateDidChange:",
            name: MPMoviePlayerPlaybackStateDidChangeNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "MPMoviePlayerPlaybackDidFinish:",
            name: MPMoviePlayerPlaybackDidFinishNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "AVPlayerItemDidPlayToEndTime:", name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)
        
        // For video background playback
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "backgroundHook",
            name: UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "appWillEnterForeground",
            name: UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    func resignObservers() {
        _PlayerViewController.observerAttached = false
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.updatePlay, object: nil)
        
//        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.playerStop, object: nil)
//        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.playerPlay, object: nil)
//        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.playerPrev, object: nil)
//        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.playerPause, object: nil)
//        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.playerNext, object: nil)
//        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.playerSeek, object: nil)
//        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.updateRepeatState, object: nil)
//        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.updateShuffleState, object: nil)
//        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.updateQualityState, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.networkStatusChanged, object: nil)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: MPMoviePlayerLoadStateDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: MPMoviePlayerPlaybackStateDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: MPMoviePlayerPlaybackDidFinishNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)

        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillEnterForegroundNotification, object: nil)
        
        handleStop()
    }
    
    func backgroundHook () {
        if (DropbeatPlayer.defaultPlayer.currentTrack != nil) {
            // Check whether it is video and stopped when it entered into background.
            if (hookingBackground) {
                return
            }
            if (DropbeatPlayer.defaultPlayer.currentTrack!.type == .YOUTUBE &&
                DropbeatPlayer.defaultPlayer.playState == PlayState.PAUSED && shouldPlayMusic) {
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
        let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.1 * Double(NSEC_PER_SEC)))
        dispatch_after(popTime, dispatch_get_main_queue()) {
            print("poll background play")
            if (!self.shouldPlayMusic || DropbeatPlayer.defaultPlayer.playState != PlayState.PAUSED) {
                print("stop polling")
                self.hookingBackground = false
                return
            }
            if (DropbeatPlayer.defaultPlayer.playState == PlayState.PAUSED) {
                print("play state is paused, try play")
                self.handlePlay(DropbeatPlayer.defaultPlayer.currentTrack, playlistId: DropbeatPlayer.defaultPlayer.currentPlaylistId,
                    section: DropbeatPlayer.defaultPlayer.playingSection, force:false)
                self.triggerBackgroundPlay(retry - 1)
            } else {
                print("play state is not paused. stop polling")
                self.hookingBackground = false
            }
        }
    }
    
    func updateExtraViews() {
//        updateStatusView()
        updateProgressView()
        updateRepeatView()
        updateShuffleView()
        updateQualityView()
        //        updatePlayerPlaylistBtn()
    }
    
//    func updateNextPrevBtn() {
//        if DropbeatPlayer.defaultPlayer.pickNextTrack() != nil {
//            nextBtn.enabled = true
//            nextBtn.setImage(UIImage(named:"ic_forward"), forState: UIControlState.Normal)
//        } else {
//            nextBtn.enabled = false
//            nextBtn.setImage(UIImage(named:"ic_forward_gray"), forState: UIControlState.Normal)
//        }
//        
//        if DropbeatPlayer.defaultPlayer.pickPrevTrack() != nil {
//            prevBtn.enabled = true
//            prevBtn.setImage(UIImage(named:"ic_rewind"), forState: UIControlState.Normal)
//        } else {
//            prevBtn.enabled = false
//            prevBtn.setImage(UIImage(named:"ic_rewind_gray"), forState: UIControlState.Normal)
//        }
//    }
//    
//    // XXX : hacky solution for hide video controls
//    // This code should be well tested before release
//    func showMPMoviePlayerControls(show:Bool) {
//        let player = audioPlayerControl.moviePlayer
//        player.controlStyle = show ? MPMovieControlStyle.Embedded : MPMovieControlStyle.None
//        if SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO("8") {
//            let subViewObjs = player.backgroundView.superview?.superview?.subviews
//            if subViewObjs == nil {
//                return
//            }
//            if let subViews = subViewObjs {
//                for subView:UIView in subViews {
//                    if subView.isKindOfClass(NSClassFromString("MPVideoPlaybackOverlayView")!) {
//                        subView.backgroundColor = UIColor.clearColor()
//                        subView.alpha = show ? 1.0 : 0.0
//                        subView.hidden = show ? false : true
//                    }
//                }
//            }
//        }
//    }
//    
//    func updateCoverView() {
//        let track = DropbeatPlayer.defaultPlayer.currentTrack
//        if track == nil || DropbeatPlayer.defaultPlayer.playState == PlayState.STOPPED {
//            videoView.hidden = true
//            coverImageView.hidden = false
//            coverBgImageView.image = UIImage(named: "player_bg")
//            coverImageView.image = UIImage(named: "default_cover_big")
//        } else if track!.type == .YOUTUBE {
//            videoView.hidden = false
//            audioPlayerControl.view.hidden = false
//            audioPlayerControl.view.frame = CGRectMake(0, 0, videoView.frame.width, videoView.frame.height)
//            audioPlayerControl.presentInView(videoView)
//            showMPMoviePlayerControls(false)
//            coverImageView.hidden = true
//            
//            
//            if track!.hasHqThumbnail {
//                coverBgImageView.sd_setImageWithURL(NSURL(string: track!.thumbnailUrl!),
//                    placeholderImage: UIImage(named: "player_bg"), completed: {
//                        (image: UIImage!, error: NSError!, cacheType:SDImageCacheType, imageURL: NSURL!) -> Void in
//                        if (error != nil) {
//                            self.coverBgImageView.image = UIImage(named: "player_bg")
//                        }
//                })
//            } else {
//                coverBgImageView.image = UIImage(named: "player_bg")!
//            }
//        } else {
//            videoView.hidden = true
//            coverImageView.hidden = false
//            coverBgImageView.image = UIImage(named: "player_bg")
//            if track!.hasHqThumbnail {
//                coverImageView.sd_setImageWithURL(NSURL(string: track!.thumbnailUrl!),
//                    placeholderImage: UIImage(named: "default_cover_big"), completed: {
//                        (image: UIImage!, error: NSError!, cacheType:SDImageCacheType, imageURL: NSURL!) -> Void in
//                        if (error != nil) {
//                            self.coverImageView.image = UIImage(named: "default_cover_big")
//                        }
//                })
//            } else {
//                coverImageView.image = UIImage(named: "default_cover_big")!
//            }
//        }
//    }
    
    func updatePlayView() {
        switch DropbeatPlayer.defaultPlayer.playState {
        case .LOADING, .SWITCHING, .BUFFERING:
            playBtn.hidden = true
            pauseBtn.hidden = true
            loadingView.hidden = false
            loadingView.rotate360Degrees(0.7, completionDelegate: self)
        case .PAUSED, .STOPPED:
            playBtn.hidden = false
            pauseBtn.hidden = true
            loadingView.hidden = true
        case .PLAYING:
            playBtn.hidden = true
            pauseBtn.hidden = false
            loadingView.hidden = true
        }
    }
    
//    func updateShuffleView() {
//        if (prevShuffleBtnState == DropbeatPlayer.defaultPlayer.shuffleState) {
//            return
//        }
//        prevShuffleBtnState = DropbeatPlayer.defaultPlayer.shuffleState
//        if (DropbeatPlayer.defaultPlayer.shuffleState == ShuffleState.NOT_SHUFFLE) {
//            shuffleBtn.setImage(UIImage(named: "ic_shuffle_gray"), forState: UIControlState.Normal)
//        } else {
//            shuffleBtn.setImage(UIImage(named: "ic_shuffle"), forState: UIControlState.Normal)
//        }
//    }
//    
//    func updateRepeatView() {
//        if (prevRepeatBtnState != nil &&
//            prevRepeatBtnState == DropbeatPlayer.defaultPlayer.repeatState) {
//                return
//        }
//        prevRepeatBtnState = DropbeatPlayer.defaultPlayer.repeatState
//        switch(DropbeatPlayer.defaultPlayer.repeatState) {
//        case RepeatState.NOT_REPEAT:
//            let image:UIImage = UIImage(named: "ic_repeat_gray")!
//            repeatBtn.setImage(image, forState: UIControlState.Normal)
//            break
//        case RepeatState.REPEAT_ONE:
//            repeatBtn.setImage(UIImage(named: "ic_repeat_one"), forState: UIControlState.Normal)
//            break
//        case RepeatState.REPEAT_PLAYLIST:
//            repeatBtn.setImage(UIImage(named: "ic_repeat"), forState: UIControlState.Normal)
//            break
//        }
//    }
    
//    func updateStatusView() {
//        let defaultText = NSLocalizedString("CHOOSE TRACK", comment:"")
//        if (DropbeatPlayer.defaultPlayer.playState == PlayState.LOADING ||
//            DropbeatPlayer.defaultPlayer.playState == PlayState.SWITCHING) {
//                playerStatus.text = NSLocalizedString("LOADING", comment:"")
//                playerTitle.text = DropbeatPlayer.defaultPlayer.currentTrack?.title ?? defaultText
//        } else if (DropbeatPlayer.defaultPlayer.playState == PlayState.PAUSED) {
//            playerStatus.text = NSLocalizedString("PAUSED", comment:"")
//            playerTitle.text = DropbeatPlayer.defaultPlayer.currentTrack?.title ?? defaultText
//        } else if (DropbeatPlayer.defaultPlayer.playState == PlayState.PLAYING) {
//            playerStatus.text = NSLocalizedString("PLAYING", comment:"")
//            playerTitle.text = DropbeatPlayer.defaultPlayer.currentTrack?.title ?? defaultText
//        } else if (DropbeatPlayer.defaultPlayer.playState == PlayState.STOPPED) {
//            playerStatus.text = NSLocalizedString("READY", comment:"")
//            playerTitle.text = defaultText
//        } else if (DropbeatPlayer.defaultPlayer.playState == PlayState.BUFFERING) {
//            playerStatus.text = NSLocalizedString("BUFFERING", comment:"")
//            playerTitle.text = DropbeatPlayer.defaultPlayer.currentTrack?.title ?? defaultText
//        }
//    }
    
    func updateQualityView() {
        switch(DropbeatPlayer.defaultPlayer.qualityState) {
        case QualityState.LQ:
            let image:UIImage = UIImage(named: "ic_hq_off")!
            qualityBtn.setImage(image, forState: UIControlState.Normal)
            break
        case QualityState.HQ:
            let image:UIImage = UIImage(named: "ic_hq_on")!
            qualityBtn.setImage(image, forState: UIControlState.Normal)
            break
        }
    }
    
    func updateProgressView() {
        if (DropbeatPlayer.defaultPlayer.playState == PlayState.PLAYING && !isProgressUpdatable) {
            return
        }
        let total:Float = Float(DropbeatPlayer.defaultPlayer.correctDuration ?? 0)
        let curr:Float = Float(DropbeatPlayer.defaultPlayer.currentPlaybackTime ?? 0)
        if (total == 0) {
            progressSliderBar.enabled = false
        } else {
            if (progressSliderBar.enabled) {
                progressSliderBar.value = (curr * 100) / total
            }
            
            if (DropbeatPlayer.defaultPlayer.playState == PlayState.PLAYING) {
                progressSliderBar.enabled = true
            } else {
                progressSliderBar.enabled = false
            }
            progressTextView.text = getTimeFormatText(DropbeatPlayer.defaultPlayer.currentPlaybackTime ?? 0)
            totalTextView.text = getTimeFormatText(DropbeatPlayer.defaultPlayer.correctDuration ?? 0)
        }
    }
    
    func updateLikeBtn() {
        if DropbeatPlayer.defaultPlayer.currentTrack?.isLiked ?? false {
            likeBtn.setImage(UIImage(named:"ic_player_heart_fill_btn"),
                forState: UIControlState.Normal)
        } else {
            likeBtn.setImage(UIImage(named:"ic_player_heart_btn"),
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
    
    func stopProgressTimer() {
        if remoteProgressTimer != nil {
            remoteProgressTimer?.invalidate()
            remoteProgressTimer = nil
        }
    }
    
    func updateProgress () {
        let currentTrack :Track? = DropbeatPlayer.defaultPlayer.currentTrack
        if (currentTrack == nil) {
            return
        }
        if (audioPlayerControl.moviePlayer.duration == 0.0) {
            // Audio meta has not been loaded.
            return
        }
        
        // Youtube duration hack.
        if (currentTrack?.type == .YOUTUBE) {
            if (DropbeatPlayer.defaultPlayer.correctDuration == nil) {
                DropbeatPlayer.defaultPlayer.correctDuration = audioPlayerControl.moviePlayer.duration
            }
            
            if (audioPlayerControl.moviePlayer.duration != DropbeatPlayer.defaultPlayer.correctDuration) {
                // To find a end of the track that has corrected duration.
                // - This is hacky way to prevent repeatedly gain pause / play event from player
                // player gain repeatedly pasuse / play event after correntDuration
                if (audioPlayerControl.moviePlayer.currentPlaybackTime >= DropbeatPlayer.defaultPlayer.correctDuration!) {
                    if (DropbeatPlayer.defaultPlayer.repeatState == RepeatState.REPEAT_ONE) {
                        handleSeek(0)
                    } else {
                        self.stopProgressTimer()
                        if (audioPlayerControl.moviePlayer.playbackState != MPMoviePlaybackState.Stopped) {
                            self.forceStopPlayer = true
                            audioPlayerControl.moviePlayer.stop()
                        }
                    }
                    return
                }
            }
            
            if (DropbeatPlayer.defaultPlayer.correctDuration == -1.0) {
                // URL has no duration info.
                DropbeatPlayer.defaultPlayer.correctDuration = audioPlayerControl.moviePlayer.duration / 2.0
            } else {
                let buffer :Double = audioPlayerControl.moviePlayer.duration * 0.75
                if (buffer <= DropbeatPlayer.defaultPlayer.correctDuration) {
                    // Cannot sure if it's wrong. So, let's return back original value.
                    DropbeatPlayer.defaultPlayer.correctDuration = audioPlayerControl.moviePlayer.duration
                }
            }
        } else {
            DropbeatPlayer.defaultPlayer.correctDuration = audioPlayerControl.moviePlayer.duration
        }
        DropbeatPlayer.defaultPlayer.currentPlaybackTime = audioPlayerControl.moviePlayer.currentPlaybackTime
        
        // update playinginfo duration
        if (!self.playingInfoDisplayDuration) {
            self.updatePlayStateView(DropbeatPlayer.defaultPlayer.playState)
        }
        // Update custom progress
        updateProgressView()
    }
    
//    func MPMoviePlayerLoadStateDidChange (noti: NSNotification) {
//        if (audioPlayerControl.moviePlayer.loadState.rawValue & MPMovieLoadState.Playable.rawValue) != 0 {
//            print("load state = playable")
//        }
//        if (audioPlayerControl.moviePlayer.loadState.rawValue & MPMovieLoadState.PlaythroughOK.rawValue != 0) {
//            print("load state = playthroughOk")
//        }
//        if (audioPlayerControl.moviePlayer.loadState.rawValue & MPMovieLoadState().rawValue != 0) {
//            print("load state = allzeros")
//        }
//        if (audioPlayerControl.moviePlayer.loadState.rawValue & MPMovieLoadState.Stalled.rawValue != 0) {
//            print("load state = Stalled")
//        }
//        if (audioPlayerControl.moviePlayer.loadState.rawValue & MPMovieLoadState.Playable.rawValue != 0 &&
//            audioPlayerControl.moviePlayer.loadState.rawValue & MPMovieLoadState.Stalled.rawValue != 0) {
//                startBackgroundTask()
//                updatePlayState(PlayState.BUFFERING)
//                print("update state to buffering")
//                if bufferingTimer == nil {
//                    bufferingTimer = NSTimer.scheduledTimerWithTimeInterval(
//                        0.5, target: self, selector: Selector("checkBufferState"), userInfo: nil, repeats: true)
//                }
//                return
//        }
//        if (audioPlayerControl.moviePlayer.loadState.rawValue & MPMovieLoadState.Playable.rawValue != 0) {
//            if ((DropbeatPlayer.defaultPlayer.playState == PlayState.SWITCHING ||
//                DropbeatPlayer.defaultPlayer.playState == PlayState.PLAYING) &&
//                lastPlaybackBeforeSwitch != nil &&
//                lastPlaybackBeforeSwitch > 0) {
//                    audioPlayerControl.moviePlayer.currentPlaybackTime = lastPlaybackBeforeSwitch!
//                    lastPlaybackBeforeSwitch = nil
//            }
//            if bufferingTimer == nil {
//                bufferingTimer = NSTimer.scheduledTimerWithTimeInterval(
//                    0.5, target: self, selector: Selector("checkBufferState"), userInfo: nil, repeats: true)
//            }
//            return
//        }
//        
//        if (audioPlayerControl.moviePlayer.loadState.rawValue & MPMovieLoadState().rawValue != 0) {
//            // If youtube which has double duration length will be get here
//            // when it play over original duration (:1/2) length
//            if (DropbeatPlayer.defaultPlayer.currentTrack != nil &&
//                DropbeatPlayer.defaultPlayer.currentTrack!.type == .YOUTUBE &&
//                DropbeatPlayer.defaultPlayer.correctDuration != nil){
//                    if (audioPlayerControl.moviePlayer.currentPlaybackTime >= DropbeatPlayer.defaultPlayer.correctDuration! - 1) {
//                        if (DropbeatPlayer.defaultPlayer.repeatState == RepeatState.REPEAT_ONE) {
//                            handleSeek(0)
//                        } else if (audioPlayerControl.moviePlayer.playbackState != MPMoviePlaybackState.Stopped) {
//                            self.stopProgressTimer()
//
//                            if (audioPlayerControl.moviePlayer.playbackState != MPMoviePlaybackState.Stopped) {
//                                self.forceStopPlayer = true
//                                audioPlayerControl.moviePlayer.stop()
//                            }
//                        }
//                    }
//            }
//        }
//    }
    
    func checkBufferState() {
        if DropbeatPlayer.defaultPlayer.playState != PlayState.BUFFERING &&
            DropbeatPlayer.defaultPlayer.playState != PlayState.LOADING &&
            DropbeatPlayer.defaultPlayer.playState != PlayState.SWITCHING {
                print("invalidate buffering timer")
                bufferingTimer?.invalidate()
                bufferingTimer = nil
                return
        }
        let currTime = audioPlayerControl.moviePlayer.currentPlaybackTime
        let playableTime = audioPlayerControl.moviePlayer.playableDuration
        let duration = audioPlayerControl.moviePlayer.duration
        if duration == 0 {
            return
        }
        
        // Buffer should be more than 3sec
        if playableTime - currTime > 3 || playableTime >= duration {
            bufferingTimer?.invalidate()
            bufferingTimer = nil
            audioPlayerControl.moviePlayer.play()
            print("play audio from buffer timer")
        } else {
            print("curr buffering state  = \(playableTime - currTime)")
        }
    }
    
    func MPMoviePlayerPlaybackStateDidChange (noti: NSNotification) {
        if (audioPlayerControl.moviePlayer.playbackState == MPMoviePlaybackState.Playing) {
            print("changed! playing")
        } else if (audioPlayerControl.moviePlayer.playbackState == MPMoviePlaybackState.Stopped) {
            print("changed! stopped")
        } else if (audioPlayerControl.moviePlayer.playbackState == MPMoviePlaybackState.Paused) {
            print("changed! paused")
        } else if (audioPlayerControl.moviePlayer.playbackState == MPMoviePlaybackState.Interrupted) {
            print("changed! interrupted")
        } else if (audioPlayerControl.moviePlayer.playbackState == MPMoviePlaybackState.SeekingForward) {
            print("changed! seekingForward")
        } else if (audioPlayerControl.moviePlayer.playbackState == MPMoviePlaybackState.SeekingBackward) {
            print("changed! seekingBackward")
        }
        
        if (forceStopPlayer && (
            audioPlayerControl.moviePlayer.playbackState == MPMoviePlaybackState.Paused ||
                audioPlayerControl.moviePlayer.playbackState == MPMoviePlaybackState.Playing)) {
                    return
        }
        
        if (audioPlayerControl.moviePlayer.playbackState == MPMoviePlaybackState.Playing) {
            updatePlayState(PlayState.PLAYING)
            print("update state to playing")
            // Periodic timer for progress update.
            if remoteProgressTimer == nil {
                remoteProgressTimer = NSTimer.scheduledTimerWithTimeInterval(
                    0.5, target: self, selector: Selector("updateProgress"), userInfo: nil, repeats: true)
            }
        } else if (audioPlayerControl.moviePlayer.playbackState == MPMoviePlaybackState.Stopped) {
            self.stopProgressTimer()

        } else if (audioPlayerControl.moviePlayer.playbackState == MPMoviePlaybackState.Paused) {
            if ((audioPlayerControl.moviePlayer.loadState.rawValue & MPMovieLoadState.Playable.rawValue != 0 &&
                audioPlayerControl.moviePlayer.loadState.rawValue & MPMovieLoadState.Stalled.rawValue != 0) ||
                DropbeatPlayer.defaultPlayer.playState == PlayState.SWITCHING ||
                DropbeatPlayer.defaultPlayer.playState == PlayState.BUFFERING) {
                    // buffering
                    return
            }
            updatePlayState(PlayState.PAUSED)
            self.stopProgressTimer()

        } else if (audioPlayerControl.moviePlayer.playbackState == MPMoviePlaybackState.Interrupted) {
            shouldPlayMusic = false
            updatePlayState(PlayState.PAUSED)
            self.stopProgressTimer()

        } else if (audioPlayerControl.moviePlayer.playbackState == MPMoviePlaybackState.SeekingForward) {
            self.stopProgressTimer()

            updatePlayState(PlayState.BUFFERING)
            print("update state to buffering")
        } else if (audioPlayerControl.moviePlayer.playbackState == MPMoviePlaybackState.SeekingBackward) {
            self.stopProgressTimer()

            updatePlayState(PlayState.BUFFERING)
            print("update state to buffering")
        }
    }
    
    func handlePlayFailure() {
        print("handle play failure")
        
        if let track = DropbeatPlayer.defaultPlayer.currentTrack {
            let errMsg = NSLocalizedString("This track is not streamable", comment:"")
            ViewUtils.showToast(self, message: errMsg)
            track.postFailureLog()
        }
        
        let success :Bool = handleNext(shouldPlayMusic)
        if (!success) {
            handleStop()
        }
    }
    
    
    func MPMoviePlayerPlaybackDidFinish (noti: NSNotification) {
        if let userInfo = noti.userInfo,
            rawValue = userInfo[MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] as? NSNumber,
            finishReason = MPMovieFinishReason(rawValue: Int(rawValue))
            where finishReason == MPMovieFinishReason.PlaybackError
        {
//            if let error = userInfo[XCDMoviePlayerPlaybackDidFinishErrorUserInfoKey] as? NSError {
//                print(error)
//            }
            
            print(finishReason)
            self.handlePlayFailure()
            return
        }
        
        if (self.audioPlayerControl.moviePlayer.contentURL == nil) {
            return
        }
        
        print("fin!!!!")
        if let _ = DropbeatPlayer.defaultPlayer.playLog {
            self.resetPlayLog(nil)
        }
        let success :Bool = handleNext(shouldPlayMusic)
        if (!success) {
            handleStop()
        }
    }
    
    func playParam(track: Track, playlistId: String) -> Dictionary<String, AnyObject> {
        let params: Dictionary<String, AnyObject> = [
            "track": track,
            "playlistId": playlistId
        ]
        return params
    }
    
    func onLikeUpdated() {
        updateLikeBtn()
    }
    
    
    // MARK: Notification Handling
    
    func remotePause() {
        handlePause(true)
    }
    
    func handleUpdatePlay(noti: NSNotification) {
        print("make time label to 00:00")
        progressSliderBar.value = 0
        progressTextView.text = getTimeFormatText(0)
        totalTextView.text = getTimeFormatText(0)
    }
    
    func remotePlay(noti: NSNotification) {
        var params = noti.object as! Dictionary<String, AnyObject>
        let track = params["track"] as? Track
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
        let value = params["value"] as? Float ?? 0
        handleSeek(value)
    }
    
    func remoteNext() {
        handleNext(true)
    }
    
    func remotePrev() {
        handlePrev(true)
    }
    
    func qualityStateUpdated() {
        if (DropbeatPlayer.defaultPlayer.playState == PlayState.PAUSED ||
            DropbeatPlayer.defaultPlayer.playState == PlayState.SWITCHING ||
            DropbeatPlayer.defaultPlayer.playState == PlayState.STOPPED ||
            DropbeatPlayer.defaultPlayer.currentTrack == nil) {
                updateQualityView()
                return
        }
        startBackgroundTask()
        switchPlayerWithQuality(DropbeatPlayer.defaultPlayer.currentTrack!, qualityState: DropbeatPlayer.defaultPlayer.qualityState)
    }
    
    func networkStatusUpdated() {
        if (DropbeatPlayer.defaultPlayer.playState == PlayState.STOPPED) {
            updateQualityView()
        }
    }
    
    // MARK: playback log
    
    func startPlaylog(track: Track) {
        if let dropbeatTrack = track as? DropbeatTrack{
            DropbeatPlayer.defaultPlayer.playLog = PlayLog(track: dropbeatTrack)
        } else {
            DropbeatPlayer.defaultPlayer.playLog = nil
        }
        
        // Log to us
        Requests.logPlay(track)
    }
    
    func resetPlayLog(currentTime: Int?) {
        DropbeatPlayer.defaultPlayer.playLog!.finished(currentTime)
        DropbeatPlayer.defaultPlayer.playLog = nil
    }
    
    func AVPlayerItemDidPlayToEndTime(noti: NSNotification) {
        if DropbeatPlayer.defaultPlayer.repeatState == RepeatState.REPEAT_ONE {
            print("looping. play again.")
            if let _ = DropbeatPlayer.defaultPlayer.playLog {
                self.resetPlayLog(nil)
            }
            self.startPlaylog(DropbeatPlayer.defaultPlayer.currentTrack!)
        }
    }
    
    func handlePlay(track: Track?, playlistId: String?, section:String?, force:Bool) {
        print("handle play")
        
        // Fetch stream urls.
        if track == nil {
            return
        }

        self.startPlaylog(track!)

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
        
        if DropbeatPlayer.defaultPlayer.currentTrack != nil && DropbeatPlayer.defaultPlayer.currentTrack!.id == track!.id {
            if DropbeatPlayer.defaultPlayer.playState == PlayState.LOADING ||
                DropbeatPlayer.defaultPlayer.playState == PlayState.BUFFERING ||
                DropbeatPlayer.defaultPlayer.playState == PlayState.SWITCHING {
                    return
            }
            if audioPlayerControl.moviePlayer.playbackState == MPMoviePlaybackState.Paused ||
                audioPlayerControl.moviePlayer.playbackState == MPMoviePlaybackState.Interrupted {
                    // Resume
//                    shouldPlayMusic = force
                    if prevQualityState != DropbeatPlayer.defaultPlayer.qualityState {
                        startBackgroundTask()
                        switchPlayerWithQuality(DropbeatPlayer.defaultPlayer.currentTrack!, qualityState: DropbeatPlayer.defaultPlayer.qualityState)
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
        
        DropbeatPlayer.defaultPlayer.currentTrack = track
        
        if playlistId != nil {
            let playlist :Playlist? = DropbeatPlayer.defaultPlayer.getPlaylist(playlistId)
            if playlist == nil {
                DropbeatPlayer.defaultPlayer.currentPlaylistId = nil
                DropbeatPlayer.defaultPlayer.currentTrackIdx = -1
            } else {
                DropbeatPlayer.defaultPlayer.currentPlaylistId = playlistId
                DropbeatPlayer.defaultPlayer.currentTrackIdx = -1
                for (idx, t): (Int, Track) in playlist!.tracks.enumerate() {
                    if t.id == track!.id {
                        DropbeatPlayer.defaultPlayer.currentTrackIdx = idx
                        break
                    }
                }
            }
        } else {
            DropbeatPlayer.defaultPlayer.currentPlaylistId = nil
            DropbeatPlayer.defaultPlayer.currentTrackIdx = -1
        }
        
        // Init correct duration.
        DropbeatPlayer.defaultPlayer.correctDuration = nil
        
        // Indicate loading status.
        updatePlayState(PlayState.LOADING)
        updateNextPrevBtn()
        updateLikeBtn()
        
        let playSection = section ?? "uknown"
        
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
        switchPlayerWithQuality(track!, qualityState: DropbeatPlayer.defaultPlayer.qualityState, isInitial: true)
    }
    
    func switchPlayerWithQuality(track:Track, qualityState: QualityState, isInitial: Bool = false) {
        
        if !isInitial {
            lastPlaybackBeforeSwitch = audioPlayerControl.moviePlayer.currentPlaybackTime
        } else {
            lastPlaybackBeforeSwitch = nil
        }
        DropbeatPlayer.defaultPlayer.correctDuration = nil
        
        audioPlayerControl.moviePlayer.contentURL = nil
        audioPlayerControl.videoIdentifier = nil
        shouldPlayMusic = true
        audioPlayerControl.moviePlayer.stop()
        
        if (isInitial) {
            DropbeatPlayer.defaultPlayer.currentPlaybackTime = 0
            DropbeatPlayer.defaultPlayer.correctDuration = nil
        } else {
            updatePlayState(PlayState.SWITCHING)
        }
        
        prevQualityState = DropbeatPlayer.defaultPlayer.qualityState
        var qualities = [AnyObject]()
        if (DropbeatPlayer.defaultPlayer.qualityState == QualityState.LQ) {
            qualities.append(XCDYouTubeVideoQuality.Small240.rawValue)
            qualities.append(XCDYouTubeVideoQuality.Medium360.rawValue)
        } else {
            qualities.append(XCDYouTubeVideoQuality.HD720.rawValue)
        }
        audioPlayerControl.preferredVideoQualities = qualities
        
//        if (track.type == .YOUTUBE) {
//            audioPlayerControl.videoIdentifier = track.id
//        } else {
//            if track.type != .UNKNOWN {
//                audioPlayerControl.moviePlayer.contentURL = NSURL(string:track.streamUrl)
//                audioPlayerControl.moviePlayer
//                audioPlayerControl.videoIdentifier = nil
//            } else {
//                ViewUtils.showNoticeAlert(self, title: NSLocalizedString("Failed to play", comment:""),
//                    message: NSLocalizedString("Unsupported track type", comment:""))
//                // XXX: Cannot play.
//                handleStop()
//                return
//            }
//        }
        
        DropbeatPlayer.defaultPlayer.play(track)
        
        if (DropbeatPlayer.defaultPlayer.repeatState == RepeatState.REPEAT_ONE) {
            audioPlayerControl.moviePlayer.repeatMode = MPMovieRepeatMode.One
        } else {
            audioPlayerControl.moviePlayer.repeatMode = MPMovieRepeatMode.None
        }
        
        // NOTE:
        // Not start play here
        // audioPlayerControl.moviePlayer.play will be called on MPMoviePlayerLoadStateDidChange func
        // receive Playable or PlaythroughOK
        // see http://macromeez.tumblr.com/post/91330737652/continuous-background-media-playback-on-ios-using
        
        print("prepare to play")
        audioPlayerControl.moviePlayer.prepareToPlay()
//        audioPlayerControl.moviePlayer.scalingMode = .AspectFill
//        audioPlayerControl.moviePlayer.controlStyle = .Fullscreen
        audioPlayerControl.moviePlayer.view.userInteractionEnabled = false
        updateCoverView()
    }
    
    var playingStateImageOperation:SDWebImageOperation?
    
    func updatePlayStateView(playingState:PlayState) {
        let track: Track? = DropbeatPlayer.defaultPlayer.currentTrack
        let playingInfoCenter:AnyClass! = NSClassFromString("MPNowPlayingInfoCenter")
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
    
    func updatePlayingInfoCenter(playingState:PlayState, image:UIImage) {
        let track: Track? = DropbeatPlayer.defaultPlayer.currentTrack
        if track == nil {
            return
        }
        
        var trackInfo = [String:AnyObject]()
        let albumArt = MPMediaItemArtwork(image: image)
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
        }
        trackInfo[MPMediaItemPropertyArtist] = stateText
        trackInfo[MPMediaItemPropertyArtwork] = albumArt
        
        let duration = DropbeatPlayer.defaultPlayer.correctDuration ?? 0
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
        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = trackInfo
    }
    
    func activateAudioSession() {
        // Init audioSession
        let sharedInstance:AVAudioSession = AVAudioSession.sharedInstance()
        do {
            try sharedInstance.setCategory(AVAudioSessionCategoryPlayback)
        } catch let audioSessionError as NSError {
            print("Audio session error \(audioSessionError) \(audioSessionError.userInfo)")
        } catch _ {
            print("unknown error from PlayViewController.activateAudioSession()")
        }
        
        do {
            try sharedInstance.setActive(true)
        } catch _ {
        }
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        startBackgroundTask()
    }
    
    func deactivateAudioSession() {
        // Init audioSession
        let sharedInstance:AVAudioSession = AVAudioSession.sharedInstance()
        do {
            try sharedInstance.setActive(false)
        } catch _ {
        }
        UIApplication.sharedApplication().endReceivingRemoteControlEvents()
        stopBackgroundTask()
    }
    
    func startBackgroundTask() {
        // register background task
        let sharedApplication = UIApplication.sharedApplication()
        let prevBgTaskId = bgTaskId
        bgTaskId = sharedApplication.beginBackgroundTaskWithExpirationHandler({ () -> Void in
            sharedApplication.endBackgroundTask(self.bgTaskId)
            self.bgTaskId = UIBackgroundTaskInvalid
            print("expired background task")
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