//
//  UserViewController.swift
//  labs
//
//  Created by Jungho Bang on 2015. 9. 14..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class UserViewController: BaseUserViewController {

    var user: BaseUser!
    var resource: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Requests.resolveUser(self.resource) {(req, resp, result, error) -> Void in
            
            if (error != nil || JSON(result!)["success"] == false) {
                UIAlertView(title: "Error", message: JSON(result!)["error"].stringValue, delegate: nil, cancelButtonTitle: "I see").show()
                return
            }
            
            var user: BaseUser?
            switch JSON(result!)["data"]["user_type"] {
            case "user":
                user = User.parseUser(result!,key:"data",secondKey:"user")
                break
            case "artist":
                user = Artist.parseArtist(result!,key:"data",secondKey:"user")
                break
            case "channel":
                user = Channel.parseChannel(result!,key:"data",secondKey: "user")
                break
            default:
                var message = "Unknown user_type"
                return
            }
            
            self.user = user
        }
    }

}
