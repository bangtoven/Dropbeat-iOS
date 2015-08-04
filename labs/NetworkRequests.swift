//
//  NetworkRequests.swift
//  labs

import Foundation

class Requests {
    static var EMPTY_RESPONSE_CALLBACK = {(req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
    }
    
    static func sendGet(url: String, params: Dictionary<String, AnyObject>? = nil, auth: Bool, background: Bool = false, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) -> Request {
        return send(Method.GET, url: url, params: params, auth: auth, background:background, respCb: respCb)
    }
   
    static func sendPost(url: String, params: Dictionary<String, AnyObject>? = nil, auth: Bool, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) -> Request {
        return send(Method.POST, url: url, params: params, auth: auth, respCb: respCb)
    }
    
    static func sendPut(url: String, params: Dictionary<String, AnyObject>? = nil, auth: Bool, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) -> Request {
        return send(Method.PUT, url: url, params: params, auth: auth, respCb: respCb)
    }
    
    static func sendHead(url: String, params: Dictionary<String, AnyObject>? = nil, auth: Bool, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) -> Request {
        return send(Method.HEAD, url: url, params: params, auth: auth, respCb: respCb)
    }
    
    static func send(method: Method, url: String, params: Dictionary<String, AnyObject>? = nil, auth: Bool, background: Bool = false,respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) -> Request {
        var adapter = WebAdapter(url: url, method: method, params: params, auth: auth, background:background)
        return adapter.send(respCb)
    }
    
    static func userSelf(respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) -> Request {
        return sendGet(ApiPath.userSelf, auth: true, respCb: respCb)
    }
    
    static func userSignin(params: Dictionary<String, String>, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) -> Request {
        return sendPost(ApiPath.userSignIn, params: params, auth: false, respCb: respCb)
    }
    
    static func getPlaylist(id: String, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) -> Request {
        return sendGet(ApiPath.playlist, params: ["id": id], auth: true, respCb: respCb)
    }
    
    static func createPlaylist(name: String, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) -> Request{
        return sendPost(ApiPath.playlist, params: ["name": name], auth: true, respCb: respCb)
    }
    
    
    // `data` should be JsonArray.
    static func setPlaylist(id: String, data: AnyObject, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) -> Request{
        return sendPost(ApiPath.playlistSet, params: ["playlist_id": id, "data": data], auth: true, respCb: respCb)
    }   
    
    static func deletePlaylist(id: String, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) -> Request{
        return sendPost(ApiPath.playlistDel, params: ["id": id], auth: true, respCb: respCb)
    }
    
    static func changePlaylistName(id: String, name: String, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void))  -> Request {
        return sendPut(ApiPath.playlist, params: ["id": id, "name": name], auth: true, respCb: respCb)
    }
    
    static func fetchAllPlaylists(respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) -> Request{
        return sendGet(ApiPath.playlistAll, auth: true, respCb: respCb)
    }
    
    static func fetchInitialPlaylist(respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) -> Request {
        return sendGet(ApiPath.playlistIntial, auth: false, respCb: respCb)
    }
    
    static func getSharedPlaylist(uid: String, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) -> Request{
        return sendGet(ApiPath.playlistShared, params: ["uid": uid], auth: false, respCb: respCb)
    }
    
    static func importPlaylist(uid: String, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) -> Request{
        return sendGet(ApiPath.playlistShared, params: ["uid": uid], auth: false, respCb: respCb)
    }
    
    static func search(q: String, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) -> Request{
        return sendGet(CorePath.search, params: ["q": q, "snippet": 1], auth: false, respCb: respCb)
    }
    
    static func searchOther(q: String, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) -> Request{
        return sendGet(CorePath.searchOther, params: ["q": q], auth: false, respCb: respCb)
    }
    
    static func searchLiveset(q: String, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) -> Request{
        return sendGet(CorePath.searchLiveset, params: ["q": q], auth: false, respCb: respCb)
    }
    
