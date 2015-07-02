//
//  CenterViewController.swift
//  labs
//
//  Created by vulpes on 2015. 5. 15..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit
import MediaPlayer
import AVFoundation

class CenterViewController: UIViewController {
    
    @IBOutlet weak var loadingView: UIImageView!
    @IBOutlet weak var progressBar: UISlider!
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var playerTitle: UILabel!
    @IBOutlet weak var playerStatus: UILabel!
    
    @IBOutlet weak var playlistBtn: UIButton!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var pauseBtn: UIButton!
    
    var audioPlayerControl: XCDYouTubeVideoPlayerViewController = XCDYouTubeVideoPlayerViewController()
    
    var remoteProgressTimer: NSTimer?
    var isProgressUpdatable = true
    var bgTaskId:UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    var removedId:UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    var signinVC:SigninViewController?
    var playlistVC:PlaylistViewController?
    var hookingBackground: Bool = false
    
    // Used only for video playback recovery.
    var userPaused: Bool = false
    var prevResolveReq:Request? = nil
    var forceStopPlayer = false
    var playingInfoDisplayDuration = false
    
    static var observerAttached: Bool = false
    
    private var activeViewController: UIViewController? {
        didSet {
            removeInactiveViewController(oldValue)
            updateActiveViewController()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.signinVC = nil
        self.playlistVC = nil
        
        if (CenterViewController.observerAttached == false) {
            CenterViewController.observerAttached = true
            
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
                self, selector: "handlePrev", name: NotifyKey.playerPrev, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(
                self, selector: "handlePause", name: NotifyKey.playerPause, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(
                self, selector: "handleNext", name: NotifyKey.playerNext, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(
                self, selector: "remoteSeek:", name: NotifyKey.playerSeek, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(
                self, selector: "repeatStateUpdated", name: NotifyKey.updateRepeatState, object: nil)
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
        
        progressBar.continuous = false
        
    }
    
    func backgroundHook () {
        if (PlayerContext.currentTrack != nil) {
            // Check whether it is video and stopped when it entered into background.
            if (hookingBackground) {
                return
            }
            if (PlayerContext.currentTrack!.type == "youtube" &&
                    PlayerContext.playState == PlayState.PAUSED && !userPaused) {
                hookingBackground = true
                
                startBackgroundTask()
                triggerBackgroundPlay(100)
            }
        }
    }
    
    func appWillEnterForeground () {
        updatePlayerViews()
    }
    
    func triggerBackgroundPlay(retry:Int) {
        var popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.1 * Double(NSEC_PER_SEC)))
        dispatch_after(popTime, dispatch_get_main_queue()) {
            if (self.userPaused || PlayerContext.playState != PlayState.PAUSED) {
                self.hookingBackground = false
                return
            }
            if (PlayerContext.playState == PlayState.PAUSED) {
                self.handlePlay(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId)
                self.triggerBackgroundPlay(retry - 1)
            }
        }
    }
    
    func updatePlayerViews() {
        updatePlayView()
        updateStatusView()
        updateProgressView()
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
    
    override func animationDidStop(anim: CAAnimation!, finished flag: Bool) {
        if (flag && (PlayerContext.playState == PlayState.LOADING ||
                PlayerContext.playState == PlayState.SWITCHING ||
                PlayerContext.playState == PlayState.BUFFERING)) {
            loadingView.rotate360Degrees(duration: 0.7, completionDelegate: self)
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
        }
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
        playlistPlayerUpdate()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        updatePlayerViews()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
//        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        becomeFirstResponder()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
//        UIApplication.sharedApplication().endReceivingRemoteControlEvents()
        resignFirstResponder()
    }
    
    func sender() {}
    
    func playlistPlayerUpdate () {
        NSNotificationCenter.defaultCenter().postNotificationName(
            NotifyKey.updatePlaylistView, object: nil)
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
            if (PlayerContext.playState == PlayState.SWITCHING &&
                    PlayerContext.currentPlaybackTime != nil &&
                    PlayerContext.currentPlaybackTime > 0) {
                audioPlayerControl.moviePlayer.currentPlaybackTime = PlayerContext.currentPlaybackTime!
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
            println("playing URL : \(audioPlayerControl.moviePlayer.contentURL)")
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
//            if (!hookingBackground && PlayerContext.currentTrack!.type == "youtube" && userPaused == false) {
//                startBackgroundTask()
//                triggerBackgroundPlay(100)
//            }
        } else if (audioPlayerControl.moviePlayer.playbackState == MPMoviePlaybackState.Interrupted) {

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
                println("Playback failed with error description: \(reason!.description)")
                ViewUtils.showNoticeAlert(self.getCurrentVisibleViewController(), title: "Failed to play",
                    message: "Caused by undefined exception (\(reason!.domain), \(reason!.code))")
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
                    var errMsg = "Caused by undefined exception "
                    if (err != nil) {
                        println("Playback failed with error description: \(err!.description)")
                        errMsg += "\(err!.domain):\(err!.code)"
                    }
                    ViewUtils.showNoticeAlert(self.getCurrentVisibleViewController(), title: "Failed to play",
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
        var success :Bool = handleNext()
        if (!success) {
            handleStop()
        }
    }
    
    func MPMoviePlayerTimedMetadataUpdated(noti: NSNotification) {
        println("time meta updated")
    }
    
    func showSigninView() {
        
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        self.signinVC = mainStoryboard.instantiateViewControllerWithIdentifier("SigninViewController") as! SigninViewController
        
        self.signinVC!.modalTransitionStyle = UIModalTransitionStyle.CoverVertical
        presentViewController(self.signinVC!, animated: true, completion: nil)
    }
    
    func showPlaylistView() {
        
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        self.playlistVC = mainStoryboard.instantiateViewControllerWithIdentifier("PlaylistViewController") as! PlaylistViewController
        
        self.playlistVC!.modalTransitionStyle = UIModalTransitionStyle.CoverVertical
        presentViewController(self.playlistVC!, animated: true, completion: nil)
    }
    
    @IBAction func onPlaylistBtnClicked(sender: AnyObject) {
        showPlaylistView()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func playParam(track: Track, playlistId: String) -> Dictionary<String, AnyObject> {
        var params: Dictionary<String, AnyObject> = [
            "track": track,
            "playlistId": playlistId
        ]
        return params
    }
    
    @IBAction func menuBtnClicked(sender: AnyObject) {
        var appDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.centerContainer!.toggleDrawerSide(MMDrawerSide.Left, animated: true, completion: nil)
    }
    
    @IBAction func playBtnClicked(sender: UIButton?) {
        println("play!")
        if (PlayerContext.currentTrack != nil) {
            var playlistId :String? = PlayerContext.currentPlaylistId
            handlePlay(PlayerContext.currentTrack!, playlistId: playlistId)
        }
    }
    
    @IBAction func pauseBtnClicked(sender: UIButton?) {
        println("pause!")
        handlePause()
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
        var playlistId = params["playlistId"] as! String
        handlePlay(track, playlistId: playlistId)
    }
    
    func handlePlay(track: Track?, playlistId: String?) {
        println("handle play")
        // Fetch stream urls.
        if track == nil {
            return
        }
        
        forceStopPlayer = false
        userPaused = false
        
        if (PlayerContext.currentTrack == nil ||
            PlayerContext.currentTrack!.id != track!.id ||
            PlayerContext.currentPlaylistId != playlistId) { 
            
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
            if audioPlayerControl.moviePlayer.playbackState == MPMoviePlaybackState.Paused {
                // Resume
                updatePlayStateView(PlayState.PLAYING)
                playAudioPlayer()
                return
            } else if audioPlayerControl.moviePlayer.playbackState == MPMoviePlaybackState.Playing {
                // Same music is clicked when it is being played.
                return
            }
            // In case of repeating one track.
        }
        
        PlayerContext.currentTrack = track
        PlayerContext.currentPlaylistId = playlistId
        PlayerContext.currentTrackIdx = -1
        var closureTrack :Track? = track
        
        if (PlayerContext.currentPlaylistId != "-1") {
            var playlist :Playlist? = PlayerContext.getPlaylist(playlistId)!
            for (idx: Int, t: Track) in enumerate(playlist!.tracks) {
                if t.id == track!.id {
                    PlayerContext.currentTrackIdx = idx
                    break
                }
            }
        }
        
        // Init correct duration.
        PlayerContext.correctDuration = nil
        
        // Indicate loading status.
        updatePlayState(PlayState.LOADING)
        
        self.activateAudioSession()
        switchPlayerWithQuality(track!, qualityState: PlayerContext.qualityState, isInitial: true)
    }
    
    func switchPlayerWithQuality(track:Track, qualityState: Int, isInitial: Bool = false) {
        PlayerContext.correctDuration = nil
       
        audioPlayerControl.moviePlayer.contentURL = nil
        audioPlayerControl.videoIdentifier = nil
        userPaused = false
        audioPlayerControl.moviePlayer.stop()

        if (isInitial) {
            PlayerContext.currentPlaybackTime = 0
            PlayerContext.correctDuration = nil
        } else {
            updatePlayState(PlayState.SWITCHING)
            userPaused = false
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
                ViewUtils.showNoticeAlert(getCurrentVisibleViewController(), title: "Failed to play",
                    message: "Unsupported track type")
                // XXX: Cannot play.
                handleStop()
                return
            }
            audioPlayerControl.moviePlayer.contentURL = NSURL(string:url!)
            audioPlayerControl.videoIdentifier = nil
        }
        
        audioPlayerControl.moviePlayer.controlStyle = MPMovieControlStyle.Embedded
        audioPlayerControl.moviePlayer.view.hidden = true
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
    }
    
    func handlePause() {
        userPaused = true
        if (audioPlayerControl.moviePlayer.playbackState == MPMoviePlaybackState.Playing) {
            pauseAudioPlayer()
            updatePlayStateView(PlayState.PAUSED)
        }
    }
    
    func handleNext() -> Bool{
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
        
        handlePlay(track, playlistId: PlayerContext.currentPlaylistId)
        return true;
    }
    
    func handlePrev() -> Bool {
        println("handlePrev")
        if remoteProgressTimer != nil {
            remoteProgressTimer?.invalidate()
            remoteProgressTimer = nil
        }
        
        var track: Track? = PlayerContext.pickPrevTrack()
        if (track == nil) {
            return false;
        }
        
        handlePlay(track, playlistId: PlayerContext.currentPlaylistId)
        return true;
    }
    
    func handleStop() {
        PlayerContext.currentPlaylistId = nil
        PlayerContext.currentTrack = nil
        PlayerContext.currentTrackIdx = -1
        PlayerContext.correctDuration = nil
        audioPlayerControl.videoIdentifier = nil
        audioPlayerControl.moviePlayer.contentURL = nil
        if (audioPlayerControl.moviePlayer.playbackState != MPMoviePlaybackState.Stopped) {
            audioPlayerControl.moviePlayer.stop()
        }
        updatePlayStateView(PlayState.STOPPED)
        deactivateAudioSession()
    }
    
    func remoteSeek(noti: NSNotification) {
        var params = noti.object as! Dictionary<String, AnyObject>
        var value = params["value"] as? Float ?? 0
        handleSeek(value)
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
    
    func repeatStateUpdated() {
        if PlayerContext.repeatState == RepeatState.REPEAT_ONE {
            audioPlayerControl.moviePlayer.repeatMode = MPMovieRepeatMode.One
        } else {
            audioPlayerControl.moviePlayer.repeatMode = MPMovieRepeatMode.None
        }
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
    }
    
    func playAudioPlayer() {
        println("playAudio")
        audioPlayerControl.moviePlayer.play()
    }
    
    func pauseAudioPlayer() {
        audioPlayerControl.moviePlayer.pause()
    }
    
    func updatePlayState(playingState: Int) {
        PlayerContext.playState = playingState
        updatePlayStateView(playingState)
    }
    
    func updatePlayStateView(playingState:Int) {
        var track: Track? = PlayerContext.currentTrack
        var playingInfoCenter:AnyClass! = NSClassFromString("MPNowPlayingInfoCenter")
        if (playingInfoCenter != nil && track != nil) {
            var trackInfo:NSMutableDictionary = NSMutableDictionary()
            var albumArt:MPMediaItemArtwork = MPMediaItemArtwork(image: UIImage(named: "logo_512x512.png"))
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
        updatePlayerViews()
        playlistPlayerUpdate()
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
    
    func onMenuSelected(menuType: MenuType) {
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        
        switch(menuType) {
        case .FEED:
            activeViewController = mainStoryboard
                .instantiateViewControllerWithIdentifier("FeedNavigationController")
                as? UIViewController
            break
        case .SEARCH:
            activeViewController = mainStoryboard
                .instantiateViewControllerWithIdentifier("SearchNavigationController")
                as? UIViewController
            break
        case .SETTINGS:
            activeViewController = mainStoryboard
                .instantiateViewControllerWithIdentifier("SettingsNavigationController")
                as? UIViewController
            break
        default:
            break
        }
    }
    
    func getCurrentVisibleViewController()-> UIViewController {
        var vc:UIViewController = self
        if (self.playlistVC != nil && self.playlistVC!.isVisible) {
            vc = self.playlistVC!
        }
        if (self.signinVC != nil && self.signinVC!.isVisible) {
            vc = self.signinVC!
        }
        return vc
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
            
            activeVC.view.frame = container.bounds
            container.addSubview(activeVC.view)
            
            // call before adding child view controller's view as subview
            activeVC.didMoveToParentViewController(self)
        }
    }
    
}
