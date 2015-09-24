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
    var likedTrackIds = Set<String>()
    var favoriteGenreIds = Set<String>()
    var following = [BaseUser]()
    
    init(token:String, user:User?) {
        self.user = user
        self.token = token
    }
    
    func syncLikeInfo(callback:((error: NSError?) -> Void)?) {
        Requests.getLikes { (request:NSURLRequest, response:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            if (error != nil) {
                callback?(error:error)
                return
            }
            
            let likeResult:[Like]? = Like.parseLikes(result)
            if likeResult == nil {
                callback?(error: NSError(domain:"getLikes", code: 102, userInfo: nil))
                return
            }
            self.likes.removeAll(keepCapacity: false)
            for like in likeResult! {
                self.likes.append(like)
                self.likedTrackIds.insert(like.track.id)
            }
            callback?(error:nil)
        }
    }
    
    func syncFollowingInfo(callback:((error: NSError?) -> Void)?) {
        self.user?.fetchFollowing({ (users, error) -> Void in
            if error != nil {
                callback!(error: error)
            } else {
                self.following = users!
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
        var gotLikeInfo = false
        var gotFavoriteInfo = false
        var didErrorHandlerFire = false
        
        var likes:[Like] = [Like]()
        var favoriteGenreIds:[String] = [String]()
        
        let responseHandler = {() -> Void in
            if !gotLikeInfo || !gotFavoriteInfo || self.account == nil {
                return
            }
            
            self.account!.likes.removeAll(keepCapacity: false)
            self.account!.likedTrackIds.removeAll(keepCapacity: false)
            
            for like: Like in likes {
                self.account!.likes.append(like)
                self.account!.likedTrackIds.insert(like.track.id)
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
        
        
        Requests.userSelf({ (request: NSURLRequest, response: NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            if (error != nil) {
                errorHandler(error!)
                return
            }
            
            let res = JSON(result!)
            let success:Bool = res["success"].bool ?? false
            if !success {
                errorHandler(NSError(domain: "account", code: 101, userInfo: nil))
                return
            }
            
            let user = User(json: JSON(result!))
            let account = Account(token:token!, user:user)
            self.account = account
            
            account.syncFollowingInfo({ (error) -> Void in
                if error != nil {
                    errorHandler(error!)
                    return
                }
            })
            responseHandler()
        })
        
        Requests.getLikes { (request:NSURLRequest, response:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            if error != nil {
                errorHandler(error!)
                return
            }
            
            let likeResult:[Like]? = Like.parseLikes(result)
            if likeResult == nil {
                errorHandler(NSError(domain:"getLikes", code: 102, userInfo: nil))
                return
            }
            for like in likeResult! {
                likes.append(like)
            }
            
            gotLikeInfo = true
            responseHandler()
        }
        
        Requests.getFavorites { (request:NSURLRequest, response:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            if error != nil || result == nil {
                errorHandler(error != nil ? error! :
                    NSError(domain: "getFavorites", code: 103, userInfo: nil))
                return
            }
            
            let json = JSON(result!)
            if !(json["success"].bool ?? false) || json["data"] == nil {
                errorHandler(NSError(domain: "getFavorites", code: 103, userInfo: nil))
                return
            }
            
            for (_, s): (String, JSON) in json["data"] {
                favoriteGenreIds.append(String(s.intValue))
            }
            
            gotFavoriteInfo = true
            responseHandler()
        }
    }
}
