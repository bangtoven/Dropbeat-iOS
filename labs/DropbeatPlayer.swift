//
//  DropbeatPlayer.swift
//  AVPlayerTest
//
//  Created by 방정호 on 2015. 10. 7..
//  Copyright © 2015년 방정호. All rights reserved.
//

import UIKit
import MediaPlayer

class DropbeatPlayer: NSObject, STKAudioPlayerDelegate {

    static let defaultPlayer = DropbeatPlayer()
    
    private var player: STKAudioPlayer = STKAudioPlayer()
    override init() {
        super.init()
        self.player.delegate = self
    }
    
    func remoteControlReceivedWithEvent(event: UIEvent?) {
        switch(event!.subtype) {
        case .RemoteControlPlay:
            print("play clicked")
            guard let currentTrack = PlayerContext.currentTrack else {
                return
            }
            var params = [String: AnyObject]()
            params["track"] = currentTrack
            if let playlistId = PlayerContext.currentPlaylistId {
                params["playlistId"] =  playlistId
            }
            NSNotificationCenter.defaultCenter().postNotificationName(NotifyKey.playerPlay, object: params)
        case .RemoteControlPause:
            print("pause clicked")
            NSNotificationCenter.defaultCenter().postNotificationName(NotifyKey.playerPause, object: nil)
        case .RemoteControlStop:
            print("stop clicked")
        case .RemoteControlPreviousTrack:
            print("prev clicked")
            NSNotificationCenter.defaultCenter().postNotificationName(NotifyKey.playerPrev, object: nil)
        case .RemoteControlNextTrack:
            print("next clicked")
            NSNotificationCenter.defaultCenter().postNotificationName(NotifyKey.playerNext, object: nil)
//        case .RemoteControlTogglePlayPause:
//        case .RemoteControlBeginSeekingBackward:
//        case .RemoteControlEndSeekingBackward:
//        case .RemoteControlBeginSeekingForward:
//        case .RemoteControlEndSeekingForward:
        default:
            break
        }
    }
    
    func play(track: Track) {
        self.lastError = nil
        
        if track.type == .YOUTUBE {
            let quality = XCDYouTubeVideoQuality.Medium360
            track.getYoutubeStreamURL(quality, callback: { (streamURL, error) -> Void in
                if let streamUrl = streamURL {
                    self.player.play(streamUrl)
                } else {
                    print(error)
                }
            })
        } else {
            player.play(track.streamUrl)
        }
        
        updatePlayingInfoCenter(track)
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
        
//        let duration = PlayerContext.correctDuration ?? 0
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
    
    func stop() {
        player.stop()
    }

    func audioPlayer(audioPlayer: STKAudioPlayer!, didStartPlayingQueueItemId queueItemId: NSObject!)
    {
        print("started")
    }
    
    func audioPlayer(audioPlayer: STKAudioPlayer!, didFinishBufferingSourceWithQueueItemId queueItemId: NSObject!)
    {
        print("buffering finished")
    }
    
    enum State: UInt32 {
        case Ready = 0
        case Running = 1
        case Playing = 3
        case Buffering = 5
        case Paused = 9
        case Stopped = 16
        case Error = 32
        case Disposed = 64
    }
    
    func audioPlayer(audioPlayer: STKAudioPlayer!, stateChanged state: STKAudioPlayerState, previousState: STKAudioPlayerState)
    {
        if let prev = State(rawValue: previousState.rawValue),
            curr = State(rawValue: state.rawValue) {
                print("state changed: \(prev) -> \(curr)")
        } else {
            print("CAN'T CONVERT!! state changed: \(previousState) -> \(state)")
        }
    }
    
    func audioPlayer(audioPlayer: STKAudioPlayer!, didFinishPlayingQueueItemId queueItemId: NSObject!, withReason stopReason: STKAudioPlayerStopReason, andProgress progress: Double, andDuration duration: Double)
    {
        
    }
    
    // TODO: Error handling
    
    enum ErrorCode:UInt32 {
        case None = 0
        case DataSource
        case StreamParseBytesFailed
        case AudioSystemError
        case CodecError
        case DataNotFound
        case Other = 0xffff
    }
    
    var lastError: STKAudioPlayerErrorCode?
    
    func audioPlayer(audioPlayer: STKAudioPlayer!, unexpectedError errorCode: STKAudioPlayerErrorCode)
    {
        if let last = self.lastError where last == errorCode {
            
        } else {
            let err = ErrorCode(rawValue: errorCode.rawValue)
            print("Error!: \(err!)")
            self.lastError = errorCode
            self.player.dispose()
            self.player = STKAudioPlayer()
            self.player.delegate = self
        }
    }

}


extension Track {
    func getYoutubeStreamURL(quality:XCDYouTubeVideoQuality, callback:(streamURL:String?, error:NSError?)->Void) {
        guard self.type == .YOUTUBE else {
            let error = NSError(domain: "TrackYouTubeStreamURL", code: -1, userInfo: nil)
            callback(streamURL: self.streamUrl, error: error)
            return
        }
        
        XCDYouTubeClient.defaultClient().getVideoWithIdentifier(self.id, completionHandler: {
            (video: XCDYouTubeVideo?, error: NSError?) -> Void in
            if error != nil {
                callback(streamURL: nil, error: error)
                return
            }
            
            if let streamURL = video?.streamURLs[quality.rawValue] as? NSURL {
                callback(streamURL: streamURL.absoluteString, error: nil)
            } else {
                let e = NSError(domain: "TrackYouTubeStreamURL", code: -2, userInfo: nil)
                callback(streamURL: nil, error: e)
            }
        })
    }
}