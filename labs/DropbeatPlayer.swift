//
//  DropbeatPlayer.swift
//  AVPlayerTest
//
//  Created by 방정호 on 2015. 10. 7..
//  Copyright © 2015년 방정호. All rights reserved.
//

import UIKit

extension Track {
    func getYoutubeStreamURL(quality:XCDYouTubeVideoQuality, callback:(streamURL:String?, error:NSError?)->Void) {
        guard self.type == .YOUTUBE else {
            let error = NSError(domain: "TrackYoutubeStreamURL", code: -1, userInfo: nil)
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
                let e = NSError(domain: "TrackYoutubeStreamURL", code: -2, userInfo: nil)
                callback(streamURL: nil, error: e)
            }
        })
    }
}

class DropbeatPlayer: NSObject, STKAudioPlayerDelegate {

    private static var _singleton: DropbeatPlayer?
    static func sharedPlayer() -> DropbeatPlayer {
        if _singleton == nil {
            _singleton = DropbeatPlayer()
        }
        
        return _singleton!
    }
    
    private var player: STKAudioPlayer = STKAudioPlayer()
    override init() {
        super.init()
        self.player.delegate = self
    }
    
    var lastError: STKAudioPlayerErrorCode?
    
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
    
    enum ErrorCode:UInt32 {
        case None = 0
        case DataSource
        case StreamParseBytesFailed
        case AudioSystemError
        case CodecError
        case DataNotFound
        case Other = 0xffff
    }
    
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
    
//    private let player = AVPlayer()
//    
//    func play(urlString: String) {
//        
//        if let url = NSURL(string: urlString) {
//            let item = AVPlayerItem(URL: url)
//            self.player.replaceCurrentItemWithPlayerItem(item)
//            self.player.play()
//        }
//    }

}