    static func searchPodcast(q: String, page: Int, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) -> Request{
        return sendGet(CorePath.podcast, params: ["q": q, "p": page], auth: false, respCb: respCb)
    }
    
    static func streamResolve(uid: String, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) -> Request{
        let systemVersion = UIDevice.currentDevice().systemVersion
        var firstDigit = ""
        if (count(systemVersion) > 0) {
            firstDigit = systemVersion.substringToIndex(advance(systemVersion.startIndex, 1))
        }
        return sendGet(ResolvePath.resolveStream, params: ["uid": uid, "v": 1, "t": "ios\(firstDigit)"], auth: false, background: false, respCb: respCb)
    }
    
    static func fetchFeed(respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) -> Request{
        let keychainItemWrapper = KeychainItemWrapper(identifier: "net.dropbeat.spark", accessGroup: nil)
        var key :String? = keychainItemWrapper["auth_token"] as? String
        var authenticated = key != nil
        return sendGet(ApiPath.feed, auth: authenticated, respCb: respCb)
    }
    
    static func logSearch(keyword: String) -> Request{
        return request(Method.GET, ApiPath.logSearch, parameters: ["q": keyword], encoding: .URL).validate()
    }
    
    static func logTrackAdd(title: String) -> Request{
        return request(Method.GET, ApiPath.logTrackAdd, parameters: ["t": title], encoding: .URL).validate()
    }
    
    static func logPlay(title: String) -> Request{
        return request(Method.GET, ApiPath.logPlay, parameters: ["t": title], encoding: .URL).validate()
    }
    
    static func getClientVersion(respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) -> Request {
        return sendGet(ApiPath.metaVersion, auth: false, respCb: respCb)
    }
    
    static func soundcloudHead(url: String, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) -> Request{
        let manager =  Manager.sharedInstance
        let enc = ParameterEncoding.URL
        var req = manager.request(Method.HEAD, url, parameters: Dictionary<String, AnyObject>(), encoding: enc)
        req.validate().response(respCb)
        return req
    }
    
    static func getChannelList(genre: String, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) -> Request {
        return sendGet(CorePath.channelList, params: ["genre": genre], auth: false, respCb: respCb)
    }
    
    static func getChannelDetail(uid: String, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) -> Request {
        return sendGet(CorePath.channelDetail, params: ["uid": uid], auth: false, respCb: respCb)
    }
    
    static func getBookmarkList(respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) -> Request {
        return sendGet(ApiPath.bookmark, auth: true, respCb: respCb)
    }
    
    static func updateBookmarkList(ids: [String], respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) -> Request {
        return sendPost(ApiPath.bookmark, params: ["data": ids], auth: true, respCb: respCb)
    }
    
    static func getChannelPlaylist(uid: String, pageToken: String?, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) -> Request {
        var params:[String:AnyObject] = [
            "part": "id,snippet",
            "key" : ApiKey.google,
            "maxResults" : 50,
            "playlistId": uid
        ]
        if pageToken != nil {
            params["pageToken"] = pageToken!
        }
        return sendGet(CorePath.channelGproxy, params: params, auth:false, respCb: respCb)
    }
    
    static func sharePlaylist(playlist:Playlist, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) -> Request {
        var playlistData = playlist.toJson()
        return sendPost(ApiPath.playlistShared, params: playlistData, auth: true, respCb: respCb)
    }
    
    static func shareTrack(track:Track, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) -> Request {
        return sendPost(ApiPath.trackShare, params: ["track_name": track.title, "ref": track.id], auth: true, respCb: respCb)
    }
    
    static func getSharedTrack(uid:String, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) -> Request {
        return sendGet(ApiPath.trackShare, params: ["uid": uid], auth:false, respCb: respCb)
    }
    
    static func sendFeedback(senderEmail:String, content:String, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) -> Request {
        
        return sendPost(ApiPath.feedback, params: ["sender": senderEmail, "content": content], auth: false, respCb: respCb)
    }
    
