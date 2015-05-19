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
        
        var sharedInstance:AVAudioSession = AVAudioSession.sharedInstance()
        
        var audioSessionError:NSError?
        if (!sharedInstance.setCategory(AVAudioSessionCategoryPlayback, error: &audioSessionError)) {
            NSLog("Audio session error \(audioSessionError) \(audioSessionError?.userInfo)")
        } else {
            UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
            becomeFirstResponder()
        }
        sharedInstance.setActive(true, error: nil)
        
        var error:NSError?
        var fileUrl = NSURL(string: "http://r2---sn-3u-bh2d.googlevideo.com/videoplayback?id=acb31ab3751215b0&itag=141&source=youtube&mm=31&pl=20&mv=m&ms=au&ratebypass=yes&mime=audio/mp4&gir=yes&clen=10702429&lmt=1429685838913555&dur=335.667&key=dg_yt0&upn=QCNuDBh__Z4&fexp=919330,9405967,9406841,9407992,9408142,9408707,9408710,9408713,9412471,9413010,9413103,945137,948124,952612,952637,952642&mt=1431923939&signature=5ED42D3F07C0F4454732FD946A1C5A7B345BD1BD.35A1A30E6529DDAB59723587C0306B349383B518&sver=3&ip=14.63.224.95&ipbits=0&expire=1431945644&sparams=ip,ipbits,expire,id,itag,source,mm,pl,mv,ms,ratebypass,mime,gir,clen,lmt,dur")
        audioPlayer = MPMoviePlayerController(contentURL: fileUrl)
        audioPlayer.shouldAutoplay = false
        audioPlayer.controlStyle = MPMovieControlStyle.Embedded
        audioPlayer.view.hidden = true
        audioPlayer.prepareToPlay()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillDisappear(animated: Bool) {
        UIApplication.sharedApplication().endReceivingRemoteControlEvents()
        resignFirstResponder()
        super.viewWillDisappear(animated)
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
            //handlePlay()
            break;
        
        case UIEventSubtype.RemoteControlPause:
            handlePause()
            break;
        
        case UIEventSubtype.RemoteControlPreviousTrack:
            handlePrev()
            break;
        
        case UIEventSubtype.RemoteControlNextTrack:
            handleNext()
            break;
            
        case UIEventSubtype.RemoteControlStop:
            handleStop()
            break;
            
        case UIEventSubtype.RemoteControlTogglePlayPause:
            break;
        default:
            break;
        }
    }
    
    @IBAction func playBtnClicked(sender: UIButton?) {
        if PlayerContext.currentTrack == nil {
            return
        }
        
    }
    
    @IBAction func pauseBtnClicked(sender: UIButton?) {
        handlePause()
    }
    
    @IBAction func playlistBtnClicked(sender: UIButton) {
        showPlaylistView()
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
    
    func handlePlay(track: Track, playlistId: String) {
        audioPlayer.play()
        playBtn.hidden = true
        pauseBtn.hidden = false
        
        updatePlayingInfo(track)
    }
    
    func handlePause() {
        audioPlayer.pause()
        playBtn.hidden = false
        pauseBtn.hidden = true
    }
    
    func handleNext() {
        
    }
    
    func handlePrev() {
        
    }
    
    func handleStop() {
        
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
