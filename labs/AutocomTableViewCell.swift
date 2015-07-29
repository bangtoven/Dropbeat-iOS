//
//  AutocomTableViewCell.swift
//  labs
//
//  Created by vulpes on 2015. 5. 23..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class AutocomTableViewCell: UITableViewCell {

    @IBOutlet weak var keywordView: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        var selectedBgView = UIView(frame: self.bounds)
        selectedBgView.autoresizingMask = UIViewAutoresizing.FlexibleHeight | UIViewAutoresizing.FlexibleWidth
        selectedBgView.backgroundColor = UIColor(netHex: 0xdddddd)
        self.selectedBackgroundView = selectedBgView
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
