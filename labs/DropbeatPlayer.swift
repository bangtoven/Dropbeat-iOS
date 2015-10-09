//
//  DropbeatPlayer.swift
//  AVPlayerTest
//
//  Created by 방정호 on 2015. 10. 7..
//  Copyright © 2015년 방정호. All rights reserved.
//

import UIKit
import MediaPlayer
import AVFoundation

public let DropbeatPlayerStateChangedNotification = "DropbeatPlayerStateChangedNotification"


class DropbeatPlayer: NSObject, STKAudioPlayerDelegate {
    
    static let defaultPlayer = DropbeatPlayer()

    private var player: STKAudioPlayer = STKAudioPlayer()
    override init() {
        super.init()
        self.player.delegate = self
    }
    
    var state = STKAudioPlayerState.Ready
    var duration: Double {
        get { return self.player.duration }
    }
    var progress: Double {
        get { return self.player.progress }
    }
    
    func play(track: Track) {
        self.lastError = nil
        
        self.currentTrack = track
        
        if track.type == .YOUTUBE {
            
            let quality = XCDYouTubeVideoQuality.Medium360
            track.getYoutubeStreamURL(quality, callback: { (streamURL, duration, error) -> Void in
                if let streamUrl = streamURL {
                    self.player.play(streamUrl, duration: duration!, withQueueItemID: streamUrl)
                    
//                    let asset = AVAsset(URL: NSURL(string: streamUrl)!)
//                    asset.loadValuesAsynchronouslyForKeys(["duration"]) {
//                        let time = CMTimeGetSeconds(asset.duration)
//                        print(time)
//                    }

                } else {
                    print(error)
                }
            })
        } else {
            player.play(track.streamUrl)
        }
        
        
        updatePlayingInfoCenter(track)
    }
    
    func resume() {
        self.player.resume()
    }
    
    func pause() {
        self.player.pause()
    }
    
    func seekTo(percent: Float) {
        let time = Double(percent) / 100.0 * self.duration
        print(time)
        self.player.seekToTime(time)
    }
    
    func prev() {}
    func next() {}
    
    func stop() {
        player.stop()
        /*
        shouldPlayMusic = false
        DropbeatPlayer.defaultPlayer.currentPlaylist?.id = nil
        DropbeatPlayer.defaultPlayer.currentTrack = nil
        DropbeatPlayer.defaultPlayer.currentTrackIdx = -1
        DropbeatPlayer.defaultPlayer.correctDuration = nil
        videoView.hidden = true
        audioPlayerControl.videoIdentifier = nil
        audioPlayerControl.moviePlayer.contentURL = nil
        if (audioPlayerControl.moviePlayer.playbackState != MPMoviePlaybackState.Stopped) {
        audioPlayerControl.moviePlayer.stop()
        }
        updatePlayState(PlayState.STOPPED)
        updateCoverView()
        deactivateAudioSession()
*/
    }

    func audioPlayer(audioPlayer: STKAudioPlayer!, didStartPlayingQueueItemId queueItemId: NSObject!)
    {
        print("started")
    }
    
    func audioPlayer(audioPlayer: STKAudioPlayer!, didFinishBufferingSourceWithQueueItemId queueItemId: NSObject!)
    {
        print("buffering finished")
    }
    
    func audioPlayer(audioPlayer: STKAudioPlayer!, stateChanged state: STKAudioPlayerState, previousState: STKAudioPlayerState)
    {
        print("state changed: \(previousState.rawValue) -> \(state.rawValue)")
        self.state = state
        
        let noti = NSNotification(name: DropbeatPlayerStateChangedNotification, object: state.rawValue, userInfo: nil)
        NSNotificationCenter.defaultCenter().postNotification(noti)
    }
    
    func audioPlayer(audioPlayer: STKAudioPlayer!, didFinishPlayingQueueItemId queueItemId: NSObject!, withReason stopReason: STKAudioPlayerStopReason, andProgress progress: Double, andDuration duration: Double)
    {
        print("stopped: \(stopReason)")
        
        print("handle play failure")
        
        if stopReason == STKAudioPlayerStopReason.Error {
            // TODO: error handling
//                let errMsg = NSLocalizedString("This track is not streamable", comment:"")
//                ViewUtils.showToast(self, message: errMsg)
            let track = DropbeatPlayer.defaultPlayer.currentTrack
            track?.postFailureLog()
            
            self.next()
        }
    }
    
    // TODO: Error handling
    
    var lastError: STKAudioPlayerErrorCode?
    
    func audioPlayer(audioPlayer: STKAudioPlayer!, unexpectedError errorCode: STKAudioPlayerErrorCode)
    {
        if let last = self.lastError where last == errorCode {
            
        } else {
            print("Error!: \(errorCode.rawValue)")
            self.lastError = errorCode
            self.player.dispose()
            self.player = STKAudioPlayer()
            self.player.delegate = self
        }
    }
    
    
    // Player Context
    
    var currentTrackIdx: Int = -1
    var currentTrack: Track?
    
    var currentPlaylist: Playlist?
    
    var repeatState = RepeatState.NOT_REPEAT
    var shuffleState = ShuffleState.NOT_SHUFFLE
    var qualityState = QualityState.LQ
    
    var playingSection:String?
    
    var playLog: PlayLog?
    
    func changeRepeatState() {
        repeatState = repeatState.next()
    }
    
    func changeShuffleState() {
        shuffleState = shuffleState.toggle()
    }
    
    func changeQualityState() {
        qualityState = qualityState.toggle()
    }
    
