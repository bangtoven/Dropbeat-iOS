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
    
    static private func parsePlaylistJson(playlistDict: JSON) -> Playlist? {
        let playlistId: Int = playlistDict["id"].intValue
        let playlistName: String = playlistDict["name"].stringValue
        var tracks: [Track] = []
        for (_, s): (String, JSON) in playlistDict["data"] {
            var id: AnyObject
            if s["id"].string == nil {
                id = String(s["id"].int!)
            } else {
                id = s["id"].string!
            }
            tracks.append(
                Track(
                    id: id as! String,
                    title: s["title"].string!,
                    type: s["type"].string!
                )
            )
        }
        
        return Playlist(
            id: String(playlistId), name: playlistName, tracks: tracks)
    }
    
    // Called with `fetchAllPlaylists`.
    static func parsePlaylists(data: AnyObject) -> [Playlist] {
        var json = JSON(data)
        var playlists :[Playlist] = []
        for (_, s): (String, JSON) in json["playlists"] {
            if let playlist = parsePlaylistJson(s) {
                playlists.append(playlist)
            }
        }
        return playlists
    }
    
    static func parsePlaylist(data: AnyObject, key: String = "obj") -> Playlist? {
        return parsePlaylistJson(JSON(data)[key])
    }
    
    static func parseSharedPlaylist(data: AnyObject) -> Playlist? {
        var json = JSON(data)
        if !(json["success"].bool ?? false) || json["playlist"] == nil {
            return nil
        }
        return parsePlaylistJson(json["playlist"])
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
}
