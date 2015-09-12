//
//  HeaderView.swift
//  labs
//
//  Created by Jungho Bang on 2015. 9. 13..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class HeaderView: AXStretchableHeaderView, AXStretchableHeaderViewDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var button: UIButton!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.delegate = self
    }
    
    func interactiveSubviewsInStretchableHeaderView(stretchableHeaderView: AXStretchableHeaderView!) -> [AnyObject]! {
        return [self.button]
    }

}
