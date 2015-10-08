//
//  BaseViewController.swift
//  labs
//
//  Created by vulpes on 2015. 5. 25..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class BaseViewController: GAITrackedViewController {
    
    private var isVisible:Bool = false

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.isVisible = true
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.isVisible = false
    }

}
