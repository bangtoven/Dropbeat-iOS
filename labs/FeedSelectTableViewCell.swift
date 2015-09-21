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
