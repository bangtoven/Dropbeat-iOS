//
//  CenterViewController.swift
//  labs
//
//  Created by vulpes on 2015. 5. 15..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit
import MMDrawerController
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
    
    var audioPlayer: MPMoviePlayerController = MPMoviePlayerController()
    
    var remoteProgressTimer: NSTimer?
    var isProgressUpdatable = true
    var backgroundTaskId:UIBackgroundTaskIdentifier?
    var isBackgroundTaskSuppored:Bool = {
        var support = false
        let device = UIDevice.currentDevice()
        if (device.respondsToSelector("isMultitaskingSupported")) {
            support = device.multitaskingSupported
        }
        return support
    }()
    
    var hookingBackground: Bool = false
    // Used only for video playback recovery.
    var lastPlaybackTime: Double = 0.0
    var userPaused: Bool = false
    
    static var observerAttached: Bool = false
    
    private var activeViewController: UIViewController? {
        didSet {
            removeInactiveViewController(oldValue)
            updateActiveViewController()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Init audioSession
        var sharedInstance:AVAudioSession = AVAudioSession.sharedInstance()
        var audioSessionError:NSError?
        if (!sharedInstance.setCategory(AVAudioSessionCategoryPlayback, error: &audioSessionError)) {
            NSLog("Audio session error \(audioSessionError) \(audioSessionError?.userInfo)")
        }
        sharedInstance.setActive(true, error: nil)
        
        if (CenterViewController.observerAttached == false) {
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
            
            
            // Observe internal player.
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "MPMoviePlayerContentPreloadDidFinishNotification:", name: "MPMoviePlayerContentPreloadDidFinishNotification", object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "MPMoviePlayerPlaybackStateDidChange:", name: "MPMoviePlayerPlaybackStateDidChangeNotification", object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "MPMoviePlayerPlaybackDidFinish:", name: "MPMoviePlayerPlaybackDidFinishNotification", object: nil)
            
            // For video background playback
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "backgroundHook", name: UIApplicationDidEnterBackgroundNotification, object: nil)
            
            CenterViewController.observerAttached = true
        }
        
        progressBar.continuous = false
        updatePlayerViews()
        
    }
    
    func backgroundHook () {
        if (PlayerContext.currentTrack != nil && PlayerContext.currentStreamCandidate != nil) {
            // Check whether it is video and stopped when it entered into background.
            if (PlayerContext.currentTrack!.type == "youtube" && PlayerContext.currentStreamCandidate?.type == "mp4" && PlayerContext.playState == PlayState.PAUSED && userPaused == false) {
                hookingBackground = true
                lastPlaybackTime = audioPlayer.currentPlaybackTime
                handlePlay(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId)
            }
        }
    }
    
    func updatePlayerViews() {
        updatePlayView()
        updateStatusView()
        updateProgressView()
    }
    
    func updatePlayView() {
        if (PlayerContext.playState == PlayState.LOADING) {
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
        if (flag && PlayerContext.playState == PlayState.LOADING) {
            loadingView.rotate360Degrees(duration: 1.0, completionDelegate: self)
        }
    }
    
    func updateStatusView() {
        let defaultText = "CHOOSE TRACK"
        if (PlayerContext.playState == PlayState.LOADING) {
            playerStatus.text = "LOADING"
            playerTitle.text = PlayerContext.currentTrack?.title ?? defaultText
        } else if (PlayerContext.playState == PlayState.PAUSED) {
            playerStatus.text = "PAUSED"
            playerTitle.text = PlayerContext.currentTrack?.title ?? defaultText
        } else if (PlayerContext.playState == PlayState.PLAYING) {
            playerStatus.text = "PLAYING"
            playerTitle.text = PlayerContext.currentTrack?.title ?? defaultText
        } else if (PlayerContext.playState == PlayState.STOPPED) {
            playerStatus.text = "STOPPED"
            playerTitle.text = defaultText
        }
    }
    
    func updateProgressView() {
        if (!isProgressUpdatable) {
            return
        }
        var total:Float = Float(PlayerContext.correctDuration ?? 0)
        var curr:Float = Float(PlayerContext.currentPlaybackTime ?? 0)
        if (total == 0) {
            progressBar.value = 0
            progressBar.enabled = false
        } else {
            progressBar.value = (curr * 100) / total
            if (PlayerContext.playState == PlayState.PLAYING) {
                progressBar.enabled = true
            } else {
                progressBar.enabled = false
            }
        }
    }
    
    func updateProgress () {
        var currentTrack :Track? = PlayerContext.currentTrack
        if (currentTrack != nil) {
            if (audioPlayer.duration == 0.0) {
                // Audio meta has not been loaded.
                return
            }
            
            if (hookingBackground && lastPlaybackTime != audioPlayer.currentPlaybackTime) {
                // Video starts playing again!
                hookingBackground = false
                lastPlaybackTime = 0.0
                println("playing again")
            }
            
            // Youtube duration hack.
            if (currentTrack?.type == "youtube") {
                if (PlayerContext.correctDuration == nil) {
                    PlayerContext.correctDuration = audioPlayer.duration
                }
                
                if (audioPlayer.duration != PlayerContext.correctDuration) {
                    // To find a end of the track that has corrected duration.
                    if (audioPlayer.currentPlaybackTime > PlayerContext.correctDuration) {
                        PlayerContext.correctDuration = nil
                        PlayerContext.currentPlaybackTime = nil
                        audioPlayer.stop()
                        return
                    }
                }
                
                if (PlayerContext.correctDuration == -1.0) {
                    // URL has no duration info.
                    PlayerContext.correctDuration = audioPlayer.duration / 2.0
                } else {
                    var buffer :Double = audioPlayer.duration * 0.75
                    if (buffer <= PlayerContext.correctDuration) {
                        // Cannot sure if it's wrong. So, let's return back original value.
                        PlayerContext.correctDuration = audioPlayer.duration
                    }
                }
            } else {
                PlayerContext.correctDuration = audioPlayer.duration
            }
            PlayerContext.currentPlaybackTime = audioPlayer.currentPlaybackTime
            
            // TODO: This method isn't necessarily called periodically.
            // Update remote control progress
            updatePlayingInfo(currentTrack!)
            
            // Update custom progress
            updateProgressView()
            playlistPlayerUpdate()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        becomeFirstResponder()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.sharedApplication().endReceivingRemoteControlEvents()
        resignFirstResponder()
    }
    
    func sender() {}
    
    func playlistPlayerUpdate () {
        NSNotificationCenter.defaultCenter().postNotificationName(
            NotifyKey.updatePlaylistView, object: nil)
    }
    
    func MPMoviePlayerPlaybackStateDidChange (noti: NSNotification) {
        println("changed!")
        println(audioPlayer.playbackState)
        if (audioPlayer.playbackState == MPMoviePlaybackState.Playing) {
            
            // Release background task
            if (self.backgroundTaskId != nil && self.isBackgroundTaskSuppored) {
                UIApplication.sharedApplication().endBackgroundTask(self.backgroundTaskId!)
                self.backgroundTaskId = nil
            }
            
            PlayerContext.playState = PlayState.PLAYING
            updatePlayerViews()
            // Periodic timer for progress update.
            if remoteProgressTimer == nil {
                remoteProgressTimer = NSTimer.scheduledTimerWithTimeInterval(
                    1.0, target: self, selector: Selector("updateProgress"), userInfo: nil, repeats: true)
            }
        } else if (audioPlayer.playbackState == MPMoviePlaybackState.Stopped) {
            
            // Release background task
            if (self.backgroundTaskId != nil && self.isBackgroundTaskSuppored) {
                UIApplication.sharedApplication().endBackgroundTask(self.backgroundTaskId!)
                self.backgroundTaskId = nil
            }
            
            PlayerContext.playState = PlayState.STOPPED
            updatePlayerViews()
            
            if (PlayerContext.currentTrack != nil) {
                updatePlayingInfo(PlayerContext.currentTrack!, rate: 0.0)
            }
            if remoteProgressTimer != nil {
                remoteProgressTimer?.invalidate()
                remoteProgressTimer = nil
            }
        } else if (audioPlayer.playbackState == MPMoviePlaybackState.Paused) {
            PlayerContext.playState = PlayState.PAUSED
            updatePlayerViews()
            
            updatePlayingInfo(PlayerContext.currentTrack!, rate: 0.0)
            if remoteProgressTimer != nil {
                remoteProgressTimer?.invalidate()
                remoteProgressTimer = nil
            }
            
            // Against background playback stopping.
            // We are checking extension here to minimize a number of excepional cases.
            if (hookingBackground && PlayerContext.currentStreamCandidate?.type == "mp4") {
                handlePlay(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId)
            }
        } else if (audioPlayer.playbackState == MPMoviePlaybackState.Interrupted) {
            
        } else if (audioPlayer.playbackState == MPMoviePlaybackState.SeekingForward) {
            
        } else if (audioPlayer.playbackState == MPMoviePlaybackState.SeekingBackward) {
            
        }
        playlistPlayerUpdate()
    }
    
    func MPMoviePlayerContentPreloadDidFinishNotification (noti:NSNotification) {
        var userInfo = noti.userInfo as? [String:AnyObject]
        if (userInfo != nil) {
            var reason:NSError? = userInfo!["error"] as? NSError
            if (reason != nil) {
                println("playback failed with error description: \(reason!.description)")
                
                // Release background task
                if (self.backgroundTaskId != nil && isBackgroundTaskSuppored) {
                    UIApplication.sharedApplication().endBackgroundTask(self.backgroundTaskId!)
                    self.backgroundTaskId = nil
                }
                var success :Bool = handleNext()
                if (!success) {
                    handleStop()
                }
            }
        }
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
                    if (err != nil) {
                        println("playback failed with error description: \(err!.description)")
                    }
                    
                    // Release background task
                    if (self.backgroundTaskId != nil && isBackgroundTaskSuppored) {
                        UIApplication.sharedApplication().endBackgroundTask(self.backgroundTaskId!)
                        self.backgroundTaskId = nil
                    }
                }
            }
        }
        
        println("fin!!!!")
        var success :Bool = handleNext()
        if (!success) {
            handleStop()
        }
    }
    
    func showSigninView() {
        
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        var signinVC = mainStoryboard.instantiateViewControllerWithIdentifier("SigninViewController") as! SigninViewController
        
        signinVC.modalTransitionStyle = UIModalTransitionStyle.CoverVertical
        presentViewController(signinVC, animated: true, completion: nil)
    }
    
    func showPlaylistView() {
        
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        var playlistVC = mainStoryboard.instantiateViewControllerWithIdentifier("PlaylistViewController") as! PlaylistViewController
        
        playlistVC.modalTransitionStyle = UIModalTransitionStyle.CoverVertical
        presentViewController(playlistVC, animated: true, completion: nil)
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
            if audioPlayer.playbackState == MPMoviePlaybackState.Paused {
                // Resume
                println("resume!!")
                playAudioPlayer()
                return
            } else if audioPlayer.playbackState == MPMoviePlaybackState.Playing {
                // Same music is clicked when it is being played.
                return
            }
            // In case of repeating one track.
        }
        
        println(track!.title)
        if audioPlayer.playbackState == MPMoviePlaybackState.Playing {
            // Pause previous track.
            // We do not use `stop` here because calling `stop` will trigger MPMoviePlaybackDidFinish.
            audioPlayer.pause()
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
        
        if (PlayerContext.playState == PlayState.PLAYING) {
            audioPlayer.stop()
        }
        
        // Indicate loading status.
        PlayerContext.playState = PlayState.LOADING
        updatePlayerViews()
        playlistPlayerUpdate()
        
        // Init correct duration.
        PlayerContext.correctDuration = nil
        
        initPlayingInfo(track!.title)
        
        // register background task
        var app = UIApplication.sharedApplication()
        if (self.backgroundTaskId != nil && self.isBackgroundTaskSuppored) {
            app.endBackgroundTask(self.backgroundTaskId!)
            self.backgroundTaskId = nil
        }
        if (self.isBackgroundTaskSuppored) {
            self.backgroundTaskId = app.beginBackgroundTaskWithExpirationHandler({ () -> Void in
                self.backgroundTaskId = nil
            })
        }
        
        resolve(track!.id, track!.type, { (req, resp, json, err) in
            if err == nil {
                println("FIN RESOLVE")
                if (closureTrack != nil && closureTrack!.id != PlayerContext.currentTrack?.id) {
                    return
                }
                
                var streamSources :[StreamSource] = getStreamUrls(json!)
                
                // Do we need multiple candidates?
                PlayerContext.currentStreamUrls = streamSources
                if streamSources.isEmpty {
                    println("empty")
                    ViewUtils.showNoticeAlert(self, title: "Failed to play",
                        message: "Failed to find proper source")
                    // XXX: Cannot play.
                    return
                }
                PlayerContext.currentStreamCandidate = streamSources[0]
                if (track!.type == "youtube" && streamSources[0].type == "webm") {
                    // Should notify that we can't play it.
                    ViewUtils.showNoticeAlert(self, title: "Failed to play",
                        message: "Failed to find proper source (webm)")
                    return
                }
                
                var url = NSURL(string: streamSources[0].url)
                
                if (PlayerContext.currentTrack?.type == "youtube" && streamSources[0].type == "m4a") {
                    // Youtube duration hack.
                    var q :String = url!.query!
                    var qa = split(q) {$0 == "&"}
                    var dur :String = ""
                    for i :String in qa {
                        var subq :[String] = split(i) {$0 == "="}
                        if subq.count >= 2 {
                            var key :String = subq[0]
                            var value :String = subq[1]
                            if key == "dur" {
                                dur = value
                            }
                        } else {
                            continue
                        }
                    }
                    
                    if (dur != "") {
                        PlayerContext.correctDuration = (dur as NSString).doubleValue
                    } else {
                        // To indicate that we should devide youtube duration into 2.
                        PlayerContext.correctDuration = -1.0
                    }
                } else if (PlayerContext.currentTrack?.type == "youtube") {
                    // Received video or other audio extension.
                    PlayerContext.correctDuration = nil
                }
                
                // Play it!
                println("play it!")
                self.audioPlayer = MPMoviePlayerController()
                self.audioPlayer.movieSourceType = MPMovieSourceType.Streaming
//                println(streamSources[0].url)
                self.audioPlayer.contentURL = url
                self.audioPlayer.controlStyle = MPMovieControlStyle.Embedded
                self.audioPlayer.view.hidden = true
                self.playAudioPlayer()
                // Log to us
                if (Account.getCachedAccount() != nil) {
                    Requests.logPlay(PlayerContext.currentTrack!.title)
                }
                
                // Log to ga
                let currentTrack = PlayerContext.currentTrack
                if (currentTrack != nil) {
                    let tracker = GAI.sharedInstance().defaultTracker
                    let event = GAIDictionaryBuilder.createEventWithCategory(
                            "player-play-from-ios",
                            action: "play-\(currentTrack!.type)",
                            label: currentTrack!.title,
                            value: nil
                        ).build()
                    
                    tracker.send(event as [NSObject: AnyObject]!)
                }
            } else {
                if (self.backgroundTaskId != nil && self.isBackgroundTaskSuppored) {
                    app.endBackgroundTask(self.backgroundTaskId!)
                    self.backgroundTaskId = nil
                }
                // XXX: Cannot play.
                println(err)
                var message:String?
                if (err!.domain == NSURLErrorDomain &&
                        err!.code == NSURLErrorNotConnectedToInternet) {
                    message = "Internet is not connected."
                } else {
                    message = "Stream source is not available."
                }
                ViewUtils.showNoticeAlert(self, title: "Failed to play", message: message!)
                PlayerContext.playState = PlayState.STOPPED
                self.playlistPlayerUpdate()
                self.updatePlayerViews()
                self.initPlayingInfo("")
            }
        })
    }
    
    func handlePause() {
        userPaused = true
        if (audioPlayer.playbackState == MPMoviePlaybackState.Playing) {
            pauseAudioPlayer()
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
        audioPlayer.stop()
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
        let newPlaybackTime:Double = (duration * Double(value)) / 100
        audioPlayer.currentPlaybackTime = newPlaybackTime
    }
    
    func playAudioPlayer() {
        audioPlayer.play()
    }
    
    func pauseAudioPlayer() {
        audioPlayer.pause()
    }
    
    func updatePlayingInfo(track: Track, rate: Float? = 1.0) {
        var playingInfoCenter:AnyClass! = NSClassFromString("MPNowPlayingInfoCenter")
        if (playingInfoCenter != nil) {
            var trackInfo:NSMutableDictionary = NSMutableDictionary()
            var albumArt:MPMediaItemArtwork = MPMediaItemArtwork(image: UIImage(named: "logo_512x512.png"))
            trackInfo[MPMediaItemPropertyTitle] = track.title
            // TODO
            trackInfo[MPMediaItemPropertyArtwork] = albumArt
            
            trackInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = audioPlayer.currentPlaybackTime ?? 0
            trackInfo[MPMediaItemPropertyPlaybackDuration] = PlayerContext.correctDuration ?? 0
            trackInfo[MPNowPlayingInfoPropertyPlaybackRate] = rate
            MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = trackInfo as [NSObject : AnyObject]
        }
    }
    
    func initPlayingInfo(title: String) {
        var playingInfoCenter:AnyClass! = NSClassFromString("MPNowPlayingInfoCenter")
        if (playingInfoCenter != nil) {
            var trackInfo:NSMutableDictionary = NSMutableDictionary()
            var albumArt:MPMediaItemArtwork = MPMediaItemArtwork(image: UIImage(named: "logo"))
            trackInfo[MPMediaItemPropertyTitle] = title
            trackInfo[MPMediaItemPropertyArtist] = "LOADING.."
            
            // TODO
            trackInfo[MPMediaItemPropertyArtwork] = albumArt
            
            trackInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0.0
            trackInfo[MPMediaItemPropertyPlaybackDuration] = 0.0
            trackInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
            MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = trackInfo as [NSObject : AnyObject]
        }       
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
