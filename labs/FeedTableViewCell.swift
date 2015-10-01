//
//  FeedSelectTableViewCell.swift
//  labs
//
//  Created by vulpes on 2015. 7. 31..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class FeedSelectTableViewCell: UITableViewCell {

    @IBOutlet weak var name: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        let selectedBgView = UIView(frame: self.bounds)
        selectedBgView.autoresizingMask = [UIViewAutoresizing.FlexibleHeight, UIViewAutoresizing.FlexibleWidth]
        selectedBgView.backgroundColor = UIColor(netHex: 0xffffff)
        self.selectedBackgroundView = selectedBgView
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

class UserTrackTableViewCell: AddableTrackTableViewCell {
    
    static let ScrollNotification = "UserTrackCellScroll"

    @IBOutlet weak var releaseDateLabel: UILabel!
    @IBOutlet weak var userProfileImageView: UIImageView!
    @IBOutlet weak var userNameView: UILabel!
    @IBOutlet weak var genreView: UILabel!
    @IBOutlet weak var trackInfoFrame: UIView!
    
    @IBOutlet weak var thumnailCenterConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let selectedBgView = UIView(frame: self.bounds)
        selectedBgView.autoresizingMask = [UIViewAutoresizing.FlexibleHeight, UIViewAutoresizing.FlexibleWidth]
        selectedBgView.backgroundColor = UIColor.whiteColor()
        self.selectedBackgroundView = selectedBgView
        
        userProfileImageView.layer.cornerRadius = 4
        userProfileImageView.layer.borderWidth = 1
        userProfileImageView.layer.borderColor = UIColor(white: 0.95, alpha: 1.0).CGColor
        
        trackInfoFrame.layer.borderColor = UIColor(netHex: 0x909090).CGColor
        trackInfoFrame.layer.borderWidth = 1
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "parentDidScroll:", name: UserTrackTableViewCell.ScrollNotification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func parentDidScroll(notification: NSNotification) {
        if let offset = notification.object as? CGFloat {
            var constant = self.thumnailCenterConstraint.constant
            constant += offset * 0.1 //> 0 ? +0.25 : -0.25
            
            let threshold:CGFloat = 70.0
            if constant > threshold {
                constant = threshold
            } else if constant < -threshold {
                constant = -threshold
            }
            
            self.thumnailCenterConstraint.constant = constant
        }
    }
    
}

class BpChartTrackTableViewCell: AddableTrackTableViewCell {
    @IBOutlet weak var artistName: UILabel!
    @IBOutlet weak var genreName: UILabel!
    @IBOutlet weak var rank: UILabel!
    @IBOutlet weak var rankWrapper: UIView!
    
    override func setSelected(selected: Bool, animated: Bool) {
        let rankWarapperColor = rankWrapper.backgroundColor
        super.setSelected(selected, animated: animated)
        
        if(selected) {
            rankWrapper.backgroundColor = rankWarapperColor
        }
    }
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {
        let rankWarapperColor = rankWrapper.backgroundColor
        super.setHighlighted(highlighted, animated: animated)
        
        if(highlighted) {
            rankWrapper.backgroundColor = rankWarapperColor
        }
    }
    
}

class TrendingTrackTableViewCell: AddableTrackTableViewCell {
    
    @IBOutlet weak var rank: UILabel!
    @IBOutlet weak var artistName: UILabel!
    
    @IBOutlet weak var artistWrapper: UIView!
    @IBOutlet weak var titleWrapper: UIView!
    @IBOutlet weak var titleWidthConstaint: NSLayoutConstraint!
    @IBOutlet weak var photoFrame: UIView!
    @IBOutlet weak var artistWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var snippet: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let selectedBgView = UIView(frame: self.bounds)
        selectedBgView.autoresizingMask = [UIViewAutoresizing.FlexibleHeight, UIViewAutoresizing.FlexibleWidth]
        selectedBgView.backgroundColor = UIColor(netHex: 0xffffff)
        
        self.selectedBackgroundView = selectedBgView
        
        photoFrame.layer.borderColor = UIColor(netHex: 0x909090).CGColor
        photoFrame.layer.borderWidth = 1
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        let artistWrapperColor = artistWrapper.backgroundColor
        let titleWrapperColor = titleWrapper.backgroundColor
        let rankWarapperColor = rank.backgroundColor
        super.setSelected(selected, animated: animated)
        
