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

extension User {
    func titleWithReposted(withDate: NSDate? = nil) -> NSAttributedString {
        let authorName = self.name
        let dateString = ((withDate == nil) ? "" : withDate!.timeAgoSinceNow()).lowercaseString
        let attrString = NSMutableAttributedString(
            string: "\(authorName) reposted \(dateString)",
            attributes: [
                NSForegroundColorAttributeName:UIColor.darkGrayColor(),
                NSFontAttributeName:UIFont.systemFontOfSize(16)
            ])
        attrString.setAttributes([
            NSForegroundColorAttributeName:UIColor.dropbeatColor(),
            NSFontAttributeName:UIFont.boldSystemFontOfSize(16)
            ], range: NSMakeRange(0, authorName.length))
        return attrString
    }
}

class RepostedTrackTableViewCell: DropbeatTrackTableViewCell {
    
    @IBOutlet weak var trackCellView: UIView!
    
    @IBOutlet weak var reposterProfileImageView: UIImageView!
    @IBOutlet weak var reposterNameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        reposterProfileImageView.layer.cornerRadius = 4
        reposterProfileImageView.layer.borderWidth = 1
        reposterProfileImageView.layer.borderColor = UIColor(white: 0.95, alpha: 1.0).CGColor
        
        trackCellView.layer.cornerRadius = 5
        trackCellView.layer.borderColor = UIColor(white: 0.8, alpha: 1.0).CGColor
        trackCellView.layer.borderWidth = 0.5
    }
    
    override func setContentsWithTrack(track: Track, reposting: Bool) {
        let cell = self
        
        let reposter = track.repostingUser!
        cell.reposterNameLabel.attributedText = reposter.titleWithReposted(track.repostedDate)
        
        if let imageUrl = reposter.image {
            cell.reposterProfileImageView.sd_setImageWithURL(NSURL(string: imageUrl), placeholderImage: UIImage(named: "default_profile"))
        } else {
            cell.reposterProfileImageView.image = UIImage(named: "default_profile")
        }
        
        super.setContentsWithTrack(track)
    }
}

class DropbeatTrackTableViewCell: AddableTrackTableViewCell {
    
    @IBOutlet weak var likeButton: UIButton!
    
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
    }
    
    func setContentsWithTrack(track: Track, reposting: Bool = false) {
        let cell = self
        
        var user: BaseUser!
        if reposting {
            let reposter = track.repostingUser
            user = reposter
            cell.userNameView.attributedText = reposter?.titleWithReposted()
            cell.releaseDateLabel.text = track.repostedDate?.timeAgoSinceNow()
        } else {
            user = track.user
            cell.userNameView.text = user?.name
            cell.releaseDateLabel.text = track.releaseDate?.timeAgoSinceNow()
        }
        
        if let imageUrl = user?.image {
            cell.userProfileImageView.sd_setImageWithURL(NSURL(string: imageUrl), placeholderImage: UIImage(named: "default_profile"))
        } else {
            cell.userProfileImageView.image = UIImage(named: "default_profile")
        }
        
        cell.nameView.text = track.title
        cell.thumbView.setImageForTrack(track, size: .LARGE, needsHighDef: false)
        
        let likeImage = track.isLiked ? UIImage(named:"ic_like") : UIImage(named:"ic_dislike")
        cell.likeButton.setImage(likeImage, forState: UIControlState.Normal)
        
        if let dropbeatTrack = track as? DropbeatTrack {
            cell.genreView.hidden = false
            cell.genreView.text = dropbeatTrack.genre
        } else {
            cell.genreView.hidden = true
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
