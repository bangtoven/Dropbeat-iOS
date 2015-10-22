//
//  OldModels.swift
//  labs
//
//  Created by Park Il Su on 2015. 5. 17..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

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
            
//            var drop:Drop?
//            var dropObj = s["drop"]
//            if dropObj != nil && dropObj["dref"].string != nil &&
//                dropObj["dref"].stringValue.characters.count > 0 &&
//                dropObj["type"].string != nil {
//                    
//                    drop = Drop(
//                        dref: dropObj["dref"].stringValue,
//                        type: dropObj["type"].stringValue,
//                        when: dropObj["when"].int)
//            }
            
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
            
            track.drop = Drop(json: s["drop"])
            
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
            
//            var drop:Drop?
//            var dropObj = s["drop"]
//            if dropObj != nil && dropObj["dref"].string != nil &&
//                dropObj["dref"].stringValue.characters.count > 0 &&
//                dropObj["type"].string != nil {
//                    
//                    drop = Drop(
//                        dref: dropObj["dref"].stringValue,
//                        type: dropObj["type"].stringValue,
//                        when: dropObj["when"].int)
//            }
            track.drop = Drop(json: s["drop"])
            
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
            
//            var drop:Drop?
//            var dropObj = s["drop"]
//            if dropObj != nil && dropObj["dref"].string != nil &&
//                dropObj["dref"].stringValue.characters.count > 0 &&
//                dropObj["type"].string != nil {
//                    
//                    drop = Drop(
//                        dref: dropObj["dref"].stringValue,
//                        type: dropObj["type"].stringValue,
//                        when: dropObj["when"].int)
//            }
            track.drop = Drop(json: s["drop"])
            
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
            
//            var drop:Drop?
//            var dropObj = s["drop"]
//            if dropObj != nil && dropObj["dref"].string != nil &&
//                dropObj["dref"].stringValue.characters.count > 0 &&
//                dropObj["type"].string != nil {
//                    
//                    drop = Drop(
//                        dref: dropObj["dref"].stringValue,
//                        type: dropObj["type"].stringValue,
//                        when: dropObj["when"].int)
//            }
            track.drop = Drop(json: s["drop"])
            
            tracks.append(track)
        }
        return StreamBeatportTrending(success: true, tracks: tracks)
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
            super.init(id: id, title: "\(artist) - \(trackName)", type: SourceType.fromString(type), tag: nil, thumbnailUrl: thumbnailUrl, drop: nil)
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
        super.init(id: id, title: "\(artist) - \(trackName)", type: SourceType.fromString(type))
        self.artist = artist
        self.snippet = snippet
        self.trackName = trackName
        if (self.type == .YOUTUBE) {
            self.thumbnailUrl = "http://img.youtube.com/vi/\(self.id)/mqdefault.jpg"
        }
    }
}

class NewReleaseTrack:Track {
    var artist:String!
    var trackName: String!
    var releasedAt: NSDate?
    init(id:String, trackName:String, artist:String, type:String, thumbnail: String?, releasedAt:NSDate?) {
        super.init(id: id, title: "\(artist) - \(trackName)", type: SourceType.fromString(type), tag: nil, thumbnailUrl:thumbnail)
        self.artist = artist
        self.trackName = trackName
        self.releasedAt = releasedAt
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