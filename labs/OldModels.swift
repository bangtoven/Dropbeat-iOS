//
//  OldModels.swift
//  labs
//
//  Created by Park Il Su on 2015. 5. 17..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class Feed {
    var result: [Track] = []
    init (tracks: [Track]) {
        self.result = tracks
    }
    
    static func parseFeed(data: AnyObject) -> Feed {
        var json = JSON(data)
        var tracks: [Track] = []
        for (_, s): (String, JSON) in json["feed"] {
            var id: AnyObject
            if s["id"].string == nil {
                id = String(s["id"].int!)
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
            
            tracks.append(track)
        }
        let feed = Feed(tracks: tracks)
        return feed
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
        var json = JSON(data)
        
        if !(json["success"].bool ?? false) {
            return BeatportChart(success:false, tracks:nil)
        }
        
        var tracks:[BeatportTrack] = [BeatportTrack]()
        for (_, s): (String, JSON) in json["data"] {
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
            
            let releasedAt = NSDate.dateFromString(s["released"].stringValue)
            
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
    
    static func parseStreamNew(data: AnyObject) -> StreamNew {
        var json = JSON(data)
        if !(json["success"].bool ?? false) || json["data"] == nil {
            return StreamNew(success: false, tracks: nil)
        }
        
        var tracks:[NewReleaseTrack] = []
        
        for (_, s): (String, JSON) in json["data"] {
            if s["id"].string == nil ||
                s["track_name"].string == nil ||
                s["type"].string == nil ||
                s["artist_name"].string == nil ||
                s["release_date"].string == nil ||
                s["thumbnail"].string == nil {
                    continue
            }
            
            let releasedAt = NSDate.dateFromString(s["release_date"].stringValue)

            let track = NewReleaseTrack(
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
        
        return StreamNew(success: true, tracks: tracks)
    }
}

class StreamTrending {
    var success:Bool
    var results:[TrendingTrack]?
    init(success: Bool, tracks:[TrendingTrack]?) {
        self.success = success
        results = tracks
    }
    
    static func parseStreamTrending(data: AnyObject) -> StreamTrending {
        var json = JSON(data)
        if !(json["success"].bool ?? false) || json["data"] == nil {
            return StreamTrending(success: false, tracks: nil)
        }
        
        var tracks:[TrendingTrack] = []
        
        for (_, s): (String, JSON) in json["data"] {
            if s["id"].string == nil ||
                s["track_name"].string == nil ||
                s["type"].string == nil ||
                s["artist_name"].string == nil ||
                s["snippet"].string == nil {
                    continue
            }
            
            
            let track = TrendingTrack(
                id: s["id"].stringValue,
                trackName: s["track_name"].stringValue,
                artist: s["artist_name"].stringValue,
                type: s["type"].stringValue,
                snippet:s["snippet"].stringValue
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
        
        return StreamTrending(success: true, tracks: tracks)
    }
}

class StreamBeatportTrending {
    var success:Bool
    var results:[BeatportTrack]?
    init(success: Bool, tracks:[BeatportTrack]?) {
        self.success = success
        results = tracks
    }
    
    static func parseStreamBeatportTrending(data: AnyObject) -> StreamBeatportTrending {
        var json = JSON(data)
        
        if !(json["success"].bool ?? false) {
            return StreamBeatportTrending(success:false, tracks:nil)
        }
        
        var tracks:[BeatportTrack] = [BeatportTrack]()
        for (_, s): (String, JSON) in json["data"] {
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
            
            let releasedAt = NSDate.dateFromString(s["released"].stringValue)
            
            
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
        return StreamBeatportTrending(success: true, tracks: tracks)
    }
}

class StreamFollowing {
    var success:Bool
    var results:[FollowingArtistTrack]?
    init(success: Bool, tracks:[FollowingArtistTrack]?) {
        self.success = success
        results = tracks
    }
    
    static func parseStreamFollowing(data: AnyObject) -> StreamFollowing {
        var json = JSON(data)
        
        if !(json["success"].bool ?? false) {
            return StreamFollowing(success:false, tracks:nil)
        }
        
        var tracks:[FollowingArtistTrack] = [FollowingArtistTrack]()
        
        for (_, s): (String, JSON) in json["data"] {
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
            
            let releasedAt = NSDate.dateFromString(s["release_date"].stringValue)
            
            var thumbnail:String?
            if let url = s["thumbnail"].string {
                thumbnail = url
            } else if type == "youtube" {
                thumbnail = "http://img.youtube.com/vi/\(id)/mqdefault.jpg"
            }
            
            let track = FollowingArtistTrack(
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
        return StreamFollowing(success: true, tracks: tracks)
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
            super.init(id: id, title: "\(artist) - \(trackName)", type: type, tag: nil, thumbnailUrl: thumbnailUrl, drop: nil)
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
        var json = JSON(data)
        
        if !(json["success"].bool ?? false) {
            return FollowingInfo(success:false, results:nil)
        }
        
        var followings = [Following]()
        for (_, s): (String, JSON) in json["data"] {
            if s["id"].int == nil {
                continue
            }
            let id = s["id"].intValue
            
            if s["name"].string == nil || s["name"].stringValue.characters.count == 0 {
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
        var json = JSON(data)
        
        if !(json["success"].bool ?? false) {
            return SearchArtist(success:false, results:nil)
        }
        
        var followings = [Following]()
        for (_, s): (String, JSON) in json["data"] {
            if s["id"].int == nil {
                continue
            }
            let id = s["id"].intValue
            
            if s["name"].string == nil || s["name"].stringValue.characters.count == 0 {
                continue
            }
            let name = s["name"].stringValue
            
            followings.append(Following(id:id, name:name, isFollowing:false))
        }
        return SearchArtist(success:true, results:followings)
    }
}

class FBPageLikes {
    var pages:[FBPage]
    var nextPageToken:String?
    
    init (pages:[FBPage], nextPageToken:String?) {
        self.pages = pages
        self.nextPageToken = nextPageToken
    }
    
    static func parseFBPageLikes(data: AnyObject) -> FBPageLikes? {
        let json = JSON(data)
        var pages = [FBPage]()
        
        if json["data"].array == nil || json["error"] != nil {
            return nil
        }
        
        var nextPageToken:String?
        if json["paging"] != nil && json["paging"]["next"].string != nil {
            nextPageToken = json["paging"]["next"].string
        }
        
        for (_, pageJson): (String, JSON) in json["data"] {
            let page = FBPage.parseFBPageJson(pageJson)
            if page == nil {
                continue
            }
            
            pages.append(page!)
        }
        
        return FBPageLikes(pages: pages, nextPageToken: nextPageToken)
    }
}

class FBPage {
    var id:String
    var name:String
    init(id:String, name:String) {
        self.id = id
        self.name = name.uppercaseString
    }
    
    static private func parseFBPageJson(json: JSON) -> FBPage? {
        if json["id"].string == nil {
            return nil
        }
        
        if json["name"].string == nil {
            return nil
        }
        
        return FBPage(id: json["id"].stringValue, name: json["name"].stringValue)
    }
}