//
//  NetworkRequests.swift
//  labs

import Foundation

typealias ResponseHandler = ((result:JSON?, error:NSError?) -> Void)

let DropbeatRequestErrorDomain = "DropbeatRequestErrorDomain"

class Requests {
    static func send(method: Method, url: String, params: [String:AnyObject]? = nil, auth: Bool, background: Bool = false, handler: ResponseHandler) -> Request {
        let adapter = WebAdapter(url: url, method: method, params: params, auth: auth, background:background)
        return adapter.send({ (request, response, result) -> Void in
            guard result.error == nil else {
                handler(result: nil, error: result.error as? NSError)
                return
            }
            
            let json = JSON(result.value!)
            guard json["success"].boolValue == true else {
                let error = NSError(
                    domain: DropbeatRequestErrorDomain,
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey:json["error"].stringValue])
                handler(result: nil, error: error)
                return
            }
            
            handler(result:json, error:nil)
        })
    }
    
    static func sendGet(url: String, params: [String:AnyObject]? = nil, auth: Bool, background: Bool = false, handler: ResponseHandler) -> Request {
        return send(Method.GET, url: url, params: params, auth: auth, background:background, handler: handler)
    }
   
    static func sendPost(url: String, params: [String:AnyObject]? = nil, auth: Bool, handler: ResponseHandler) -> Request {
        return send(Method.POST, url: url, params: params, auth: auth, handler: handler)
    }
    
    static func sendPut(url: String, params: [String:AnyObject]? = nil, auth: Bool, handler: ResponseHandler) -> Request {
        return send(Method.PUT, url: url, params: params, auth: auth, handler: handler)
    }
}

extension Requests {
    static func userSelf(handler: ResponseHandler) -> Request {
        return sendGet(ApiPath.userSelf, auth: true, handler: handler)
    }
    
    static func userSignin(params: [String: String], handler: ResponseHandler) -> Request {
        return sendPost(ApiPath.userSignIn, params: params, auth: false, handler: handler)
    }
    
    static func userChangeEmail(email:String, handler:ResponseHandler) -> Request {
        return sendPost(ApiPath.userChangeEmail, params:["email":email], auth:true, handler:handler)
    }
    
    static func getPlaylist(id: String, handler: ResponseHandler) -> Request {
        return sendGet(ApiPath.playlist, params: ["id": id], auth: true, handler: handler)
    }
    
    static func createPlaylist(name: String, handler: ResponseHandler) -> Request{
        return sendPost(ApiPath.playlist, params: ["name": name], auth: true, handler: handler)
    }
    
    // `data` should be JsonArray.
    static func setPlaylist(id: String, data: AnyObject, handler: ResponseHandler) -> Request{
        return sendPost(ApiPath.playlistSet, params: ["playlist_id": id, "data": data], auth: true, handler: handler)
    }   
    
    static func deletePlaylist(id: String, handler: ResponseHandler) -> Request{
        return sendPost(ApiPath.playlistDel, params: ["id": id], auth: true, handler: handler)
    }
    
    static func changePlaylistName(id: String, name: String, handler: ResponseHandler)  -> Request {
        return sendPut(ApiPath.playlist, params: ["id": id, "name": name], auth: true, handler: handler)
    }
    
    static func fetchPlaylistList(handler: ResponseHandler) -> Request{
        return sendGet(ApiPath.playlistList, auth: true, handler: handler)
    }
    
    static func fetchInitialPlaylist(handler: ResponseHandler) -> Request {
        return sendGet(ApiPath.playlistIntial, auth: false, handler: handler)
    }
    
    static func getSharedPlaylist(uid: String, handler: ResponseHandler) -> Request{
        return sendGet(ApiPath.playlistShared, params: ["uid": uid], auth: false, handler: handler)
    }
    
    static func importPlaylist(uid: String, handler: ResponseHandler) -> Request{
        return sendGet(ApiPath.playlistShared, params: ["uid": uid], auth: false, handler: handler)
    }
    
