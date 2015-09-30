//
//  Track.swift
//  labs
//
//  Created by Jungho Bang on 2015. 9. 25..
//  Copyright © 2015년 dropbeat. All rights reserved.
//

import UIKit

class Drop {
    var type:String
    var dref:String
    var when:Int?
    init (dref:String, type:String, when:Int?) {
        self.type = type
        self.dref = dref
        self.when = when
    }
    
    func resolveStreamUrl() -> String? {
        if self.type == "soundcloud" {
            return "https://api.soundcloud.com/tracks/\(self.dref)/stream?client_id=b45b1aa10f1ac2941910a7f0d10f8e28"
        } else if (self.type != "youtube" && self.dref.characters.startsWith("http".characters)) {
            return self.dref.stringByRemovingPercentEncoding!
        }
        return nil
    }
}

class Like {
    var track:Track
    var id:Int

    init?(json:JSON) {
        if json["id"].int == nil || json["data"] == nil {
            self.id = -1
            self.track = Track(id: "", title: "", type: "")
            return nil
        }
        
        var track:Track
        if json["type"].stringValue == "user_track" {
            track = UserTrack(json: json["data"])
        } else {
            var trackJson:JSON = json["data"]
            if trackJson["id"].string == nil || trackJson["type"].string == nil || trackJson["title"].string == nil {
                self.id = -1
                self.track = Track(id: "", title: "", type: "")
                return nil
            }
            let trackId = trackJson["id"].stringValue
            let type = trackJson["type"].stringValue
            var thumbnailUrl:String?
            if type == "youtube" {
                thumbnailUrl = "http://img.youtube.com/vi/\(trackId)/mqdefault.jpg"
            }
            track = Track(id: trackId, title: trackJson["title"].stringValue, type: type, tag: nil, thumbnailUrl: thumbnailUrl)
        }
        self.id = json["id"].intValue
        self.track = track
    }
    
    static func parseLikes(data:AnyObject?, key: String = "like") -> [Like]? {
        if data == nil {
            return nil
        }
        let json = JSON(data!)
        if !(json["success"].bool ?? false) || json[key] == nil {
            return nil
        }
        
        var likes = [Like]()
        for (_, obj): (String, JSON) in json[key] {
            if let like = Like(json: obj) {
                likes.append(like)
            }
        }
        return likes
    }
}

