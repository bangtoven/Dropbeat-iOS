//
//  Track.swift
//  labs
//
//  Created by Jungho Bang on 2015. 9. 25..
//  Copyright © 2015년 dropbeat. All rights reserved.
//

import UIKit

enum SourceType: String {
    case DROPBEAT = "dropbeat"
    case YOUTUBE = "youtube"
    case SOUNDCLOUD = "soundcloud"
    case PODCAST = "podcast"
    case SPOTIFY = "spotify"
    case UNKNOWN
    
    static func fromString(string: String) -> SourceType {
        if let type = SourceType(rawValue: string) {
            return type
        } else {
            print("what the fuck is this? \(string)")
            return .UNKNOWN
        }
    }
}

extension UIImageView {
    enum ThumnailSize { case LARGE; case SMALL }
    func setImageForTrack(track: Track, size: ThumnailSize, var needsHighDef: Bool = true) {
        if size == .SMALL {
            needsHighDef = false
        }
        
        let placeHolder = size == .LARGE ?
            UIImage(named: "default_cover_big") :
            UIImage(named: "default_artwork")
        
        switch track.type {
        case .YOUTUBE:
            let lowUrlString = "http://img.youtube.com/vi/\(track.id)/mqdefault.jpg"
            let highUrlString = "http://img.youtube.com/vi/\(track.id)/sddefault.jpg"
            
            func cropImage16_9(image: UIImage) -> UIImage {
                let newHeight = image.size.width * 9/16
                let rect = CGRectMake(
                    0, 0.5 * (image.size.height - newHeight),
                    image.size.width, newHeight)
                let imageRef = CGImageCreateWithImageInRect(image.CGImage, rect)
                let croppedImage = UIImage(CGImage: imageRef!)
                return croppedImage
            }
            
            if needsHighDef == false {
                self.sd_setImageWithURL(NSURL(string: lowUrlString), placeholderImage: placeHolder)
            }
            else if let notNilHasHigh = track.hasHighDefThumbnail {
                let urlString = notNilHasHigh ? highUrlString : lowUrlString
                self.sd_setImageWithURL(NSURL(string: urlString), placeholderImage: placeHolder) {
                    (image, error, cacheType, imageURL) -> Void in
                    
                    self.image = cropImage16_9(image)
                }
            }
            else {
                self.sd_setImageWithURL(NSURL(string: highUrlString), placeholderImage: placeHolder) {
                    (image, error, cacheType, imageURL) -> Void in
                    
                    if let _ = error {
                        track.hasHighDefThumbnail = false
                        self.setImageForTrack(track, size: size, needsHighDef: false)
                        return
                    } else {
                        track.hasHighDefThumbnail = true
                        self.image = cropImage16_9(image)
                    }
                }
            }
        default:
            if let urlString = track.thumbnailUrl {
                self.sd_setImageWithURL(NSURL(string: urlString), placeholderImage: placeHolder)
            } else {
                self.image = placeHolder
            }
        }
    }
}

class Track {
    static var soundCloudKey: String = "02gUJC0hH2ct1EGOcYXQIzRFU91c72Ea"
    static func loadSoundCloudKey (callback:(NSError)->Void) {
        Requests.sendGet(ApiPath.metaKey, auth: false) { (req, resp, result, error) -> Void in
            if error != nil {
                print("can't fetch sound cloud key")
                return
            }
            
            if let r = result, key = JSON(r)["soundcloud_key"].string {
                soundCloudKey = key
            }
        }
    }
    
    var id: String
    var title: String
    var type: SourceType
    var tag: String?
    var drop: Drop?
    var user: BaseUser?
    var releaseDate: NSDate?
    
    var hasHighDefThumbnail: Bool?
    var thumbnailUrl: String?
    
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
    
