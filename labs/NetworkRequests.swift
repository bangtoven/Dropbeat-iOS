//
//  NetworkRequests.swift
//  labs


import Alamofire


class Requests {
    static func sendGet(url: String, params: Dictionary<String, AnyObject>? = nil, auth: Bool, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) {
        send(Method.GET, url: url, params: params, auth: auth, respCb: respCb)
    }
   
    static func sendPost(url: String, params: Dictionary<String, AnyObject>? = nil, auth: Bool, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) {
        send(Method.POST, url: url, params: params, auth: auth, respCb: respCb)
    }
    
    static func sendPut(url: String, params: Dictionary<String, AnyObject>? = nil, auth: Bool, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) {
        send(Method.PUT, url: url, params: params, auth: auth, respCb: respCb)
    }
    
    static func send(method: Method, url: String, params: Dictionary<String, AnyObject>? = nil, auth: Bool, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) {
        var adapter = WebAdapter(url: url, method: method, params: params, auth: auth)
        adapter.send(respCb)
    }
    
    static func userSelf(respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) {
        sendGet(ApiPath.userSelf, auth: true, respCb: respCb)
    }
    
    static func userSignin(params: Dictionary<String, String>, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) {
        sendPost(ApiPath.userSignIn, params: params, auth: false, respCb: respCb)
    }
    
    static func getPlaylist(id: String, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) {
        sendGet(ApiPath.playlist, params: ["id": id], auth: true, respCb: respCb)
    }
    
    static func createPlaylist(name: String, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) {
        sendPost(ApiPath.playlist, params: ["name": name], auth: true, respCb: respCb)
    }
    
    
    // `data` should be JsonArray.
    static func setPlaylist(id: String, data: AnyObject, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) {
        sendPost(ApiPath.playlist, params: ["id": id, "data": data], auth: true, respCb: respCb)
    }   
    
    static func deletePlaylist(id: String, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void))  {
        sendPost(ApiPath.playlistDel, params: ["id": id], auth: true, respCb: respCb)
    }
    
    static func changePlaylistName(id: String, name: String, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void))  {
        sendPut(ApiPath.playlist, params: ["id": id, "name": name], auth: true, respCb: respCb)
    }
    
    static func fetchAllPlaylists(respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) {
        sendGet(ApiPath.playlistAll, auth: true, respCb: respCb)
    }
    
    static func fetchInitialPlaylist(respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) {
        sendGet(ApiPath.playlistIntial, auth: false, respCb: respCb)
    }
    
    static func getSharedPlaylist(uid: String, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) {
        sendGet(ApiPath.playlistShared, params: ["uid": uid], auth: false, respCb: respCb)
    }
    
    static func sharePlaylist(name: String, data: AnyObject, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) {
        sendPost(ApiPath.playlistShared, params: ["name": name, "data": data], auth: true, respCb: respCb)
    }
    
    static func importPlaylist(uid: String, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) {
        sendGet(ApiPath.playlistShared, params: ["uid": uid], auth: false, respCb: respCb)
    }
    
    static func search(q: String, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) {
        sendGet(CorePath.search, params: ["q": q], auth: false, respCb: respCb)
    }
    
    static func streamResolve(uid: String, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) {
        sendGet(ResolvePath.resolveStream, params: ["uid": uid], auth: false, respCb: respCb)
    }
    
    static func fetchFeed(respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) {
        // TODO: Get global session key.
        var authenticated = false;
        sendGet(ApiPath.feed, auth: authenticated, respCb: respCb)
    }
    
    static func logSearch(keyword: String) {
        Alamofire.request(Method.GET, ApiPath.logSearch, parameters: ["q": keyword], encoding: .URL).validate()
    }
    
    static func logTrackAdd(title: String) {
        Alamofire.request(Method.GET, ApiPath.logSearch, parameters: ["t": title], encoding: .URL).validate()
    }
    
    static func logPlay(title: String) {
        Alamofire.request(Method.GET, ApiPath.logSearch, parameters: ["t": title], encoding: .URL).validate()
    }
    
    static func getClientVersion(respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) {
        sendGet(ApiPath.metaVersion, auth: false, respCb: respCb)
    }
}

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
            let keychainItemWrapper = KeychainItemWrapper(identifier: "net.dropbeat.spark", accessGroup: nil)
            var key :String = keychainItemWrapper["auth_token"] as! String
//            var key :String = "0osyggg96aogbrb0vk820kcb9v8i3nv5"
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
        Alamofire.request(self.method!, self.url!, parameters: self.params, encoding: enc!).validate().responseJSON(completionHandler: respCb)
    }
}