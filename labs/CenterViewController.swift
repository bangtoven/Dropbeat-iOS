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
    
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var playerTitle: UILabel!
    @IBOutlet weak var playerStatus: UILabel!
    
    @IBOutlet weak var playlistBtn: UIButton!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var pauseBtn: UIButton!
    
    var audioPlayer: MPMoviePlayerController = MPMoviePlayerController()
    
    var remoteProgressTimer: NSTimer?
    
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
        
        // Used for playlistView bottom controller update.
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "sender", name: NotifyKey.updatePlaylistView, object: nil)
        
        // Observe remote input.
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "remotePlay:", name: NotifyKey.playerPlay, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "handlePrev", name: NotifyKey.playerPrev, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "handlePause", name: NotifyKey.playerPause, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "handleNext", name: NotifyKey.playerNext, object: nil)
        
        
        // Observe internal player.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "MPMoviePlayerPlaybackStateDidChange:", name: "MPMoviePlayerPlaybackStateDidChangeNotification", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "MPMoviePlayerPlaybackDidFinish:", name: "MPMoviePlayerPlaybackDidFinishNotification", object: nil)
        
    }
    
    func updateProgress () {
        var currentTrack :Track? = PlayerContext.currentTrack
        if (currentTrack != nil) {
            if (audioPlayer.duration == 0.0) {
                // Audio meta has not been loaded.
                return
            }
            
            // Youtube duration hack.
            if (currentTrack?.type == "youtube") {
                if (PlayerContext.correctDuration == nil) {
                    // Prevent race condition between timer and UIThread.
                    return
                }
                
                if (audioPlayer.duration != PlayerContext.correctDuration) {
                    // To find a end of the track that has corrected duration.
                    if (audioPlayer.currentPlaybackTime > PlayerContext.correctDuration) {
                        var success :Bool = handleNext()
                        if (!success) {
                            handleStop()
                        }
                        PlayerContext.correctDuration = nil
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
            
            // TODO: This method isn't necessarily called periodically.
            // Update remote control progress
            updatePlayingInfo(currentTrack!)
            
            // Update custom progress
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
            PlayerContext.playState = PlayState.PLAYING
            // Periodic timer for progress update.
            if remoteProgressTimer == nil {
                remoteProgressTimer = NSTimer.scheduledTimerWithTimeInterval(
                    1.0, target: self, selector: Selector("updateProgress"), userInfo: nil, repeats: true)
            }
        } else if (audioPlayer.playbackState == MPMoviePlaybackState.Stopped) {
            PlayerContext.playState = PlayState.STOPPED
            
            updatePlayingInfo(PlayerContext.currentTrack!, rate: 0.0)
            if remoteProgressTimer != nil {
                remoteProgressTimer?.invalidate()
                remoteProgressTimer = nil
            }
        } else if (audioPlayer.playbackState == MPMoviePlaybackState.Paused) {
            PlayerContext.playState = PlayState.PAUSED
            
            updatePlayingInfo(PlayerContext.currentTrack!, rate: 0.0)
            if remoteProgressTimer != nil {
                remoteProgressTimer?.invalidate()
                remoteProgressTimer = nil
            }
        } else if (audioPlayer.playbackState == MPMoviePlaybackState.Interrupted) {
            
        } else if (audioPlayer.playbackState == MPMoviePlaybackState.SeekingForward) {
            
        } else if (audioPlayer.playbackState == MPMoviePlaybackState.SeekingBackward) {
            
        }
        playlistPlayerUpdate()
    }
    
    func MPMoviePlayerPlaybackDidFinish (noti: NSNotification) {
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
        var playlistId :String? = PlayerContext.currentPlaylistId
        handlePlay(PlayerContext.currentTrack!, playlistId: playlistId)
    }
    
    @IBAction func pauseBtnClicked(sender: UIButton?) {
        println("pause!")
        handlePause()
    }
    
    @IBAction func playlistBtnClicked(sender: UIButton) {
        showPlaylistView()
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
        }
        
        println(track!.title)
        PlayerContext.currentTrack = track
        PlayerContext.currentPlaylistId = playlistId
        PlayerContext.currentTrackIdx = -1
        
        if (PlayerContext.currentPlaylistId != "-1") {
            var playlist :Playlist? = PlayerContext.getPlaylist(playlistId)!
            for (idx: Int, t: Track) in enumerate(playlist!.tracks) {
                if t.id == track!.id {
                    PlayerContext.currentTrackIdx = idx
                    break
                }
            }
        }
        
        // Indicate loading status.
        PlayerContext.playState = PlayState.LOADING
        playlistPlayerUpdate()
        
        // Init correct duration.
        PlayerContext.correctDuration = nil
        
        initPlayingInfo(track!.title)
        
        resolve(track!.id, track!.type, { (req, resp, json, err) in
            if err == nil {
                println("FIN RESOLVE")
                var streamSources :[StreamSource] = getStreamUrls(json!)
                
                // Do we need multiple candidates?
                PlayerContext.currentStreamUrls = streamSources
                if streamSources.isEmpty {
                    println("empty")
                    // XXX: Cannot play.
                    return
                }
                PlayerContext.currentStreamCandidate = streamSources[0]
                if (track!.type == "youtube" && streamSources[0].type == "webm") {
                    // Should notify that we can't play it.
                    return;
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
                } else {
                    PlayerContext.correctDuration = nil
                }
                
                // Play it!
                self.audioPlayer = MPMoviePlayerController()
                self.audioPlayer.movieSourceType = MPMovieSourceType.Streaming
                self.audioPlayer.contentURL = url
                self.audioPlayer.controlStyle = MPMovieControlStyle.Embedded
                self.audioPlayer.view.hidden = true
                println("call play")
                self.playAudioPlayer()
            } else {
                // XXX: Cannot play.
                println(err)
            }
        })
    }
    
    func handlePause() {
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
    
    func playAudioPlayer() {
        self.audioPlayer.play()
        self.playBtn.hidden = true
        self.pauseBtn.hidden = false
    }
    
    func pauseAudioPlayer() {
        audioPlayer.pause()
        playBtn.hidden = false
        pauseBtn.hidden = true       
    }
    
    func updatePlayingInfo(track: Track, rate: Float? = 1.0) {
        var playingInfoCenter:AnyClass! = NSClassFromString("MPNowPlayingInfoCenter")
        if (playingInfoCenter != nil) {
            var trackInfo:NSMutableDictionary = NSMutableDictionary()
            var albumArt:MPMediaItemArtwork = MPMediaItemArtwork(image: UIImage(named: "logo"))
            trackInfo[MPMediaItemPropertyTitle] = track.title
            // TODO
            trackInfo[MPMediaItemPropertyArtwork] = albumArt
            
            trackInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = audioPlayer.currentPlaybackTime
            trackInfo[MPMediaItemPropertyPlaybackDuration] = PlayerContext.correctDuration
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
