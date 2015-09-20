//
//  AXStretchableHeaderTabViewController.h
//  Pods
//

#import <UIKit/UIKit.h>
#import "AXStretchableHeaderView.h"
#import "AXTabBar.h"

@class AXStretchableHeaderTabViewController;

@protocol AXStretchableSubViewControllerViewSource <NSObject>
@optional
- (UIScrollView *)stretchableSubViewInSubViewController;
@end

@protocol AXSubViewController <NSObject>
- (void)subViewWillAppear;
- (void)subViewWillDisappear;
@end

@interface AXStretchableHeaderTabViewController : UIViewController <UIScrollViewDelegate, AXTabBarDelegate>
@property (nonatomic) NSUInteger selectedIndex;
@property (readwrite, nonatomic) UIViewController *selectedViewController;
@property (readonly, nonatomic) UIScrollView *selectedScrollView;

@property (copy, nonatomic) NSArray *viewControllers;

@property (weak, nonatomic) IBOutlet AXStretchableHeaderView *headerView;
@property (readonly, nonatomic) AXTabBar *tabBar;
@property (weak, nonatomic) IBOutlet UIScrollView *containerView;
@property (nonatomic) BOOL shouldBounceHeaderView;

@property CGFloat headerViewHeightRatio;

// Layout
- (void)layoutHeaderViewAndTabBar;
- (void)layoutViewControllers;
- (void)layoutSubViewControllerToSelectedViewController;

- (void)didHeightRatioChange:(CGFloat)ratio;


@end
