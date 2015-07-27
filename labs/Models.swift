//
//  Models.swift
//  labs
//
//  Created by Park Il Su on 2015. 5. 17..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

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
    
    func parseFeed(data: AnyObject) -> Feed {
        return Feed.fromJson(data, key: "feed")
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
        var playlistDict = JSON(data)
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

class SearchShowType {
    static var ROW = 0
    static var TAB = 1
}

class SearchSections {
    static var TOP_MATCH = "top_match"
    static var OFFICIAL = "released"
    static var PODCAST = "podcast"
    static var LIVESET = "liveset"
    static var RELEVANT = "relevant"
}


class Search {
    static var availableSections = [
        SearchSections.OFFICIAL,
        SearchSections.PODCAST,
        SearchSections.LIVESET,
        SearchSections.TOP_MATCH,
        SearchSections.RELEVANT
    ]
    
    var hasEvent:Bool = false
    var hasPodcast:Bool = false
    var hasLiveset:Bool = false
    var artistImage:String?
    var artistName:String?
    var sectionedTracks: [String:[Track]] = [String:[Track]]()
    var showType:Int = SearchShowType.ROW
    
    init (artistName:String?, artistImage:String?) {
        self.artistImage = artistImage
        self.artistName = artistName
        if (artistName == nil) {
            self.showType = SearchShowType.ROW
        } else {
            self.showType = SearchShowType.TAB
        }
    }
    
    func getConcatedSectionTracks () -> [Track] {
        var tracks = [Track]()
        if (sectionedTracks[SearchSections.TOP_MATCH] != nil) {
            for track in sectionedTracks[SearchSections.TOP_MATCH]! {
                tracks.append(track)
            }
        }
        if (sectionedTracks[SearchSections.RELEVANT] != nil) {
            for track in sectionedTracks[SearchSections.RELEVANT]! {
                tracks.append(track)
            }
        }
        return tracks
    }
    
    
    func fetchRelevant(callback:((tracks:[Track]?, error:NSError?) -> Void)) {
        let sectionTracks = sectionedTracks[SearchSections.RELEVANT]
        if (sectionTracks != nil) {
            callback(tracks: sectionTracks!, error: nil)
            return
        }
        if (artistName == nil) {
            callback(tracks: nil, error: NSError(domain: "search", code: 1, userInfo: nil))
            return
        }
        Requests.searchOther(artistName!, respCb: { (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            if (error != nil) {
                callback(tracks: nil, error: error)
                return
            }
            if (result == nil) {
                callback(tracks: [], error: nil)
                return
            }
            self.sectionedTracks[SearchSections.RELEVANT] = Search.parseTracks(result!, key: "data", secondKey:"tracks")
            callback(tracks:self.sectionedTracks[SearchSections.RELEVANT], error:nil)
        })
    }
    
    func fetchListset(callback:((tracks:[Track]?, error:NSError?) -> Void)) {
        let sectionTracks = sectionedTracks[SearchSections.LIVESET]
        if (sectionTracks != nil) {
            callback(tracks: sectionTracks!, error: nil)
            return
        }
        if (artistName == nil) {
            callback(tracks: nil, error: NSError(domain: "search", code: 1, userInfo: nil))
            return
        }
        if (!hasLiveset) {
            callback(tracks: [], error: nil)
            return
        }
        Requests.searchLiveset(artistName!, respCb: { (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            if (error != nil) {
                callback(tracks: nil, error: error)
                return
            }
            if (result == nil) {
                callback(tracks: [], error: nil)
                return
            }
            self.sectionedTracks[SearchSections.LIVESET] = Search.parseTracks(result!, key: "data")
            callback(tracks:self.sectionedTracks[SearchSections.LIVESET], error:nil)
        })
    }
    
    func fetchPodcast(callback:((tracks:[Track]?, error:NSError?) -> Void)) {
        let sectionTracks = sectionedTracks[SearchSections.PODCAST]
        if (sectionTracks != nil) {
            callback(tracks: sectionTracks!, error: nil)
            return
        }
        if (artistName == nil) {
            callback(tracks: nil, error: NSError(domain: "search", code: 1, userInfo: nil))
            return
        }
        if (!hasPodcast) {
            callback(tracks: [], error: nil)
            return
        }
        Requests.searchPodcast(artistName!, page: -1, respCb: { (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            if (error != nil) {
                callback(tracks: nil, error: error)
                return
            }
            if (result == nil) {
                callback(tracks: [], error: nil)
                return
            }
            var t = JSON(result!)
            if !t["success"].boolValue {
                callback(tracks: [], error: nil)
                return
            }
            
            var tracks = [Track]()
            for (idx: String, s:JSON) in t["data"] {
                var id = s["stream_url"].string
                var title = s["title"].string
                if (id == nil || title == nil) {
                    continue
                }
                var track = Track(
                    id: id!,
                    title: title!,
                    type: "podcast",
                    tag:nil
                )
                tracks.append(track)
            }
            self.sectionedTracks[SearchSections.PODCAST] = tracks
            callback(tracks:self.sectionedTracks[SearchSections.PODCAST], error:nil)
        })
    }
    
    static func fromJson(data: AnyObject, key: String) -> Search {
        
        var json = JSON(data)
        var artistImage:String?
        var artistName:String?
        var hasEvent:Bool
        var hasPodcast:Bool
        var hasLiveset:Bool
        var s = json[key]
        
        artistName = s["artist_name"].string
        artistImage = s["artist_image"].string
        hasEvent = s["has_event"].boolValue
        hasPodcast = s["has_podcast"].boolValue
        hasLiveset = artistName != nil
        
        var search = Search(artistName: artistName, artistImage: artistImage)
        search.hasEvent = hasEvent
        search.hasPodcast = hasPodcast
        search.hasLiveset = hasLiveset
       
        for (idx:String, s:JSON) in s["tracks"] {
            var id: AnyObject
            if s["id"].string == nil {
                if s["id"].int == nil {
                    continue
                }
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
            
            var topMatch = s["top_match"]
            if topMatch.error == nil {
                track.topMatch = s["top_match"].boolValue ?? false
            }
            
            if (track.type == "youtube") {
                track.thumbnailUrl = "http://img.youtube.com/vi/\(track.id)/mqdefault.jpg"
            } else {
                var artwork = s["artwork"]
                if artwork.error == nil {
                    track.thumbnailUrl = s["artwork"].stringValue
                }
            }
            
            if (track.tag == nil) {
                continue
            }
            
            var sectionName = track.tag!
            if track.topMatch! {
                sectionName = SearchSections.TOP_MATCH
            }
            if (search.sectionedTracks[sectionName] == nil) {
                search.sectionedTracks[sectionName] = []
            }
            search.sectionedTracks[sectionName]!.append(track)
        }
        return search
    }
    
    static func parseTracks(data: AnyObject, key: String, secondKey: String?=nil) -> [Track] {
        var tracks = [Track]()
        var t = JSON(data)
        var tracksObj:JSON
        if (!t["success"].boolValue || t[key] == nil) {
            return []
        }
        if (secondKey != nil) {
            tracksObj = t[key][secondKey!]
        } else {
            tracksObj = t[key]
        }
        for (idx:String, s:JSON) in tracksObj {
            var id: AnyObject
            if s["id"].string == nil {
                if s["id"].int != nil {
                    id = String(s["id"].int!)
                } else {
                    continue
                }
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
            
            var topMatch = s["top_match"]
            if topMatch.error == nil {
                track.topMatch = s["top_match"].boolValue ?? false
            }
            
            if (track.type == "youtube") {
                track.thumbnailUrl = "http://img.youtube.com/vi/\(track.id)/mqdefault.jpg"
            } else {
                var artwork = s["artwork"]
                if artwork.error == nil {
                    track.thumbnailUrl = s["artwork"].stringValue
                }
            }
            
            if (track.tag == nil) {
                continue
            }
            tracks.append(track)
        }
        return tracks
    }
}

class Feed {
    var result: [Track] = []
    init (tracks: [Track]) {
        self.result = tracks
    }
    
    static func fromJson(data: AnyObject, key: String) -> Feed {
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
            
            var topMatch = s["top_match"]
            if topMatch.error == nil {
                track.topMatch = s["top_match"].boolValue
            }
            
            if (track.type == "youtube") {
                track.thumbnailUrl = "http://img.youtube.com/vi/\(track.id)/mqdefault.jpg"
            } else {
                var artwork = s["artwork"]
                if artwork.error == nil {
                    track.thumbnailUrl = s["artwork"].stringValue
                }
            }
            
            
            tracks.append(track)
        }
        var feed = Feed(tracks: tracks)
        return feed
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
    var topMatch: Bool?
    
    init(id: String, title: String, type: String, tag: String? = nil, thumbnailUrl: String? = nil, drop: String? = nil, dref: String? = nil, topMatch: Bool? = false) {
        self.id = id
        self.title = title
        self.drop = drop
        self.type = type
        self.dref = dref
        self.tag = tag
        self.thumbnailUrl = thumbnailUrl
        self.topMatch = topMatch
    }
}

class ChannelPlaylist {
    var name:String
    var uid: String
    init (uid: String, name: String) {
        self.name = name
        self.uid = uid
    }
}

class Channel {
    var uid: String?
    var thumbnail: String?
    var name :String
    var genre: [String]
    var playlists: [ChannelPlaylist]
    var isBookmarked:Bool
    
    init(uid: String, name: String, thumbnail: String? = nil) {
        self.uid = uid
        self.name = name
        self.thumbnail = thumbnail
        self.playlists = [ChannelPlaylist]()
        self.genre = []
        self.isBookmarked = false
    }
    
    init(name: String, thumbnail: String? = nil, genre: [String],
            playlists: [ChannelPlaylist]) {
        self.uid = nil
        self.name = name
        self.thumbnail = thumbnail
        self.playlists = playlists
        self.genre = genre
        self.isBookmarked = false
    }
    
    static func fromListJson(data: AnyObject, key: String) -> [Channel] {
        var json = JSON(data)
        var channels: [Channel] = []
        for (idx: String, s: JSON) in json[key] {
            if (s["uid"].error != nil || s["name"].error != nil) {
                continue
            }
            var uid: String = s["uid"].stringValue
            var name: String = s["name"].stringValue
            var thumbnail: String? = nil
            if (s["thumbnail"].error == nil) {
                thumbnail = s["thumbnail"].stringValue
            }
            channels.append(Channel(uid:uid, name: name, thumbnail: thumbnail))
        }
        return channels
    }
    
    static func fromDetailJson(data: AnyObject, key: String) -> Channel? {
        var json = JSON(data)
        var detail = json[key]
        if (detail["channel_name"].error != nil) {
            return nil
        }
        var name = detail["channel_name"].stringValue
        var thumbnail:String?
        if (detail["channel_thumbnail"].error == nil) {
            thumbnail = detail["channel_thumbnail"].stringValue
        }
        var genreArray:[String] = []
        if (detail["genre"].error == nil) {
            var genres = detail["genre"]
            for (idx: String, g: JSON) in genres {
                genreArray.append(g.stringValue)
            }
        }
        var playlists = [ChannelPlaylist]()
        if (detail["uploads"].error == nil) {
            playlists.append(ChannelPlaylist(uid: detail["uploads"].stringValue, name: "RECENT"))
        }
        if (detail["playlist"].error == nil) {
            for (idx: String, s:JSON) in detail["playlist"] {
                if (s["uid"].error == nil && s["title"].error == nil) {
                    playlists.append(ChannelPlaylist(uid:s["uid"].stringValue, name: s["title"].stringValue))
                }
            }
        }
        return Channel(name:name, thumbnail: thumbnail, genre:genreArray, playlists: playlists)
    }
}

class Account {
    var user:User?
    var token:String
    
    init(token:String, user:User?) {
        self.user = user
        self.token = token
    }
    
    static private var account:Account?
    
    static func signout() {
        let keychainItemWrapper = KeychainItemWrapper(identifier: "net.dropbeat.spark", accessGroup:nil)
        keychainItemWrapper["auth_token"] = nil
        Account.account = nil
        let appDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.account = nil
        CenterViewController.sharedInstance!.resignObservers()
        var navController:UINavigationController = appDelegate.window?.rootViewController as! UINavigationController
        navController.popToRootViewControllerAnimated(false)
    }
    
    static func getCachedAccount() -> Account? {
        return account
    }
    
    static func getAccountWithCompletionHandler(handler:(account: Account?, error: NSError?) -> Void) {
        let keychainItemWrapper = KeychainItemWrapper(identifier: "net.dropbeat.spark", accessGroup:nil)
        let token:String? = keychainItemWrapper["auth_token"] as! String?
        if (token == nil) {
            handler(account: nil, error: nil)
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
                email: userObj.valueForKey("email") as! String,
                firstName: userObj.valueForKey("first_name") as! String,
                lastName: userObj.valueForKey("last_name") as! String,
                unlocked: userObj.valueForKey("unlocked") as! Bool,
                createdAt: userObj.valueForKey("created_at") as! String,
                fbId: userObj.valueForKey("fb_id") as! String
            )
            var account = Account(token:token!, user:user)
            self.account = account
            handler(account:account, error:nil)
        })
    }
}