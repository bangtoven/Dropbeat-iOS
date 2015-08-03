//
//  AddableTrackTableViewCell.swift
//  labs
//
//  Created by vulpes on 2015. 5. 20..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit
    
protocol AddableTrackCellDelegate {
    func onMenuBtnClicked(sender:AddableTrackTableViewCell)
}

class AddableTrackTableViewCell: UITableViewCell {
    
    var delegate:AddableTrackCellDelegate?

    @IBOutlet weak var nameView: UILabel!
    @IBOutlet weak var thumbView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        var selectedBgView = UIView(frame: self.bounds)
        selectedBgView.autoresizingMask = UIViewAutoresizing.FlexibleHeight | UIViewAutoresizing.FlexibleWidth
        selectedBgView.backgroundColor = UIColor(netHex: 0xffffff)
        self.selectedBackgroundView = selectedBgView
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func onMenuBtnClicked(sender: UIButton) {
        delegate?.onMenuBtnClicked(self)
    }
    
}

class BpChartTrackTableViewCell: AddableTrackTableViewCell {
    @IBOutlet weak var artistName: UILabel!
    @IBOutlet weak var genreName: UILabel!
    @IBOutlet weak var rank: UILabel!
}

class TrendingTrackTableViewCell: AddableTrackTableViewCell {

    @IBOutlet weak var rank: UILabel!
    @IBOutlet weak var snippet: UILabel!
    @IBOutlet weak var artistName: UILabel!
}

class BpTrendingTrackTableViewCell: AddableTrackTableViewCell {

    @IBOutlet weak var rank: UILabel!
    @IBOutlet weak var artistName: UILabel!
}

class NewReleasedTrackTableViewCell: AddableTrackTableViewCell {
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
        titleWidthConstaint.constant = self.bounds.width - 16
        artistWidthConstraint.constant = self.bounds.width - 16
        photoFrame.layer.borderColor = UIColor(netHex: 0x909090).CGColor
        photoFrame.layer.borderWidth = 1
    }
    
}

class AddableChannelTrackTableViewCell: AddableTrackTableViewCell {
    @IBOutlet weak var publishedAt: UILabel!
}

class AddableChannelFeedTrackTableViewCell: AddableChannelTrackTableViewCell {
    @IBOutlet weak var channelName: UILabel!
}
