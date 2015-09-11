//
//  Models.swift
//  labs
//
//  Created by Park Il Su on 2015. 5. 17..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class User {
    var id: String
    var email: String
    var firstName: String
    var lastName: String
    var fbId: String?
    var nickname:String
    
    init(id: String, email: String, firstName: String, lastName: String,
            nickname:String, fbId: String?) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.fbId = fbId
        self.nickname = nickname
    }
    
    static private func fromJson(data: AnyObject) -> User {
        var json = JSON(data)
        var fbId:String?
        if json["fb_id"].string != nil && count(json["fb_id"].stringValue) > 0 {
            fbId = json["fb_id"].stringValue
        }
        return User(
                id: json["id"].stringValue,
                email: json["email"].stringValue,
                firstName: json["firstName"].stringValue,
                lastName: json["lastName"].stringValue,
                nickname: json["nickname"].stringValue,
                fbId: fbId
        )
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
    var idx:Int?
    
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
    
    static func parseChannelList(data: AnyObject) -> [Channel] {
        var json = JSON(data)
        var channels: [Channel] = []
        var index = 0
        for (idx: String, s: JSON) in json["data"] {
            if (s["uid"].error != nil || s["name"].error != nil) {
                continue
            }
            var uid: String = s["uid"].stringValue
            var name: String = s["name"].stringValue
            var thumbnail: String? = nil
            if (s["thumbnail"].error == nil) {
                thumbnail = s["thumbnail"].stringValue
            }
            let c = Channel(uid:uid, name: name, thumbnail: thumbnail)
            c.idx = index
            channels.append(c)
        }
        return channels
    }
    
    static func parseChannel(data: AnyObject) -> Channel? {
        var json = JSON(data)
        var detail = json["data"]
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

class Artist {
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
                
                var drop:Drop?
                var dropObj = s["drop"]
                if dropObj != nil && dropObj["dref"].string != nil &&
                    count(dropObj["dref"].stringValue) > 0 &&
                    dropObj["type"].string != nil {
                        
                        drop = Drop(
                            dref: dropObj["dref"].stringValue,
                            type: dropObj["type"].stringValue,
                            when: dropObj["when"].int)
                }
                track.drop = drop
                
                tracks.append(track)
            }
            self.sectionedTracks[SearchSections.PODCAST] = tracks
            callback(tracks:self.sectionedTracks[SearchSections.PODCAST], error:nil)
        })
    }
    
    static private func fromJson(data: AnyObject, key: String) -> Search {
        
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
            
            var dropObj = s["drop"]
            if dropObj != nil && dropObj["dref"].string != nil &&
                count(dropObj["dref"].stringValue) > 0 &&
                dropObj["type"].string != nil {
                    track.drop = Drop(
                        dref: dropObj["dref"].stringValue,
                        type: dropObj["type"].stringValue,
                        when: dropObj["when"].int)
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
            
            var dropObj = s["drop"]
            if dropObj != nil && dropObj["dref"].string != nil &&
                count(dropObj["dref"].stringValue) > 0 &&
                dropObj["type"].string != nil {
                    track.drop = Drop(
                        dref: dropObj["dref"].stringValue,
                        type: dropObj["type"].stringValue,
                        when: dropObj["when"].int)
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
        for (idx:Int, t:Track) in enumerate(tracks) {
            if t.id == track.id {
                return idx
            }
        }
        return -1
    }
    
    static private func fromJson(data: AnyObject) -> Playlist? {
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
    
    // Called with `fetchAllPlaylists`.
    static func parsePlaylists(data: AnyObject) -> [Playlist] {
        var json = JSON(data)
        var playlists :[Playlist] = []
        for (idx: String, s: JSON) in json["playlists"] {
            if let playlist = Playlist.fromJson(s.rawValue) {
                playlists.append(playlist)
            }
        }
        return playlists
    }
    
    static func parsePlaylist(data: AnyObject, key: String = "obj") -> Playlist? {
        return Playlist.fromJson(JSON(data)[key].rawValue)
    }
    
    static func parseSharedPlaylist(data: AnyObject) -> Playlist? {
        var json = JSON(data)
        if !(json["success"].bool ?? false) || json["playlist"] == nil {
            return nil
        }
        return Playlist.fromJson(json["playlist"].rawValue)
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
                
                var drop:Drop?
                var dropObj = s["drop"]
                if dropObj != nil && dropObj["dref"].string != nil &&
                    count(dropObj["dref"].stringValue) > 0 &&
                    dropObj["type"].string != nil {
                    
                    drop = Drop(
                        dref: dropObj["dref"].stringValue,
                        type: dropObj["type"].stringValue,
                        when: dropObj["when"].int)
                }
                track.drop = drop
            
                tracks.append(track)
            }
            self.sectionedTracks[SearchSections.PODCAST] = tracks
            callback(tracks:self.sectionedTracks[SearchSections.PODCAST], error:nil)
        })
    }
    
    static private func fromJson(data: AnyObject, key: String) -> Search {
        
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
            
            var dropObj = s["drop"]
            if dropObj != nil && dropObj["dref"].string != nil &&
                count(dropObj["dref"].stringValue) > 0 &&
                dropObj["type"].string != nil {
                track.drop = Drop(
                    dref: dropObj["dref"].stringValue,
                    type: dropObj["type"].stringValue,
                    when: dropObj["when"].int)
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
    
    static func parseSearch(data: AnyObject) -> Search {
        return Search.fromJson(data, key: "data")
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
            
            var dropObj = s["drop"]
            if dropObj != nil && dropObj["dref"].string != nil &&
                count(dropObj["dref"].stringValue) > 0 &&
                dropObj["type"].string != nil {
                track.drop = Drop(
                    dref: dropObj["dref"].stringValue,
                    type: dropObj["type"].stringValue,
                    when: dropObj["when"].int)
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
    
    static private func fromJson(data: AnyObject, key: String) -> Feed {
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
            
            var dropObj = s["drop"]
            if dropObj != nil && dropObj["dref"].string != nil &&
                count(dropObj["dref"].stringValue) > 0 &&
                dropObj["type"].string != nil {
                track.drop = Drop(
                    dref: dropObj["dref"].stringValue,
                    type: dropObj["type"].stringValue,
                    when: dropObj["when"].int)
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
    
    static func parseFeed(data: AnyObject) -> Feed {
        return Feed.fromJson(data, key: "feed")
    }
}

class BeatportChart {
    var success:Bool
    var results:[BeatportTrack]?
    init(success:Bool, tracks:[BeatportTrack]?) {
        self.success = success
        self.results = tracks
    }
    
    static func parseBeatportChart(data: AnyObject) -> BeatportChart {
        return BeatportChart.fromJson(data, key: "data")
    }
    
    static private func fromJson(data:AnyObject, key:String) -> BeatportChart {
        var json = JSON(data)
        
        if !(json["success"].bool ?? false) {
            return BeatportChart(success:false, tracks:nil)
        }
        
        var dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        var tracks:[BeatportTrack] = [BeatportTrack]()
        for (idx:String, s:JSON) in json["data"] {
            if s["artist_name"].string == nil {
                continue
            }
            let artist = s["artist_name"].stringValue
            
            if s["youtube_uid"].string == nil {
                continue
            }
            let uid = s["youtube_uid"].stringValue
            
            if s["track_name"].string == nil {
                continue
            }
            let trackName = s["track_name"].stringValue
            
            if s["thumbnail"].string == nil {
                continue
            }
            let thumbnailUrl = s["thumbnail"].stringValue
            
            if s["released"].string == nil {
                continue
            }
            var releasedAtStr = s["released"].stringValue
            var releasedAt:NSDate?
            if releasedAtStr.length >= 10 {
                releasedAt = dateFormatter.dateFromString(releasedAtStr.subString(0, length: 10))
            }
            
            var drop:Drop?
            var dropObj = s["drop"]
            if dropObj != nil && dropObj["dref"].string != nil &&
                count(dropObj["dref"].stringValue) > 0 &&
                dropObj["type"].string != nil {
                    
                drop = Drop(
                    dref: dropObj["dref"].stringValue,
                    type: dropObj["type"].stringValue,
                    when: dropObj["when"].int)
            }
            
            let track = BeatportTrack(
                id: uid,
                trackName: trackName,
                artist: artist,
                type: "youtube",
                thumbnailUrl: thumbnailUrl,
                mixType: s["mix_type"].string,
                genre: s["genre"].string,
                label: s["label"].string,
                releasedAt:releasedAt)
            
            track.drop = drop
            
            tracks.append(track)
        }
        return BeatportChart(success: true, tracks:tracks)
    }
}

class StreamNew {
    var success:Bool
    var results:[NewReleaseTrack]?
    init(success: Bool, tracks:[NewReleaseTrack]?) {
        self.success = success
        results = tracks
    }
    
    static private func fromJson(data:AnyObject, key:String) ->StreamNew {
        var json = JSON(data)
        if !(json["success"].bool ?? false) || json[key] == nil {
            return StreamNew(success: false, tracks: nil)
        }
        
        var tracks:[NewReleaseTrack] = []
        var formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        for (idx:String, s:JSON) in json[key] {
            if s["id"].string == nil ||
                    s["track_name"].string == nil ||
                    s["type"].string == nil ||
                    s["artist_name"].string == nil ||
                    s["release_date"].string == nil ||
                    s["thumbnail"].string == nil {
                continue
            }
            
            var releasedAtStr = s["release_date"].stringValue
            var releasedAt:NSDate?
            if releasedAtStr.length >= 10 {
                releasedAt = formatter.dateFromString(releasedAtStr.subString(0, length: 10))
            }
            
            var track = NewReleaseTrack(
                id: s["id"].stringValue,
                trackName: s["track_name"].stringValue,
                artist: s["artist_name"].stringValue,
                type: s["type"].stringValue,
                thumbnail: s["thumbnail"].stringValue,
                releasedAt: releasedAt
            )
            
            var drop:Drop?
            var dropObj = s["drop"]
            if dropObj != nil && dropObj["dref"].string != nil &&
                count(dropObj["dref"].stringValue) > 0 &&
                dropObj["type"].string != nil {
                    
                drop = Drop(
                    dref: dropObj["dref"].stringValue,
                    type: dropObj["type"].stringValue,
                    when: dropObj["when"].int)
            }
            track.drop = drop
            
            tracks.append(track)
        }
        
        return StreamNew(success: true, tracks: tracks)
    }
    
    static func parseStreamNew(data: AnyObject) -> StreamNew {
        return StreamNew.fromJson(data, key: "data")
    }
}

class StreamTrending {
    var success:Bool
    var results:[TrendingTrack]?
    init(success: Bool, tracks:[TrendingTrack]?) {
        self.success = success
        results = tracks
    }
    
    static private func fromJson(data:AnyObject, key:String) -> StreamTrending {
        var json = JSON(data)
        if !(json["success"].bool ?? false) || json[key] == nil {
            return StreamTrending(success: false, tracks: nil)
        }
        
        var tracks:[TrendingTrack] = []
        var formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        for (idx:String, s:JSON) in json[key] {
            if s["id"].string == nil ||
                    s["track_name"].string == nil ||
                    s["type"].string == nil ||
                    s["artist_name"].string == nil ||
                    s["snippet"].string == nil {
                continue
            }
            
            
            var track = TrendingTrack(
                id: s["id"].stringValue,
                trackName: s["track_name"].stringValue,
                artist: s["artist_name"].stringValue,
                type: s["type"].stringValue,
                snippet:s["snippet"].stringValue
            )
            
            var drop:Drop?
            var dropObj = s["drop"]
            if dropObj != nil && dropObj["dref"].string != nil &&
                count(dropObj["dref"].stringValue) > 0 &&
                dropObj["type"].string != nil {
                    
                drop = Drop(
                    dref: dropObj["dref"].stringValue,
                    type: dropObj["type"].stringValue,
                    when: dropObj["when"].int)
            }
            track.drop = drop
            
            tracks.append(track)
        }
        
        return StreamTrending(success: true, tracks: tracks)
    }
    
    static func parseStreamTrending(data: AnyObject) -> StreamTrending {
        return StreamTrending.fromJson(data, key: "data")
    }
}

class StreamBeatportTrending {
    var success:Bool
    var results:[BeatportTrack]?
    init(success: Bool, tracks:[BeatportTrack]?) {
        self.success = success
        results = tracks
    }
    
    static private func fromJson(data:AnyObject, key:String) -> StreamBeatportTrending {
        var json = JSON(data)
        
        if !(json["success"].bool ?? false) {
            return StreamBeatportTrending(success:false, tracks:nil)
        }
        
        var dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        var tracks:[BeatportTrack] = [BeatportTrack]()
        for (idx:String, s:JSON) in json["data"] {
            if s["artist_name"].string == nil {
                continue
            }
            let artist = s["artist_name"].stringValue
            
            if s["youtube_uid"].string == nil {
                continue
            }
            let uid = s["youtube_uid"].stringValue
            
            if s["track_name"].string == nil {
                continue
            }
            let trackName = s["track_name"].stringValue
            
            if s["thumbnail"].string == nil {
                continue
            }
            let thumbnailUrl = s["thumbnail"].stringValue
            
            if s["released"].string == nil {
                continue
            }
            var releasedAtStr = s["released"].stringValue
            var releasedAt:NSDate?
            if releasedAtStr.length >= 10 {
                releasedAt = dateFormatter.dateFromString(releasedAtStr.subString(0, length: 10))
            }
            
            
            let track = BeatportTrack(
                id: uid,
                trackName: trackName,
                artist: artist,
                type: "youtube",
                thumbnailUrl: thumbnailUrl,
                mixType: s["mix_type"].string,
                genre: s["genre"].string,
                label: s["label"].string,
                releasedAt:releasedAt)
            
            var drop:Drop?
            var dropObj = s["drop"]
            if dropObj != nil && dropObj["dref"].string != nil &&
                count(dropObj["dref"].stringValue) > 0 &&
                dropObj["type"].string != nil {
                    
                drop = Drop(
                    dref: dropObj["dref"].stringValue,
                    type: dropObj["type"].stringValue,
                    when: dropObj["when"].int)
            }
            track.drop = drop
            
            tracks.append(track)
        }
        return StreamBeatportTrending(success: true, tracks: tracks)
    }
    
    static func parseStreamBeatportTrending(data: AnyObject) -> StreamBeatportTrending {
        return StreamBeatportTrending.fromJson(data, key: "data")
    }
}

class StreamFollowing {
    var success:Bool
    var results:[FollowingArtistTrack]?
    init(success: Bool, tracks:[FollowingArtistTrack]?) {
        self.success = success
        results = tracks
    }
    
    static private func fromJson(data:AnyObject, key:String) -> StreamFollowing {
        var json = JSON(data)
        
        if !(json["success"].bool ?? false) {
            return StreamFollowing(success:false, tracks:nil)
        }
        
        var dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        var tracks:[FollowingArtistTrack] = [FollowingArtistTrack]()
        
        for (idx:String, s:JSON) in json[key] {
            if s["id"].string == nil {
                continue
            }
            let id = s["id"].stringValue
            
            if s["dj"].string == nil {
                continue
            }
            let artist = s["dj"].stringValue
            
            if s["type"].string == nil {
                continue
            }
            let type = s["type"].stringValue
            
            if s["title"].string == nil {
                continue
            }
            let title = s["title"].stringValue
            
            var releasedAt:NSDate?
            if let releasedAtStr = s["release_date"].string {
                if releasedAtStr.length >= 10 {
                    releasedAt = dateFormatter.dateFromString(releasedAtStr.subString(0, length: 10))
                }
            }
            
            var thumbnail:String?
            if let url = s["thumbnail"].string {
                thumbnail = url
            } else if type == "youtube" {
                thumbnail = "http://img.youtube.com/vi/\(id)/mqdefault.jpg"
            }
            
            var track = FollowingArtistTrack(
                id: id,
                trackName: title,
                artist: artist,
                type: type,
                thumbnail: thumbnail,
                releasedAt: releasedAt
            )
            
            var drop:Drop?
            var dropObj = s["drop"]
            if dropObj != nil && dropObj["dref"].string != nil &&
                count(dropObj["dref"].stringValue) > 0 &&
                dropObj["type"].string != nil {
                    
                drop = Drop(
                    dref: dropObj["dref"].stringValue,
                    type: dropObj["type"].stringValue,
                    when: dropObj["when"].int)
            }
            track.drop = drop
            
            tracks.append(track)
        }
        return StreamFollowing(success: true, tracks: tracks)
    }
    
    static func parseStreamFollowing(data: AnyObject) -> StreamFollowing {
        return StreamFollowing.fromJson(data, key: "data")
    }
}

class StreamFriend {
    var success:Bool
    var results:[FriendTrack]?
    init(success: Bool, tracks:[FriendTrack]?) {
        self.success = success
        results = tracks
    }
    
    static private func fromJson(data:AnyObject) -> StreamFriend {
        var json = JSON(data)
        
        if !(json["success"].bool ?? false) {
            return StreamFriend(success:false, tracks:nil)
        }
        
        if json["data"] == nil || json["data"]["tracks"] == nil {
            return StreamFriend(success:false, tracks:nil)
        }
        
        let dataObj = json["data"]
        
        var tracks = [FriendTrack]()
        
        for(idx:String, s:JSON) in dataObj["tracks"] {
            if s["id"].string == nil ||
                    s["nickname"].string == nil ||
                    s["release_date"].string == nil ||
                    s["ts"].int == nil ||
                    s["artist_name"].string == nil ||
                    s["track_name"].string == nil ||
                    s["genre"].string == nil ||
                    s["type"].string == nil {
                continue
            }
            
            let track = FriendTrack(
                nickname:s["nickname"].stringValue,
                id:s["id"].stringValue,
                trackName: s["track_name"].stringValue,
                type: s["type"].stringValue,
                artistName: s["artist_name"].stringValue,
                ts: s["ts"].intValue,
                genre:s["genre"].stringValue,
                thumbnail:s["thumbnail"].string
            )
            
            var drop:Drop?
            var dropObj = s["drop"]
            if dropObj != nil && dropObj["dref"].string != nil &&
                count(dropObj["dref"].stringValue) > 0 &&
                dropObj["type"].string != nil {
                    
                drop = Drop(
                    dref: dropObj["dref"].stringValue,
                    type: dropObj["type"].stringValue,
                    when: dropObj["when"].int)
            }
            track.drop = drop
            
            tracks.append(track)
        }
        return StreamFriend(success:true, tracks:tracks)
    }
    
    static func parseStreamFriend(data: AnyObject) -> StreamFriend {
        return StreamFriend.fromJson(data)
    }

}

class Drop {
    var type:String
    var dref:String
    var when:Int?
    init (dref:String, type:String, when:Int?) {
        self.type = type
        self.dref = dref
        self.when = when
    }
}

class Track {
    var id: String
    var title: String
    var type: String
    var tag: String?
    var drop: Drop?
    var dref: String?
    var thumbnailUrl: String?
    var topMatch: Bool?
    var rank: Int
    var hasHqThumbnail:Bool {
        get {
            if self.thumbnailUrl == nil {
                return false
            }
            if self.thumbnailUrl!.indexOf("http://img.youtube.com") >= 0 {
                return false
            }
            return true
        }
    }
    
    var isLiked: Bool {
        get {
            if let account = Account.getCachedAccount() {
                return account.likedTrackIds.contains(self.id)
            }
            return false
        }
    }
    
    init(id: String, title: String, type: String, tag: String? = nil,
            thumbnailUrl: String? = nil, drop: Drop? = nil,
            dref: String? = nil, topMatch: Bool? = false) {
        self.id = id
        self.title = title
        self.drop = drop
        self.type = type
        self.dref = dref
        self.tag = tag
        self.thumbnailUrl = thumbnailUrl
        self.topMatch = topMatch
        self.rank = -1
    }
    
    static func parseSharedTrack(data: AnyObject) -> Track? {
        var json = JSON(data)
        if !(json["success"].bool ?? false) {
            return nil
        }
        var s:JSON?
        if json["data"] != nil {
            s = json["data"]
        } else {
            s = json["obj"]
        }
        
        if s == nil {
            return nil
        }
        
        if s!["ref"] == nil || s!["track_name"] == nil ||
            s!["type"].string == nil {
                return nil
        }
        
        return Track(
            id: s!["ref"].stringValue,
            title: s!["track_name"].stringValue,
            type: s!["type"].stringValue,
            tag: nil,
            thumbnailUrl: nil,
            drop: nil,
            topMatch: nil)
    }
    
    func doLike(callback:((error:NSError?) -> Void)?) {
        if Account.getCachedAccount() == nil {
            return
        }
        Requests.doLike(self, respCb: { (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            if error != nil {
                callback?(error:error)
                return
            }
            
            var json:JSON?
            if result != nil {
                json = JSON(result!)
            }
            
            if result == nil || !(json!["success"].bool ?? false) {
                callback?(error:NSError(domain:"doLike", code: 0, userInfo:nil))
                return
            }
            
            let obj = json!["obj"]
            let id = obj["id"].intValue
            let trackObj = obj["data"]
            let track = Track(
                id: trackObj["id"].stringValue,
                title: trackObj["title"].stringValue,
                type: trackObj["type"].stringValue)
            
            let like = Like(id: id, track: track)
            
            let account = Account.getCachedAccount()
            account!.likes.append(like)
            account!.likedTrackIds.insert(self.id)
            callback?(error:nil)
            
            NSNotificationCenter.defaultCenter().postNotificationName(
                NotifyKey.likeUpdated, object: nil)
        })
    }
    
    func doUnlike(callback:((error:NSError?) -> Void)?) {
        if Account.getCachedAccount() == nil {
            return
        }
        var likeId:Int?
        let account = Account.getCachedAccount()!
        for (idx:Int, like:Like) in enumerate(account.likes) {
            if like.track.id == self.id {
                likeId = like.id
                break
            }
        }
        if likeId == nil {
            return
        }
        
        Requests.doUnlike(likeId!, respCb: { (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            if error != nil {
                callback?(error:error)
                return
            }
            if result == nil || !(JSON(result!)["success"].bool ?? false) {
                callback?(error:NSError(domain:"doUnlike", code: 0, userInfo:nil))
                return
            }
            var foundIdx = -1
            for (idx:Int, like:Like) in enumerate(account.likes) {
                if like.track.id == self.id {
                    foundIdx = idx
                    break
                }
            }
            
            account.likes.removeAtIndex(foundIdx)
            account.likedTrackIds.remove(self.id)
            callback?(error:nil)
            
            NSNotificationCenter.defaultCenter().postNotificationName(
                NotifyKey.likeUpdated, object: nil)
        })
    }
    
    func shareTrack(section:String, afterShare: (error:NSError?, uid:String?) -> Void) {
        Requests.shareTrack(self, respCb: { (req:NSURLRequest, resp:NSHTTPURLResponse?, data:AnyObject?, error:NSError?) -> Void in
            if error != nil {
                afterShare(error: error, uid: nil)
                return
            }
            
            if data == nil {
                afterShare(error: NSError(domain: "shareTrack", code: 0, userInfo: nil), uid: nil)
                return
            }
            
            var json = JSON(data!)
            if !(json["success"].bool ?? false) ||
                    (json["obj"].dictionary == nil && json["data"].dictionary == nil) {
                afterShare(error: NSError(domain: "shareTrack", code: 1, userInfo: nil), uid: nil)
                return
            }
            
            var uid:String?
            
            if json["obj"].dictionary != nil {
                let dict = json["obj"]
                uid = dict["uid"].string
            } else {
                let dict = json["data"]
                uid = dict["uid"].string
            }
            
            if uid == nil {
                afterShare(error: NSError(domain: "shareTrack", code: 1, userInfo: nil), uid: nil)
                return
            }
            
            // Log to GA
            let tracker = GAI.sharedInstance().defaultTracker
            let event = GAIDictionaryBuilder.createEventWithCategory(
                    "track-share",
                    action: "from-\(section)",
                    label: self.title,
                    value: 0
                ).build()
            tracker.send(event as [NSObject: AnyObject]!)
            
            afterShare(error: nil, uid: uid)
        })
    }
    
    func addToPlaylist(playlist: Playlist, section:String, afterAdd: (error:NSError?) -> Void) {
        var tracks = playlist.tracks
        
        var dummyTracks = [[String:AnyObject]]()
        for t in tracks {
            if (self.id == t.id) {
                afterAdd(error: NSError(domain: "addTrack", code:101, userInfo: nil))
                return
            }
            dummyTracks.append(["title": t.title, "id": t.id, "type": t.type])
        }
        dummyTracks.append(["title": self.title, "id": self.id, "type": self.type])
        
        if Account.getCachedAccount() != nil {
            // Log to us
            Requests.logTrackAdd(self.title)
        }
        // Log to GA
        let tracker = GAI.sharedInstance().defaultTracker
        let event = GAIDictionaryBuilder.createEventWithCategory(
                "playlist-add-from-\(section)",
                action: "add-\(self.type)",
                label: self.title,
                value: 0
            ).build()
        
        tracker.send(event as [NSObject: AnyObject]!)
        
        Requests.setPlaylist(playlist.id, data: dummyTracks) {
                (request:NSURLRequest, response:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            
            if (error != nil) {
                afterAdd(error: error)
                return
            }
            var changedPlaylist:Playlist? = nil
            for p in PlayerContext.playlists {
                if (p.id == playlist.id) {
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
            changedPlaylist!.tracks.append(self)
            afterAdd(error: nil)
        }
    }
    
    func deleteFromPlaylist(selectedPlaylist:Playlist, afterDelete:(error:NSError?) -> Void) {
        var tracks = selectedPlaylist.tracks
        
        var dummyTracks = [[String:AnyObject]]()
        for t in tracks {
            if (t.id != self.id) {
                dummyTracks.append(["title": t.title, "id": t.id, "type": t.type])
            }
        }
        
        Requests.setPlaylist(selectedPlaylist.id, data: dummyTracks) {
            (request:NSURLRequest, response:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            if (error != nil) {
                afterDelete(error: error)
                return
            }
            var playlist:Playlist? = nil
            for p in PlayerContext.playlists {
                if (p.id == selectedPlaylist.id) {
                    playlist = p
                    break
                }
            }
            if (playlist == nil) {
                afterDelete(error: nil)
                return
            }
            var foundIdx:Int?
            for (idx, track) in enumerate(playlist!.tracks) {
                if (track.id == self.id) {
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
                    PlayerContext.currentPlaylistId == selectedPlaylist.id) {
                for (idx, track) in enumerate(playlist!.tracks) {
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

class BeatportTrack:Track {
    var artist:String!
    var mixType:String?
    var genre:String?
    var label:String?
    var trackName: String!
    var releasedAt:NSDate?
    
    init(id: String, trackName:String, artist:String, type:String,
            thumbnailUrl:String, mixType:String?, genre:String?, label:String?, releasedAt:NSDate?) {
        super.init(id: id, title: "\(artist) - \(trackName)", type: type, tag: nil, thumbnailUrl: thumbnailUrl, drop: nil, dref: nil, topMatch: nil)
        self.artist = artist
        self.mixType = mixType
        self.genre = genre
        self.label = label
        self.trackName = trackName
        self.releasedAt = releasedAt
    }
}

class TrendingTrack:Track {
    var artist:String!
    var snippet:String!
    var trackName: String!
    init(id:String, trackName:String, artist:String, type:String, snippet:String) {
        super.init(id: id, title: "\(artist) - \(trackName)", type: type)
        self.artist = artist
        self.snippet = snippet
        self.trackName = trackName
        if (self.type == "youtube") {
            self.thumbnailUrl = "http://img.youtube.com/vi/\(self.id)/mqdefault.jpg"
        }
    }
}

class NewReleaseTrack:Track {
    var artist:String!
    var trackName: String!
    var releasedAt: NSDate?
    init(id:String, trackName:String, artist:String, type:String, thumbnail: String?, releasedAt:NSDate?) {
        super.init(id: id, title: "\(artist) - \(trackName)", type: type, tag: nil, thumbnailUrl:thumbnail)
        self.artist = artist
        self.trackName = trackName
        self.releasedAt = releasedAt
    }
}

class FollowingArtistTrack:Track {
    var artist:String!
    var trackName: String!
    var releasedAt: NSDate?
    init(id:String, trackName:String, artist:String, type:String, thumbnail: String?, releasedAt:NSDate?) {
        super.init(id: id, title: trackName, type: type, tag: nil, thumbnailUrl:thumbnail)
        self.artist = artist
        self.trackName = trackName
        self.releasedAt = releasedAt
    }
}

class ChannelTrack : Track {
    var publishedAt : NSDate?
    init (id:String, title:String, publishedAt:NSDate?) {
        super.init(id: id, title: title, type: "youtube", tag: nil,
            thumbnailUrl: "http://img.youtube.com/vi/\(id)/mqdefault.jpg",
            drop: nil, dref: nil, topMatch: false)
        self.publishedAt = publishedAt
    }
}

class ChannelFeedTrack: ChannelTrack {
    var channelTitle: String?
    init (id:String, title:String, publishedAt:NSDate?, channelTitle:String) {
        super.init(id: id, title: title, publishedAt: publishedAt)
        self.channelTitle = channelTitle
    }
}

class FriendTrack: Track {
    var trackName:String!
    var nickname:String!
    var ts: Int!
    var artistName:String!
    var genre:String!
    init (nickname:String, id:String, trackName:String, type:String, artistName:String,
        ts:Int, genre:String, thumbnail:String?) {
        let title = artistName + " - " + trackName
        var thumbnailUrl = thumbnail
        if thumbnailUrl == nil && type == "youtube" {
            thumbnailUrl = "http://img.youtube.com/vi/\(id)/mqdefault.jpg"
        }
        super.init(id:id, title: title, type: type, tag: nil, thumbnailUrl:thumbnailUrl)
        self.trackName = trackName
        self.nickname = nickname
        self.ts = ts
        self.genre = genre
        self.artistName = artistName
    }
}

class Like {
    var track:Track
    var id:Int
    init(id:Int, track:Track) {
        self.id = id
        self.track = track
    }
    
    static private func fromJson(data:JSON) -> Like? {
        if data["id"].int == nil || data["data"] == nil {
            return nil
        }
        var trackJson:JSON = data["data"]
        if trackJson["id"].string == nil {
            return nil
        }
        if trackJson["type"].string == nil {
            return nil
        }
        if trackJson["title"].string == nil {
            return nil
        }
        let trackId = trackJson["id"].stringValue
        let type = trackJson["type"].stringValue
        var thumbnailUrl:String?
        if type == "youtube" {
            thumbnailUrl = "http://img.youtube.com/vi/\(trackId)/mqdefault.jpg"
        }
        let track:Track = Track(id: trackId, title: trackJson["title"].stringValue, type: type, tag: nil, thumbnailUrl: thumbnailUrl)
        let like:Like = Like(id: data["id"].intValue, track:track)
        return like
    }
    
    static func parseLikes(data:AnyObject?) -> [Like]? {
        if data == nil {
            return nil
        }
        let json = JSON(data!)
        if !(json["success"].bool ?? false) || json["like"] == nil {
            return nil
        }
        
        var likes = [Like]()
        for (idx:String, obj:JSON) in json["like"] {
            if let like = Like.fromJson(obj) {
                likes.append(like)
            }
        }
        return likes
    }
}

class Account {
    var user:User?
    var token:String
    var likes:[Like] = [Like]()
    var likedTrackIds:Set<String> = Set<String>()
    var favoriteGenreIds:Set<String> = Set<String>()
    
    init(token:String, user:User?) {
        self.user = user
        self.token = token
    }
    
    func syncLikeInfo(callback:((error: NSError?) -> Void)?) {
        Requests.getLikes { (request:NSURLRequest, response:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            if (error != nil) {
                callback?(error:error)
                return
            }

            let likeResult:[Like]? = Like.parseLikes(result)
            if likeResult == nil {
                callback?(error: NSError(domain:"getLikes", code: 102, userInfo: nil))
                return
            }
            self.likes.removeAll(keepCapacity: false)
            for like in likeResult! {
                self.likes.append(like)
                self.likedTrackIds.insert(like.track.id)
            }
            callback?(error:nil)
        }
    }
    
    static var account:Account?
    
//    -> SettingsViewController > onSignoutBtnClicked()
//    static func signout() {
//        let keychainItemWrapper = KeychainItemWrapper(identifier: "net.dropbeat.spark", accessGroup:nil)
//        keychainItemWrapper.resetKeychain()
//        Account.account = nil
//        let appDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
//        appDelegate.account = nil
//        PlayerViewController.sharedInstance!.resignObservers()
//        var navController:UINavigationController = appDelegate.window?.rootViewController as! UINavigationController
//        navController.popToRootViewControllerAnimated(false)
//    }
    
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
        
        self.account = nil
        var gotLikeInfo = false
        var gotFavoriteInfo = false
        var didErrorHandlerFire = false
        
        var likes:[Like] = [Like]()
        var favoriteGenreIds:[String] = [String]()
        
        var responseHandler = {() -> Void in
            if !gotLikeInfo || !gotFavoriteInfo || self.account == nil {
                return
            }
            
            self.account!.likes.removeAll(keepCapacity: false)
            self.account!.likedTrackIds.removeAll(keepCapacity: false)
            
            for like: Like in likes {
                self.account!.likes.append(like)
                self.account!.likedTrackIds.insert(like.track.id)
            }
            
            
            self.account!.favoriteGenreIds.removeAll(keepCapacity: false)
            
            for favoriteId:String in favoriteGenreIds {
                self.account!.favoriteGenreIds.insert(favoriteId)
            }
            
            handler(account:self.account, error: nil)
        }
        
        var errorHandler = {(error:NSError) -> Void in
            if didErrorHandlerFire {
                return
            }
            
            self.account = nil
            didErrorHandlerFire = true
            handler(account:nil, error: error)
        }
        
        
        Requests.userSelf({ (request: NSURLRequest, response: NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            if (error != nil) {
                errorHandler(error!)
                return
            }
            
            let res = JSON(result!)
            var success:Bool = res["success"].bool ?? false
            if !success {
                errorHandler(NSError(domain: "account", code: 101, userInfo: nil))
                return
            }
            
            var userObj = res["user"]
            var fbId:String?
            if userObj["fb_id"].string != nil && count(userObj["fb_id"].stringValue) > 0 {
                fbId = userObj["fb_id"].stringValue
            }
            let user = User(
                id: String(userObj["id"].intValue),
                email: userObj["email"].stringValue,
                firstName: userObj["first_name"].stringValue,
                lastName: userObj["last_name"].stringValue,
                nickname: userObj["nickname"].stringValue,
                fbId: fbId
            )
            var account = Account(token:token!, user:user)
            self.account = account
            responseHandler()
        })
        
        Requests.getLikes { (request:NSURLRequest, response:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            if error != nil {
                errorHandler(error!)
                return
            }

            let likeResult:[Like]? = Like.parseLikes(result)
            if likeResult == nil {
                errorHandler(NSError(domain:"getLikes", code: 102, userInfo: nil))
                return
            }
            for like in likeResult! {
                likes.append(like)
            }
            
            gotLikeInfo = true
            responseHandler()
        }
        
        Requests.getFavorites { (request:NSURLRequest, response:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            if error != nil || result == nil {
                errorHandler(error != nil ? error! :
                    NSError(domain: "getFavorites", code: 103, userInfo: nil))
                return
            }
            
            let json = JSON(result!)
            if !(json["success"].bool ?? false) || json["data"] == nil {
                errorHandler(NSError(domain: "getFavorites", code: 103, userInfo: nil))
                return
            }
            
            for (idx:String, s:JSON) in json["data"] {
                favoriteGenreIds.append(String(s.intValue))
            }
            
            gotFavoriteInfo = true
            responseHandler()
        }
    }
}

class FBPageLikes {
    var pages:[FBPage]
    var nextPageToken:String?
    
    init (pages:[FBPage], nextPageToken:String?) {
        self.pages = pages
        self.nextPageToken = nextPageToken
    }
    
    static private func fromJson(data:AnyObject) -> FBPageLikes? {
        let json = JSON(data)
        var pages = [FBPage]()
        
        if json["data"].array == nil || json["error"] != nil {
            return nil
        }
        
        var nextPageToken:String?
        if json["paging"] != nil && json["paging"]["next"].string != nil {
            nextPageToken = json["paging"]["next"].string
        }
        
        for (idx:String, pageJson:JSON) in json["data"] {
            let page = FBPage.fromJson(pageJson)
            if page == nil {
                continue
            }
            
            pages.append(page!)
        }
        
        return FBPageLikes(pages: pages, nextPageToken: nextPageToken)
    }
    
    static func parseFBPageLikes(data: AnyObject) -> FBPageLikes? {
        return FBPageLikes.fromJson(data)
    }
}

class FBPage {
    var id:String
    var name:String
    init(id:String, name:String) {
        self.id = id
        self.name = name.uppercaseString
    }
    
    static private func fromJson(json: JSON) -> FBPage? {
        if json["id"].string == nil {
            return nil
        }
        
        if json["name"].string == nil {
            return nil
        }
        
        return FBPage(id: json["id"].stringValue, name: json["name"].stringValue)
    }
}


class Genre {
    var name:String
    var key:String
    init(key:String, name:String) {
        self.name = name
        self.key = key
    }
}

class GenreList {
    static var cachedResult:[String:[Genre]]?
    var success:Bool
    var results: [String:[Genre]]?
    
    init (success:Bool, results:[String:[Genre]]?) {
        self.success = success
        self.results = results
    }
    
    static func parseGenre(data: AnyObject) -> GenreList {
        return GenreList.fromJson(data)
    }
    
    static private func fromJson(data:AnyObject) -> GenreList {
        var json = JSON(data)
        
        if !(json["success"].bool ?? false) {
            return GenreList(success: false, results: nil)
        }
        
        var genres = [String:[Genre]]()
        var defaultGenres = [Genre]()
        var channelGenres = [Genre]()
        var trendingGenres = [Genre]()
        
        
        defaultGenres.append(Genre(key:"", name:"ALL"))
        for (idx:String, s:JSON) in json["default"] {
            if s["id"].int == nil {
                continue
            }
            let key = s["id"].intValue
            
            if s["name"].string == nil {
                continue
            }
            
            let name = s["name"].stringValue
            defaultGenres.append(Genre(key:"\(key)", name:name))
        }
        
        channelGenres.append(Genre(key:"", name:"ALL"))
        for (idx:String, s:JSON) in json["channel"] {
            if s["id"].int == nil {
                continue
            }
            let key = s["id"].intValue
            
            if s["name"].string == nil {
                continue
            }
            
            let name = s["name"].stringValue
            channelGenres.append(Genre(key:"\(key)", name:name))
        }
        
        trendingGenres.append(Genre(key:"", name:"NOW TRENDING"))
        for (idx:String, s:JSON) in json["trending"] {
            if s["key"].string == nil {
                continue
            }
            let key = s["key"].stringValue
            
            if s["name"].string == nil {
                continue
            }
            
            let name = s["name"].stringValue
            trendingGenres.append(Genre(key:key, name:name))
        }
        
        genres["default"] = defaultGenres
        genres["channel"] = channelGenres
        genres["trending"] = trendingGenres
        
        GenreList.cachedResult = genres
        return GenreList(success: true, results: genres)
    }
}


class Following {
    var name:String
    var id:Int
    var isFollowing:Bool
    init(id:Int, name:String, isFollowing:Bool) {
        self.id = id
        self.name = name
        self.isFollowing = isFollowing
    }
}

class FollowingInfo {
    var success:Bool
    var results:[Following]?
    init (success:Bool, results:[Following]?) {
        self.success = success
        self.results = results
    }
    
    static func parseFollowing(data: AnyObject) -> FollowingInfo {
        return FollowingInfo.fromJson(data, key: "data")
    }
    
    static private func fromJson(data:AnyObject, key:String) -> FollowingInfo {
        
        var json = JSON(data)
        
        if !(json["success"].bool ?? false) {
            return FollowingInfo(success:false, results:nil)
        }
        
        var followings = [Following]()
        for (idx:String, s:JSON) in json[key] {
            if s["id"].int == nil {
                continue
            }
            let id = s["id"].intValue
            
            if s["name"].string == nil || count(s["name"].stringValue) == 0 {
                continue
            }
            let name = s["name"].stringValue
            
            followings.append(Following(id:id, name:name, isFollowing: true))
        }
        return FollowingInfo(success:true, results:followings)
    }
}

class SearchArtist {
    var success:Bool
    var results:[Following]?
    init (success:Bool, results:[Following]?) {
        self.success = success
        self.results = results
    }
    
    static func parseSearchArtist(data: AnyObject) -> SearchArtist {
        return SearchArtist.fromJson(data, key:"data")
    }
    
    static private func fromJson(data:AnyObject, key:String) -> SearchArtist {
        
        var json = JSON(data)
        
        if !(json["success"].bool ?? false) {
            return SearchArtist(success:false, results:nil)
        }
        
        var followings = [Following]()
        for (idx:String, s:JSON) in json[key] {
            if s["id"].int == nil {
                continue
            }
            let id = s["id"].intValue
            
            if s["name"].string == nil || count(s["name"].stringValue) == 0 {
                continue
            }
            let name = s["name"].stringValue
            
            followings.append(Following(id:id, name:name, isFollowing:false))
        }
        return SearchArtist(success:true, results:followings)
    }
}

class GenreSample {
    var genreIds:[String]
    var streamUrl:String
    var thumbnailUrl:String?
    var id:Int
    init(id:Int, streamUrl:String, genreIds:[String], thumbnailUrl:String?) {
        self.id = id
        self.genreIds = genreIds
        self.streamUrl = streamUrl
        self.thumbnailUrl = thumbnailUrl
    }
    
    static func fronJson(sample:JSON) -> GenreSample? {
        return nil
    }
    
    static func parseGenreSamples(data:AnyObject?) -> [GenreSample]? {
        if data == nil {
            return nil
        }
        var json = JSON(data!)
        if !(json["success"].bool ?? false) || json["data"] == nil {
            return nil
        }
        
        var samples = [GenreSample]()
        var count = 0
        for (idx:String, s:JSON) in json["data"] {
            if s["id"].int == nil ||
                s["name"].string == nil ||
                s["sample_track"] == nil {
                    continue
            }
            let id = String(s["id"].intValue)
            let sampleJson = s["sample_track"]
            if sampleJson["url"].string == nil{
                continue
            }
            samples.append(GenreSample(
                id:count,
                streamUrl: sampleJson["url"].stringValue,
                genreIds:[id],
                thumbnailUrl:sampleJson["thumbnail"].string))
            
            count += 1
        }
        return samples
    }
    
}