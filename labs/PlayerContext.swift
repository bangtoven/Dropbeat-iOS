//
//  PlayerContext.swift
//  labs
//
//  Created by Park Il Su on 2015. 5. 18..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import Foundation


class PlayerContext {
    static var currentTrackIdx: Int = -1
    static var currentPlaylistId: String?
    static var currentTrack: Track?
    static var repeatState = RepeatState.NOT_REPEAT
    static var shuffleState = ShuffleState.NOT_SHUFFLE
    static var playState = PlayState.STOPPED
    static var currentStreamUrls: [StreamSource] = []
    static var currentStreamCandidate: StreamSource?
    static var playlists: [Playlist] = []
    
    static func resetPlaylist(playlists: [Playlist]) {
        PlayerContext.playlists = playlists
    }
    
    static func changeRepeatState() {
        PlayerContext.repeatState = (PlayerContext.repeatState + 1) % 3
    }
    
    static func changeShuffleState() {
        PlayerContext.shuffleState = (PlayerContext.shuffleState + 1) % 2
    }
    
    static func pickNextTrack() -> Track? {
        var track :Track? = nil
        var playlist :Playlist? = getPlaylist(currentPlaylistId)
        let size = playlist?.tracks.count
        
        if currentTrackIdx == -1 || currentPlaylistId == nil{
            return nil;
        }
        
        if PlayerContext.shuffleState == ShuffleState.SHUFFLE {
            var idx = Int(arc4random_uniform(UInt32(size!)))
            track = playlist!.tracks[idx] as Track
        } else {
            var nextIdx :Int
            
            if PlayerContext.repeatState == RepeatState.NOT_REPEAT {
                nextIdx = currentTrackIdx + 1
                if (nextIdx < size) {
                    track = playlist!.tracks[nextIdx] as Track
                }
            } else if PlayerContext.repeatState == RepeatState.REPEAT_PLAYLIST {
                nextIdx = (currentTrackIdx + 1) % size!
                track = playlist!.tracks[nextIdx] as Track
            } else if PlayerContext.repeatState == RepeatState.REPEAT_ONE {
                track = playlist!.tracks[currentTrackIdx] as Track
            }
        }
        return track
    }
    
    static func pickPrevTrack() -> Track? {
        var track :Track? = nil
        var playlist :Playlist? = getPlaylist(currentPlaylistId)
        let size = playlist?.tracks.count
        
        if currentTrackIdx == -1 || currentPlaylistId == nil {
            return nil;
        }
        
        if PlayerContext.shuffleState == ShuffleState.SHUFFLE {
            var idx = Int(arc4random_uniform(UInt32(size!)))
            track = playlist!.tracks[idx] as Track
        } else {
            var prevIdx :Int
            
            if PlayerContext.repeatState == RepeatState.NOT_REPEAT {
                prevIdx = currentTrackIdx - 1
                if prevIdx >= 0 {
                    track = playlist!.tracks[prevIdx] as Track
                }
            } else if PlayerContext.repeatState == RepeatState.REPEAT_PLAYLIST {
                prevIdx = currentTrackIdx - 1
                if prevIdx <= 0 {
                    prevIdx = size! - 1
                }
                track = playlist!.tracks[prevIdx] as Track
            } else if PlayerContext.repeatState == RepeatState.REPEAT_ONE {
                track = playlist!.tracks[currentTrackIdx] as Track
            }
        }
        return track       
    }
    
    static func getPlaylist(playlistId: String?) -> Playlist? {
        for playlist: Playlist in PlayerContext.playlists {
            if playlist.id == playlistId {
                return playlist
            }
        }
        return nil
    }
}


class RepeatState {
    static var NOT_REPEAT = 0
    static var REPEAT_PLAYLIST = 1
    static var REPEAT_ONE = 2
}


enum ShuffleState {
    static var NOT_SHUFFLE = 0
    static var SHUFFLE = 1
}

enum PlayState {
    static var STOPPED = 0
    static var LOADING = 1
    static var PLAYING = 2
    static var PAUSED = 3
}