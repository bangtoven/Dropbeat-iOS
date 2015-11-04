//
//  Account.swift
//  labs
//
//  Created by Jungho Bang on 2015. 9. 25..
//  Copyright © 2015년 dropbeat. All rights reserved.
//

import UIKit

class Account {
    var user:User?
    var token:String
    var likes = [Like]()
    var favoriteGenreIds = Set<String>()
    var following = [BaseUser]()

    init(token:String, user:User?) {
        self.user = user
        self.token = token
    }
    
    func syncLikeInfo(callback:((error: NSError?) -> Void)?) {
        self.user?.fetchLikeList({ (likes, error) -> Void in
            if (error != nil) {
                callback?(error:error)
                return
            }
            self.likes.removeAll(keepCapacity: false)
            for like in likes! {
                self.likes.append(like)
            }
            callback?(error:nil)
        })
    }
    
    func syncFollowingInfo(callback:((error: NSError?) -> Void)?) {
        self.user?.fetchFollowing({ (users, error) -> Void in
            if error != nil {
                callback!(error: error)
            } else {
                self.following = users!
                self.user?.num_following = self.following.count
                callback!(error: nil)
            }
        })
    }
    
    static var account:Account?
    
    static func getCachedAccount() -> Account? {
        return account
    }
    
    static func getAccountWithCompletionHandler(handler:(account: Account?, error: NSError?) -> Void) {
        let keychainItemWrapper = KeychainItemWrapper(identifier: "net.dropbeat.spark", accessGroup:nil)
        let token:String? = keychainItemWrapper.objectForKey("auth_token") as? String
        if (token == nil) {
            handler(account: nil, error: nil)
            return
        }
        
        self.account = nil
        var gotFavoriteInfo = false
        var didErrorHandlerFire = false
        
        var favoriteGenreIds:[String] = [String]()
        
        let responseHandler = {() -> Void in
            if !gotFavoriteInfo || self.account == nil {
                return
            }
            
            self.account!.favoriteGenreIds.removeAll(keepCapacity: false)
            
            for favoriteId:String in favoriteGenreIds {
                self.account!.favoriteGenreIds.insert(favoriteId)
            }
            
            handler(account:self.account, error: nil)
        }
        
        let errorHandler = {(error:NSError) -> Void in
            if didErrorHandlerFire {
                return
            }
            
            self.account = nil
            didErrorHandlerFire = true
            handler(account:nil, error: error)
        }
        
        
        Requests.userSelf(){ (result, error) -> Void in
            if (error != nil) {
                errorHandler(error!)
                return
            }
            
            let user = User(json: result!)
            let account = Account(token:token!, user:user)
            self.account = account
            
            account.syncFollowingInfo({ (error) -> Void in
                if error != nil {
                    errorHandler(error!)
                    return
                }
            })
            
            account.syncLikeInfo({ (error) -> Void in
                if error != nil {
                    errorHandler(error!)
                    return
                }
            })
            
            responseHandler()
        }
        
        Requests.getFavoriteGenres() { (result, error) -> Void in
            if error != nil {
                errorHandler(error!)
                return
            }
            
            for (_, s): (String, JSON) in result!["data"] {
                favoriteGenreIds.append(String(s.intValue))
            }
            
            gotFavoriteInfo = true
            responseHandler()
        }
    }
    
    static var location:[String:String]?
    
    static func loadLocation(callback:((dict:[String:String]) -> Void)) {
        Requests.sendGet("http://geo.ironbricks.com/json/", auth: false) { (result, error) -> Void in
            if error != nil {
                Account.location = [:]
                return
            }
            
            var location = [String:String]()
            let lat = result!["latitude"].stringValue
            let lng = result!["longitude"].stringValue
            
            let url = "http://maps.google.com/maps/api/geocode/json?latlng=\(lat),\(lng)&sensor=false&language=en"
            Requests.sendGet(url, auth: false) { (result, error) -> Void in
                if error != nil {
                    Account.location = [:]
                    return
                }
                let json = result!["results"]
                
                location["country_name"] = json[json.count-1]["address_components"][0]["long_name"].stringValue
                location["country_code"] = json[json.count-1]["address_components"][0]["short_name"].stringValue
                
                location["city_name"] = json[json.count-2]["address_components"][0]["long_name"].stringValue
                location["lat"] = json[json.count-2]["geometry"]["location"]["lat"].stringValue
                location["lng"] = json[json.count-2]["geometry"]["location"]["lng"].stringValue
                
                Account.location = location
                callback(dict: location)
            }
        }
    }
}
