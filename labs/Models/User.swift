//
//  User.swift
//  labs
//
//  Created by Jungho Bang on 2015. 9. 25..
//  Copyright © 2015년 dropbeat. All rights reserved.
//

import UIKit

enum UserType {
    case UNKNOWN
    case USER
    case ARTIST
    case CHANNEL
}

class BaseUser {
    var userType: UserType
    var id: String?
    var name: String
    var resourceName: String
    var image: String?
    var coverImage: String?
    var aboutMe: String?
    
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
    
    init(userType: UserType, id: String? = nil, name: String, image: String?, coverImage: String? = nil, aboutMe: String? = nil,resourceName: String) {
        self.userType = userType
        self.id = id
        self.name = name
        self.image = image
        self.coverImage = coverImage
        self.aboutMe = aboutMe
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
    
    static func resolve(resource: String, callback:((user: BaseUser?, error: NSError?) -> Void)) {
        Requests.sendGet(ApiPath.resolveResource, params:["url":"/r/"+resource], auth: false) { (result, error) -> Void in
            if (error != nil) {
                callback(user: nil, error: error)
                return
            }
            
            var user: BaseUser?
            let data = result!["data"]
            let type: String = data["user_type"].stringValue
            switch type {
            case "user":
                user = User(json: data)
            case "artist":
                user = Artist(json: data)
            case "channel":
                user = Channel(json: data)
            default:
                callback(user: nil, error: NSError(domain: "ResolveUser", code: -1, userInfo: [NSLocalizedDescriptionKey:"Unknown user type: \(type)"]))
                return
            }
            
            callback(user: user, error: nil)
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
        case .UNKNOWN:
            callback(error: NSError(domain: DropbeatRequestErrorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey : "Can't follow unknown type user."]))
            return
        }
        params[key] = self.id
        
        Requests.sendPost(path, params: params, auth: true) { (result, error) -> Void in
            if error != nil {
                callback(error: error)
                return
            }
            
            self._isFollowed = follow
            Account.getCachedAccount()?.syncFollowingInfo({ (error) -> Void in
                self._isFollowed = nil
                self.isFollowed()
            })
            callback(error: nil)
        }
    }
    
    func follow(callback:((error: NSError?) -> Void)) {
        self._follow(true, callback: callback)
    }
    
    func unfollow(callback:((error: NSError?) -> Void)) {
        self._follow(false, callback: callback)
    }
}

enum FollowInfoType {
    case FOLLOWING
    case FOLLOWERS
}

// MARK: - User

class User: BaseUser {
    var email: String
    var firstName: String
    var lastName: String
    var nickname: String {
        get { return self.name }
        set(n) { self.name = n }
    }
    var fbId: String?
    var num_tracks: Int
    var num_following: Int
    var num_followers: Int
    var tracks: [DropbeatTrack] = []
    var likes: [Like]?
    
    override init(json: JSON) {
        var userJson = json["user"]
        
        self.email = userJson["email"].stringValue
        self.firstName = userJson["firstName"].stringValue
        self.lastName = userJson["lastName"].stringValue
        self.num_tracks = userJson["num_tracks"].intValue
        self.num_following = userJson["num_following"].intValue
        self.num_followers = userJson["num_followers"].intValue
        
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
            aboutMe: userJson["description"].stringValue,
            resourceName: userJson["resource_name"].stringValue
        )
        
