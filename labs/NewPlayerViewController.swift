//
//  PlayerViewController.swift
//  labs
//
//  Created by 방정호 on 2015. 10. 9..
//  Copyright © 2015년 dropbeat. All rights reserved.
//

import UIKit

class PlayerViewController: GAITrackedViewController {

    @IBOutlet weak var hidePlayerButton: UIButton!
    
    @IBOutlet weak var playerTitleHeightConstaint: NSLayoutConstraint!
    
    @IBOutlet weak var coverView: UIView!
    @IBOutlet weak var loadingView: UIImageView!
    @IBOutlet weak var progressSliderBar: UISlider!
    
    @IBOutlet weak var playerTitle: MarqueeLabel!
    @IBOutlet weak var playerStatus: UILabel!
    
    @IBOutlet weak var likeProgIndicator: UIActivityIndicatorView!
    @IBOutlet weak var likeBtn: UIButton!
    @IBOutlet weak var shareBtn: UIButton!
    @IBOutlet weak var repeatBtn: UIButton!
    @IBOutlet weak var shuffleBtn: UIButton!
    @IBOutlet weak var totalTextView: UILabel!
    @IBOutlet weak var progressTextView: UILabel!
    @IBOutlet weak var nextBtn: UIButton!
    @IBOutlet weak var prevBtn: UIButton!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var pauseBtn: UIButton!
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var qualityBtn: UIButton!
    @IBOutlet weak var coverBgImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        hidePlayerButton.layer.cornerRadius = 10.0
        
        if UIScreen.mainScreen().bounds.height == 480 {
            resizeViewUnder4inch()
        }
    }
    
    func resizeViewUnder4inch() {
        playerTitleHeightConstaint.constant = 28
        let heightConstraint = NSLayoutConstraint(item: coverView,
            attribute: NSLayoutAttribute.Height,
            relatedBy: NSLayoutRelation.Equal,
            toItem: nil,
            attribute: NSLayoutAttribute.NotAnAttribute,
            multiplier: 1.0,
            constant: 200)
        coverView.addConstraint(heightConstraint)
    }

    @IBAction func closeButtonAction(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
