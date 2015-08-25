//
//  AddableTrackTableViewCell.swift
//  labs
//
//  Created by vulpes on 2015. 5. 20..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit
    
protocol AddableTrackCellDelegate {
    func onTrackMenuBtnClicked(sender:AddableTrackTableViewCell)
    func onTrackDropBtnClicked(sender:AddableTrackTableViewCell)
}

class AddableTrackTableViewCell: UITableViewCell {
    
    var delegate:AddableTrackCellDelegate?

    @IBOutlet weak var filterView: UIView!
    @IBOutlet weak var nameView: UILabel!
    @IBOutlet weak var thumbView: UIImageView!
    @IBOutlet weak var dropBtn: UIButton!
    override func awakeFromNib() {
        super.awakeFromNib()
//        // Initialization code
        var selectedBgView = UIView(frame: self.bounds)
        selectedBgView.autoresizingMask = UIViewAutoresizing.FlexibleHeight | UIViewAutoresizing.FlexibleWidth
        selectedBgView.backgroundColor = UIColor(netHex: 0xffffff)
        self.selectedBackgroundView = selectedBgView
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        if(selected) {
            filterView.hidden = false
            filterView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.4)
        } else {
            filterView.hidden = true
        }
    }

    @IBAction func onMenuBtnClicked(sender: UIButton) {
        delegate?.onTrackMenuBtnClicked(self)
    }
    
    @IBAction func onDropBtnClicked(sender: AnyObject) {
        delegate?.onTrackDropBtnClicked(self)
    }
}

class UserTrackTableViewCell: AddableTrackTableViewCell {
    
    @IBOutlet weak var contentFrame: UIView!
    @IBOutlet weak var listenTimeView: UILabel!
    @IBOutlet weak var userNameView: UILabel!
    @IBOutlet weak var artistName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        var selectedBgView = UIView(frame: self.bounds)
        selectedBgView.autoresizingMask = UIViewAutoresizing.FlexibleHeight | UIViewAutoresizing.FlexibleWidth
        selectedBgView.backgroundColor = UIColor(netHex: 0xEFEFF4)
        self.selectedBackgroundView = selectedBgView
        
        contentFrame.layer.borderColor = UIColor(netHex: 0xD6D6D6).CGColor
        contentFrame.layer.borderWidth = 1
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        contentFrame.backgroundColor = UIColor.whiteColor()
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
        var selectedBgView = UIView(frame: self.bounds)
        selectedBgView.autoresizingMask = UIViewAutoresizing.FlexibleHeight | UIViewAutoresizing.FlexibleWidth
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
        var selectedBgView = UIView(frame: self.bounds)
        selectedBgView.autoresizingMask = UIViewAutoresizing.FlexibleHeight | UIViewAutoresizing.FlexibleWidth
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
            rank.backgroundColor = rank.backgroundColor
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
        var selectedBgView = UIView(frame: self.bounds)
        selectedBgView.autoresizingMask = UIViewAutoresizing.FlexibleHeight | UIViewAutoresizing.FlexibleWidth
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

class AddableChannelTrackTableViewCell: AddableTrackTableViewCell {
    @IBOutlet weak var publishedAt: UILabel!
}

class AddableChannelFeedTrackTableViewCell: AddableChannelTrackTableViewCell {
    @IBOutlet weak var channelName: UILabel!
}
