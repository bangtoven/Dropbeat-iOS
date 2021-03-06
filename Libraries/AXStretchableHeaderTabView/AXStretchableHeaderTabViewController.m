//
//  AXStretchableHeaderTabViewController.m
//  Pods
//

#import "AXStretchableHeaderTabViewController.h"

static NSString * const AXStretchableHeaderTabViewControllerSelectedIndexKey = @"selectedIndex";

@interface AXStretchableHeaderTabViewController ()

@property NSMutableArray *shownViewController;

@end

@implementation AXStretchableHeaderTabViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        _shouldBounceHeaderView = YES;
        
        _tabBar = [[AXTabBar alloc] init];
        [_tabBar setDelegate:self];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [_tabBar sizeToFit];
    [self.view addSubview:_tabBar];
    self.headerViewHeightRatio = 1.0;
}

- (void)dealloc
{
    [_viewControllers enumerateObjectsUsingBlock:^(UIViewController *viewController, NSUInteger idx, BOOL *stop) {
        UIScrollView *scrollView = [self scrollViewWithSubViewController:viewController];
        if (scrollView) {
            [scrollView removeObserver:self forKeyPath:@"contentOffset"];
        }
        [viewController removeFromParentViewController];
    }];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    [_headerView setFrame:(CGRect){
        0.0, 0.0,
        CGRectGetWidth(self.view.bounds), _headerView.maximumOfHeight + _containerView.contentInset.top
    }];
    
    [self layoutHeaderViewAndTabBar];
    [self layoutViewControllers];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Property

- (UIViewController *)selectedViewController
{
    return _viewControllers[_selectedIndex];
}

- (UIScrollView*)selectedScrollView
{
    return [self scrollViewWithSubViewController:self.selectedViewController];
}

- (void)setSelectedViewController:(UIViewController *)selectedViewController
{
    NSInteger newIndex = [_viewControllers indexOfObject:selectedViewController];
    if (newIndex == NSNotFound) {
        return;
    }
    if (newIndex != _selectedIndex) {
        [self changeSelectedIndex:newIndex];
    }
}

//- (void)setHeaderView:(AXStretchableHeaderView *)headerView
//{
//    if (_headerView != headerView) {
//        [_headerView removeFromSuperview];
//        _headerView = headerView;
//        [self.view addSubview:_headerView];
//    }
//}

- (void)setViewControllers:(NSArray *)viewControllers
{
    if ([_viewControllers isEqualToArray:viewControllers] == NO) {
        // Load nib file, if self.view is nil.
        [self view];
        
        // Remove views in old view controllers
        [_viewControllers enumerateObjectsUsingBlock:^(UIViewController *viewController, NSUInteger idx, BOOL *stop) {
            [viewController.view removeFromSuperview];
            UIScrollView *scrollView = [self scrollViewWithSubViewController:viewController];
            if (scrollView) {
                [scrollView removeObserver:self forKeyPath:@"contentOffset"];
            }
            [viewController removeFromParentViewController];
        }];
        
        // Assign new view controllers
        _viewControllers = [viewControllers copy];
        
        // Add views in new view controllers
        NSMutableArray *tabItems = [NSMutableArray array];
        [_viewControllers enumerateObjectsUsingBlock:^(UIViewController *viewController, NSUInteger idx, BOOL *stop) {
            [_containerView addSubview:viewController.view];
            UIScrollView *scrollView = [self scrollViewWithSubViewController:viewController];
            if (scrollView) {
                [scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
            }
            [self addChildViewController:viewController];
            [tabItems addObject:viewController.tabBarItem];
        }];
        [_tabBar setItems:tabItems];
        
        [self layoutViewControllers];
        
        // tab bar
        [_tabBar setSelectedItem:[_tabBar.items firstObject]];
        if (_selectedIndex != 0) {
            [self changeSelectedIndex:0];
        }
        
        self.shownViewController = [[NSMutableArray alloc] initWithCapacity:10];
        for (int i = 0; i<viewControllers.count; i++) {
            [self.shownViewController insertObject:@(NO) atIndex:i];
        }
        [self didEndScrollToIndex:0];
        
        // 왜 이게 되는지 나도 모르겠다만...
        [self.selectedScrollView setContentOffset:CGPointMake(0, -1000)];
    }
}

#pragma mark - Layout

-(void)didHeightRatioChange:(CGFloat)ratio {
    
}

- (void)layoutHeaderViewAndTabBar
{
    UIViewController *selectedViewController = self.selectedViewController;
    
    // Get selected scroll view.
    UIScrollView *scrollView = [self scrollViewWithSubViewController:selectedViewController];
    
    if (scrollView) {
        // Set header view frame
        CGFloat headerViewHeight = _headerView.maximumOfHeight - (scrollView.contentOffset.y + scrollView.contentInset.top);
        headerViewHeight = MAX(headerViewHeight, _headerView.minimumOfHeight);
        if (_headerView.bounces == NO) {
            headerViewHeight = MIN(headerViewHeight, _headerView.maximumOfHeight);
        }
        [_headerView setFrame:(CGRect)
         {
             _headerView.frame.origin,
             CGRectGetWidth(_headerView.frame), headerViewHeight + _containerView.contentInset.top
         }];
        
        CGFloat ratio = (headerViewHeight - self.headerView.minimumOfHeight) /
        (self.headerView.maximumOfHeight - self.headerView.minimumOfHeight);
        if (ratio != self.headerViewHeightRatio) {
            self.headerViewHeightRatio = ratio;
            [self didHeightRatioChange:ratio];
            [self.headerView didHeightRatioChange:ratio];
        }
    
        CGFloat top = CGRectGetMaxY(_tabBar.frame) - CGRectGetMaxY(self.navigationController.navigationBar.frame);
        // Set scroll view indicator insets
        [scrollView setScrollIndicatorInsets:
         UIEdgeInsetsMake(top, 0.0, scrollView.contentInset.bottom, 0.0)];
        
    } else {
        // Set header view frame
        [_headerView setFrame:(CGRect){
            _headerView.frame.origin,
            CGRectGetWidth(_headerView.frame), _headerView.maximumOfHeight + _containerView.contentInset.top
        }];
    }
    
    // Tab bar
    CGFloat tabBarY =
    (_headerView ?
     CGRectGetMaxY(_headerView.frame) :
     _containerView.contentInset.top
     );
    [_tabBar setFrame:(CGRect){
        0.0, tabBarY,
        _tabBar.frame.size
    }];
    
}

- (void)layoutViewControllers
{
    [self.view layoutSubviews];
    
    CGSize size = _containerView.bounds.size;
    
    CGFloat headerOffset =
    (_headerView ?
     _headerView.maximumOfHeight :
     0.0
     );
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(headerOffset + CGRectGetHeight(_tabBar.bounds), 0.0, _containerView.contentInset.top, 0.0);
    
    // Resize sub view controllers
    [_viewControllers enumerateObjectsUsingBlock:^(UIViewController *viewController, NSUInteger idx, BOOL *stop) {
        CGRect newFrame = (CGRect){size.width * idx, 0.0, size};
        UIScrollView *scrollView = [self scrollViewWithSubViewController:viewController];
        if (scrollView) {
            [viewController.view setFrame:newFrame];
            [scrollView setContentInset:contentInsets];
        } else {
            [viewController.view setFrame:UIEdgeInsetsInsetRect(newFrame, contentInsets)];
        }
    }];
    [_containerView setContentSize:(CGSize){size.width * _viewControllers.count, 0.0}];
}

- (void)layoutSubViewControllerToSelectedViewController
{
    UIViewController *selectedViewController = [self selectedViewController];
    // Define selected scroll view
    UIScrollView *selectedScrollView = [self scrollViewWithSubViewController:selectedViewController];
    if (!selectedScrollView) {
        return;
    }
    
    // Define relative y calculator
    CGFloat (^calcRelativeY)(CGFloat contentOffsetY, CGFloat contentInsetTop) = ^CGFloat(CGFloat contentOffsetY, CGFloat contentInsetTop) {
        return _headerView.maximumOfHeight - _headerView.minimumOfHeight - (contentOffsetY + contentInsetTop);
    };
    
    // Adjustment offset or frame for sub views.
    [_viewControllers enumerateObjectsUsingBlock:^(UIViewController *viewController, NSUInteger idx, BOOL *stop) {
        if (selectedViewController == viewController) {
            return;
        }
        
        UIScrollView *targetScrollView = [self scrollViewWithSubViewController:viewController];
        if ([targetScrollView isKindOfClass:[UIScrollView class]]) {
            // Scroll view
            // -> Adjust offset
            CGFloat relativePositionY = calcRelativeY(selectedScrollView.contentOffset.y, selectedScrollView.contentInset.top);//headerViewHeight - _headerView.minimumOfHeight;
            if (relativePositionY > 0) {
                // The header view's height is higher than minimum height.
                // -> Adjust same offset.
                [targetScrollView setContentOffset:selectedScrollView.contentOffset];
                
            } else {
                // The header view height is lower than minimum height.
                // -> Adjust top of scrollview, If target header view's height is higher than minimum height.
                CGFloat targetRelativePositionY = calcRelativeY(targetScrollView.contentOffset.y, targetScrollView.contentInset.top);
                if (targetRelativePositionY > 0) {
                    targetScrollView.contentOffset = (CGPoint){
                        targetScrollView.contentOffset.x,
                        -(CGRectGetMaxY(_tabBar.frame) - _containerView.contentInset.top)
                    };
                }
            }
        } else {
            // Not scroll view
            // -> Adjust frame to area at the bottom of tab bar.
            CGFloat y = CGRectGetMaxY(_tabBar.frame) - _containerView.contentInset.top;
            [targetScrollView setFrame:(CGRect){
                CGRectGetMinX(targetScrollView.frame), y,
                CGRectGetMinX(targetScrollView.frame), CGRectGetHeight(_containerView.frame) - y
            }];
        }
    }];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    UIViewController *selectedViewController = [self selectedViewController];
    if ([keyPath isEqualToString:@"contentOffset"]) {
        UIScrollView *scrollView = [self scrollViewWithSubViewController:selectedViewController];
        if (scrollView != object) {
            return;
        }
        [self layoutHeaderViewAndTabBar];
    }
}

#pragma mark - Scroll view delegate (tab view controllers)

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self layoutSubViewControllerToSelectedViewController];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.isDragging) {
        NSUInteger numberOfViewControllers = _viewControllers.count;
        CGFloat offset = scrollView.contentOffset.x / scrollView.contentSize.width * numberOfViewControllers;

        NSInteger lower = floor(offset);
        NSInteger upper = ceil(offset);
        [self didSubViewAppearWithIndex:lower];
        [self didSubViewAppearWithIndex:upper];
        
        NSInteger newSelectedIndex = round(offset);
        newSelectedIndex = MIN(numberOfViewControllers - 1, MAX(0, newSelectedIndex));
        if (_selectedIndex != newSelectedIndex) {
            [_tabBar setSelectedItem:_tabBar.items[newSelectedIndex]];
            [self changeSelectedIndex:newSelectedIndex];
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    NSUInteger numberOfViewControllers = _viewControllers.count;
    CGFloat offset = scrollView.contentOffset.x / scrollView.contentSize.width * numberOfViewControllers;
    NSInteger newSelectedIndex = round(offset);
    [self didEndScrollToIndex:newSelectedIndex];
}

- (void)didEndScrollToIndex:(NSInteger)index
{
    for (int i=0; i<self.shownViewController.count; i++) {
        if (i == index) {
            [self didSubViewAppearWithIndex:i];
        }
        else {
            if ([self.shownViewController[i] boolValue] == YES) {
                self.shownViewController[i] = @(NO);
                id<AXSubViewController> vc = self.viewControllers[i];
                [vc subViewWillDisappear];
            }
        }
    }
    
//    UIScrollView *scrollView = self.selectedScrollView;
//    
//    CGFloat minHeight = self.view.frame.size.height - (CGRectGetMaxY(self.navigationController.navigationBar.frame)+ CGRectGetHeight(_tabBar.bounds));
//    if (scrollView.contentSize.height < minHeight) {
//        [scrollView setContentSize:CGSizeMake(scrollView.contentSize.width, minHeight)];
//    }
}

- (void)didSubViewAppearWithIndex:(NSInteger)index
{
    if (index < 0 || index >= self.shownViewController.count) {
        NSLog(@"%ld sub view controller??", index);
        return;
    }
    
    if ([self.shownViewController[index] boolValue]== NO) {
        self.shownViewController[index] = @(YES);
        id<AXSubViewController> vc = self.viewControllers[index];
        [vc subViewWillAppear];
    }
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView
{
    NSLog(@"scrollViewShouldScrollToTop");
    return NO;
}

#pragma mark - Tab bar delegate

- (BOOL)tabBar:(AXTabBar *)tabBar shouldSelectItem:(UITabBarItem *)item
{
    [self layoutSubViewControllerToSelectedViewController];
    return YES;
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    NSInteger newSelectedIndex = [[tabBar items] indexOfObject:item];
    if (_selectedIndex != newSelectedIndex) {
        [_containerView setContentOffset:(CGPoint){newSelectedIndex * CGRectGetWidth(_containerView.bounds), _containerView.contentOffset.y} animated:YES];
        [self changeSelectedIndex:newSelectedIndex];
        [self didEndScrollToIndex:newSelectedIndex];
    }
}

#pragma mark - Private Method

- (UIScrollView *)scrollViewWithSubViewController:(UIViewController *)viewController
{
    if ([viewController respondsToSelector:@selector(stretchableSubViewInSubViewController)]) {
        return [(id<AXStretchableSubViewControllerViewSource>)viewController stretchableSubViewInSubViewController];
    } else if ([viewController.view isKindOfClass:[UIScrollView class]]) {
        return (id)viewController.view;
    } else {
        return nil;
    }
}

- (void)changeSelectedIndex:(NSInteger)selectedIndex
{
    [self willChangeValueForKey:@"selectedIndex"];
    [self willChangeValueForKey:@"selectedViewController"];
    _selectedIndex = selectedIndex;
    [self didChangeValueForKey:@"selectedIndex"];
    [self didChangeValueForKey:@"selectedViewController"];
}

@end