    func pickNextTrack() -> Track? {
        var track :Track? = nil
        let playlist :Playlist? = currentPlaylist
        let size = playlist?.tracks.count ?? 0
        
        if playlist == nil || size == 0{
            return nil;
        }
        
        if self.shuffleState == .SHUFFLE {
            track = randomPick()
        } else {
            var nextIdx :Int
            
            if self.repeatState == .REPEAT_PLAYLIST {
                if currentTrackIdx < 0 {
                    nextIdx = 0
                } else {
                    nextIdx = (currentTrackIdx + 1) % size
                }
                track = playlist!.tracks[nextIdx] as Track
            } else {
                if currentTrackIdx < 0 {
                    nextIdx = 0
                } else {
                    nextIdx = currentTrackIdx + 1
                }
                if (nextIdx < size) {
                    track = playlist!.tracks[nextIdx] as Track
                }
            }
        }
        return track
    }
    
    func pickPrevTrack() -> Track? {
        var track :Track? = nil
        let playlist :Playlist? = currentPlaylist
        let size = playlist?.tracks.count ?? 0
        
        if  playlist == nil || size == 0{
            return nil;
        }
        
        if self.shuffleState == .SHUFFLE {
            track = randomPick()
        } else {
            var prevIdx :Int
            
            if self.repeatState == .REPEAT_PLAYLIST {
                prevIdx = currentTrackIdx - 1
                if prevIdx <= 0 {
                    prevIdx = size - 1
                }
                track = playlist!.tracks[prevIdx] as Track
            } else {
                prevIdx = currentTrackIdx - 1
                if prevIdx >= 0 {
                    track = playlist!.tracks[prevIdx] as Track
                }
            }
        }
        return track
    }
    
    func randomPick() -> Track? {
        // Randomly pick next track in shuffle mode.
        // NOTE that this method should exclude current track in next candidates.
        let playlist :Playlist? = currentPlaylist
        let size = playlist?.tracks.count
        if size <= 1 {
            return nil
        }
        
        while (true) {
            let idx = Int(arc4random_uniform(UInt32(size!)))
            if idx != currentTrackIdx {
                return playlist!.tracks[idx] as Track
            }
        }
    }

    func remoteControlReceivedWithEvent(event: UIEvent?) {
        switch(event!.subtype) {
        case .RemoteControlPlay:
            print("play clicked")
            guard let currentTrack = self.currentTrack else {
                return
            }
            self.play(currentTrack)
        case .RemoteControlPause:
            print("pause clicked")
            self.pause()
        case .RemoteControlStop:
            print("stop clicked")
        case .RemoteControlPreviousTrack:
            print("prev clicked")
            self.prev()
        case .RemoteControlNextTrack:
            print("next clicked")
            self.next()
            //        case .RemoteControlTogglePlayPause:
            //        case .RemoteControlBeginSeekingBackward:
            //        case .RemoteControlEndSeekingBackward:
            //        case .RemoteControlBeginSeekingForward:
            //        case .RemoteControlEndSeekingForward:
        default:
            break
        }
    }
    
    func updatePlayingInfoCenter(track: Track) {
        var trackInfo = [String:AnyObject]()
        trackInfo[MPMediaItemPropertyTitle] = track.title
        
        //        var stateText:String?
        let rate:Float = 0.0
        //        switch(playingState) {
        //        case PlayState.LOADING:
        //            stateText = NSLocalizedString("LOADING..", comment:"")
        //            rate = 0.0
        //            break
        //        case PlayState.SWITCHING:
        //            stateText = NSLocalizedString("LOADING..", comment:"")
        //            rate = 1.0
        //            break
        //        case PlayState.PAUSED:
        //            stateText = NSLocalizedString("PAUSED", comment:"")
        //            rate = 0.0
        //            break
        //        case PlayState.STOPPED:
        //            stateText = NSLocalizedString("READY", comment:"")
        //            rate = 0.0
        //            break
        //        case PlayState.PLAYING:
        //            stateText = NSLocalizedString("PLAYING", comment:"")
        //            rate = 1.0
        //            break
        //        case PlayState.BUFFERING:
        //            stateText = NSLocalizedString("BUFFERING", comment:"")
        //            rate = 1.0
        //            break
        //        }
        //        trackInfo[MPMediaItemPropertyArtist] = stateText
        
        //        let duration = DropbeatPlayer.defaultPlayer.correctDuration ?? 0
        //        var currentPlayback:NSTimeInterval?
        //        if audioPlayerControl.moviePlayer.currentPlaybackTime.isNaN {
        //            currentPlayback = 0
        //        } else {
        //            currentPlayback = audioPlayerControl.moviePlayer.currentPlaybackTime ?? 0
        //        }
        //        playingInfoDisplayDuration = duration > 0 && currentPlayback >= 0
        
        //        trackInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentPlayback
        //        trackInfo[MPMediaItemPropertyPlaybackDuration] = duration
        trackInfo[MPNowPlayingInfoPropertyPlaybackRate] = rate
        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = trackInfo
    }
}


enum RepeatState: Int {
    case NOT_REPEAT = 0
    case REPEAT_PLAYLIST = 1
    case REPEAT_ONE = 2
    
    func next() -> RepeatState {
        return RepeatState(rawValue: (self.rawValue + 1) % 3)!
    }
}

enum ShuffleState: Int  {
    case NOT_SHUFFLE = 0
    case SHUFFLE = 1
    
    func toggle() -> ShuffleState {
        switch self {
        case .NOT_SHUFFLE: return .SHUFFLE
        case .SHUFFLE: return .NOT_SHUFFLE
        }
    }
}

enum QualityState: Int  {
    case LQ = 0
    case HQ = 1
    
    func toggle() -> QualityState {
        switch self {
        case .LQ: return .HQ
        case .HQ: return .LQ
        }
    }
}

//enum PlayState: Int {
//    case STOPPED = 0
//    case LOADING
//    case PLAYING
//    case PAUSED
//    case SWITCHING
//    case BUFFERING
//}
