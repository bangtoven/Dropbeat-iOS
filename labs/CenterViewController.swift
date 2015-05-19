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
    
    var audioPlayer: MPMoviePlayerController!
    
    private var activeViewController: UIViewController? {
        didSet {
            removeInactiveViewController(oldValue)
            updateActiveViewController()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        onMenuSelected(LeftSideViewController.MENU_FEED)
        
        var sharedInstance:AVAudioSession = AVAudioSession.sharedInstance()
        
        var audioSessionError:NSError?
        if (!sharedInstance.setCategory(AVAudioSessionCategoryPlayback, error: &audioSessionError)) {
            NSLog("Audio session error \(audioSessionError) \(audioSessionError?.userInfo)")
        } else {
            UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
            becomeFirstResponder()
        }
        sharedInstance.setActive(true, error: nil)
        
        // Observe remote input.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "remotePlay:", name: "playPipe", object: nil)
        
        // Observe internal player state change.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "MPMoviePlayerPlaybackStateDidChange:", name: "MPMoviePlayerPlaybackStateDidChangeNotification", object: nil)
    }
    
    func MPMoviePlayerPlaybackStateDidChange(noti: NSNotification) {
        println("changed!")
        println(self.audioPlayer.playbackState)
    }
    
    override func viewWillDisappear(animated: Bool) {
        UIApplication.sharedApplication().endReceivingRemoteControlEvents()
        resignFirstResponder()
        super.viewWillDisappear(animated)
    }
    
    func showSigninView() {
        
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        var signinVC = mainStoryboard.instantiateViewControllerWithIdentifier("SigninViewController") as! SigninViewController
        
//        addChildViewController(signinVC)
//        view.addSubview(signinVC.view)
//        signinVC?.didMoveToParentViewController(nil)
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
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override func remoteControlReceivedWithEvent(event: UIEvent) {
        switch(event.subtype) {
        case UIEventSubtype.RemoteControlPlay:
            println("play clicked")
            //handlePlay()
            break;
        
        case UIEventSubtype.RemoteControlPause:
            println("pause clicked")
            handlePause()
            break;
        
        case UIEventSubtype.RemoteControlPreviousTrack:
            println("prev clicked")
            handlePrev()
            break;
        
        case UIEventSubtype.RemoteControlNextTrack:
            println("next clicked")
            handleNext()
            break;
            
        case UIEventSubtype.RemoteControlStop:
            println("stop clicked")
            handleStop()
            break;
        case UIEventSubtype.RemoteControlTogglePlayPause:
            println("toggle clicked")
            break;
        default:
            break;
        }
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
        handlePlay(PlayerContext.currentTrack!, playlistId: PlayerContext.currentPlaylistId!)
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
        // Fetch stream urls.
        if track == nil {
            return
        }
        
        println("gogo!")
        if audioPlayer != nil && PlayerContext.currentTrack != nil && PlayerContext.currentTrack!.id == track!.id {
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
        
        if (PlayerContext.currentPlaylistId != nil) {
            var playlist :Playlist? = PlayerContext.getPlaylist(playlistId)!
            for (idx: Int, t: Track) in enumerate(playlist!.tracks) {
                if t.id == track!.id {
                    PlayerContext.currentTrackIdx = idx
                    break
                }
            }
        }
        
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
                
                var url = NSURL(string: streamSources[0].url)
                self.audioPlayer = MPMoviePlayerController(contentURL: url)
                self.audioPlayer.controlStyle = MPMovieControlStyle.Embedded
                self.audioPlayer.view.hidden = true
                self.playAudioPlayer()
                self.updatePlayingInfo(track!)
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
    
    func handleNext() {
        handlePlay(PlayerContext.pickNextTrack(), playlistId: PlayerContext.currentPlaylistId)
    }
    
    func handlePrev() {
        handlePlay(PlayerContext.pickPrevTrack(), playlistId: PlayerContext.currentPlaylistId)
    }
    
    func handleStop() {
        // Do we have a stop btn?
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
    
    func updatePlayingInfo(track: Track) {
        var playingInfoCenter:AnyClass! = NSClassFromString("MPNowPlayingInfoCenter")
        if (playingInfoCenter != nil) {
            var trackInfo:NSMutableDictionary = NSMutableDictionary()
            var albumArt:MPMediaItemArtwork = MPMediaItemArtwork(image: UIImage(named: "logo"))
            trackInfo[MPMediaItemPropertyTitle] = track.title
            trackInfo[MPMediaItemPropertyArtist] = "Dropbeat"
            trackInfo[MPMediaItemPropertyAlbumTitle] = "Dropbeat"
            // TODO
            trackInfo[MPMediaItemPropertyArtwork] = albumArt
            
            trackInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = audioPlayer.currentPlaybackTime
            trackInfo[MPMediaItemPropertyPlaybackDuration] = audioPlayer.duration
            trackInfo[MPNowPlayingInfoPropertyPlaybackRate] = NSNumber(double:0.0)
            MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = trackInfo as [NSObject : AnyObject]
        }       
    }
    
    func onMenuSelected(menuIdx: Int) {
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        
        switch(menuIdx) {
        case LeftSideViewController.MENU_FEED:
            activeViewController = mainStoryboard
                .instantiateViewControllerWithIdentifier("FeedViewController")
                as? UIViewController
            break
        case LeftSideViewController.MENU_SEARCH:
            activeViewController = mainStoryboard
                .instantiateViewControllerWithIdentifier("SearchViewController")
                as? UIViewController
            break
        case LeftSideViewController.MENU_SETTINGS:
            activeViewController = mainStoryboard
                .instantiateViewControllerWithIdentifier("SettingsViewController")
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
