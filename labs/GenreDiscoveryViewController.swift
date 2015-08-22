//
//  GenreDiscoveryViewController.swift
//  labs
//
//  Created by vulpes on 2015. 8. 22..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class GenreDiscoveryViewController: BaseViewController {
    
    var currPlayer:AVPlayer?
    var currItem:AVPlayerItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = "GenreDiscoveryViewScreen"
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "sender", name:NotifyKey.playerStop , object: nil)
        
        let noti = NSNotification(name: NotifyKey.playerStop, object: nil)
        NSNotificationCenter.defaultCenter().postNotification(noti)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self, name:NotifyKey.playerStop , object: nil)
    }
    
    func sender() {}
    
    @IBAction func onBackBtnClicked(sender: AnyObject) {
        self.navigationController?.popViewControllerAnimated(true)
    }

    @IBAction func onGoodBtnClicked(sender: AnyObject) {
        
    }
    
    @IBAction func onBadBtnClicked(sender: AnyObject) {
        
    }
    
    @IBAction func onPlayBtnClicked(sender: AnyObject) {
        playDrop(NSURL(string: "https://p.scdn.co/mp3-preview/93c1ac82e54927fa5a45de12f106f2ce9ac4ee17")!)
    }
    
    func playDrop(url:NSURL) {
        currPlayer?.pause()
        currItem = AVPlayerItem(URL: url)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "onTrackFinished:", name: AVPlayerItemDidPlayToEndTimeNotification, object: currItem!)
        currPlayer = AVPlayer(playerItem: currItem!)
        currPlayer!.play()
    }
    
    func onTrackFinished(noti:NSNotification) {
        NSNotificationCenter.defaultCenter().removeObserver(
            self, name: AVPlayerItemDidPlayToEndTimeNotification, object: currItem!)
        ViewUtils.showToast(self, message: "Finished")
    }
}
