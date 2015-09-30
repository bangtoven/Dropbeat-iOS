//
//  User.swift
//  labs
//
//  Created by Jungho Bang on 2015. 9. 25..
//  Copyright © 2015년 dropbeat. All rights reserved.
//

import UIKit

//\b(.*): (.*)
//$1 <- map["$1"]

enum UserType {
    case USER
    case ARTIST
    case CHANNEL
}

class BaseUser {
    var userType: UserType
    var id: String
    var name: String
    var resourceName: String
    var image: String?
    var coverImage: String?
    
    private var _isFollowed: Bool?
    func isFollowed() -> Bool {
        if let isFollowed = self._isFollowed {
            return isFollowed
        } else if let following = Account.getCachedAccount()?.following {
            var isFollowed = false
            for u in following {
                if u.userType == self.userType && u.id == self.id {
                    isFollowed = true
                    break
                }
            }
            self._isFollowed = isFollowed
            return isFollowed
        } else {
            return false
        }
    }
    func updateFollowInfo() {
        self._isFollowed = nil
    }
    
    init(userType: UserType, id: String, name: String, image: String?, coverImage: String?, resourceName: String) {
        self.userType = userType
        self.id = id
        self.name = name
        self.image = image
        self.coverImage = coverImage
        self.resourceName = resourceName
    }
    
    init?(json: JSON) {
        self.id = json["id"].stringValue
        self.name = json["name"].stringValue
        self.resourceName = json["resource_name"].stringValue
        self.image = json["image"].string
        
        switch json["user_type"].stringValue {
        case "user":
            self.userType = .USER
        case "artist":
            self.userType = .ARTIST
        case "channel":
            self.userType = .CHANNEL
        default:
            self.userType = .USER
            return nil
        }
    }
    
    private func _follow(follow: Bool, callback:((error: NSError?) -> Void)) {
        let path = follow ? ApiPath.followUser : ApiPath.unfollowUser
        
        var params = [String:String]()
        var key:String
        switch self.userType {
        case .USER:
            key = "user_id"
        case .ARTIST:
            key = "artist_id"
        case .CHANNEL:
            key = "channel_id"
        }
        params[key] = self.id
        
        Requests.sendPost(path, params: params, auth: true) { (req, resp, result, error) -> Void in
            if error != nil {
                callback(error: error)
                return
            }
            if JSON(result!)["success"].boolValue != true {
                callback(error: error)
            } else {
                self._isFollowed = follow
                Account.getCachedAccount()?.syncFollowingInfo({ (error) -> Void in
                    self._isFollowed = nil
                    self.isFollowed()
                })
                callback(error: nil)
            }
        }
    }
    
    func follow(callback:((error: NSError?) -> Void)) {
        self._follow(true, callback: callback)
    }
    
    func unfollow(callback:((error: NSError?) -> Void)) {
        self._follow(false, callback: callback)
    }
}

class User: BaseUser {
    var email: String
    var firstName: String
    var lastName: String
    var nickname: String {
        get {
            return self.name
        }
        set(n) {
            self.name = n
        }
    }
    var fbId: String?
    var num_tracks: Int
    var num_following: Int
    var num_followers: Int
    var aboutMe: String
    var tracks: [UserTrack] = []
    var likes: [Like]?
    
    override init(json: JSON) {
        var userJson = json["user"]
        
        self.email = userJson["email"].stringValue
        self.firstName = userJson["firstName"].stringValue
        self.lastName = userJson["lastName"].stringValue
        self.num_tracks = userJson["num_tracks"].intValue
        self.num_following = userJson["num_following"].intValue
        self.num_followers = userJson["num_followers"].intValue
        self.aboutMe = userJson["description"].stringValue
        
        var fbId:String?
        if userJson["fb_id"].string != nil && userJson["fb_id"].stringValue.characters.count > 0 {
            fbId = userJson["fb_id"].stringValue
        }
        self.fbId = fbId
        
        var profileImage = userJson["profile_image"].string
        if profileImage == nil && fbId != nil{
            profileImage = "https://graph.facebook.com/\(fbId)/picture?type=large"
        }
        
        super.init(
            userType: UserType.USER,
            id: userJson["id"].stringValue,
            name: userJson["nickname"].stringValue,
            image: profileImage,
            coverImage: userJson["profile_cover_image"].string,
            resourceName: userJson["resource_name"].stringValue
        )
        
        let tracksJson = json["tracks"]
        if tracksJson != nil {
            var tracks = [UserTrack]()
            for (_, t): (String, JSON) in tracksJson {
                tracks.append(UserTrack(json: t))
            }
            self.tracks = tracks
        }
    }
    
    private func _fetchFollowInfo(path: String, callback:((users: [BaseUser]?, error: NSError?) -> Void)) {
        Requests.sendGet(path, params: ["user_id": self.id], auth: false) { (req, resp, result, error) -> Void in
            if (error != nil) {
                callback(users: nil, error: error)
                return
            }
            if (result == nil) {
                callback(users: [], error: nil)
                return
            }
            var users = [BaseUser]()
            for (_, json): (String, JSON) in JSON(result!)["data"] {
                if let user = BaseUser(json: json) {
                    users.append(user)
                }
            }
            callback(users: users, error: nil)
        }
    }
    
