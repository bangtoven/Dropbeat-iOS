//
//  GradientView.m
//  labs
//
//  Created by Jungho Bang on 2015. 9. 15..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

#import "GradientView.h"

@implementation GradientView

- (void)drawRect:(CGRect)rect {
    //// General Declarations
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //// Color Declarations
    UIColor* fill = [UIColor colorWithWhite:0 alpha:1];
    UIColor* clear = [UIColor colorWithWhite:0 alpha:0.5];
    UIColor* middle = [UIColor colorWithWhite:0 alpha:0];
    if (self.fillColor) {
        fill = self.fillColor;
        CGFloat r, g, b, a;
        [fill getRed:&r green:&g blue:&b alpha:&a];
        clear = [UIColor colorWithRed:r green:g blue:b alpha:0];
        middle= [UIColor colorWithRed:r green:g blue:b alpha:a/2];
    }
    
    //// Gradient Declarations
    NSArray* gradient2Colors = [NSArray arrayWithObjects:
                                (id)fill.CGColor,
                                (id)fill.CGColor,
                                (id)middle.CGColor,
                                (id)clear.CGColor, nil];
    CGFloat gradient2Locations[] = {0, self.fillRatio, (1+self.fillRatio)/2.0, 1};
    CGGradientRef gradient2 = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)gradient2Colors, gradient2Locations);
    
    //// Gradient Drawing
//    CGRect gradientRect = CGRectMake(CGRectGetMinX(frame), CGRectGetMinY(frame), CGRectGetWidth(frame), CGRectGetHeight(frame));
    UIBezierPath* gradientPath = [UIBezierPath bezierPathWithRect: rect];
    CGContextSaveGState(context);
    [gradientPath addClip];
    if (self.reverse == NO)
        CGContextDrawLinearGradient(context, gradient2,
                                CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect)),
                                CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect)),
                                0);
    else
        CGContextDrawLinearGradient(context, gradient2,
                                    CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect)),
                                    CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect)),
                                    0);

    CGContextRestoreGState(context);
    
    
    //// Cleanup
    CGGradientRelease(gradient2);
    CGColorSpaceRelease(colorSpace);
}


@end