    static func fetchChannelFeed(pageIdx:Int, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) -> Request {
        return sendGet(ApiPath.feedChannel, params: ["p": pageIdx], auth:true, respCb: respCb)
    }
    
    static func artistFilter(names:[String], respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) -> Request {
        return sendPost(CorePath.artistFilter, params: ["q": names], auth:false, respCb: respCb)
    }
    
    static func follow(ids:[Int], respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) -> Request {
        return sendPost(ApiPath.artistFollow, params: ["ids": ids], auth:true, respCb: respCb)
    }
    
    static func unfollow(ids:[Int], respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) -> Request {
        return sendPost(ApiPath.artistUnfollow, params: ["ids": ids], auth:true, respCb: respCb)
    }
    
    static func following(respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) -> Request {
        return sendGet(ApiPath.artistFollowing, params: nil, auth:true, respCb: respCb)
    }
    
    static func fetchBeatportChart(genre:String, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) -> Request {
        return sendGet(CorePath.trendingChart, params:["type": genre], auth:false, respCb: respCb)
    }
    
    static func getFeedGenre(respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) -> Request {
        return sendGet(CorePath.genre, params:nil, auth:false, respCb: respCb)
    }
    
    static func getStreamNew(genre:String?, pageIdx:Int, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) -> Request {
        var params:[String:AnyObject] = ["p": pageIdx]
        if genre != nil && count(genre!) > 0 {
            params["g"] = genre
        }
        return sendGet(CorePath.streamNew, params:params, auth:false, respCb: respCb)
    }
    
    static func getStreamTrending(genre:String?, pageIdx:Int, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) -> Request {
        var params:[String:AnyObject] = ["p": pageIdx]
        if genre != nil && count(genre!) > 0 {
            params["g"] = genre
        }
        return sendGet(CorePath.streamTrending, params:params, auth:false, respCb: respCb)
    }
    
    static func getStreamFollowing(pageIdx:Int, order:String, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) -> Request {
        var params:[String:AnyObject] = ["p": pageIdx, "order": order]
        return sendGet(ApiPath.streamFollowing, params:params, auth:true, respCb: respCb)
    }
    
    static func searchArtist(keyword:String, respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) -> Request {
        return sendGet(CorePath.searchArtist, params:["q": keyword], auth:false, respCb:respCb)
    }
}


class WebAdapter {
    var url: String?
    var method :Method?
    var params :Dictionary<String, AnyObject>?
    var auth: Bool?
    var background: Bool?
    var manager:Manager
    class var backgroundManager:Manager {
        let sessionId = "net.dropbeat.labs.background"
        let config = NSURLSessionConfiguration.backgroundSessionConfiguration(sessionId)
        let manager = Manager(configuration: config)
        manager.startRequestsImmediately = true
        return manager
    }
    
    init(url :String, method :Method, params: Dictionary<String, AnyObject>?, auth :Bool, background :Bool = false) {
        self.url = url
        self.method = method
        self.params = params
        self.auth = auth
        if (background) {
            self.manager = WebAdapter.backgroundManager
        } else {
            self.manager = Manager.sharedInstance
        }
    }
    
    func prepare() {
        if (auth == true) {
            // TODO: Get global session key.
            let keychainItemWrapper = KeychainItemWrapper(identifier: "net.dropbeat.spark", accessGroup: nil)
            if keychainItemWrapper["auth_token"] != nil {
                var key :String = keychainItemWrapper["auth_token"] as! String
//                var key :String = "5yqy1zxvvv7pcm7xrsbmvqje3n99f8ok"
                manager.session.configuration.HTTPAdditionalHeaders = [
                    "Cookie": "sessionid=" + key
                ]
            }
        }
    }
    
    func send(respCb: ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)) -> Request {
        prepare()
        
        var enc :ParameterEncoding?
        if (self.method == Method.GET) {
            enc = .URL
        } else {
            enc = .JSON
        }
        var req = manager.request(self.method!, self.url!, parameters: self.params, encoding: enc!)
        req.validate().responseJSON(completionHandler: respCb)
        return req
    }
}

