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
            
            account.syncLikeInfo({ (error) -> Void in
                if error != nil {
                    errorHandler(error!)
                    return
                }
            })
            
            responseHandler()
        })
        
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
