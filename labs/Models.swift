//
//  Models.swift
//  labs
//
//  Created by Park Il Su on 2015. 5. 17..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import Foundation
import SwiftyJSON

class Parser {
    // Called with `fetchAllPlaylists`.
    func parsePlaylists(data: AnyObject) -> [Playlist] {
        var json = JSON(data)
        var playlists :[Playlist] = []
        for (idx: String, s: JSON) in json["playlists"] {
            playlists.append(
                Playlist.fromJson(s.rawValue)
            )
        }
        return playlists
    }
    
    func parseSearch(data: AnyObject) -> Search {
        return Search.fromJson(data, key: "data")
    }
    
    func parseFeed(data: AnyObject) -> Search {
        return Search.fromJson(data, key: "feed")
    }
}


class User {
    var id: String
    var email: String
    var firstName: String
    var lastName: String
    var unlocked: Bool
    var createdAt: String
    var fbId: String
    
    init(id: String, email: String, firstName: String, lastName: String,
            unlocked: Bool, createdAt: String, fbId: String) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.unlocked = unlocked
        self.createdAt = createdAt
        self.fbId = fbId
    }
}


class Playlist {
    var id: String
    var name: String
    var tracks: [Track]
    
    init(id: String, name: String, tracks: [Track]) {
        self.id = id
        self.name = name
        self.tracks = tracks
    }
    
    static func fromJson(data: AnyObject) -> Playlist {
        var json = JSON(data)
        var playlistDict = json["playlist"]
        var playlistId: Int = playlistDict["id"].intValue
        var playlistName: String = playlistDict["name"].stringValue
        var tracks: [Track] = []
        for (idx: String, s: JSON) in playlistDict["data"] {
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
    
    func toJson() -> JSON {
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
        return JSON(playlist)
    }
}


class StreamSource {
    var url: String
    var formatNote: String?
    var type: String?
    
    init(url: String, type: String? = nil, formatNote: String? = nil) {
        self.url = url
        self.formatNote = formatNote
        self.type = type
    }
}


class Search {
    var result: [Track] = []
    init (tracks: [Track]) {
        self.result = tracks
    }
    
    static func fromJson(data: AnyObject, key: String) -> Search {
        var json = JSON(data)
        var tracks: [Track] = []
        for (idx: String, s: JSON) in json[key] {
            var id: AnyObject
            if s["id"].string == nil {
                id = String(s["id"].int!)
            } else {
                id = s["id"].string!
            }
            
            var track = Track(
                id: id as! String,
                title: s["title"].stringValue,
                type: s["type"].stringValue,
                tag: s["tag"].stringValue
            )
            var drop = s["drop"]
            if drop.error == nil {
                track.drop = s["drop"].stringValue
            }
            
            var dref = s["dref"]
            if dref.error == nil {
                track.dref = s["dref"].stringValue
            }
            
            var tag = s["tag"]
            if tag.error == nil {
                track.tag = s["tag"].stringValue
            }
            
            tracks.append(track)
        }
        var search = Search(tracks: tracks)
        return search
    }
}


class Track {
    var id: String
    var title: String
    var type: String
    var tag: String?
    var drop: String?
    var dref: String?
    var thumbnailUrl: String?
    var isTopMatch: Bool?
    
    init(id: String, title: String, type: String, tag: String? = nil, thumbnailUrl: String? = nil, drop: String? = nil, dref: String? = nil, isTopMatch: Bool? = false) {
        self.id = id
        self.title = title
        self.drop = drop
        self.type = type
        self.dref = dref
        self.tag = tag
        self.thumbnailUrl = thumbnailUrl
        self.isTopMatch = isTopMatch
    }
}