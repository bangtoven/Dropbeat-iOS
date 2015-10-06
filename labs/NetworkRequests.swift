//
//  NetworkRequests.swift
//  labs

import Foundation

typealias RespCallback = ((NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void)

class Requests {
    static var EMPTY_RESPONSE_CALLBACK = {(req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
    }
    
    static func send(method: Method, url: String, params: Dictionary<String, AnyObject>? = nil, auth: Bool, background: Bool = false,respCb: RespCallback) -> Request {
        let adapter = WebAdapter(url: url, method: method, params: params, auth: auth, background:background)
        return adapter.send({ (request, response, result) -> Void in
            respCb(request!, response, result.value, result.error as? NSError)
        })
    }
    
    static func sendGet(url: String, params: Dictionary<String, AnyObject>? = nil, auth: Bool, background: Bool = false, respCb: RespCallback) -> Request {
        return send(Method.GET, url: url, params: params, auth: auth, background:background, respCb: respCb)
    }
   
    static func sendPost(url: String, params: Dictionary<String, AnyObject>? = nil, auth: Bool, respCb: RespCallback) -> Request {
        return send(Method.POST, url: url, params: params, auth: auth, respCb: respCb)
    }
    
    static func sendPut(url: String, params: Dictionary<String, AnyObject>? = nil, auth: Bool, respCb: RespCallback) -> Request {
        return send(Method.PUT, url: url, params: params, auth: auth, respCb: respCb)
    }
    
    static func sendHead(url: String, params: Dictionary<String, AnyObject>? = nil, auth: Bool, respCb: RespCallback) -> Request {
        return send(Method.HEAD, url: url, params: params, auth: auth, respCb: respCb)
    }
    
    static func userSelf(respCb: RespCallback) -> Request {
        return sendGet(ApiPath.userSelf, auth: true, respCb: respCb)
    }
    
    static func userSignin(params: Dictionary<String, String>, respCb: RespCallback) -> Request {
        return sendPost(ApiPath.userSignIn, params: params, auth: false, respCb: respCb)
    }
    
    static func userChangeEmail(email:String, respCb:RespCallback) -> Request {
        return sendPost(ApiPath.userChangeEmail, params:["email":email], auth:true, respCb:respCb)
    }
    
    static func getPlaylist(id: String, respCb: RespCallback) -> Request {
        return sendGet(ApiPath.playlist, params: ["id": id], auth: true, respCb: respCb)
    }
    
    static func createPlaylist(name: String, respCb: RespCallback) -> Request{
        return sendPost(ApiPath.playlist, params: ["name": name], auth: true, respCb: respCb)
    }
    
    // `data` should be JsonArray.
    static func setPlaylist(id: String, data: AnyObject, respCb: RespCallback) -> Request{
        return sendPost(ApiPath.playlistSet, params: ["playlist_id": id, "data": data], auth: true, respCb: respCb)
    }   
    
    static func deletePlaylist(id: String, respCb: RespCallback) -> Request{
        return sendPost(ApiPath.playlistDel, params: ["id": id], auth: true, respCb: respCb)
    }
    
    static func changePlaylistName(id: String, name: String, respCb: RespCallback)  -> Request {
        return sendPut(ApiPath.playlist, params: ["id": id, "name": name], auth: true, respCb: respCb)
    }
    
    static func fetchPlaylistList(respCb: RespCallback) -> Request{
        return sendGet(ApiPath.playlistList, auth: true, respCb: respCb)
    }
    
    static func fetchInitialPlaylist(respCb: RespCallback) -> Request {
        return sendGet(ApiPath.playlistIntial, auth: false, respCb: respCb)
    }
    
    static func getSharedPlaylist(uid: String, respCb: RespCallback) -> Request{
        return sendGet(ApiPath.playlistShared, params: ["uid": uid], auth: false, respCb: respCb)
    }
    
    static func importPlaylist(uid: String, respCb: RespCallback) -> Request{
        return sendGet(ApiPath.playlistShared, params: ["uid": uid], auth: false, respCb: respCb)
    }
    
    static func search(q: String, respCb: RespCallback) -> Request{
        return sendGet(CorePath.newSearch, params: ["q": q], auth: false, respCb: respCb)
    }
    
    static func logSearch(keyword: String) -> Request{
        return request(Method.GET, ApiPath.logSearch, parameters: ["q": keyword, "device_type": "ios"], encoding: .URL).validate()
    }
    
    static func logTrackAdd(title: String) -> Request{
        return request(Method.GET, ApiPath.logTrackAdd, parameters: ["t": title, "device_type": "ios"], encoding: .URL).validate()
    }
    
    static func logPlayDrop(track:Track) -> Request{
        var id: String
        if let dropbeatTrack = track as? DropbeatTrack {
            id = dropbeatTrack.uniqueKey
        } else {
            id = track.id
        }
        
        return request(Method.GET, ApiPath.logPlayDrop, parameters: ["t": track.title, "device_type": "ios", "uid": id], encoding: .URL).validate()
    }
    
    static func logPlay(track:Track) -> Request{
        var id: String
        if let dropbeatTrack = track as? DropbeatTrack {
            id = dropbeatTrack.uniqueKey
        } else {
            id = track.id
        }
        
        return request(Method.GET, ApiPath.logPlay, parameters: ["t": track.title, "device_type": "ios", "uid": id], encoding: .URL).validate()
    }
    
    static func getClientVersion(respCb: RespCallback) -> Request {
        return sendGet(ApiPath.metaVersion, auth: false, respCb: respCb)
    }
    
    static func getChannelPlaylist(uid: String, pageToken: String?, respCb: RespCallback) -> Request {
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
    
    static func sharePlaylist(playlist:Playlist, respCb: RespCallback) -> Request {
        let playlistData = playlist.toJson()
        return sendPost(ApiPath.playlistShared, params: playlistData, auth: true, respCb: respCb)
    }
    
    static func shareTrack(track:Track, respCb: RespCallback) -> Request {
        return sendPost(ApiPath.trackShare, params: ["track_name": track.title, "ref": track.id], auth: true, respCb: respCb)
    }
    
    static func getSharedTrack(uid:String, respCb: RespCallback) -> Request {
        return sendGet(ApiPath.trackShare, params: ["uid": uid], auth:false, respCb: respCb)
    }
    
    static func sendFeedback(senderEmail:String, content:String, respCb: RespCallback) -> Request {
        
        return sendPost(ApiPath.feedback, params: ["sender": senderEmail, "content": content], auth: false, respCb: respCb)
    }
    
    static func fetchExploreChannelFeed(pageIdx:Int, respCb: RespCallback) -> Request {
        return sendPost(CorePath.channelFeed, params: ["p": pageIdx], auth:false, respCb: respCb)
    }
    
    static func fetchBeatportChart(genre:String, respCb: RespCallback) -> Request {
        return sendGet(CorePath.trendingChart, params:["type": genre], auth:false, respCb: respCb)
    }
    
    static func getFeedGenre(respCb: RespCallback) -> Request {
        return sendGet(CorePath.genre, params:nil, auth:false, respCb: respCb)
    }
    
    static func getStreamNew(genre:String?, pageIdx:Int, respCb: RespCallback) -> Request {
        var params:[String:AnyObject] = ["p": pageIdx]
        if genre != nil && (genre!).characters.count > 0 {
            params["g"] = genre
        }
        return sendGet(CorePath.streamNew, params:params, auth:false, respCb: respCb)
    }
    
    static func getStreamTrending(genre:String?, pageIdx:Int, respCb: RespCallback) -> Request {
        var params:[String:AnyObject] = ["p": pageIdx]
        if genre != nil && (genre!).characters.count > 0 {
            params["g"] = genre
        }
        return sendGet(CorePath.streamTrending, params:params, auth:false, respCb: respCb)
    }
    
    static func doLike(track: Track, respCb: RespCallback) -> Request {
        var params:[String:AnyObject] = [String:AnyObject]()
        params["data"] = ["id":track.id, "type":track.type.rawValue, "title": track.title]
        return sendPost(ApiPath.trackLike, params:params, auth: true, respCb:respCb)
    }
    
    static func doUnlike(likeId:Int, respCb: RespCallback) -> Request {
        return sendPost(ApiPath.trackDislike, params:["id":likeId], auth: true, respCb:respCb)
    }
    
    static func addFavoriteGenre(ids:[String], respCb: RespCallback) -> Request {
        return sendPost(ApiPath.genreAddFavorite, params: ["ids": ids], auth: true, respCb:respCb)
    }
    
    static func delFavoriteGenre(ids:[String], respCb: RespCallback) -> Request {
        return sendPost(ApiPath.genreDelFavorite, params: ["ids": ids], auth: true, respCb:respCb)
    }
    
    static func getFavoriteGenres(respCb: RespCallback) -> Request {
        return sendGet(ApiPath.genreFavorite, params: nil, auth: true, respCb:respCb)
    }
    
    static func emailSignup(email:String, firstName:String, lastName:String, nickname:String, password:String, respCb: RespCallback) -> Request {
        
        var params:[String:AnyObject] = [String:AnyObject]()
        params["email"] = email
        params["first_name"] = firstName
        params["last_name"] = lastName
        params["nickname"] = nickname
        params["password"] = password
        return sendPost(ApiPath.userEmailSignup, params: params, auth:false, respCb:respCb)
    }
    
    static func emailSignin(email:String, password:String, respCb: RespCallback) -> Request {
        
        var params:[String:AnyObject] = [String:AnyObject]()
        params["email"] = email
        params["password"] = password
        return sendPost(ApiPath.userEmailSignin, params: params, auth:false, respCb:respCb)
    }
    
    static func changeNickname(nickname:String, respCb:RespCallback) -> Request {
        return sendPost(ApiPath.userChangeNickname, params: ["nickname": nickname], auth: true, respCb: respCb)
    }
    
    static func changeAboutMe(desc:String, respCb:RespCallback) -> Request {
        return sendPost(ApiPath.userChangeAboutMe, params: ["desc": desc], auth: true, respCb: respCb)
    }
    
    static func getGenreSamples(respCb: RespCallback) -> Request {
        return sendGet(CorePath.genreSample, params: nil, auth: false, respCb: respCb)
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
            let keychainItemWrapper = KeychainItemWrapper(identifier: "net.dropbeat.spark", accessGroup: nil)
            if let token:String = (keychainItemWrapper.objectForKey("auth_token") as? String) {
                manager.session.configuration.HTTPAdditionalHeaders = [
                    "Cookie": "sessionid=" + token
                ]
            }
        }
    }
    
    func send(respCb: ((NSURLRequest?, NSHTTPURLResponse?, Result<AnyObject>) -> Void)) -> Request {
        prepare()
        
        var enc :ParameterEncoding?
        if (self.method == Method.GET) {
            enc = .URL
        } else {
            enc = .JSON
        }
        let req = manager.request(self.method!, self.url!, parameters: self.params, encoding: enc!)
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
        if (keyword.characters.count == 0) {
            self.handler(keywords: [], error: nil)
            return
        }
        var params = Dictionary<String, String>()
        for key in defaultParams.keys {
            params[key] = defaultParams[key]
        }
        
        var id:String?
        
        repeat {
            id = makeRandId()
        } while(onTheFlyRequests[id!] != nil)
        
        params["q"] = keyword
        params["gs_id"] = id!
//        
//        Tuple types '(NSURLRequest?, NSHTTPURLResponse?, Result<String>)' (aka '(Optional<NSURLRequest>, Optional<NSHTTPURLResponse>, Result<String>)') and '(NSURLRequest, NSHTTPURLResponse?, String?, NSError?)' (aka '(NSURLRequest, Optional<NSHTTPURLResponse>, Optional<String>, Optional<NSError>)') have a different number of elements (3 vs. 4)
        
        let req = request(Method.GET, self.youtubeApiPath, parameters: params).responseString(encoding: NSUTF8StringEncoding,
            completionHandler: {
                    (request:NSURLRequest?, response:NSHTTPURLResponse?, result:Result<String>) -> Void in
                self.onTheFlyRequests.removeValueForKey(id!)
                
                if (result.error != nil) {
                    self.handler(keywords: nil, error:result.error as? NSError)
                    return
                }
                let resultStr = result.value
                if (resultStr == nil) {
                    self.handler(keywords: nil, error:NSError(domain: "autocompleteRequester", code: 0, userInfo: nil))
                    return
                }
                let funcRegex = try! NSRegularExpression(pattern: self.funcRegexPattern, options: [])
//                let koreanRegex = try! NSRegularExpression(pattern: self.koreanRegexPattern, options: [])
                
                let matches = funcRegex.matchesInString(resultStr!,
                    options: [],
                    range:NSMakeRange(0, resultStr!.characters.count)) 
                if (matches.count > 0) {
                    let substring = NSString(string:resultStr!).substringWithRange(matches[0].rangeAtIndex(1))
                    let data:NSData = substring.dataUsingEncoding(NSUTF8StringEncoding)!
                    var error: NSError?
                    
                    // convert NSData to 'AnyObject'
                    let anyObj: AnyObject?
                    do {
                        anyObj = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0))
                    } catch let error1 as NSError {
                        error = error1
                        anyObj = nil
                    } catch {
                        fatalError()
                    }
                    
                    if (error != nil) {
                        self.handler(keywords:nil, error:error)
                        return
                    }
                    if (anyObj is Array<AnyObject>) {
                        let argArray = anyObj as! Array<AnyObject>
                        if (argArray.count > 2) {
                            let words = argArray[1] as! Array<AnyObject>
//                            let q:String = argArray[0] as! String
//                            let appendix: AnyObject = argArray[2] as AnyObject
                            
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
        let possible = Array("abcdefghijklmnopqrstuvwxyz0123456789".characters)
        var id = ""
        for _ in 0...1 {
            id.append(possible[random() % possible.count])
        }
        return id
    }
}