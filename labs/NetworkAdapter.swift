//
//  NetworkAdapter.swift
//  labs
//
//  Created by Park Il Su on 2015. 5. 15..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import Alamofire

class WebAdapter {
    var url: String?
    var method :Method?
    var params :Dictionary<String, AnyObject>?
    var auth: Bool?
    
    init(url :String, method :Method, params: Dictionary<String, AnyObject>?, auth :Bool) {
        self.url = url
        self.method = method
        self.params = params
        self.auth = auth
    }
    
    func prepare() {
        var manager = Manager.sharedInstance
        if (auth == true) {
            // TODO: Get global session key.
            var key :String = "0osyggg96aogbrb0vk820kcb9v8i3nv5"
            manager.session.configuration.HTTPAdditionalHeaders = [
                "Cookie": "sessionid=" + key
            ]
        }
    }
    
    func send(respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) {
        prepare()
        
        var enc :ParameterEncoding?
        if (self.method == Method.GET) {
            enc = .URL
        } else {
            enc = .JSON
        }
        Alamofire.request(self.method!, self.url!, parameters: self.params, encoding: enc!).responseJSON(completionHandler: respCb)
    }
}