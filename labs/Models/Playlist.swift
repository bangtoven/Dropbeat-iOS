//
//  Playlist.swift
//  labs
//
//  Created by Jungho Bang on 2015. 9. 25..
//  Copyright © 2015년 dropbeat. All rights reserved.
//

import UIKit

enum PlaylistType {
    case EXTERNAL
    case SHARED
    case USER
}

extension Playlist {
    func copy() -> Playlist {
        let copied = Playlist(id: self.id, name: self.name, tracks: self.tracks)
        copied.type = self.type
        copied.dummy = self.dummy
        return copied
    }
}

func trackToDict(t: Track) -> [String:AnyObject] {
    return ["title": t.title, "id": t.id, "type": t.type.rawValue]
}

class Playlist {
    static var allPlaylists = [Playlist]()
    
    var id: String
    var name: String
    var tracks: [Track]
    var type = PlaylistType.USER
    var dummy = false
    
    init(id: String, name: String, tracks: [Track]) {
        self.id = id
        self.name = name
        self.tracks = tracks
    }
    
    func resolve(callback:((error:NSError?)->Void)) {
        guard dummy else {
            callback(error: nil)
            return
        }
        
        Requests.getPlaylist(id) { (result, error) -> Void in
            if (error != nil) {
                callback(error: error!)
                return
            }
            
            let playlist = Playlist.parsePlaylist(result!["playlist"])
            self.name = playlist.name
            self.tracks = playlist.tracks
            self.dummy = false
            
            callback(error: nil)
        }
    }
    
    static func fetchAllPlaylists(callback:(playlists:[Playlist]?, error:NSError?)->Void) {
        Requests.fetchPlaylistList() { (result, error) -> Void in
            if error != nil || result == nil {
                callback(playlists:nil, error: error)
                return
            }
            
            var playlists = [Playlist]()
            for (_, s): (String, JSON) in result!["data"] {
                let playlist = parsePlaylist(s)
                playlist.dummy = true
                playlists.append(playlist)
            }

            Playlist.allPlaylists = playlists.reverse()
            callback(playlists: Playlist.allPlaylists, error: nil)            
        }
    }
    
    static func parsePlaylist(json: JSON) -> Playlist {
        let playlistId: Int = json["id"].intValue
        let playlistName: String = json["name"].stringValue
        let tracks = Track.parseTracks(json["data"])
        
        return Playlist(id: String(playlistId), name: playlistName, tracks: tracks)
    }
    
    static func parseSharedPlaylist(json: JSON) -> Playlist? {
        return parsePlaylist(json["playlist"])
    }
    
    func toJson() -> [String:AnyObject] {
        var playlist: [String:AnyObject] = [
            "id": self.id,
            "name": self.name,
        ]
        
        playlist["data"] = tracks.map(trackToDict)
        return playlist
    }
    
    func addTrack(track: Track, section:String, afterAdd: (error:NSError?) -> Void) {
        if self.dummy {
            resolve({ (error) -> Void in
                if error != nil {
                    afterAdd(error: error)
                } else {
                    self.addTrack(track, section: section, afterAdd: afterAdd)
                }
            })
            return
        }
        
        if tracks.contains({ $0.id == track.id }) {
            afterAdd(error: NSError(
                domain: DropbeatRequestErrorDomain,
                code: -1,
                userInfo: nil))
            return
        }
        
        var newTracks = self.tracks // copy tracks array.
        newTracks.append(track)
        
        let newTracksDict = newTracks.map(trackToDict)
        
        Requests.setPlaylist(self.id, data: newTracksDict) { (result, error) -> Void in
            if (error != nil) {
                afterAdd(error: error)
                return
            }
            
            self.tracks.append(track)
            afterAdd(error: nil)
            
            // Log
            Requests.logTrackAdd(track.title)
            let event = GAIDictionaryBuilder.createEventWithCategory(
                "playlist-add-from-\(section)",
                action: "add-\(track.type)",
                label: track.title,
                value: 0
                ).build()
            GAI.sharedInstance().defaultTracker.send(event as [NSObject: AnyObject]!)
        }
    }
    
    func deleteTrack(track: Track, afterDelete: (error:NSError?) -> Void) {
        let newTracksDict = tracks.filter({ $0.id != track.id }).map(trackToDict)
        
        Requests.setPlaylist(self.id, data: newTracksDict) { (result, error) -> Void in
            if (error != nil) {
                afterDelete(error: error)
                return
            }
            
            if let index = self.tracks.indexOf({ $0.id == track.id }) {
                self.tracks.removeAtIndex(index)
            }
            afterDelete(error: nil)
        }
    }
    
    func setTracks(newTracks: [Track], callback: (error:NSError?) -> Void) {
        let newTracksDict = newTracks.map(trackToDict)
        
        Requests.setPlaylist(self.id, data: newTracksDict) { (result, error) -> Void in
            if (error != nil) {
                callback(error: error)
                return
            }
            
            self.tracks = newTracks
            callback(error: nil)
        }
    }
    
    static func importPlaylist(playlist:Playlist, callback: (playlist:Playlist?, error:NSError?) -> Void) {
        
        Requests.createPlaylist(playlist.name) { (result, error) -> Void in
            if (error != nil) {
                callback(playlist:nil, error: error)
                return
            }
            
            let importedPlaylist = Playlist.parsePlaylist(result!["obj"])
            importedPlaylist.tracks = playlist.tracks
            let tracksDict = importedPlaylist.tracks.map(trackToDict)
            
            Requests.setPlaylist(importedPlaylist.id, data: tracksDict) { (result, error) -> Void in
                if (error != nil) {
                    Requests.deletePlaylist(importedPlaylist.id) {_,_ in }
                    callback(playlist:nil, error: error)
                    return
                }
                
                Playlist.allPlaylists.append(importedPlaylist)
                callback(playlist:importedPlaylist, error:nil)
            }
        }
    }
}