    var streamUrl: String {
        get {
            switch self.type {
            case .YOUTUBE:
                print("this is very exceptional case that youtube track asks for stream URL.")
                return self.id
            case .SOUNDCLOUD:
                let key = Track.soundCloudKey
                return "https://api.soundcloud.com/tracks/\(self.id)/stream?client_id=\(key)"
            default:
                return self.id.stringByRemovingPercentEncoding!
            }
        }
    }
    
    func getYouTubeStreamURL(quality:XCDYouTubeVideoQuality, callback:(streamURL:String?, duration:Double?, error:NSError?)->Void) {
        guard self.type == .YOUTUBE else {
            let error = NSError(domain: "TrackYouTubeStreamURL", code: -1, userInfo: nil)
            callback(streamURL: nil, duration: nil, error: error)
            return
        }
        
        XCDYouTubeClient.defaultClient().getVideoWithIdentifier(self.id, completionHandler: {
            (video: XCDYouTubeVideo?, error: NSError?) -> Void in
            if error != nil {
                callback(streamURL: nil, duration:nil, error: error)
                return
            }
            
            if let streamURL = video?.streamURLs[quality.rawValue] as? NSURL {
                callback(streamURL: streamURL.absoluteString, duration:video?.duration, error: nil)
            } else {
                let e = NSError(domain: "TrackYouTubeStreamURL", code: -2, userInfo: nil)
                callback(streamURL: nil, duration:nil, error: e)
            }
        })
    }
    
