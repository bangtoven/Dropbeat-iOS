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
    
    static func fromJson(data: AnyObject) -> User {
        var json = JSON(data)
        return User(
                id: json["id"].string!,
                email: json["email"].string!,
                firstName: json["firstName"].string!,
                lastName: json["lastName"].string!,
                unlocked: json["unlock"].boolValue,
                createdAt: json["createdAt"].string!,
                fbId: json["fb_id"].string!
        )
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
    var formatNote: String
    var type: String
    
    init(url: String, formatNote: String, type: String) {
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
            if (drop.error == nil) {
                track.drop = s["drop"].stringValue
            }
            
            var dref = s["dref"]
            if (dref.error == nil) {
                track.dref = s["dref"].stringValue
            }
            
            var tag = s["tag"]
            if (tag.error == nil) {
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

class Account {
    var user:User?
    var token:String
    
    init(token:String, user:User?) {
        self.user = user
        self.token = token
    }
    
    static func getAccountWithCompletionHandler(handler:(account: Account?, error: NSError?) -> Void) {
        let keychainItemWrapper = KeychainItemWrapper(identifier: "net.dropbeat.spark", accessGroup:nil)
        let token:String? = keychainItemWrapper["auth_token"] as! String?
        if (token == nil) {
            handler(account: nil, error: NSError(domain: "account", code: 100, userInfo: nil))
            return
        }
        Requests.userSelf({ (request: NSURLRequest, response: NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            if (error != nil) {
                handler(account: nil, error:error)
                return
            }
            
            let res = result as! NSDictionary
            var success:Bool = res.objectForKey("success") as! Bool? ?? false
            if (!success) {
                var errorMsg:String? = res.objectForKey("error") as! String?
                handler(account:nil, error: NSError(domain: "account", code: 101, userInfo: nil))
                return
            }
            
            var userObj = res.objectForKey("user") as! NSDictionary
            let user = User(
                id: String(userObj.valueForKey("id") as! Int),
                email: userObj.valueForKey("last_name") as! String,
                firstName: userObj.valueForKey("first_name") as! String,
                lastName: userObj.valueForKey("last_name") as! String,
                unlocked: userObj.valueForKey("unlocked") as! Bool,
                createdAt: userObj.valueForKey("created_at") as! String,
                fbId: userObj.valueForKey("fb_id") as! String
            )
            var account = Account(token:token!, user:user)
            handler(account:account, error:nil)
        })
    }
}