// TODO: Track class structure has to be modified!!
class Track {
    var id: String
    var title: String
    var type: String
    var tag: String?
    var drop: Drop?
    var dref: String?
    var thumbnailUrl: String?
    var topMatch: Bool?
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
    }
    
    func resolveStreamUrl() -> String? {
        if self.type == "soundcloud" {
            return "https://api.soundcloud.com/tracks/\(self.id)/stream?client_id=b45b1aa10f1ac2941910a7f0d10f8e28"
        } else if (self.type != "youtube" && self.id.characters.startsWith("http".characters)) {
            return self.id.stringByRemovingPercentEncoding!
        }
        return nil
    }
    
    static func parseTracks(json: JSON) -> [Track] {
        var tracks = [Track]()
        for (_, s): (String, JSON) in json {
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
            
            let track = Track(
                id: id as! String,
                title: s["title"].stringValue,
                type: s["type"].stringValue,
                tag: s["tag"].stringValue
            )
            
            var dropObj = s["drop"]
            if dropObj != nil && dropObj["dref"].string != nil &&
                dropObj["dref"].stringValue.characters.count > 0 &&
                dropObj["type"].string != nil {
                    track.drop = Drop(
                        dref: dropObj["dref"].stringValue,
                        type: dropObj["type"].stringValue,
                        when: dropObj["when"].int)
            }
            
            let dref = s["dref"]
            if dref.error == nil {
                track.dref = s["dref"].stringValue
            }
            
            let tag = s["tag"]
            if tag.error == nil {
                track.tag = s["tag"].stringValue
            }
            
            let topMatch = s["top_match"]
            if topMatch.error == nil {
                track.topMatch = s["top_match"].boolValue ?? false
            }
            
            if (track.type == "youtube") {
                track.thumbnailUrl = "http://img.youtube.com/vi/\(track.id)/mqdefault.jpg"
            } else {
                let artwork = s["artwork"]
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
    
    static func parseTracks(data: AnyObject, key: String, secondKey: String?=nil) -> [Track] {
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
        return self.parseTracks(tracksObj)
    }
    
    var isLiked: Bool {
        get {
            if let account = Account.getCachedAccount() {
                return account.likedTrackIds.contains(self.id)
            }
            return false
        }
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
            
            if let like = Like(json: json!["obj"]) {
                let account = Account.getCachedAccount()
                account!.likes.append(like)
                account!.likedTrackIds.insert(self.id)
                callback?(error:nil)
                
                NSNotificationCenter.defaultCenter().postNotificationName(
                    NotifyKey.likeUpdated, object: nil)
            }
        })
    }
    
    func doUnlike(callback:((error:NSError?) -> Void)?) {
        if Account.getCachedAccount() == nil {
            return
        }
        var likeId:Int?
        let account = Account.getCachedAccount()!
        for (_, like): (Int, Like) in account.likes.enumerate() {
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
            for (idx, like): (Int, Like) in account.likes.enumerate() {
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
        let tracks = playlist.tracks
        
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
        let tracks = selectedPlaylist.tracks
        
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
            for (idx, track) in playlist!.tracks.enumerate() {
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

enum TrackType {
    case TRACK
    case MIXSET
}

class UserTrack: Track {
    var streamUrl: String = "" // TODO: change to id
    var userTrackType: TrackType = .TRACK
    var description: String?
    var genre: String?
    var likeCount: Int = 0
    var playCount: Int = 0
    var repostCount: Int = 0
    var createdAt: NSDate?
    
    var userName: String?
    var userProfileImage: String?
    var userResourceName: String?
    
    // playlist에서는 id에 userTrackId, title은 필요 없음., type "dropbeat"
    
    // like는 endpoint 다름.
    
    init (json: JSON) {
        let name = json["name"].stringValue
        let id = json["id"].stringValue
        let coverArt = json["coverart_url"].string
        let streamUrl = json["stream_url"].stringValue
        let dropStart = json["drop_start"].int
        let drop = Drop(dref: streamUrl, type: "dropbeat", when: dropStart)
        super.init(id: id, title: name, type: "dropbeat", thumbnailUrl: coverArt, drop: drop)
        
        self.streamUrl = streamUrl
        self.description = json["description"].stringValue
        self.userTrackType = (json["track_type"].stringValue == "TRACK") ? TrackType.TRACK : TrackType.MIXSET
        self.likeCount = json["like_count"].intValue
        self.playCount = json["play_count"].intValue
        self.repostCount = json["repost_count"].intValue
        
        let genreId = json["genre_id"].intValue
        self.genre = GenreList.getGenreName(genreId)
        
        self.userName = json["user_name"].string
        self.userProfileImage = json["user_profile_image"].string
        self.userResourceName = json["user_resource_name"].string

        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        self.createdAt = formatter.dateFromString(json["created_at"].stringValue)
    }
    
    static func fetchNewUploads(genre:String?, pageIdx: Int, callback:((tracks:[UserTrack]?, error:NSError?) -> Void)) {
        var params:[String:AnyObject] = ["p": pageIdx]
        if genre != nil && (genre!).characters.count > 0 {
            params["genre_id"] = genre
        }
        Requests.sendGet(ApiPath.userTrackNewUploads, params: params, auth: false) { (req, res, result, error) -> Void in
            if (error != nil) {
                callback(tracks: nil, error: error)
                return
            }
            if (result == nil) {
                callback(tracks: [], error: nil)
                return
            }
            
            var tracks = [UserTrack]()
            for (_, json) in JSON(result!)["data"] {
               let t = UserTrack(json: json)
                tracks.append(t)
            }
            callback(tracks: tracks, error: nil)
        }
    }
}

class ChannelTrack : Track {
    // for channel user page view
    var publishedAt : NSDate?
    init (id:String, title:String, publishedAt:NSDate?) {
        super.init(id: id, title: title, type: "youtube", tag: nil,
            thumbnailUrl: "http://img.youtube.com/vi/\(id)/mqdefault.jpg",
            drop: nil, dref: nil, topMatch: false)
        self.publishedAt = publishedAt
    }

    // for Explore tab
    var channelTitle: String?
    var channelImage: String?
    var channelResourceName: String?
    
    convenience init (json: JSON) {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.000Z"
        let publishedAt = formatter.dateFromString(json["published_at"].stringValue)
        
        self.init(id: json["video_id"].stringValue,
            title: json["title"].stringValue,
            publishedAt: publishedAt)
        
        self.channelTitle = json["channel_title"].stringValue
        self.channelImage = json["channel_image"].stringValue
        self.channelResourceName = json["resource_name"].stringValue
    }
}