    static func search(q: String, handler: ResponseHandler) -> Request{
        return sendGet(CorePath.newSearch, params: ["q": q], auth: false, handler: handler)
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
    
    static func getClientVersion(handler: ResponseHandler) -> Request {
        return sendGet(ApiPath.metaVersion, auth: false, handler: handler)
    }
    
    static func getChannelPlaylist(uid: String, pageToken: String?, handler: ResponseHandler) -> Request {
        var params = ["uid":uid]
        if pageToken != nil {
            params["pageToken"] = pageToken!
        }
        return sendGet(CorePath.channelGproxy, params: params, auth:false, handler: handler)
    }
    
    static func sharePlaylist(playlist:Playlist, handler: ResponseHandler) -> Request {
        let playlistData = playlist.toJson()
        return sendPost(ApiPath.playlistShared, params: playlistData, auth: true, handler: handler)
    }
    
    static func shareTrack(track:Track, handler: ResponseHandler) -> Request {
        return sendPost(ApiPath.trackShare, params: ["track_name": track.title, "ref": track.id], auth: true, handler: handler)
    }
    
    static func getSharedTrack(uid:String, handler: ResponseHandler) -> Request {
        return sendGet(ApiPath.trackShare, params: ["uid": uid], auth:false, handler: handler)
    }
    
    static func sendFeedback(senderEmail:String, content:String, handler: ResponseHandler) -> Request {
        
        return sendPost(ApiPath.feedback, params: ["sender": senderEmail, "content": content], auth: false, handler: handler)
    }
    
    static func fetchExploreChannelFeed(pageIdx:Int, handler: ResponseHandler) -> Request {
        return sendPost(CorePath.channelFeed, params: ["p": pageIdx], auth:false, handler: handler)
    }
    
    static func fetchBeatportChart(genre:String, handler: ResponseHandler) -> Request {
        return sendGet(CorePath.trendingChart, params:["type": genre], auth:false, handler: handler)
    }
    
    static func getFeedGenre(handler: ResponseHandler) -> Request {
        return sendGet(CorePath.genre, params:nil, auth:false, handler: handler)
    }
    
    static func getStreamNew(genre:String?, pageIdx:Int, handler: ResponseHandler) -> Request {
        var params:[String:AnyObject] = ["p": pageIdx]
        if genre != nil && (genre!).characters.count > 0 {
            params["g"] = genre
        }
        return sendGet(CorePath.streamNew, params:params, auth:false, handler: handler)
    }
    
    static func getStreamTrending(genre:String?, pageIdx:Int, handler: ResponseHandler) -> Request {
        var params:[String:AnyObject] = ["p": pageIdx]
        if genre != nil && (genre!).characters.count > 0 {
            params["g"] = genre
        }
        return sendGet(CorePath.streamTrending, params:params, auth:false, handler: handler)
    }
    
    static func doLike(track: Track, handler: ResponseHandler) -> Request {
        var params:[String:AnyObject] = [String:AnyObject]()
        params["data"] = ["id":track.id, "type":track.type.rawValue, "title": track.title]
        return sendPost(ApiPath.trackLike, params:params, auth: true, handler:handler)
    }
    
    static func doUnlike(likeId:Int, handler: ResponseHandler) -> Request {
        return sendPost(ApiPath.trackDislike, params:["id":likeId], auth: true, handler:handler)
    }
    
    static func addFavoriteGenre(ids:[String], handler: ResponseHandler) -> Request {
        return sendPost(ApiPath.genreAddFavorite, params: ["ids": ids], auth: true, handler:handler)
    }
    
    static func delFavoriteGenre(ids:[String], handler: ResponseHandler) -> Request {
        return sendPost(ApiPath.genreDelFavorite, params: ["ids": ids], auth: true, handler:handler)
    }
    
    static func getFavoriteGenres(handler: ResponseHandler) -> Request {
        return sendGet(ApiPath.genreFavorite, params: nil, auth: true, handler:handler)
    }
    
    static func emailSignup(email:String, firstName:String, lastName:String, nickname:String, password:String, handler: ResponseHandler) -> Request {
        
        var params:[String:AnyObject] = [String:AnyObject]()
        params["email"] = email
        params["first_name"] = firstName
        params["last_name"] = lastName
        params["nickname"] = nickname
        params["password"] = password
        return sendPost(ApiPath.userEmailSignup, params: params, auth:false, handler:handler)
    }
    
    static func emailSignin(email:String, password:String, handler: ResponseHandler) -> Request {
        
        var params:[String:AnyObject] = [String:AnyObject]()
        params["email"] = email
        params["password"] = password
        return sendPost(ApiPath.userEmailSignin, params: params, auth:false, handler:handler)
    }
    
    static func changeNickname(nickname:String, handler:ResponseHandler) -> Request {
        return sendPost(ApiPath.userChangeNickname, params: ["nickname": nickname], auth: true, handler: handler)
    }
    
    static func changeAboutMe(desc:String, handler:ResponseHandler) -> Request {
        return sendPost(ApiPath.userChangeAboutMe, params: ["desc": desc], auth: true, handler: handler)
    }
    
    static func getGenreSamples(handler: ResponseHandler) -> Request {
        return sendGet(CorePath.genreSample, params: nil, auth: false, handler: handler)
    }
}


class WebAdapter {
    var url: String?
    var method :Method?
    var params :[String:AnyObject]?
    var auth: Bool?
    var background: Bool?
    var manager:Manager
    class var backgroundManager:Manager {
        let sessionId = "net.dropbeat.labs.background"
        let config = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(sessionId)
//        backgroundSessionConfiguration(sessionId)
        let manager = Manager(configuration: config)
        manager.startRequestsImmediately = true
        return manager
    }
    
    init(url :String, method :Method, params: [String:AnyObject]?, auth :Bool, background :Bool = false) {
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
    
    func send(handler: ((NSURLRequest?, NSHTTPURLResponse?, Result<AnyObject>) -> Void)) -> Request {
        prepare()
        let enc :ParameterEncoding = (self.method == Method.GET) ? .URL : .JSON
        let req = manager.request(self.method!, self.url!, parameters: self.params, encoding: enc)
        req.validate().responseJSON(completionHandler: handler)
        return req
    }
}