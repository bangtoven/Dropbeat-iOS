//
//  DropbeatPlayer.swift
//  AVPlayerTest
//
//  Created by 방정호 on 2015. 10. 7..
//  Copyright © 2015년 방정호. All rights reserved.
//

import UIKit
import MediaPlayer

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

enum PlayState: Int {
    case STOPPED = 0
    case LOADING
    case PLAYING
    case PAUSED
    case SWITCHING
    case BUFFERING
}

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
            guard let currentTrack = self.currentTrack else {
                return
            }
            var params = [String: AnyObject]()
            params["track"] = currentTrack
            if let playlistId = self.currentPlaylistId {
                params["playlistId"] =  playlistId
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
    
    func pause() {
        self.player.pause()
    }
    func prev() {}
    func next() {}
    
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
    
    
    var currentTrackIdx: Int = -1
    var currentTrack: Track?
    
    var currentPlaylistId: String?
    var playlists: [Playlist] = []
    var externalPlaylist: Playlist?
    
    var repeatState = RepeatState.NOT_REPEAT
    var shuffleState = ShuffleState.NOT_SHUFFLE
    var playState = PlayState.STOPPED
    var qualityState = QualityState.LQ
    
    var correctDuration: Double?
    var currentPlaybackTime: Double?
    var playingSection:String?
    
    var playLog: PlayLog?
    
    func resetPlaylist(playlists: [Playlist]) {
        self.playlists = playlists
    }
    
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
        let playlist :Playlist? = getPlaylist(currentPlaylistId)
        let size = playlist?.tracks.count ?? 0
        
        if currentPlaylistId == nil || playlist == nil || size == 0{
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
        let playlist :Playlist? = getPlaylist(currentPlaylistId)
        let size = playlist?.tracks.count ?? 0
        
        if currentPlaylistId == nil || playlist == nil || size == 0{
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
        let playlist :Playlist? = getPlaylist(currentPlaylistId)
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
    
    func getPlaylist(playlistId: String?) -> Playlist? {
        for playlist: Playlist in self.playlists {
            if playlist.id == playlistId {
                return playlist
            }
        }
        if self.externalPlaylist != nil &&
            self.externalPlaylist!.id == playlistId {
                return self.externalPlaylist
        }
        return nil
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