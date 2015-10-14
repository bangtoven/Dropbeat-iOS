//
//  ViewController.swift
//  DropbeatTutorial
//
//  Created by LeeTaeksoo on 2015. 10. 12..
//  Copyright © 2015년 Dropbeat. All rights reserved.
//

import UIKit

class TutorialViewController: FBSigninableViewController, EAIntroDelegate {

    @IBOutlet weak var introView: EAIntroView!
    @IBOutlet var accountView: UIView!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if introView.hidden {
            introView.hidden = false

            var font: UIFont!
            if #available(iOS 8.2, *) {
                font = UIFont.systemFontOfSize(30, weight: UIFontWeightLight)
            } else {
                font = UIFont.systemFontOfSize(30)
            };
            
            let page1 = EAIntroPage()
            page1.title = "ENJOY UNLIMITED\nFREE STREAMING"
            page1.titleFont = font
            page1.titlePositionY = self.view.bounds.size.height / 2 + 34;
            page1.bgImage = UIImage(named: "tutorial_bg_1")
            
            let page2 = EAIntroPage()
            let viewHeight:CGFloat = 240;
            let dropImg = UIImage(named:"tutorial_drop_btn")!
            let dropIcon = UIImageView(image: dropImg)
            page2.titleIconPositionY = (self.view.bounds.size.height + viewHeight) / 2 - dropImg.size.height
            page2.titleIconView = dropIcon
            
            page2.title = "PLAY ONLY\nTHE HIGHLIGHTS"
            page2.titleFont = font
            page2.titlePositionY = (self.view.bounds.size.height + viewHeight) / 2;
            page2.bgImage = UIImage(named: "tutorial_bg_2")
            
            
//            let page3 = EAIntroPage()
//            page3.title = "COMPREHENSIVE\n DISCOVERY AND\n STREAMING\n EDM PLATFORM"
//            page3.titleFont = font
//            page3.titlePositionY = self.view.bounds.size.height / 2 + 80;
//            page3.bgImage = UIImage(named: "tutorial_bg_3")
            
            let page4 = EAIntroPage()
            page4.title = "DISCOVER AND\nFOLLOW YOUR\nFAVORITE ARTISTS"
            page4.titleFont = font
            page4.titlePositionY = self.view.bounds.size.height / 2 + 60;
            page4.bgImage = UIImage(named: "tutorial_bg_4")
            
            let page5 = EAIntroPage()
            page5.title = "EXPLORE MORE\nFEATURES FOR DJs\n@ DROPBEAT.NET"
            page5.titleFont = font
            page5.titlePositionY = self.view.bounds.size.height / 2 + 100;
            page5.bgImage = UIImage(named: "tutorial_bg_5")
            
            let finalPage = EAIntroPage(customView: self.accountView)
            finalPage.bgImage = UIImage(named: "tutorial_bg_6")
            
            introView.pages = [page1, page2, page4, page5, finalPage]
            introView.bgViewContentMode = UIViewContentMode.ScaleAspectFill
            
            introView.swipeToExit = false
            introView.skipButton = nil
        }
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }

    func introDidFinish(introView: EAIntroView!) {
        
    }
    
    func intro(introView: EAIntroView!, pageAppeared page: EAIntroPage!, withIndex pageIndex: UInt) {
        
    }
    
    func intro(introView: EAIntroView!, pageEndScrolling page: EAIntroPage!, withIndex pageIndex: UInt) {
        
    }
    
    func intro(introView: EAIntroView!, pageStartScrolling page: EAIntroPage!, withIndex pageIndex: UInt) {
        
    }

}

