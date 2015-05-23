//
//  SparkSlider.swift
//  labs
//
//  Created by vulpes on 2015. 5. 24..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class SparkSlider: UISlider {
    
    
    override init(frame: CGRect) {
        super.init(frame: CGRectMake(frame.origin.x, frame.origin.y, frame.width, 8))
        self.setThumbImage(UIImage(named: "slider_thumb.png"), forState: UIControlState.Normal)
        self.setMaximumTrackImage(UIImage(named: "slider_max.png"), forState: UIControlState.Normal)
        self.setMinimumTrackImage(UIImage(named: "slider_min.png"), forState: UIControlState.Normal)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.width, 8)
        self.setThumbImage(UIImage(named: "slider_thumb.png"), forState: UIControlState.Normal)
        self.setMaximumTrackImage(UIImage(named: "slider_max.png"), forState: UIControlState.Normal)
        self.setMinimumTrackImage(UIImage(named: "slider_min.png"), forState: UIControlState.Normal)
    }

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}
