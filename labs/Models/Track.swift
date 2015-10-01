//
//  Track.swift
//  labs
//
//  Created by Jungho Bang on 2015. 9. 25..
//  Copyright © 2015년 dropbeat. All rights reserved.
//

import UIKit

class Track {
    var id: String
    var title: String
    var type: String
    var tag: String?
    var drop: Drop?
    var thumbnailUrl: String?
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
    var user: BaseUser?
    var releaseDate: NSDate?
    
    var isLiked: Bool {
        get {
            if let account = Account.getCachedAccount() {
                return account.likes.contains { like in
                    like.track.id == self.id
                }
            }
            return false
        }
    }

    init(id: String, title: String, type: String, tag: String? = nil, thumbnailUrl: String? = nil, drop: Drop? = nil, releaseDate: NSDate? = nil) {
        self.id = id
        self.title = title
        self.drop = drop
        self.type = type
        self.tag = tag
        self.thumbnailUrl = thumbnailUrl
        self.releaseDate = releaseDate
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
            
            let tag = s["tag"]
            if tag.error == nil {
                track.tag = s["tag"].stringValue
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
            drop: nil)
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
    
    convenience init(artistTrack json: JSON) {
        var drop: Drop?
        let dropObj = json["drop"]
        if dropObj != JSON.null {
            drop = Drop(dref: dropObj["dref"].stringValue,
                type: dropObj["type"].stringValue,
                when: dropObj["when"].int)
        } else {
            print("no drop data")
        }
        
        self.init(
            id: json["id"].stringValue,
            title: json["title"].stringValue,
            type: json["type"].stringValue,
            drop: drop,
            releaseDate: NSDate.dateFromString(json["release_date"].stringValue))
        
        self.user = BaseUser(
            userType: .ARTIST,
            name: json["dj"].stringValue,
            image: json["artist_image"].string,
            resourceName: json["resource_name"].stringValue)
    }
    
    convenience init (channelTrack json: JSON) {
        let id = json["video_id"].string ?? json["id"].stringValue
        self.init(
            id: id,
            title: json["title"].stringValue,
            type: "youtube",
            thumbnailUrl: "http://img.youtube.com/vi/\(id)/mqdefault.jpg",
            releaseDate: NSDate.dateFromString(json["published_at"].stringValue))
        
        self.user = BaseUser(
            userType: .CHANNEL,
            name: json["channel_title"].stringValue,
            image: json["channel_image"].string,
            resourceName: json["resource_name"].stringValue)
    }
    
    convenience init (channelSnippet snippet: JSON) {
        let id = snippet["resourceId"]["videoId"].stringValue
        self.init(
            id: id,
            title: snippet["title"].stringValue,
            type: "youtube",
            thumbnailUrl: "http://img.youtube.com/vi/\(id)/mqdefault.jpg",
            releaseDate: NSDate.dateFromString(snippet["publishedAt"].stringValue))
    }
    
    static func fetchFollowingTracks(pageIdx: Int, callback:((tracks:[Track]?, error:NSError?) -> Void)) {
        Requests.sendGet(ApiPath.streamFollowing, params: ["p": pageIdx], auth: true) { (req, res, result, error) -> Void in
            if (error != nil) {
                callback(tracks: nil, error: error)
                return
            }
            if (result == nil) {
                callback(tracks: [], error: nil)
                return
            }
            
            var tracks = [Track]()
            for (_, json) in JSON(result!)["data"] {
                var track:Track?
                if json["unique_key"] != JSON.null {
                    track = UserTrack(json: json)
                } else if json["dj"] != JSON.null {
                    track = Track(artistTrack: json)
                } else if json["channel_title"] != JSON.null {
                    track = Track(channelTrack: json)
                } else {
                    print("what the hell is this??")
                }
                
                if let t = track {
                    tracks.append(t)
                }
            }
            callback(tracks: tracks, error: nil)
        }
    }
}

class UserTrack: Track {
    enum TrackType {
        case TRACK
        case MIXSET
    }
    