    init(id: String, title: String, type: SourceType, tag: String? = nil, thumbnailUrl: String? = nil, drop: Drop? = nil, releaseDate: NSDate? = nil) {
        self.id = id
        self.title = title
        self.drop = drop
        self.type = type
        self.tag = tag
        
        if let url = thumbnailUrl {
            self.thumbnailUrl = url
        } else if type == .YOUTUBE {
            self.thumbnailUrl = "http://img.youtube.com/vi/\(id)/mqdefault.jpg"
        }
        
        self.releaseDate = releaseDate
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
            type: SourceType.fromString(json["type"].stringValue),
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
            type: .YOUTUBE,
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
            type: .YOUTUBE,
            releaseDate: NSDate.dateFromString(snippet["publishedAt"].stringValue))
    }
    
    static func parsePodcastTracks(json: JSON) -> [Track] {
        var tracks = [Track]()
        for (_, s): (String, JSON) in json {
            let id = s["stream_url"].string
            let title = s["title"].string
            if (id == nil || title == nil) {
                continue
            }
            let track = Track(
                id: id!,
                title: title!,
                type: .PODCAST,
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
        return tracks
    }
    
    static func parseTracks(json: JSON) -> [Track] {
        var tracks = [Track]()
        for (_, s): (String, JSON) in json {
            let type = SourceType.fromString(s["type"].stringValue)
            if type == .DROPBEAT {
                tracks.append(DropbeatTrack(json: s))
            } else {
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
                    type: type,
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
                
                let artwork = s["artwork"]
                if artwork.error == nil {
                    track.thumbnailUrl = s["artwork"].stringValue
                }
                
                if (track.tag == nil) {
                    continue
                }
                tracks.append(track)
            }
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
            type: SourceType.fromString(s!["type"].stringValue),
            tag: nil,
            thumbnailUrl: nil,
            drop: nil)
    }
    
    func shareTrack(section:String, afterShare: (error:NSError?, sharedURL:NSString?) -> Void) {
        Requests.shareTrack(self, respCb: { (req:NSURLRequest, resp:NSHTTPURLResponse?, data:AnyObject?, error:NSError?) -> Void in
            if error != nil {
                afterShare(error: error, sharedURL: nil)
                return
            }
            
            if data == nil {
                afterShare(error: NSError(domain: "shareTrack", code: 0, userInfo: nil), sharedURL: nil)
                return
            }
            
            var json = JSON(data!)
            if !(json["success"].bool ?? false) ||
                (json["obj"].dictionary == nil && json["data"].dictionary == nil) {
                    afterShare(error: NSError(domain: "shareTrack", code: 1, userInfo: nil), sharedURL: nil)
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
                afterShare(error: NSError(domain: "shareTrack", code: 1, userInfo: nil), sharedURL: nil)
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
            
            let URL = "http://dropbeat.net/?track=" + uid!
            afterShare(error: nil, sharedURL:URL)
        })
    }
}

class DropbeatTrack: Track {
    enum TrackType {
        case TRACK
        case MIXSET
    }
    
    private var _streamUrl: String
    override var streamUrl: String { get {return _streamUrl } }
    
    var trackType: TrackType = .TRACK
    var description: String?
    var genre: String?
    var likeCount: Int = 0
    var playCount: Int = 0
    var repostCount: Int = 0
    var resourcePath: String!
    var uniqueKey: String!
 
    init (json: JSON) {
        let name = json["name"].stringValue
        let id = json["id"].stringValue
        let coverArt = json["coverart_url"].string
        let streamUrl = json["stream_url"].stringValue
        let dropStart = json["drop_start"].int
        let drop = Drop(dref: streamUrl, type: "dropbeat", when: dropStart)

        self._streamUrl = streamUrl
        super.init(
            id: id,
            title: name,
            type: .DROPBEAT,
            thumbnailUrl: coverArt,
            drop: drop,
            releaseDate: NSDate.dateFromString(json["created_at"].stringValue))
        
        self.description = json["description"].stringValue
        self.trackType = (json["track_type"].stringValue == "TRACK") ? TrackType.TRACK : TrackType.MIXSET
        self.likeCount = json["like_count"].intValue
        self.playCount = json["play_count"].intValue
        self.repostCount = json["repost_count"].intValue
        
        self.resourcePath = json["resource_path"].stringValue
        self.uniqueKey = json["unique_key"].stringValue
        
        let genreId = json["genre_id"].intValue
        self.genre = GenreList.getGenreName(genreId)
        
        self.user = BaseUser(
            userType: .USER,
            name: json["user_name"].stringValue,
            image: json["user_profile_image"].stringValue,
            resourceName: json["user_resource_name"].stringValue)
    }
    
    static func resolve(user: String, track: String, callback:((track: Track?, error: NSError?) -> Void)) {
        Requests.sendGet(ApiPath.resolveResource, params:["url":"/r/\(user)/\(track)"], auth: false) {
            (req, resp, result, error) -> Void in
            if (error != nil || JSON(result!)["success"] == false) {
                callback(track: nil, error: error)
                return
            }
            
            let t = DropbeatTrack(json: JSON(result!)["data"])
            callback(track: t, error: nil)
        }
    }
    
    override func shareTrack(section:String, afterShare: (error:NSError?, sharedURL:NSString?) -> Void) {
        guard let userResourceName = self.user?.resourceName else {
            super.shareTrack(section, afterShare: afterShare)
            return
        }
        
        // Log to GA
        let tracker = GAI.sharedInstance().defaultTracker
        let event = GAIDictionaryBuilder.createEventWithCategory(
            "user-track-share",
            action: "from-\(section)",
            label: self.title,
            value: 0
            ).build()
        tracker.send(event as [NSObject: AnyObject]!)
        
        let URL = "http://dropbeat.net/r/\(userResourceName)/\(self.resourcePath)"
        afterShare(error: nil, sharedURL: URL)
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
                    track = DropbeatTrack(json: json)
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
    
    enum Order: Int {
        case POPULAR = 0
        case RECENT = 1
    }
    
    static func fetchNewUploads(order:Order, pageIdx: Int, callback:((tracks:[DropbeatTrack]?, error:NSError?) -> Void)) {
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
            
            var tracks = [DropbeatTrack]()
            for (_, json) in JSON(result!)["data"] {
                let t = DropbeatTrack(json: json)
                tracks.append(t)
            }
            callback(tracks: tracks, error: nil)
        }
    }
}

class PlayLog {
    private var track_id: Int
    private var seekLog = [(Int,Int)]()
    
    init(track: DropbeatTrack) {
        self.track_id = Int(track.id)!
    }
    
    func seek(from from:Int, to:Int) {
        self.seekLog.append((from,to))
    }
    
    func finished(end: Int? = nil) {
        var log = [String:AnyObject]()
        log["track_id"] = self.track_id
        log["location"] = Account.location
        
        var data = [AnyObject]()
        data.append(["type":"start"])
        for (from,to) in seekLog {
            data.append(["type":"seek_from","ts":from])
            data.append(["type":"seek_to","ts":to])
        }
        if let exit = end {
            data.append(["type":"exit","ts":exit])
        } else {
            data.append(["type":"end"])
        }
        log["data"] = data

        request(.POST, ApiPath.logPlaybackDetail, parameters: log, encoding: .JSON)
            .responseJSON { (req, resp, result) -> Void in
                print("playback detail log posted: " + result.description)
        }
    }
}

extension Track { // for Play Failure Log
    func postFailureLog() {
        var log = [String:AnyObject]()
        
        log["title"] = self.title
        log["stream_urls"] = [self.streamUrl]
        
        if let user = Account.getCachedAccount()?.user {
            log["email"] = user.email
        } else {
            log["email"] = ""
        }
        
        if let dropbeatTrack = self as? DropbeatTrack {
            log["uid"] = dropbeatTrack.uniqueKey
        } else {
            log["uid"] = self.id
        }
        
        var device = [String:String]()
        let d = UIDevice.currentDevice()
        device["system"] = d.systemName
        device["model"] = d.model
        device["version"] = d.systemVersion
        log["device_info"] = device
        
        log["location"] = Account.location
        
        request(.POST, ApiPath.logPlayFailure, parameters: log, encoding: .JSON)
            .responseJSON{ (req, resp, result) -> Void in
                print("play failure log posted: " + result.description)
        }
    }
}

class Drop {
    var type:String
    var dref:String

    init (dref:String, type:String, when:Int?) {
        self.type = type
        self.dref = dref
    }
    
    var streamUrl:String? {
        get {
            if self.type == "soundcloud" {
                let key = Track.soundCloudKey
                return "https://api.soundcloud.com/tracks/\(self.dref)/stream?client_id=\(key)"
            } else if self.type == "dropbeat" {
                return self.dref
            }
            else if (self.type != "youtube" && self.dref.characters.startsWith("http".characters)) {
                return self.dref.stringByRemovingPercentEncoding!
            }
            return nil
        }
    }
}

class Like {
    var track:Track
    var id:Int
    
    init?(json:JSON) {
        if json["id"].int == nil || json["data"] == nil {
            self.id = -1
            self.track = Track(id: "", title: "", type: .UNKNOWN)
            return nil
        }
        
        var track:Track
        if json["type"].stringValue == "user_track" {
            track = DropbeatTrack(json: json["data"])
        } else {
            var trackJson:JSON = json["data"]
            if trackJson["id"].string == nil || trackJson["type"].string == nil || trackJson["title"].string == nil {
                self.id = -1
                self.track = Track(id: "", title: "", type: .UNKNOWN)
                return nil
            }
            let trackId = trackJson["id"].stringValue
            let type = SourceType.fromString(trackJson["type"].stringValue)
            track = Track(id: trackId, title: trackJson["title"].stringValue, type: type, tag: nil, thumbnailUrl: nil)
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
            callback?(error: NSError(domain: NeedAuthViewController.NeedAuthErrorDomain, code: -1, userInfo: nil))
            return
        }
        
        switch track {
        case is DropbeatTrack:
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
            Requests.doLike(track, respCb: { (req, resp, result, error) -> Void in
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
        case is DropbeatTrack:
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
            Requests.doUnlike(likeId!, respCb: { (req, resp, result, error) -> Void in
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

