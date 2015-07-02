//
//  Stream.swift
//  labs
//
//  Created by Park Il Su on 2015. 5. 18..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import Foundation


func resolveLocal(uid: String, type: String) -> String? {
    if type == "soundcloud" {
        return "https://api.soundcloud.com/tracks/\(uid)/stream?client_id=b45b1aa10f1ac2941910a7f0d10f8e28"
    } else if (type != "youtube" && startsWith(uid, "http")) {
        return uid.stringByRemovingPercentEncoding!
    }
    return nil
}

func resolve(uid: String, type: String, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) -> Request? {
    if type == "soundcloud" {
        var url :String = "https://api.soundcloud.com/tracks/\(uid)/stream?client_id=b45b1aa10f1ac2941910a7f0d10f8e28"

        Requests.soundcloudHead(url, respCb: {(request:NSURLRequest, response:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            var statusCode = response?.statusCode ?? 999
            var raw: Dictionary<String, AnyObject> = [String: AnyObject]()
            var data: [Dictionary<String, AnyObject>] = Array<[String: AnyObject]>()
            if (response == nil || Int(response!.statusCode / 100) > 2) {
                raw["urls"] = data
                respCb(NSURLRequest(), nil, raw, nil)
            }
            data.append([
                "url": url,
                "ext": "mp3"
            ])
            raw["urls"] = data
            respCb(NSURLRequest(), nil, raw, nil)
        })
    } else if type == "youtube" {
        return Requests.streamResolve(uid, respCb: respCb)
    } else if (startsWith(uid, "http")) {
        var raw: Dictionary<String, AnyObject> = [String: AnyObject]()
        var data: [Dictionary<String, AnyObject>] = Array<[String: AnyObject]>()
        var url = uid.stringByRemovingPercentEncoding!
        
        data.append([
            "url": url,
            "ext": "mp3"
        ])
        raw["urls"] = data
        respCb(NSURLRequest(), nil, raw, nil)
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
