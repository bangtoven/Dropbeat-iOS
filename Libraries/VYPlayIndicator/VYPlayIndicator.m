//
//  VYPlayIndicator.m
//
//  Created by Dennis Oberhoff on 05/04/15.
//  Copyright (c) 2015 Dennis Oberhoff. All rights reserved.
//

#import "VYPlayIndicator.h"

@interface VYPlayIndicator()

@property (nonatomic, readwrite, strong) CAShapeLayer *firstBeam;
@property (nonatomic, readwrite, strong) CAShapeLayer *secondBeam;

@end

@implementation VYPlayIndicator

@synthesize color = _color;

-(instancetype)init {
    self = [super init];
    if (self) {
        self.firstBeam = [CAShapeLayer new];
        self.secondBeam = [CAShapeLayer new];
        [self addSublayer:self.firstBeam];
        [self addSublayer:self.secondBeam];
        [self applyStyle];
        [self applyPath];
    }
    return self;
}

-(void)applyStyle {
    
    self.color = [UIColor redColor];
    self.firstBeam.fillColor = self.color.CGColor;
    self.secondBeam.fillColor = self.color.CGColor;
    
    self.firstBeam.opaque = YES;
    self.secondBeam.opaque = YES;

    self.opacity = 0.0;

}

-(void)applyPath {

    CGRect bounds = [self pathWithPercentage:100].bounds;
    UIBezierPath *path = [self pathWithPercentage:5];
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.firstBeam.frame = bounds;
    self.secondBeam.frame = bounds;
    
    self.firstBeam.path = path.CGPath;
    self.secondBeam.path = path.CGPath;
    
    self.secondBeam.position = (CGPoint) {CGRectGetMaxX(self.bounds) - CGRectGetWidth(self.secondBeam.bounds) / 2, CGRectGetMidY(self.bounds)};
    
    [CATransaction commit];
    
}

-(void)animatePlayback {
    
    CABasicAnimation *opacity = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opacity.toValue = @(1.0);
    opacity.fromValue = [self.presentationLayer valueForKeyPath:opacity.keyPath];
    opacity.duration = 0.2;
    opacity.fillMode = kCAFillModeBoth;
    opacity.removedOnCompletion = NO;
    
    CAKeyframeAnimation *keyframe = [CAKeyframeAnimation animationWithKeyPath:@"path"];
    keyframe.duration = 2.75;
    keyframe.beginTime = CACurrentMediaTime() + 0.35;
    keyframe.fillMode = kCAFillModeForwards;
    keyframe.removedOnCompletion = NO;
    keyframe.autoreverses = YES;
    keyframe.repeatCount = INFINITY;
    
    CAKeyframeAnimation *secondBeam = keyframe.copy;
    
    NSUInteger count = 10;
    
    keyframe.values = [self randomPaths:count];
    secondBeam.values = [self randomPaths:count];

    keyframe.keyTimes = [self randomKeytimes:count];
    secondBeam.keyTimes = [self randomKeytimes:count];
    
    keyframe.timingFunctions = [self randomTimingFunctions:count];
    secondBeam.timingFunctions = [self randomTimingFunctions:count];
    
    CABasicAnimation *begin = [CABasicAnimation animationWithKeyPath:@"path"];
    begin.duration = 0.35;
    begin.fillMode = kCAFillModeRemoved;
    begin.removedOnCompletion = YES;
    
    CABasicAnimation *secondBegin = begin.copy;

    begin.fromValue = [self.firstBeam.presentationLayer valueForKeyPath:begin.keyPath];
    secondBegin.fromValue = [self.secondBeam.presentationLayer valueForKeyPath:secondBeam.keyPath];

    begin.toValue = keyframe.values.firstObject;
    secondBegin.toValue = secondBeam.values.firstObject;

    [self.firstBeam addAnimation:begin forKey:begin.keyPath];
    [self.firstBeam addAnimation:keyframe forKey:@"keyFrame"];
    [self.secondBeam addAnimation:secondBegin forKey:secondBegin.keyPath];
    [self.secondBeam addAnimation:secondBeam forKey:@"keyFrame"];
    [self addAnimation:opacity forKey:opacity.keyPath];
    
}

