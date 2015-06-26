//
//  Stream.swift
//  labs
//
//  Created by Park Il Su on 2015. 5. 18..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import Foundation


func resolve(uid: String, type: String, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) -> Request? {
    if type == "soundcloud" {
        var url :String = "https://api.soundcloud.com/tracks/\(uid)/stream?client_id=b45b1aa10f1ac2941910a7f0d10f8e28"

        var raw: Dictionary<String, AnyObject> = [String: AnyObject]()
        var data: [Dictionary<String, AnyObject>] = Array<[String: AnyObject]>()
        data.append([
            "url": url,
            "ext": "mp3"
        ])
        raw["urls"] = data
        respCb(NSURLRequest(), nil, raw, nil)
    } else if type == "youtube" {
        return Requests.streamResolve(uid, respCb: respCb)
    }
    return nil
}


func getStreamUrls(data: AnyObject) -> [StreamSource]{
    var urls :[StreamSource] = []
    var json = JSON(data)
    for (index: String, s: JSON) in json["urls"] {
        var streamSource = StreamSource(url: s["url"].stringValue, type: s["ext"].stringValue)
        var formatNote = s["format_note"]
        if formatNote.error == nil {
            streamSource.formatNote = formatNote.stringValue
        }
        urls.append(streamSource)
    }
    return urls
}
