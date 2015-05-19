//
//  Stream.swift
//  labs
//
//  Created by Park Il Su on 2015. 5. 18..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import SwiftyJSON
import Foundation


func resolve(uid: String, type: String, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) {
    if type == "soundcloud" {
        var url :String = String(format: "https://api.soundcloud.com/tracks/%s/stream?client_id=b45b1aa10f1ac2941910a7f0d10f8e28", uid)

        var raw: Dictionary<String, AnyObject> = [String: AnyObject]()
        var data: [Dictionary<String, AnyObject>] = Array<[String: AnyObject]>()
        raw["urls"] = data
        data.append([
            "url": url
        ])
        respCb(NSURLRequest(), nil, raw, nil)
    } else if type == "youtube" {
        Requests.streamResolve(uid, respCb: respCb)
    }
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