-(void)stopPlayback {
    
    if (![self animationForKey:@"opacity"]) return;
    
    UIBezierPath *path = [self pathWithPercentage:5];
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"path"];
    animation.toValue = (id) path.CGPath;
    animation.duration = 0.2;
    animation.fillMode = kCAFillModeForwards;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    animation.removedOnCompletion = NO;

    CABasicAnimation *opacity = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opacity.toValue = @(0.0);
    opacity.fromValue = [self.presentationLayer valueForKeyPath:opacity.keyPath];
    opacity.beginTime = CACurrentMediaTime() + animation.duration * 0.8;
    opacity.duration = 0.1;
    opacity.fillMode = kCAFillModeBoth;
    opacity.removedOnCompletion = NO;
    opacity.delegate = self;
    
    for (CAShapeLayer *beam in @[self.firstBeam, self.secondBeam]) {
        CABasicAnimation *step = animation.copy;
        step.fromValue = [beam.presentationLayer valueForKeyPath:step.keyPath];
        [beam addAnimation:step forKey:step.keyPath];
    }
    [self addAnimation:opacity forKey:opacity.keyPath];
    
    
}

-(void)reset {
    [self removeAllAnimations];
    for (CAShapeLayer *layer in @[self.firstBeam, self.secondBeam]) {
        [layer removeAllAnimations];
        layer.fillColor = self.color.CGColor;
    }
}

-(NSArray*)randomPaths:(NSUInteger)count {
    NSMutableArray *frames = [NSMutableArray arrayWithCapacity:count];
    while (count--) [frames addObject: (id) [self pathWithPercentage:(CGFloat) rand() / RAND_MAX * 100].CGPath];
    return frames.copy;
}

-(NSArray*)randomTimingFunctions:(NSUInteger)count {
    NSMutableArray *randomTimings = [NSMutableArray arrayWithCapacity:count];
    NSArray *timings = @[kCAMediaTimingFunctionLinear, kCAMediaTimingFunctionEaseInEaseOut, kCAMediaTimingFunctionEaseOut,kCAMediaTimingFunctionEaseIn];
    while (count--) [randomTimings addObject:[CAMediaTimingFunction functionWithName:timings[arc4random() % timings.count]]];
    return randomTimings.copy;
}

-(NSArray*)randomKeytimes:(NSUInteger)count {
    NSMutableArray *timings = [NSMutableArray arrayWithCapacity:count];
    for (int idx = 0; idx < count; idx++) [timings addObject:@((CGFloat) idx / count)];
    return timings.copy;
}

-(UIBezierPath*)pathWithPercentage:(CGFloat)percentageFactor {
    
    CGFloat originY = CGRectGetHeight(self.bounds) - (CGRectGetHeight(self.bounds) * (percentageFactor / 100.0 ));
    CGFloat originX = CGRectGetMaxX(self.bounds) * 0.4;
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(originX, CGRectGetMaxY(self.bounds))];
    [path addLineToPoint:CGPointMake(CGRectGetMinX(self.bounds), CGRectGetMaxY(self.bounds))];
    [path addLineToPoint:CGPointMake(CGRectGetMinX(self.bounds), originY)];
    [path addLineToPoint:CGPointMake(originX, originY)];
    [path closePath];
    return path;
}

-(void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    if (!flag) return;
    if (self.completionBlock) self.completionBlock();
    self.completionBlock = nil;
}

-(void)setColor:(UIColor *)color {
    _color = color;
    self.firstBeam.fillColor = color.CGColor;
    self.secondBeam.fillColor = color.CGColor;
}

-(void)layoutSublayers {
    [super layoutSublayers];
    [self applyPath];
}

@end
