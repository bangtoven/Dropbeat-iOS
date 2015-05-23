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
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
