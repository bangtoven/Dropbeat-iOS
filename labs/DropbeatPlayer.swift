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
public let DropbeatPlayerErrorNotification = "DropbeatPlayerErrorNotification"

class DropbeatPlayer: NSObject, STKAudioPlayerDelegate {
    
    static let defaultPlayer = DropbeatPlayer()

    private var player: STKAudioPlayer = STKAudioPlayer()
    override init() {
        super.init()
        self.player.delegate = self
        
        let sharedInstance = AVAudioSession.sharedInstance()
        do {
            try sharedInstance.setCategory(AVAudioSessionCategoryPlayback)
            try sharedInstance.setActive(true)
        } catch let audioSessionError as NSError {
            print("Audio session error \(audioSessionError) \(audioSessionError.userInfo)")
        }
        
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
    }
    
    private var playbackLog: PlayLog?
    
    func resetPlaybackLog(currentTime: Int?) {
        if let playbackLog = self.playbackLog {
            playbackLog.finished(currentTime)
            self.playbackLog = nil
        }
    }
    
    var currentTrack: Track?
    private var currentIndex = -1
    private var currentThumbnail = UIImage(named: "default_cover_big")
    var currentPlaylist: Playlist? {
        didSet {
            currentIndex = -1
        }
    }
    
    // MARK: - Play
    
    func play(track: Track) {
        self.lastError = nil
        if track.id == self.currentTrack?.id {
            return
        }
        
        if track.type == .YOUTUBE {
            track.getYouTubeStreamURL(qualityState == .HQ ? .Medium360 : .Small240) {
                (streamURL, duration, error) -> Void in
                if error != nil {
                    self.handleError()
                    return
                }
                
                self.player.play(streamURL, withQueueItemId: track.id, duration: duration!)
            }
        } else {
            self.player.play(track.streamUrl, withQueueItemId: track.id)
        }
    }
    
    func audioPlayer(audioPlayer: STKAudioPlayer!, didStartPlayingQueueItemId queueItemId: NSObject!)
    {
        self.lastError = nil
        
        guard let currentPlaylist = self.currentPlaylist else {
            return
        }
        
        for (i,track) in currentPlaylist.tracks.enumerate() {
            if track.id == queueItemId {
                self.currentIndex = i
                
                if self.currentTrack == nil || track.id != self.currentTrack!.id {
                    self.currentTrack = track
                    print("new track: \(track.title)")
                }
                
                break
            }
        }
        
        self.didPlayStart()
    }
    
    private func didPlayStart() {
        guard let track = self.currentTrack else {
            return
        }
        
        SDWebImageManager.sharedManager().downloadImageWithURL(NSURL(string: track.thumbnailUrl!), options: SDWebImageOptions.ContinueInBackground, progress: nil) {
            (image, error, cacheType, finished, imageURL) -> Void in
            self.currentThumbnail = image
        }
        
        Requests.logPlay(track)
        
        self.resetPlaybackLog(nil)
        if let dropbeatTrack = track as? DropbeatTrack{
            self.playbackLog = PlayLog(track: dropbeatTrack)
        } else {
            self.playbackLog = nil
        }
        
        self.enqueueNextTrack()
        
        if self.timer == nil {
            self.timer = NSTimer(
                timeInterval: 1.0,
                target: self,
                selector: "updatePlayingInfoCenter",
                userInfo: nil,
                repeats: true)
            NSRunLoop.currentRunLoop().addTimer(timer!, forMode: NSRunLoopCommonModes)
        }
    }
    
    private func enqueueNextTrack() {
        guard let (next, index) = self.pickTrack(.NEXT) else {
            print("End of playlist")
            return
        }
        
        if next.type == .YOUTUBE {
            next.getYouTubeStreamURL(qualityState == .HQ ? .Medium360 : .Small240) {
                (streamURL, duration, error) -> Void in
                if error != nil {
                    next.postFailureLog()
                    // remove this track and find new one.
                    self.currentPlaylist?.tracks.removeAtIndex(index)
                    self.enqueueNextTrack()
                    return
                }
                
                self.player.queue(streamURL!, withQueueItemId: next.id, duration: duration!)
            }
        } else {
            self.player.queue(next.streamUrl, withQueueItemId: next.id)
        }
        
        print("Enqueue next track: \(next.title)")
    }
    
    // MARK: - Next track handling
    
    func next() -> Bool {
        self.resetPlaybackLog(Int(self.progress))
        
        if let (nextTrack, index) = self.pickTrack(.NEXT) {
            self.currentIndex = index
            self.play(nextTrack)
            return true
        } else {
            return false
        }
    }
    
    func prev() -> Bool {
        self.resetPlaybackLog(Int(self.progress))

        if let (prevTrack, index) = self.pickTrack(.PREV) {
            self.currentIndex = index
            self.play(prevTrack)
            return true
        } else {
            return false
        }
    }
    
