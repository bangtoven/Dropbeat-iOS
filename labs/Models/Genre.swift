//
//  Genre.swift
//  labs
//
//  Created by Jungho Bang on 2015. 9. 25..
//  Copyright © 2015년 dropbeat. All rights reserved.
//

import UIKit


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
    
    static func getGenreName(id: Int, key: String = "dropbeat") -> String? {
        if let genres = GenreList.cachedResult![key] {
            var name: String?
            for g: Genre in genres {
                if g.key == String(id) {
                    name = g.name
                    break
                }
            }
            return name
        } else {
            return nil
        }
    }
    
    static func parseGenre(data: AnyObject) -> GenreList {
        var json = JSON(data)
        
        if !(json["success"].bool ?? false) {
            return GenreList(success: false, results: nil)
        }
        
        var genres = [String:[Genre]]()
        var defaultGenres = [Genre]()
        var channelGenres = [Genre]()
        var trendingGenres = [Genre]()
        var dropbeatGenres = [Genre]()
        
        
        defaultGenres.append(Genre(key:"", name:"ALL"))
        for (_, s): (String, JSON) in json["default"] {
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
        for (_, s): (String, JSON) in json["channel"] {
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
        for (_, s): (String, JSON) in json["trending"] {
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
        
        dropbeatGenres.append(Genre(key:"", name:"ALL"))
        for (_, s): (String, JSON) in json["dropbeat"] {
            if s["id"].int == nil {
                continue
            }
            let key = s["id"].intValue
            
            if s["name"].string == nil {
                continue
            }
            
            let name = s["name"].stringValue
            dropbeatGenres.append(Genre(key:"\(key)", name:name))
        }
        
        genres["default"] = defaultGenres
        genres["channel"] = channelGenres
        genres["trending"] = trendingGenres
        genres["dropbeat"] = dropbeatGenres
        
        GenreList.cachedResult = genres
        
        return GenreList(success: true, results: genres)
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
        for (_, s): (String, JSON) in json["data"] {
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