    var streamUrl: String
    var userTrackType: TrackType = .TRACK
    var description: String?
    var genre: String?
    var likeCount: Int = 0
    var playCount: Int = 0
    var repostCount: Int = 0
 
    init (json: JSON) {
        let name = json["name"].stringValue
        let id = json["id"].stringValue
        let coverArt = json["coverart_url"].string
        let streamUrl = json["stream_url"].stringValue
        let dropStart = json["drop_start"].int
        let drop = Drop(dref: streamUrl, type: "dropbeat", when: dropStart)

        self.streamUrl = streamUrl
        super.init(
            id: id,
            title: name,
            type: "dropbeat",
            thumbnailUrl: coverArt,
            drop: drop,
            releaseDate: NSDate.dateFromString(json["created_at"].stringValue))
        
        self.description = json["description"].stringValue
        self.userTrackType = (json["track_type"].stringValue == "TRACK") ? TrackType.TRACK : TrackType.MIXSET
        self.likeCount = json["like_count"].intValue
        self.playCount = json["play_count"].intValue
        self.repostCount = json["repost_count"].intValue
        
        let genreId = json["genre_id"].intValue
        self.genre = GenreList.getGenreName(genreId)
        
        self.user = BaseUser(
            userType: .USER,
            name: json["user_name"].stringValue,
            image: json["user_profile_image"].stringValue,
            resourceName: json["user_resource_name"].stringValue)
    }
    
    enum NewUploadsOrder: Int {
        case POPULAR = 0
        case RECENT = 1
    }
    
    static func fetchNewUploads(order:NewUploadsOrder, pageIdx: Int, callback:((tracks:[UserTrack]?, error:NSError?) -> Void)) {
        var params:[String:AnyObject] = ["p": pageIdx]
        switch order {
        case .POPULAR: params["order"] = "popular"
        case .RECENT: params["order"] = "recent"
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
    
    static func likeTrack(track:Track, callback: ((error: NSError?) -> Void)?) {
        if Account.getCachedAccount() == nil {
            // TODO: 로그인 안했을 때 어쩔꺼니?
            return
        }
        
        switch track {
        case is UserTrack:
            Requests.sendPost(ApiPath.userTrackLike, params: ["track_id":track.id], auth: true) { (req, resp, result, error) -> Void in
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
                    callback?(error:nil)
                    
                    NSNotificationCenter.defaultCenter().postNotificationName(
                        NotifyKey.likeUpdated, object: nil)
                }
            }
        default:
            Requests.doLike(track, respCb: { (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
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
                    callback?(error:nil)
                    
                    NSNotificationCenter.defaultCenter().postNotificationName(
                        NotifyKey.likeUpdated, object: nil)
                }
            })
        }
    }
    
    static func unlikeTrack(track:Track, callback: ((error: NSError?) -> Void)?) {
        if Account.getCachedAccount() == nil {
            return
        }
        
        let account = Account.getCachedAccount()!
        let filteredLikes = account.likes.filter { like in
            like.track.id == track.id
        }
        guard filteredLikes.count == 1 else {
            print("filtered likes count is not 1. what the hell?")
            assertionFailure()
            return
        }
        
        let likeId = filteredLikes.first?.id
        switch track {
        case is UserTrack:
            Requests.send(.DELETE, url: ApiPath.userTrackLike, params: ["like_id":likeId!], auth: true) { (req, resp, result, error) -> Void in
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
                    if like.track.id == track.id {
                        foundIdx = idx
                        break
                    }
                }
                
                account.likes.removeAtIndex(foundIdx)
                callback?(error:nil)
                
                NSNotificationCenter.defaultCenter().postNotificationName(
                    NotifyKey.likeUpdated, object: nil)
            }
            break
        default:
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
                    if like.track.id == track.id {
                        foundIdx = idx
                        break
                    }
                }
                
                account.likes.removeAtIndex(foundIdx)
                callback?(error:nil)
                
                NSNotificationCenter.defaultCenter().postNotificationName(
                    NotifyKey.likeUpdated, object: nil)
            })
        }
    }
    
}
