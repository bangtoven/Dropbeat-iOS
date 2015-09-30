//
//  Playlist.swift
//  labs
//
//  Created by Jungho Bang on 2015. 9. 25..
//  Copyright © 2015년 dropbeat. All rights reserved.
//

import UIKit

class Playlist {
    var id: String
    var name: String
    var tracks: [Track]
    var type:PlaylistType = PlaylistType.USER
    var dummy = false
    
    init(id: String, name: String, tracks: [Track]) {
        self.id = id
        self.name = name
        self.tracks = tracks
    }
    
    func getTrackIdx(track:Track) -> Int {
        for (idx, t): (Int, Track) in tracks.enumerate() {
            if t.id == track.id {
                return idx
            }
        }
        return -1
    }
    
    // Called with `fetchAllPlaylists`.
    static func parsePlaylists(data: AnyObject) -> [Playlist] {
        var json = JSON(data)
        var playlists :[Playlist] = []
        for (_, s): (String, JSON) in json["data"] {
            if let playlist = parsePlaylist(s) {
                playlist.dummy = true
                playlists.append(playlist)
            }
        }
        return playlists
    }
    
    static private func parsePlaylist(json: JSON) -> Playlist? {
        let playlistId: Int = json["id"].intValue
        let playlistName: String = json["name"].stringValue
        var tracks: [Track] = []
        for (_, s): (String, JSON) in json["data"] {
            var id: AnyObject
            if s["id"].string == nil {
                id = String(s["id"].int!)
            } else {
                id = s["id"].string!
            }
            tracks.append(
                Track(
                    id: id as! String,
                    title: s["title"].stringValue,
                    type: s["type"].string!
                )
            )
        }
        
        return Playlist(id: String(playlistId), name: playlistName, tracks: tracks)
    }
    
    static func parsePlaylist(data: AnyObject, key: String = "obj") -> Playlist? {
        return parsePlaylist(JSON(data)[key])
    }
    
    static func parseSharedPlaylist(data: AnyObject) -> Playlist? {
        var json = JSON(data)
        if !(json["success"].bool ?? false) || json["playlist"] == nil {
            return nil
        }
        return parsePlaylist(json["playlist"])
    }
    
    func toJson() -> Dictionary<String, AnyObject> {
        var playlist: Dictionary<String, AnyObject> = [
            "id": self.id,
            "name": self.name,
        ]
        
        var data: [Dictionary<String, AnyObject>] = []
        
        // Parse tracks to JSON like array.
        for t: Track in self.tracks {
            data.append([
                "id": t.id,
                "title": t.title,
                "type": t.type
                ])
        }
        playlist["data"] = data
        return playlist
    }
    
    func addTrack(track: Track, section:String, afterAdd: (error:NSError?) -> Void) {
        let tracks = self.tracks
        
        var dummyTracks = [[String:AnyObject]]()
        for t in tracks {
            if (track.id == t.id) {
                afterAdd(error: NSError(domain: "addTrack", code:101, userInfo: nil))
                return
            }
            dummyTracks.append(["title": t.title, "id": t.id, "type": t.type])
        }
        dummyTracks.append(["title": track.title, "id": track.id, "type": track.type])
        
        if Account.getCachedAccount() != nil {
            // Log to us
            Requests.logTrackAdd(track.title)
        }
        // Log to GA
        let tracker = GAI.sharedInstance().defaultTracker
        let event = GAIDictionaryBuilder.createEventWithCategory(
            "playlist-add-from-\(section)",
            action: "add-\(track.type)",
            label: track.title,
            value: 0
            ).build()
        
        tracker.send(event as [NSObject: AnyObject]!)
        
        Requests.setPlaylist(self.id, data: dummyTracks) {
            (request:NSURLRequest, response:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            
            if (error != nil) {
                afterAdd(error: error)
                return
            }
            var changedPlaylist:Playlist? = nil
            for p in PlayerContext.playlists {
                if (p.id == self.id) {
                    changedPlaylist = p
                    break
                }
            }
            if (changedPlaylist == nil) {
                afterAdd(error: nil)
                return
            }
            for t in changedPlaylist!.tracks {
                if (t.id == self.id) {
                    afterAdd(error: nil)
                    return
                }
            }
            changedPlaylist!.tracks.append(track)
            afterAdd(error: nil)
        }
    }
    
    func deleteTrack(track: Track, afterDelete: (error:NSError?) -> Void) {
        let tracks = self.tracks
        
        var dummyTracks = [[String:AnyObject]]()
        for t in tracks {
            if (t.id != track.id) {
                dummyTracks.append(["title": t.title, "id": t.id, "type": t.type])
            }
        }
        
        Requests.setPlaylist(self.id, data: dummyTracks) {
            (request:NSURLRequest, response:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            if (error != nil) {
                afterDelete(error: error)
                return
            }
            var playlist:Playlist? = nil
            for p in PlayerContext.playlists {
                if (p.id == self.id) {
                    playlist = p
                    break
                }
            }
            if (playlist == nil) {
                afterDelete(error: nil)
                return
            }
            var foundIdx:Int?
            for (idx, t) in playlist!.tracks.enumerate() {
                if (t.id == track.id) {
                    foundIdx = idx
                }
            }
            if (foundIdx == nil) {
                afterDelete(error: nil)
                return
            }
            playlist!.tracks.removeAtIndex(foundIdx!)
            
            // Update current PlayerContext with new index
            let playingTrack:Track? = PlayerContext.currentTrack
            if (playingTrack != nil &&
                PlayerContext.currentPlaylistId != nil &&
                PlayerContext.currentPlaylistId == self.id) {
                    for (idx, track) in playlist!.tracks.enumerate() {
                        if (track.id == playingTrack!.id) {
                            PlayerContext.currentTrackIdx = idx
                            break
                        }
                    }
            }
            afterDelete(error: nil)
        }
    }
}
