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
        } else {
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            if appDelegate.networkStatus == .ReachableViaWiFi {
                needsHighDef = true
            }
        }
        
        let placeHolder = size == .LARGE ?
            UIImage(named: "default_cover_big") :
            UIImage(named: "default_artwork")
        
        switch track.type {
        case .YOUTUBE:
            let lowUrlString = "http://img.youtube.com/vi/\(track.id)/mqdefault.jpg"
            let highUrlString = "http://img.youtube.com/vi/\(track.id)/sddefault.jpg"
            
            func cropImage16_9(_image: UIImage?) -> UIImage? {
                guard let image = _image else {
                    return nil
                }
                
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
                    
                    self.image = (image != nil) ? cropImage16_9(image) : placeHolder
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
        case .SOUNDCLOUD:
            if let urlString = track.thumbnailUrl {
                self.sd_setImageWithURL(NSURL(string: urlString), placeholderImage: placeHolder)
            } else {
                self.sd_setImageWithURL(
                    NSURL(string: "\(CorePath.soundCloudImage)?uid=\(track.id)&size=large"),
                    placeholderImage: placeHolder)
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

// MARK: - YouTube track

extension Track {
    func getYouTubeStreamURL(callback:(streamURL:String?, duration:Double?, error:NSError?)->Void) {
        guard self.type == .YOUTUBE else {
            callback(streamURL: nil, duration: nil, error: NSError(domain: "TrackYouTubeStreamURL", code: -1, userInfo: nil))
            return
        }
        
        XCDYouTubeClient.defaultClient().getVideoWithIdentifier(self.id, completionHandler: {
            (video: XCDYouTubeVideo?, error: NSError?) -> Void in
            if error != nil {
//                callback(streamURL: nil, duration:nil, error: error)
                print("XCDYouTube can't fetch URLs. Try to resolve via Dropbeat.")
                self.getYouTubeStreamURLFromDropbeat(callback)
                return
            }
            
            var preferredQuality: [XCDYouTubeVideoQuality] {
                let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                if appDelegate.networkStatus == .ReachableViaWiFi {
                    return [.HD720, .Medium360, .Small240]
                } else {
                    return [.Medium360, .Small240]
                }
            }
            
            var streamURL: NSURL?
            for quality in preferredQuality {
                if let url = video?.streamURLs[quality.rawValue] {
                    streamURL = url
                    break
                } else {
                    var qualityString: String {
                        switch quality {
                        case .Small240: return "Small240"
                        case .Medium360: return "Medium360"
                        case .HD720: return "HD720"
                        case .HD1080: return "HD1080"
                        }
                    }
                    
                    print("(\(self.title)) doesn't have \(qualityString) stream url. try next quality.")
                }
            }
            
            if streamURL != nil {
                callback(streamURL: streamURL!.absoluteString, duration:video?.duration, error: nil)
            } else {
                callback(streamURL: nil, duration:nil, error: NSError(domain: "TrackYouTubeStreamURL", code: -2, userInfo: nil))
            }
        })
    }
    
    func getYouTubeStreamURLFromDropbeat(callback:(streamURL:String?, duration:Double?, error:NSError?)->Void) {
        Requests.sendGet(ApiPath.youTubeResolve, params: ["uid": self.id, "t":"ios"], auth: false) { (result, error) -> Void in
            if error != nil {
                callback(streamURL: nil, duration:nil, error: error)
                return
            }
            
            guard let urls = result?["urls"] else {
                callback(streamURL: nil, duration:nil, error: NSError(domain: "TrackYouTubeStreamURL", code: -3, userInfo: nil))
                return
            }
            
            var preferredQualityFromDropbeat: [String] {
                let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                if appDelegate.networkStatus == .ReachableViaWiFi {
                    return ["high", "mid", "low"]
                } else {
                    return ["mid", "low"]
                }
            }
            
            var streamJson: JSON?
            for quality in preferredQualityFromDropbeat {
                if urls[quality] != JSON.null {
                    streamJson = urls[quality]
                    break
                } else {
                    print("(\(self.title)) doesn't have \(quality) stream url. try next quality.")
                }
            }
            
            if streamJson != nil {
                callback(
                    streamURL: streamJson!["url"].stringValue,
                    duration:streamJson!["duration"].doubleValue,
                    error: nil
                )
            } else {
                callback(streamURL: nil, duration:nil, error: NSError(domain: "TrackYouTubeStreamURL", code: -4, userInfo: nil))
            }
        }
    }
}

class Track {
    static var soundCloudKey: String = "02gUJC0hH2ct1EGOcYXQIzRFU91c72Ea"
    static func loadSoundCloudKey (callback:(NSError)->Void) {
        Requests.sendGet(ApiPath.metaKey, auth: false) { (result, error) -> Void in
            if error != nil {
                print("can't fetch sound cloud key")
                return
            }
            
            if let r = result, key = r["soundcloud_key"].string {
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
    
    var repostingUser: User?
    var repostedDate: NSDate?
    
    var hasHighDefThumbnail: Bool?
    var thumbnailUrl: String?
    
    var isLiked: Bool {
        if let account = Account.getCachedAccount() {
            return account.likes.contains { like in
                like.track.id == self.id
            }
        }
        return false
    }
    
    var streamUrl: String {
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
    
    init(id: String, title: String, type: SourceType, tag: String? = nil, thumbnailUrl: String? = nil, drop: Drop? = nil, releaseDate: NSDate? = nil) {
        self.id = id
        self.title = title
        self.drop = drop
        self.type = type
        self.tag = tag
        self.releaseDate = releaseDate
        
        switch type {
        case .YOUTUBE:
            self.thumbnailUrl = "http://img.youtube.com/vi/\(id)/mqdefault.jpg"
        case .SOUNDCLOUD:
            if let urlString = thumbnailUrl
                where urlString.contains("large.jpg") {
                self.thumbnailUrl = urlString.stringByReplacingOccurrencesOfString("large.jpg", withString: "t500x500.jpg")
            } else {
                fallthrough
            }
        default:
            self.thumbnailUrl = thumbnailUrl
        }
    }
    
    private convenience init(json: JSON) {
        self.init(
            id: json["id"].stringValue,
            title: json["title"].stringValue,
            type: SourceType.fromString(json["type"].stringValue),
            tag: json["tag"].string,
            thumbnailUrl: json["artwork"].string,
            drop: Drop(json: json["drop"]))
    }
    
    private convenience init(artistTrack json: JSON) {
        self.init(json: json)
        self.releaseDate = NSDate.dateFromString(json["release_date"].stringValue)
        
        self.user = BaseUser(
            userType: .ARTIST,
            name: json["dj"].stringValue,
            image: json["artist_image"].string,
            resourceName: json["resource_name"].stringValue)
    }
    
    private convenience init (channelTrack json: JSON) {
        self.init(json: json)
        self.releaseDate = NSDate.dateFromString(json["published_at"].stringValue)
        
        self.user = BaseUser(
            userType: .CHANNEL,
            name: json["channel_title"].stringValue,
            image: json["channel_image"].string,
            resourceName: json["resource_name"].stringValue)
    }
    
    static func parseRepostedTrack(json: JSON) -> Track {
        var track: Track!
        if json["unique_key"] != JSON.null {
            track = DropbeatTrack(json: json)
        } else {
            track = Track(json: json)
            if json["author_resource_name"] != JSON.null {
                track.user = BaseUser(
                    userType: .UNKNOWN,
                    name: json["author_nickname"].stringValue,
                    image: json["author_profile_image"].string,
                    resourceName: json["author_resource_name"].stringValue)
            }
        }
        track.repostingUser = User(json: json["repost"])
        track.repostedDate = NSDate.dateFromString(json["repost"]["created_at"].stringValue)
        
        return track
    }
    
    static func parseTracks(json: JSON) -> [Track] {
        var tracks = [Track]()
        for (_, t): (String, JSON) in json {
            var track: Track {
                if t["repost"] != JSON.null {
                    return parseRepostedTrack(t)
                } else if t["unique_key"] != JSON.null {
                    return DropbeatTrack(json: t)
                } else if t["dj"] != JSON.null {
                    return Track(artistTrack: t)
                } else if t["channel_title"] != JSON.null {
                    return Track(channelTrack: t)
                } else {
                    return Track(json: t)
                }
            }
            
            tracks.append(track)
        }
        return tracks
    }
    
    static func fetchFollowingTracks(pageIdx: Int, callback:((tracks:[Track]?, error:NSError?) -> Void)) {
        Requests.sendGet(ApiPath.streamFollowing, params: ["p": pageIdx], auth: true) { (result, error) -> Void in
            if (error != nil) {
                callback(tracks: nil, error: error)
                return
            }
            if (result == nil) {
                callback(tracks: [], error: nil)
                return
            }
            
            let tracks = Track.parseTracks(result!["data"])
            callback(tracks: tracks, error: nil)
        }
    }
    
    static func parseSharedTrack(json: JSON) -> Track? {
        var data = json["data"]
        if data == JSON.null {
            data = json["obj"]
        }
        
        return Track(
            id: data["ref"].stringValue,
            title: data["track_name"].stringValue,
            type: SourceType.fromString(data["type"].stringValue),
            tag: nil,
            thumbnailUrl: nil,
            drop: nil)
    }
    
    func repostTrack(afterRepost: (data:JSON?, error:NSError?) -> Void) {
        let data = self.toRepostData()
        
        Requests.sendPost(ApiPath.repost, params: ["data":data], auth: true) { (result, error) -> Void in
            guard error == nil else {
                afterRepost(data: nil, error: error)
                return
            }
            
            afterRepost(data: result!, error: nil)
        }
    }
    
    func toRepostData() -> [String:String] {
        var data = [String:String]()
        data["id"] = self.id
        data["title"] = self.title
        data["type"] = self.type.rawValue
        if self.user != nil {
            data["author_resource_name"] = self.user!.resourceName
            data["author_nickname"] = self.user!.name
            data["author_profile_image"] = self.user!.image
        }
        
        return data
    }
    
    func shareTrack(section:String, afterShare: (error:NSError?, sharedURL:NSURL?) -> Void) {
        Requests.shareTrack(self) { (result, error) -> Void in
            if error != nil {
                afterShare(error: error, sharedURL: nil)
                return
            }
            
            var data = result!["obj"]
            if data == JSON.null {
                data = result!["data"]
            }
            if let uid = data["uid"].string {
                // Log to GA
                let tracker = GAI.sharedInstance().defaultTracker
                let event = GAIDictionaryBuilder.createEventWithCategory(
                    "track-share",
                    action: "from-\(section)",
                    label: self.title,
                    value: 0
                    ).build()
                tracker.send(event as [NSObject: AnyObject]!)
                
                let URL = NSURL(string: "http://dropbeat.net/?track=" + uid)
                afterShare(error: nil, sharedURL:URL)
            } else {
                afterShare(error: NSError(domain: "shareTrack", code: 1, userInfo: nil), sharedURL: nil)
                return
            }
            
            
        }
    }
}

class DropbeatTrack: Track {
    enum TrackType {
        case TRACK
        case MIXSET
    }
    
    private var _streamUrl: String
    override var streamUrl: String { return _streamUrl }
    
    var trackType: TrackType = .TRACK
    var description: String?
    var genre: String?
    var likeCount = 0
    var playCount = 0
    var repostCount = 0
    var resourcePath: String!
    var uniqueKey: String!
 
    init (json: JSON) {

        self._streamUrl = json["stream_url"].stringValue
        super.init(
            id: json["id"].stringValue,
            title: json["name"].stringValue,
            type: .DROPBEAT,
            thumbnailUrl: json["coverart_url"].string,
            releaseDate: NSDate.dateFromString(json["created_at"].stringValue))
        
        if let dropUrl = json["drop_url"].string {
            self.drop = Drop(dref: dropUrl, type: .DROPBEAT)
        }
        
        self.description = json["description"].stringValue
        self.trackType = (json["track_type"].stringValue == "TRACK") ? .TRACK : .MIXSET
        self.likeCount = json["like_count"].intValue
        self.playCount = json["play_count"].intValue
        self.repostCount = json["repost_count"].intValue
        
        self.resourcePath = json["resource_path"].stringValue
        self.uniqueKey = json["unique_key"].stringValue
        
        self.genre = GenreList.getGenreName(json["genre_id"].intValue)
        
        self.user = BaseUser(
            userType: .USER,
            name: json["user_name"].stringValue,
            image: json["user_profile_image"].stringValue,
            resourceName: json["user_resource_name"].stringValue)
    }
    
    static func resolve(user: String, track: String, callback:((track: Track?, error: NSError?) -> Void)) {
        Requests.sendGet(ApiPath.resolveResource, params:["url":"/r/\(user)/\(track)"], auth: false) {
            (result, error) -> Void in
            if (error != nil) {
                callback(track: nil, error: error)
                return
            }
            
            let t = DropbeatTrack(json: result!["data"])
            callback(track: t, error: nil)
        }
    }
    
    override func toRepostData() -> [String : String] {
        return [
            "id" : self.id,
            "type" : self.type.rawValue
        ]
    }
    
    override func shareTrack(section:String, afterShare: (error:NSError?, sharedURL:NSURL?) -> Void) {
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
        
        let URL = NSURL(string: "http://dropbeat.net/r/\(userResourceName)/\(self.resourcePath)")
        afterShare(error: nil, sharedURL: URL)
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
        Requests.sendGet(ApiPath.userTrackNewUploads, params: params, auth: false) { (result, error) -> Void in
            if (error != nil) {
                callback(tracks: nil, error: error)
                return
            }
            if (result == nil) {
                callback(tracks: [], error: nil)
                return
            }
            
            var tracks = [DropbeatTrack]()
            for (_, t) in result!["data"] {
                let track = DropbeatTrack(json: t)
                tracks.append(track)
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

        Requests.sendPost(ApiPath.logPlaybackDetail, params: log, auth: false) { (result, error) -> Void in
            if result != nil {
                print("playback detail log posted: \(result!)")
            }
        }
    }
}

extension Track { // for Play Failure Log
    func postFailureLog(description: String) {
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
        
        log["description"] = description
        
        Requests.sendPost(ApiPath.logPlayFailure, params: log, auth: false) { (result, error) -> Void in
            if result != nil {
                print("play failure log posted: \(result!) (\(description))")
            }
        }
    }
}

class Drop {
    var dref:String
    var type:SourceType
    
    init (dref:String, type:SourceType) {
        self.type = type
        self.dref = dref
    }
    
    convenience init? (json: JSON) {
        if json == JSON.null {
            return nil
        }
        
        self.init(
            dref: json["dref"].stringValue,
            type: SourceType.fromString(json["type"].stringValue)
        )
    }
    
    var streamUrl:String? {
        switch self.type {
        case .DROPBEAT:
            return self.dref
        case .SOUNDCLOUD:
            return "https://api.soundcloud.com/tracks/\(self.dref)/stream?client_id=\(Track.soundCloudKey)"
        default:
            if self.dref.characters.startsWith("http".characters) {
                return self.dref.stringByRemovingPercentEncoding!
            } else {
                return nil
            }
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
    
    static func parseLikes(json:JSON) -> [Like]? {
        var likes = [Like]()
        for (_, obj): (String, JSON) in json {
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
            Requests.sendPost(ApiPath.userTrackLike, params: ["track_id":track.id], auth: true) { (result, error) -> Void in
                if error != nil {
                    callback?(error:error)
                    return
                }
                
                if let like = Like(json: result!["obj"]) {
                   let account = Account.getCachedAccount()
                    account!.likes.append(like)
                    callback?(error:nil)
                    
                    postLikeUpdatedNotification(track)
                }
            }
        default:
            Requests.doLike(track) { (result, error) -> Void in
                if error != nil {
                    callback?(error:error)
                    return
                }
                
                if let like = Like(json: result!["obj"]) {
                    let account = Account.getCachedAccount()
                    account!.likes.append(like)
                    callback?(error:nil)
                    
                    postLikeUpdatedNotification(track)
                }
            }
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
            callback?(error: NSError(domain: "unlikeTrack", code: -9, userInfo: nil))
            return
        }
        
        let likeId = filteredLikes.first?.id
        switch track {
        case is DropbeatTrack:
            Requests.send(.DELETE, url: ApiPath.userTrackLike, params: ["like_id":likeId!], auth: true) { (result, error) -> Void in
                if error != nil {
                    callback?(error:error)
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
                
                postLikeUpdatedNotification(track)
            }
            break
        default:
            Requests.doUnlike(likeId!) { (result, error) -> Void in
                if error != nil {
                    callback?(error:error)
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
                
                postLikeUpdatedNotification(track)
            }
        }
    }
    
    static func postLikeUpdatedNotification(track: Track) {
        NSNotificationCenter.defaultCenter().postNotificationName(NotifyKey.likeUpdated, object: track)
    }
    
}