        if(selected) {
            artistWrapper.backgroundColor = artistWrapperColor
            titleWrapper.backgroundColor = titleWrapperColor
            rank.backgroundColor = rankWarapperColor
        }
    }
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {
        let artistWrapperColor = artistWrapper.backgroundColor
        let titleWrapperColor = titleWrapper.backgroundColor
        let rankWarapperColor = rank.backgroundColor
        super.setHighlighted(highlighted, animated: animated)
        
        if(highlighted) {
            artistWrapper.backgroundColor = artistWrapperColor
            titleWrapper.backgroundColor = titleWrapperColor
            rank.backgroundColor = rankWarapperColor
        }
    }
}

class BpTrendingTrackTableViewCell: AddableTrackTableViewCell {
    
    @IBOutlet weak var artistWrapper: UIView!
    @IBOutlet weak var titleWrapper: UIView!
    @IBOutlet weak var rank: UILabel!
    @IBOutlet weak var artistName: UILabel!
    @IBOutlet weak var releasedAt: UILabel!
    @IBOutlet weak var titleWidthConstaint: NSLayoutConstraint!
    @IBOutlet weak var photoFrame: UIView!
    @IBOutlet weak var artistWidthConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let selectedBgView = UIView(frame: self.bounds)
        selectedBgView.autoresizingMask = [UIViewAutoresizing.FlexibleHeight, UIViewAutoresizing.FlexibleWidth]
        selectedBgView.backgroundColor = UIColor(netHex: 0xffffff)
        
        self.selectedBackgroundView = selectedBgView
        
        photoFrame.layer.borderColor = UIColor(netHex: 0x909090).CGColor
        photoFrame.layer.borderWidth = 1
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        let artistWrapperColor = artistWrapper.backgroundColor
        let titleWrapperColor = titleWrapper.backgroundColor
        super.setSelected(selected, animated: animated)
        
        if(selected) {
            artistWrapper.backgroundColor = artistWrapperColor
            titleWrapper.backgroundColor = titleWrapperColor
            rank.backgroundColor = rank.backgroundColor
        }
    }
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {
        let artistWrapperColor = artistWrapper.backgroundColor
        let titleWrapperColor = titleWrapper.backgroundColor
        super.setHighlighted(highlighted, animated: animated)
        
        if(highlighted) {
            artistWrapper.backgroundColor = artistWrapperColor
            titleWrapper.backgroundColor = titleWrapperColor
            rank.backgroundColor = rank.backgroundColor
        }
    }
}

class NewReleasedTrackTableViewCell: AddableTrackTableViewCell {
    
    @IBOutlet weak var artistWrapper: UIView!
    @IBOutlet weak var titleWrapper: UIView!
    @IBOutlet weak var titleWidthConstaint: NSLayoutConstraint!
    @IBOutlet weak var photoFrame: UIView!
    @IBOutlet weak var artistWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var releasedAt: UILabel!
    @IBOutlet weak var artistName: PaddingLabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let selectedBgView = UIView(frame: self.bounds)
        selectedBgView.autoresizingMask = [UIViewAutoresizing.FlexibleHeight, UIViewAutoresizing.FlexibleWidth]
        selectedBgView.backgroundColor = UIColor(netHex: 0xffffff)
        
        self.selectedBackgroundView = selectedBgView
        
        photoFrame.layer.borderColor = UIColor(netHex: 0x909090).CGColor
        photoFrame.layer.borderWidth = 1
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        let artistWrapperColor = artistWrapper.backgroundColor
        let titleWrapperColor = titleWrapper.backgroundColor
        super.setSelected(selected, animated: animated)
        
        if(selected) {
            artistWrapper.backgroundColor = artistWrapperColor
            titleWrapper.backgroundColor = titleWrapperColor
        }
    }
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {
        let artistWrapperColor = artistWrapper.backgroundColor
        let titleWrapperColor = titleWrapper.backgroundColor
        super.setHighlighted(highlighted, animated: animated)
        
        if(highlighted) {
            artistWrapper.backgroundColor = artistWrapperColor
            titleWrapper.backgroundColor = titleWrapperColor
        }
    }
}
