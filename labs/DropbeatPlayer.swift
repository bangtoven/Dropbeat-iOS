//
//  DropbeatPlayer.swift
//  DropbeatPlayer
//
//  Created by 방정호 on 2015. 10. 7..
//  Copyright © 2015년 방정호. All rights reserved.
//

import UIKit
import MediaPlayer
import AVFoundation
import Raygun4iOS

public let DropbeatPlayerTrackChangedNotification = "TrackChangedNotification"
public let DropbeatPlayerStateChangedNotification = "StateChangedNotification"
public let DropbeatPlayerErrorNotification = "ErrorNotification"

class DropbeatPlayer: NSObject, STKAudioPlayerDelegate {
    
    static let defaultPlayer = DropbeatPlayer()

    private var player: STKAudioPlayer = STKAudioPlayer()
    override init() {
        super.init()
        self.player.delegate = self
        
        self.activateAudioSession()
        
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "applicationWillEnterForeground",
            name: UIApplicationWillEnterForegroundNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "audioSessionInterrupted:",
            name: AVAudioSessionInterruptionNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "audioSessionRouteChanged:",
            name: AVAudioSessionRouteChangeNotification, object: nil)
    }
    
    private var playbackLog: PlayLog?
    
    private func resetPlaybackLog(currentTime: Int?) {
        if let playbackLog = self.playbackLog {
            playbackLog.finished(currentTime)
            self.playbackLog = nil
        }
    }
    
    // MARK: - Play
    
    var currentTrack: Track? {
        didSet {
            let noti = NSNotification(name: DropbeatPlayerTrackChangedNotification, object: currentTrack, userInfo: nil)
            NSNotificationCenter.defaultCenter().postNotification(noti)
            
            if currentTrack == nil {
                self.currentThumbnail = UIImage(named: "default_cover_big")
            }
        }
    }
    private var _copiedPlaylist: Playlist?
    var currentPlaylist: Playlist? {
        get {
            return _copiedPlaylist
        }
        set {
            _copiedPlaylist = newValue?.copy()
            currentIndex = -1
        }
    }
    private var currentIndex = -1
    
    private func getIndexOfTrackWithId(id: String) -> Int {
        guard let currentPlaylist = self.currentPlaylist else {
            return -1
        }

        for (index,track) in currentPlaylist.tracks.enumerate() {
            if track.id == id {
                return index
            }
        }
        
        return self.currentIndex
    }
    
    func play(track: Track) {
        self.lastError = nil
        if self.state == .Disposed {
            let e = NSError(domain: "DropbeatPlayer", code: -713, userInfo: [NSLocalizedDescriptionKey:"플레이 요청하려 하는데 player가 dispose 되어 있는 상황이 실제로 발생합니다!"])
            Raygun.sharedReporter().sendError(e, withTags: ["정호가 로그 받을라고 가라로 만든 거"], withUserCustomData: ["data":"레이건에서 이거 튀어나오면 대박ㅋㅋㅋ"])
            self.player = STKAudioPlayer()
            self.player.delegate = self
        }
        
        if track.id == self.currentTrack?.id {
            self.currentTrack = track // to send notification
            return
        }
        
        self.state = .Buffering
        
        self.activateAudioSession()
        if track.type == .YOUTUBE {
            track.getYouTubeStreamURL() {
                (streamURL, duration, error) -> Void in
                if error != nil {
                    self.currentIndex = self.getIndexOfTrackWithId(track.id)
                    self.handleErrorAndPlayNextTrack(track, description: "can't start play: invalid youtube stream url")
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
        
        self.currentIndex = self.getIndexOfTrackWithId(queueItemId as! String)
        if currentIndex != -1 {
            let track = currentPlaylist!.tracks[currentIndex]
            self.currentTrack = track
            print("Starting track: \(track.title)")
        }
        
        self.didPlayStart()
    }
    
    private func didPlayStart() {
        guard let track = self.currentTrack else {
            return
        }
        
        if let thumbnailUrl = track.thumbnailUrl {
            SDWebImageManager.sharedManager().downloadImageWithURL(NSURL(string: thumbnailUrl), options: SDWebImageOptions.ContinueInBackground, progress: nil) {
                (image, error, cacheType, finished, imageURL) -> Void in
                self.currentThumbnail = image
            }
        } else {
            self.currentThumbnail = UIImage(named: "default_cover_big")
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
            next.getYouTubeStreamURL() {
                (streamURL, duration, error) -> Void in
                if error != nil {
                    next.postFailureLog("failed to enqueue track: invalid youtube stream url")
                    // remove this track and find new one.
                    self.currentPlaylist?.tracks.removeAtIndex(index)
                    self.enqueueNextTrack()
                    return
                }
                
                self.player.clearQueue()
                self.player.queue(streamURL!, withQueueItemId: next.id, duration: duration!)
                
                print("Enqueued track: \(next.title)")
            }
        } else {
            self.player.clearQueue()
            self.player.queue(next.streamUrl, withQueueItemId: next.id)
            
            print("Enqueued track: \(next.title)")
        }
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
    private func pickTrack(pick: _Pick) -> (Track, Int)? {
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
    
    func seekTo(var percent: Float) {
        if percent > 0.98 {
            percent = 0.98
        }
        let oldTime = self.progress
        let newTime = Double(percent) * self.duration
        self.player.seekToTime(newTime)
        
        if let log = self.playbackLog {
            log.seek(from: Int(oldTime), to: Int(newTime))
        }
    }
    
    func resume() {
        self.activateAudioSession()
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
        
        self.deactivateAudioSession()
    }
    
    // MARK: - Audio Session
    
    func audioSessionInterrupted(noti: NSNotification) {
        guard let userInfo = noti.userInfo,
            typeObj = userInfo[AVAudioSessionInterruptionTypeKey] as? NSNumber,
            type = AVAudioSessionInterruptionType(rawValue: typeObj.unsignedIntegerValue) else {
                return
        }
        
        switch type {
        case .Began:
            print("Audio session interruption begins.")
            self.pause()
            self.deactivateAudioSession()
        case .Ended:
            print("Audio session interruption ended.")
            if let option = userInfo[AVAudioSessionInterruptionOptionKey] as? NSNumber
                where .ShouldResume == AVAudioSessionInterruptionOptions(rawValue: option.unsignedIntegerValue) {
                    print("Resume after interruption.")
                    self.resume()
            } else {
                self.activateAudioSession()
            }
        }
    }
    
    func audioSessionRouteChanged(noti: NSNotification) {
        print(noti.userInfo)
        
        guard let userInfo = noti.userInfo,
            changeReasonObj = userInfo[AVAudioSessionRouteChangeReasonKey] as? NSNumber,
            changeReason = AVAudioSessionRouteChangeReason(rawValue: changeReasonObj.unsignedIntegerValue) else {
                return
        }
        
        switch changeReason {
        case .OldDeviceUnavailable:
            self.pause()
        default:
            break
        }
    }
    
    private func activateAudioSession() {
        let sharedInstance = AVAudioSession.sharedInstance()
        do {
            try sharedInstance.setCategory(AVAudioSessionCategoryPlayback)
            try sharedInstance.setActive(true)
        } catch let audioSessionError as NSError {
            print("Audio session error \(audioSessionError) \(audioSessionError.userInfo)")
        }
        
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
    }
    
    private func deactivateAudioSession() {
        let sharedInstance:AVAudioSession = AVAudioSession.sharedInstance()
        do {
            try sharedInstance.setActive(false)
        } catch let audioSessionError as NSError {
            print("Audio session error \(audioSessionError) \(audioSessionError.userInfo)")
        }
        
        UIApplication.sharedApplication().endReceivingRemoteControlEvents()
    }
    
    
    // MARK: - State change

    func applicationWillEnterForeground() {
        self.state = self.player.state
        self.activateAudioSession()
    }
    
    var state = STKAudioPlayerState.Ready {
        didSet {
            let noti = NSNotification(name: DropbeatPlayerStateChangedNotification, object: state.rawValue, userInfo: nil)
            NSNotificationCenter.defaultCenter().postNotification(noti)
        }
    }

    func audioPlayer(audioPlayer: STKAudioPlayer!, didFinishBufferingSourceWithQueueItemId queueItemId: NSObject!)
    {
        print("buffering finished")
    }
    
    func audioPlayer(audioPlayer: STKAudioPlayer!, stateChanged state: STKAudioPlayerState, previousState: STKAudioPlayerState)
    {
        self.state = state

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
 
    private func handleErrorAndPlayNextTrack(track: Track?, description: String) {
        print("Error!")
        
        let noti = NSNotification(name: DropbeatPlayerErrorNotification, object: (lastError ?? .Other).rawValue, userInfo: nil)
        NSNotificationCenter.defaultCenter().postNotification(noti)
        self.state = self.player.state
        
        if self.next() == false {
            if let track = self.currentTrack {
                self.play(track)
            }
        }

        track?.postFailureLog(description)
    }
    
    func audioPlayer(audioPlayer: STKAudioPlayer!, didFinishPlayingQueueItemId queueItemId: NSObject!, withReason stopReason: STKAudioPlayerStopReason, andProgress progress: Double, andDuration duration: Double)
    {
        print("Finish playing: \(stopReason.rawValue)")
        
        self.timer?.invalidate()
        self.timer = nil
        
        if stopReason == STKAudioPlayerStopReason.Error {
            self.handleErrorAndPlayNextTrack(self.currentTrack, description: "play finished with error: \(stopReason)")
        }
        
        self.currentTrack = nil
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
    private var currentThumbnail = UIImage(named: "default_cover_big")

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
    
    private var stateChangeCallCounter = 0
    
    private func changeState() {
        self.stateChangeCallCounter++
        
        dispatch_after(
            dispatch_time(DISPATCH_TIME_NOW, Int64(1 * NSEC_PER_SEC)),
            dispatch_get_main_queue()) { () in
                if self.stateChangeCallCounter == 1 {
                    self.player.clearQueue()
                    self.enqueueNextTrack()
                }
                
                self.stateChangeCallCounter--
        }
    }
    
    func changeRepeatState() {
        repeatState = repeatState.next()
        self.changeState()
    }
    
    func changeShuffleState() {
        shuffleState = shuffleState.toggle()
        self.changeState()
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

//enum QualityState: Int  {
//    case LQ = 0
//    case HQ = 1
//    
//    func toggle() -> QualityState {
//        switch self {
//        case .LQ: return .HQ
//        case .HQ: return .LQ
//        }
//    }
//}
