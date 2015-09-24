//
//  LinkedImageTransitionSegue.h
//  labs
//
//  Created by Jungho Bang on 2015. 9. 25..
//  Copyright © 2015년 dropbeat. All rights reserved.
//

#import "JHImageTransitionSegue.h"
@class RBStoryboardLink;

@interface LinkedImageTransitionSegue : JHImageTransitionSegue

@property (nonatomic, assign, getter = isAnimated) BOOL animated;

+ (UIViewController *)viewControllerFromLink:(RBStoryboardLink *)link;

@end