class AutocompleteRequester {
    let youtubeApiPath = "https://clients1.google.com/complete/search"
    let funcRegexPattern = "[a-zA-Z0-9\\.]+\\(([^\\)]+)\\)"
    let koreanRegexPattern = ".*[ㄱ-ㅎㅏ-ㅣ가-힣]+."
    
    var defaultParams:[String:String]
    var onTheFlyRequests = [String:Request]()
    
    var handler:(keywords:Array<String>?, error:NSError?) -> Void
    
    init (handler:(keywords:Array<String>?, error:NSError?) -> Void) {
        self.handler = handler
        self.defaultParams = [
            "client": "youtube",
            "hl": "en",
            "gl": "us",
            "gs_rn": "23",
            "gs_ri": "youtube",
            "tok": "I9KDmvOmJAg1Xq-coNjwGg",
            "ds": "yt",
            "cp": "3",
            "gs_gbg": "K111AA607"
        ]
    }
    
    func send(keyword:String) {
        if (count(keyword) == 0) {
            self.handler(keywords: [], error: nil)
            return
        }
        var params = Dictionary<String, String>()
        for key in defaultParams.keys {
            params[key] = defaultParams[key]
        }
        
        var id:String?
        
        do {
            id = makeRandId()
        } while(onTheFlyRequests[id!] != nil)
        
        params["q"] = keyword
        params["gs_id"] = id!
        
        var req = request(Method.GET, self.youtubeApiPath, parameters: params)
        .responseString(encoding: NSUTF8StringEncoding,
            completionHandler: {
                    (request:NSURLRequest, response:NSHTTPURLResponse?, result:String?, error:NSError?) -> Void in
                self.onTheFlyRequests.removeValueForKey(id!)
                
                if (error != nil) {
                    self.handler(keywords: nil, error:error)
                    return
                }
                if (result == nil) {
                    self.handler(keywords: nil, error:NSError(domain: "autocompleteRequester", code: 0, userInfo: nil))
                    return
                }
                let funcRegex = NSRegularExpression(pattern: self.funcRegexPattern, options: nil, error: nil)!
                let koreanRegex = NSRegularExpression(pattern: self.koreanRegexPattern, options: nil, error: nil)!
                
                let matches = funcRegex.matchesInString(result!,
                    options: nil,
                    range:NSMakeRange(0, count(result!))) as! [NSTextCheckingResult]
                if (matches.count > 0) {
                    let substring = (result! as NSString).substringWithRange(matches[0].rangeAtIndex(1))
                    var data:NSData = substring.dataUsingEncoding(NSUTF8StringEncoding)!
                    var error: NSError?
                    
                    // convert NSData to 'AnyObject'
                    let anyObj: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(0),
                        error: &error)
                    
                    if (error != nil) {
                        self.handler(keywords:nil, error:error)
                        return
                    }
                    if (anyObj is Array<AnyObject>) {
                        let argArray = anyObj as! Array<AnyObject>
                        if (argArray.count > 2) {
                            let q:String = argArray[0] as! String
                            let words = argArray[1] as! Array<AnyObject>
                            let appendix: AnyObject = argArray[2] as AnyObject
                            
                            var keywords = [String]()
                            for word in words {
                                let entries = word as! Array<AnyObject>
                                let keyword = entries[0] as! String
                                keywords.append(keyword)
                            }
                            self.handler(keywords: keywords, error: nil)
                            return
                        }
                    }
                }
                self.handler(keywords: nil, error: NSError(domain: "autocom", code: 0, userInfo: nil))
        })
        onTheFlyRequests[id!] = req
    }
    
    func cancelAll() {
        for request in onTheFlyRequests.values {
            request.cancel()
        }
    }
    
    private func makeRandId()->String {
        let possible = Array("abcdefghijklmnopqrstuvwxyz0123456789")
        var id = ""
        for i in 0...1 {
            id.append(possible[random() % possible.count])
        }
        return id
    }
}