    func fetchFollowers(callback:((users: [BaseUser]?, error: NSError?) -> Void)) {
        self._fetchFollowInfo(ApiPath.userFollowers, callback: callback)
    }
    
    func fetchFollowing(callback:((users: [BaseUser]?, error: NSError?) -> Void)) {
        self._fetchFollowInfo(ApiPath.userFollowing, callback: callback)
    }
    
    func fetchLikeList(callback:((likes:[Like]?, error:NSError?) -> Void)) {
        //        if (likes != nil) {
        //            callback(likes: likes!, error: nil)
        //            return
        //        }
        Requests.getUserLikeList(id, respCb: { (req, resp, result, error) -> Void in
            if (error != nil) {
                callback(likes: nil, error: error)
                return
            }
            if (result == nil) {
                callback(likes: [], error: nil)
                return
            }
            self.likes = Like.parseLikes(result!, key: "data")
            callback(likes:self.likes, error:nil)
        })
    }
    
    func fetchTracksFromLikeList(callback:((tracks:[Track]?, error:NSError?) -> Void)) {
        self.fetchLikeList { (likes, error) -> Void in
            if (error != nil) {
                callback(tracks: nil, error: error)
                return
            }
            if (likes == nil) {
                callback(tracks: [], error: nil)
                return
            }
            
            var tracks:[Track] = []
            for i in 0..<likes!.count {
                tracks.append(likes![i].track)
            }
            callback(tracks: tracks, error: nil)
        }
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

class Channel: BaseUser {
    var genre: [String] // description ...
    var playlists: [ChannelPlaylist]
    var isBookmarked:Bool
    var idx:Int?
    
    init(id: String, name: String, thumbnail: String? = nil, resourceName: String) {
        self.playlists = [ChannelPlaylist]()
        self.genre = []
        self.isBookmarked = false
        super.init(userType: UserType.CHANNEL, id: id, name: name, image: thumbnail, coverImage: thumbnail, resourceName: resourceName)
    }
    
    init(id: String, name: String, thumbnail: String? = nil, genre: [String], playlists: [ChannelPlaylist], resourceName: String) {
        self.playlists = playlists
        self.genre = genre
        self.isBookmarked = false
        super.init(userType: UserType.CHANNEL, id: id, name: name, image: thumbnail, coverImage: thumbnail, resourceName: resourceName)
    }
    
    override convenience init(json: JSON) {
        var detail = json["user"]
        
        let name = detail["channel_name"].stringValue
        var thumbnail:String?
        if (detail["channel_thumbnail"].error == nil) {
            thumbnail = detail["channel_thumbnail"].stringValue
        }
        var genreArray:[String] = []
        if (detail["genre"].error == nil) {
            let genres = detail["genre"]
            for (_, g): (String, JSON) in genres {
                genreArray.append(g.stringValue)
            }
        }
        var playlists = [ChannelPlaylist]()
        if (detail["uploads"].error == nil) {
            playlists.append(ChannelPlaylist(uid: detail["uploads"].stringValue, name: "RECENT"))
        }
        if (detail["playlist"].error == nil) {
            for (_, s): (String, JSON) in detail["playlist"] {
                if (s["uid"].error == nil && s["title"].error == nil) {
                    playlists.append(ChannelPlaylist(uid:s["uid"].stringValue, name: s["title"].stringValue))
                }
            }
        }
        let resourceName = detail["resource_name"].stringValue
        let id = detail["channel_id"].stringValue
        
        self.init(id: id, name:name, thumbnail: thumbnail, genre:genreArray, playlists: playlists, resourceName: resourceName)
    }
    
    static func parseChannelList(data: AnyObject) -> [Channel] {
        var json = JSON(data)
        var channels: [Channel] = []
        let index = 0
        for (_, s): (String, JSON) in json["data"] {
            if (s["uid"].error != nil || s["name"].error != nil) {
                continue
            }
            let uid: String = s["uid"].stringValue
            let name: String = s["name"].stringValue
            var thumbnail: String? = nil
            if (s["thumbnail"].error == nil) {
                thumbnail = s["thumbnail"].stringValue
            }
            
            let resourceName = s["resource_name"].stringValue
            let c = Channel(id:uid, name: name, thumbnail: thumbnail, resourceName: resourceName)
            c.idx = index
            channels.append(c)
        }
        return channels
    }
}

class ArtistEvent {
    var date: NSDate
    var detail: String
    var info: String
    var url: String
    var venue: String
    
    private static var dateFormatter:NSDateFormatter {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }
    
    init (json:JSON) {
        self.date = ArtistEvent.dateFormatter.dateFromString(json["date"].stringValue)!
        self.detail = json["detail"].stringValue
        self.info = json["info"].stringValue
        self.url = json["url"].stringValue
        self.venue = json["venue"].stringValue
    }
    
    static func parseEvents(data: AnyObject) -> [ArtistEvent] {
        let eventsJson = JSON(data)["data"]
        
        var events = [ArtistEvent]()
        for (_, e): (String, JSON) in eventsJson {
            events.append(ArtistEvent(json: e))
        }
        return events
    }
}

class Artist: BaseUser {
    static let SECTION_PODCAST = "podcast"
    static let SECTION_LIVESET = "liveset"
    
    var hasEvent = false
    var hasPodcast = false
    var hasLiveset = true
    var sectionedTracks = [String:[Track]]()
    var events: [ArtistEvent] = []
    
    init (id:String, name:String, image:String, resourceName:String) {
        super.init(userType: UserType.ARTIST, id: id, name: name, image: image, coverImage: image, resourceName: resourceName)
    }
    
    override convenience init (json: JSON) {
        var detail = json["user"]
        self.init(
            id: detail["artist_id"].stringValue,
            name: detail["artist_name"].stringValue,
            image: detail["artist_image"].stringValue,
            resourceName: detail["resource_name"].stringValue)
        
        self.hasEvent = detail["has_event"].boolValue
        self.hasPodcast = detail["has_podcast"].boolValue
        
        if json["tracks"] != nil  {
            let tracks = Track.parseTracks(json["tracks"])
            for t: Track in tracks {
                let sectionName = t.tag!
                if self.sectionedTracks[sectionName] == nil {
                    self.sectionedTracks[sectionName] = []
                }
                self.sectionedTracks[sectionName]!.append(t)
            }
        }
    }
    
    func fetchEvents(callback:((events:[ArtistEvent]?, error:NSError?) -> Void)) {
        //        if (self.name == nil) {
        //            callback(events: nil, error: NSError(domain: "artist_fetch", code: 1, userInfo: nil))
        //            return
        //        }
        if (!hasEvent) {
            callback(events:[], error: nil)
            return
        }
        Requests.fetchArtistEvent(name, respCb: { (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            if (error != nil) {
                callback(events: nil, error: error)
                return
            }
            if (result == nil) {
                callback(events: [], error: nil)
                return
            }
            self.events = ArtistEvent.parseEvents(result!)
            callback(events:self.events, error:nil)
        })
    }
    
    func fetchLiveset(callback:((tracks:[Track]?, error:NSError?) -> Void)) {
        let sectionTracks = sectionedTracks[Artist.SECTION_LIVESET]
        if (sectionTracks != nil) {
            callback(tracks: sectionTracks!, error: nil)
            return
        }
        //        if (name == nil) {
        //            callback(tracks: nil, error: NSError(domain: "artist_fetch", code: 1, userInfo: nil))
        //            return
        //        }
        if (!hasLiveset) {
            callback(tracks: [], error: nil)
            return
        }
        Requests.fetchArtistLiveset(name, respCb: { (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            if (error != nil) {
                callback(tracks: nil, error: error)
                return
            }
            if (result == nil) {
                callback(tracks: [], error: nil)
                return
            }
            self.sectionedTracks[Artist.SECTION_LIVESET] = Track.parseTracks(result!, key: "data")
            callback(tracks:self.sectionedTracks[Artist.SECTION_LIVESET], error:nil)
        })
    }
    
    func fetchPodcast(callback:((tracks:[Track]?, error:NSError?) -> Void)) {
        let sectionTracks = sectionedTracks[Artist.SECTION_PODCAST]
        if (sectionTracks != nil) {
            callback(tracks: sectionTracks!, error: nil)
            return
        }
        //        if (name == nil) {
        //            callback(tracks: nil, error: NSError(domain: "artist_fetch", code: 1, userInfo: nil))
        //            return
        //        }
        if (!hasPodcast) {
            callback(tracks: [], error: nil)
            return
        }
        Requests.fetchArtistPodcast(name, page: -1, respCb: { (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
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
            for (_, s): (String, JSON) in t["data"] {
                let id = s["stream_url"].string
                let title = s["title"].string
                if (id == nil || title == nil) {
                    continue
                }
                let track = Track(
                    id: id!,
                    title: title!,
                    type: "podcast",
                    tag:nil
                )
                
                var drop:Drop?
                var dropObj = s["drop"]
                if dropObj != nil && dropObj["dref"].string != nil &&
                    dropObj["dref"].stringValue.characters.count > 0 &&
                    dropObj["type"].string != nil {
                        
                        drop = Drop(
                            dref: dropObj["dref"].stringValue,
                            type: dropObj["type"].stringValue,
                            when: dropObj["when"].int)
                }
                track.drop = drop
                
                tracks.append(track)
            }
            self.sectionedTracks[Artist.SECTION_PODCAST] = tracks
            callback(tracks:self.sectionedTracks[Artist.SECTION_PODCAST], error:nil)
        })
    }
}