        let tracksJson = json["tracks"]
        if tracksJson != nil {
            var tracks = [DropbeatTrack]()
            for (_, t): (String, JSON) in tracksJson {
                tracks.append(DropbeatTrack(json: t))
            }
            self.tracks = tracks
        }
    }
    
    private func _fetchFollowInfo(type: FollowInfoType, callback:((users: [BaseUser]?, error: NSError?) -> Void)) {
        let path = type == .FOLLOWING ? ApiPath.userFollowing : ApiPath.userFollowers
        
        Requests.sendGet(path, params: ["user_id": self.id!], auth: false) { (result, error) -> Void in
            if (error != nil) {
                callback(users: nil, error: error)
                return
            }
            if (result == nil) {
                callback(users: [], error: nil)
                return
            }
            var users = [BaseUser]()
            for (_, json): (String, JSON) in result!["data"] {
                if let user = BaseUser(json: json) {
                    users.append(user)
                }
            }
            callback(users: users, error: nil)
        }
    }
    
    func fetchFollowers(callback:((users: [BaseUser]?, error: NSError?) -> Void)) {
        self._fetchFollowInfo(.FOLLOWERS, callback: callback)
    }
    
    func fetchFollowing(callback:((users: [BaseUser]?, error: NSError?) -> Void)) {
        self._fetchFollowInfo(.FOLLOWING, callback: callback)
    }
    
    func fetchReposts(callback:((tracks:[Track]?, error:NSError?) -> Void)) {
        Requests.sendGet(ApiPath.repost, params: ["user_id": self.id!], auth: true) { (result, error) -> Void in
            if (error != nil) {
                callback(tracks: nil, error: error)
                return
            }
            
            let tracks = Track.parseTracks(result!["data"])
            callback(tracks: tracks, error: nil)
        }
    }
    
    func fetchLikeList(callback:((likes:[Like]?, error:NSError?) -> Void)) {
        Requests.sendGet(ApiPath.userLikeList, params: ["user_id": self.id!], auth: true) {
            (result, error) -> Void in
            if (error != nil) {
                callback(likes: nil, error: error)
                return
            }
            if (result == nil) {
                callback(likes: [], error: nil)
                return
            }
            self.likes = Like.parseLikes(result!["data"])
            callback(likes:self.likes, error:nil)
        }
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

// MARK: - Channel

class Channel: BaseUser {
    var genre: [String]
    var playlists: [ChannelPlaylist]
    var isBookmarked:Bool
    var idx:Int?
    
    var facebookId: Int?

    private init(id: String, name: String, thumbnail: String? = nil, resourceName: String) {
        self.playlists = [ChannelPlaylist]()
        self.genre = []
        self.isBookmarked = false
        super.init(userType: UserType.CHANNEL, id: id, name: name, image: thumbnail, coverImage: thumbnail, resourceName: resourceName)
    }
    
    override init(json: JSON) {
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
        
        self.facebookId = Int(detail["channel_uid"].stringValue)
        
        self.playlists = playlists
        self.genre = genreArray
        self.isBookmarked = false
        
        super.init(
            userType: UserType.CHANNEL,
            id: id,
            name: name,
            image: thumbnail,
            coverImage: thumbnail,
            aboutMe: detail["channel_description"].string,
            resourceName: resourceName)
    }
    
    static func parseChannelList(json: JSON) -> [Channel] {
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

struct ChannelPlaylist {
    var uid: String
    var name:String
}

// MARK: - Artist

class Artist: BaseUser {
    static let SECTION_PODCAST = "podcast"
    static let SECTION_LIVESET = "liveset"
    
    var hasEvent = false
    var hasPodcast = false
    var hasLiveset = true
    var sectionedTracks = [String:[Track]]()
    var events: [ArtistEvent] = []
    
    override init (json: JSON) {
        var detail = json["user"]

        let id = detail["artist_id"].stringValue
        let name = detail["artist_name"].stringValue
        let image = detail["artist_image"].stringValue
        let resourceName = detail["resource_name"].stringValue
        
        super.init(userType: UserType.ARTIST, id: id, name: name, image: image, coverImage: image, resourceName: resourceName)
        
        self.hasEvent = detail["has_event"].boolValue
        self.hasPodcast = detail["has_podcast"].boolValue
        
        if json["tracks"] != nil  {
            let tracks = Track.parseTracks(json["tracks"])
            for t: Track in tracks {
                t.user = self
                let sectionName = t.tag!
                if self.sectionedTracks[sectionName] == nil {
                    self.sectionedTracks[sectionName] = []
                }
                self.sectionedTracks[sectionName]!.append(t)
            }
        }
    }
    
    func fetchLiveset(callback:((tracks:[Track]?, error:NSError?) -> Void)) {
        let sectionTracks = sectionedTracks[Artist.SECTION_LIVESET]
        if (sectionTracks != nil) {
            callback(tracks: sectionTracks!, error: nil)
            return
        }
        if (!hasLiveset) {
            callback(tracks: [], error: nil)
            return
        }
        Requests.sendGet(CorePath.searchLiveset, params: ["q": name], auth: false) {
            (result, error) -> Void in
            if (error != nil) {
                callback(tracks: nil, error: error)
                return
            }
            if (result == nil) {
                callback(tracks: [], error: nil)
                return
            }
            
            let tracks = Track.parseTracks(result!["data"])
            tracks.forEach({ $0.user = self })

            self.sectionedTracks[Artist.SECTION_LIVESET] = tracks
            callback(tracks:self.sectionedTracks[Artist.SECTION_LIVESET], error:nil)
        }
    }
    
    func fetchPodcast(callback:((tracks:[Track]?, error:NSError?) -> Void)) {
        let sectionTracks = sectionedTracks[Artist.SECTION_PODCAST]
        if (sectionTracks != nil) {
            callback(tracks: sectionTracks!, error: nil)
            return
        }
        if (!hasPodcast) {
            callback(tracks: [], error: nil)
            return
        }
        Requests.sendGet(CorePath.podcast, params: ["q": name, "p": -1], auth: false) { (result, error) -> Void in
            if (error != nil) {
                callback(tracks: nil, error: error)
                return
            }
            if (result == nil) {
                callback(tracks: [], error: nil)
                return
            }
            
            var tracks = [Track]()
            for (_, s): (String, JSON) in result!["data"] {
                guard let streamUrl = s["stream_url"].string,
                    title = s["title"].string else {
                        continue
                }
                
                let track = Track(
                    id: streamUrl,
                    title: title,
                    type: .PODCAST,
                    drop: Drop(json: s["drop"])
                )
                
                track.user = self
                
                tracks.append(track)
            }
            
            self.sectionedTracks[Artist.SECTION_PODCAST] = tracks
            callback(tracks:self.sectionedTracks[Artist.SECTION_PODCAST], error:nil)
        }
    }
    
    func fetchEvents(callback:((events:[ArtistEvent]?, error:NSError?) -> Void)) {
        if (!hasEvent) {
            callback(events:[], error: nil)
            return
        }
        Requests.sendGet(CorePath.event, params: ["q": name], auth: false) {
            (result, error) -> Void in
            if (error != nil) {
                callback(events: nil, error: error)
                return
            }
            if (result == nil) {
                callback(events: [], error: nil)
                return
            }
            self.events = ArtistEvent.parseEvents(result!["data"])
            callback(events:self.events, error:nil)
        }
    }
}

class ArtistEvent {
    var date: NSDate
    var detail: String
    var info: String
    var url: String
    var venue: String
    
    init (json:JSON) {
        self.date = NSDate.dateFromString(json["date"].stringValue)!
        self.detail = json["detail"].stringValue
        self.info = json["info"].stringValue
        self.url = json["url"].stringValue
        self.venue = json["venue"].stringValue
    }
    
    static func parseEvents(json: JSON) -> [ArtistEvent] {
        var events = [ArtistEvent]()
        for (_, e): (String, JSON) in json {
            events.append(ArtistEvent(json: e))
        }
        return events
    }
}