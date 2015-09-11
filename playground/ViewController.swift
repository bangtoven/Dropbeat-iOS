//
//  ViewController.swift
//  playground
//
//  Created by Jungho Bang on 2015. 9. 10..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Requests.emailSignin("jungho@jungho.com", password: "jungho") { (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            println("signed in")
            
//            Account.getAccountWithCompletionHandler({ (account:Account?, error) -> Void in
//                println(account)
//            })
            
        }
        
    }
    
    @IBAction func userBtnTapped(sender: AnyObject) {
        self.requestUserInfo("teksu")
    }
    
    @IBAction func artistBtnTapped(sender: AnyObject) {
        self.requestUserInfo("oliver-heldens")
    }

    @IBAction func channelBtnTapped(sender: AnyObject) {
        self.requestUserInfo("liquicity")
    }
    
    func requestUserInfo(string: String!) {
        let baseUrl = "http://spark.coroutine.io/api/v1/resolve/?url=spark.coroutine.io/r/"
        var requestUrl = baseUrl + string
        Requests.sendGet(requestUrl, params: nil, auth: false, background: false) { (req, resp, result, error) -> Void in
            var jsonData = JSON(result!)["data"]
            var userType = jsonData["user_type"]
            
            switch userType {
            case "user":
                var user: User = User.parseUser(result!,key:"data",secondKey:"user")
                break
            case "artist":
                var artist: Artist = Artist.parseArtist(result!,key:"data",secondKey:"user")
                artist.fetchEvents({ (artist, events, error) -> Void in
                    artist.fetchLiveset({ (artist, tracks, error) -> Void in
                        artist.fetchPodcast({ (artist, tracks, error) -> Void in
                            println(artist)
                        })
                    })
                })
                break
            case "channel":
                var channel: Channel! = Channel.parseChannel(result!,key:"data",secondKey: "user")
                
                break
            default:
                UIAlertView(title: "망했어요", message: result?.stringValue, delegate: nil, cancelButtonTitle: "알았다.").show()
            }
        }
    }
}