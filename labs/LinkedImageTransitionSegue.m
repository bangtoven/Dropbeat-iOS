//
//  LinkedImageTransitionSegue.m
//  labs
//
//  Created by Jungho Bang on 2015. 9. 25..
//  Copyright © 2015년 dropbeat. All rights reserved.
//

#import "LinkedImageTransitionSegue.h"
#import "RBStoryboardLink.h"

@implementation LinkedImageTransitionSegue

+ (UIViewController *)viewControllerFromLink:(RBStoryboardLink *)link {
    
    NSParameterAssert(link);
    
    if (link.scene)
    {
        return link.scene;
    }
    
    // Grabs the user-defined runtime attributes.
    NSString * storyboardName = [(RBStoryboardLink *)link storyboardName];
    NSString * storyboardID = [(RBStoryboardLink *)link sceneIdentifier];
    NSString * storyboardBundleIdentifier = [(RBStoryboardLink *)link storyboardBundleIdentifier];
    
    NSAssert(storyboardName, @"Unable to load linked storyboard. RBStoryboardLink storyboardName is nil. Forgot to set attribute in interface builder?");
    
    // Creates new destination.
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:storyboardName bundle:[NSBundle bundleWithIdentifier:storyboardBundleIdentifier]];
    
    if ([storyboardID length] == 0) {
        return [storyboard instantiateInitialViewController];
    }
    else {
        return [storyboard instantiateViewControllerWithIdentifier:storyboardID];
    }
}

- (id)initWithIdentifier:(NSString *)identifier source:(UIViewController *)source destination:(UIViewController *)destination
{
    NSAssert([destination isKindOfClass:[RBStoryboardLink class]], @"RBStoryboardSegue can only be used with a RBStoryboardLink as seque destination.");
    
    UIViewController * newDestination = [[self class] viewControllerFromLink:(RBStoryboardLink *)destination];
    
    if ((self = [super initWithIdentifier:identifier source:source destination:newDestination])) {
        _animated = YES;
    }
    
    return self;
}

@end