    enum _Pick { case NEXT; case PREV }
    func pickTrack(pick: _Pick) -> (Track, Int)? {
        guard let playlist = currentPlaylist
            where playlist.tracks.count != 0 else {
                return nil
        }
        
        let size = playlist.tracks.count
        
        if self.shuffleState == .SHUFFLE {
            if size <= 1 {
                return nil
            }
            
            while (true) {
                let idx = Int(arc4random_uniform(UInt32(size)))
                if idx != currentIndex {
                    return (playlist.tracks[idx], idx)
                }
            }
        } else if self.repeatState == .REPEAT_ONE {
            if let track = self.currentTrack {
                return (track, self.currentIndex)
            } else {
                return nil
            }
        }
        else {
            var track: Track?
            var index: Int?
            
            switch pick {
            case .NEXT:
                var nextIdx :Int
                
                if self.repeatState == .REPEAT_PLAYLIST {
                    if currentIndex < 0 {
                        nextIdx = 0
                    } else {
                        nextIdx = (currentIndex + 1) % size
                    }
                    track = playlist.tracks[nextIdx] as Track
                } else {
                    if currentIndex < 0 {
                        nextIdx = 0
                    } else {
                        nextIdx = currentIndex + 1
                    }
                    if (nextIdx < size) {
                        track = playlist.tracks[nextIdx] as Track
                    }
                }
                
                index = nextIdx
                
            case .PREV:
                var prevIdx :Int
                
                if self.repeatState == .REPEAT_PLAYLIST {
                    prevIdx = currentIndex - 1
                    if prevIdx <= 0 {
                        prevIdx = size - 1
                    }
                    track = playlist.tracks[prevIdx] as Track
                } else {
                    prevIdx = currentIndex - 1
                    if prevIdx >= 0 {
                        track = playlist.tracks[prevIdx] as Track
                    }
                }
                
                index = prevIdx
            }
            
            if let t = track {
                return (t, index!)
            } else {
                return nil
            }
        }
    }

    var duration: Double {
        get { return self.player.duration }
    }
    var progress: Double {
        get { return self.player.progress }
    }
    
    func seekTo(percent: Float) {
        let time = Double(percent) / 100.0 * self.duration
        print(time)
        self.player.seekToTime(time)
        
        if let log = self.playbackLog {
            log.seek(from: Int(self.duration), to: Int(time))
        }
    }
    
    func resume() {
        self.player.resume()
    }
    
    func pause() {
        self.player.pause()
    }
    
    func stop() {
        self.player.stop()
        self.resetPlaybackLog(Int(self.progress))
        
        self.currentTrack = nil
        self.currentPlaylist = nil
    }
    
    // MARK: - State change

    var state = STKAudioPlayerState.Ready

    func audioPlayer(audioPlayer: STKAudioPlayer!, didFinishBufferingSourceWithQueueItemId queueItemId: NSObject!)
    {
        print("buffering finished")
    }
    
    func audioPlayer(audioPlayer: STKAudioPlayer!, stateChanged state: STKAudioPlayerState, previousState: STKAudioPlayerState)
    {
        self.state = state

        let noti = NSNotification(name: DropbeatPlayerStateChangedNotification, object: state.rawValue, userInfo: nil)
        NSNotificationCenter.defaultCenter().postNotification(noti)

        switch state {
        case .Ready:
            break
        case .Running:
            break
        case .Playing:
            break
        case .Buffering:
            break
        case .Paused:
            break
        case .Stopped:
            break
        case .Error:
            break
        case .Disposed:
            break
        }
    }
    
    // MARK: - Error handling

    var lastError: STKAudioPlayerErrorCode?
 
    private func handleError() {
        print("Error!")
        
        let noti = NSNotification(name: DropbeatPlayerErrorNotification, object: (lastError ?? .Other).rawValue, userInfo: nil)
        NSNotificationCenter.defaultCenter().postNotification(noti)
        
        self.next()

        let track = DropbeatPlayer.defaultPlayer.currentTrack
        track?.postFailureLog()
    }
    
    func audioPlayer(audioPlayer: STKAudioPlayer!, didFinishPlayingQueueItemId queueItemId: NSObject!, withReason stopReason: STKAudioPlayerStopReason, andProgress progress: Double, andDuration duration: Double)
    {
        print("Stopped: \(stopReason.rawValue)")
        
        self.timer?.invalidate()
        self.timer = nil
        
        if stopReason == STKAudioPlayerStopReason.Error {
            self.handleError()
        }
    }
    
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

    // MARK: - Remote control action
    
    func remoteControlReceivedWithEvent(event: UIEvent?) {
        if self.currentTrack == nil {
            return
        }
        
        switch(event!.subtype) {
        case .RemoteControlPlay:
            self.resume()
        case .RemoteControlPause:
            self.pause()
        case .RemoteControlStop:
            self.stop()
        case .RemoteControlPreviousTrack:
            self.prev()
        case .RemoteControlNextTrack:
            self.next()
        default:
            break
        }
    }
    
    private var timer: NSTimer?

    func updatePlayingInfoCenter() {
        guard let track = self.currentTrack else {
            return
        }

        var trackInfo = [String:AnyObject]()
        if let image = self.currentThumbnail {
            let albumArt = MPMediaItemArtwork(image: image)
            trackInfo[MPMediaItemPropertyArtwork] = albumArt
        }
        trackInfo[MPMediaItemPropertyTitle] = track.title
        trackInfo[MPMediaItemPropertyArtist] = track.user?.name ?? ""
        trackInfo[MPMediaItemPropertyPlaybackDuration] = self.duration
        trackInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.progress
        trackInfo[MPNowPlayingInfoPropertyPlaybackRate] = self.state == .Playing ? 1.0 : 0.0
        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = trackInfo
    }
    
    // MARK: - Player Context
    
    var repeatState = RepeatState.NOT_REPEAT
    var shuffleState = ShuffleState.NOT_SHUFFLE
    var qualityState = QualityState.HQ
    
    func changeRepeatState() {
        repeatState = repeatState.next()
        self.player.clearQueue()
        self.enqueueNextTrack()
    }
    
    func changeShuffleState() {
        shuffleState = shuffleState.toggle()
        self.player.clearQueue()
        self.enqueueNextTrack()
    }
    
    func changeQualityState() {
        qualityState = qualityState.toggle()
    }
}

// MARK: - Enums

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
