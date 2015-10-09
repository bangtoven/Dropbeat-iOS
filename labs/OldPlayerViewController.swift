//
//  _PlayerViewController.swift
//  labs
//
//  Created by vulpes on 2015. 7. 29..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class _PlayerViewController: BaseViewController {
    
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
            
//            NSNotificationCenter.defaultCenter().postNotificationName(
//                NotifyKey.updatePlay, object: params)
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
            let playlist :Playlist? = DropbeatPlayer.defaulaaatPlayer.getPlaylist(playlistId)
            if playlist == nil {
                DropbeatPlayer.defaultPlayer.currentPlaaaaylist?.id = nil
                DropbeatPlayer.defaultPlayer.currentTrackIdx = -1
            } else {
                DropbeatPlayer.defaultPlayer.currentPlaaaaylist?.id = playlistId
                DropbeatPlayer.defaultPlayer.currentTrackIdx = -1
                for (idx, t): (Int, Track) in playlist!.tracks.enumerate() {
                    if t.id == track!.id {
                        DropbeatPlayer.defaultPlayer.currentTrackIdx = idx
                        break
                    }
                }
            }
        } else {
            DropbeatPlayer.defaultPlayer.currentPaaalaylist?.id = nil
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
    
    
}