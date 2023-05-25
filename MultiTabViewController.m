#import "MultiTabViewController.h"
#import <Masonry.h>

@interface MultiTabViewController () <UIScrollViewDelegate>

@property (strong, nonatomic) UIView *tabMenu;
@property (strong, nonatomic) UIView *tabBody;
@property (strong, nonatomic) NSArray<NSString *> *tabTitles;
@property (strong, nonatomic) NSArray<UIView *> *tabViews;
@property (strong, nonatomic) NSArray<UIViewController *> *tabControllers;
@property (assign, nonatomic) NSInteger tabSelectedIndex;
@property (assign, nonatomic) BOOL tabScrollEnabled;

@property (strong, nonatomic) UIView *tabMenuContainerView;
@property (strong, nonatomic) UIView *tabMenuView;
@property (strong, nonatomic) NSMutableArray<UIView *> *tabMenus;
@property (strong, nonatomic) NSMutableArray<UILabel *> *tabMenuTitles;
@property (strong, nonatomic) NSMutableArray<UIView *> *tabMenuIndicators;
@property (strong, nonatomic) NSMutableArray<id> *tabMenuBadges;
@property (strong, nonatomic) UIView *tabMenuIndicator;
@property (strong, nonatomic) UIView *tabBodyContainerView;
@property (strong, nonatomic) UIScrollView *tabBodyScrollView;

@end

@implementation MultiTabViewController

- (UIFont *)tabMenuFont {
    if (!_tabMenuFont) {
        _tabMenuFont = [UIFont systemFontOfSize:16];
    }
    return _tabMenuFont;
}

- (UIFont *)tabMenuSelectedFont {
    if (!_tabMenuSelectedFont) {
        _tabMenuSelectedFont = self.tabMenuFont;
    }
    return _tabMenuSelectedFont;
}

- (UIColor *)tabMenuColor {
    if (!_tabMenuColor) {
        _tabMenuColor = [UIColor blackColor];
    }
    return _tabMenuColor;
}

- (UIColor *)tabMenuSelectedColor {
    if (!_tabMenuSelectedColor) {
        _tabMenuSelectedColor = [UIColor redColor];
    }
    return _tabMenuSelectedColor;
}

- (UIColor *)tabMenuIndicatorColor {
    if (!_tabMenuIndicatorColor) {
        _tabMenuIndicatorColor = self.tabMenuSelectedColor;
    }
    return _tabMenuIndicatorColor;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    CGRect frame = self.view.frame;
    frame.size.width = UIScreen.mainScreen.bounds.size.width;
    self.view.frame = frame;
    [self.view layoutIfNeeded];
}

- (void)deinitTab {
    self.tabMenuIndicator = nil;
    [self.tabMenuContainerView removeFromSuperview];
    
    for (UIViewController *controller in self.tabControllers) {
        [controller willMoveToParentViewController:nil];
        [controller.view removeFromSuperview];
        [controller removeFromParentViewController];
    }
    
    [self.tabBodyContainerView removeFromSuperview];
}

- (BOOL)initTabWithMenu:(UIView *)menu body:(UIView *)body titles:(NSArray<NSString *> *)titles views:(NSArray<UIView *> *)views selectedIndex:(NSInteger)selectedIndex scrollEnabled:(BOOL)scrollEnabled {
    [self deinitTab];
    
    self.tabMenu = menu;
    self.tabBody = body;
    self.tabTitles = titles;
    self.tabViews = views;
    self.tabSelectedIndex = selectedIndex;
    self.tabScrollEnabled = scrollEnabled;
    
    [self initMenu];
    [self initBody];
    [self.view layoutIfNeeded];
    [self selectTabAtIndex:selectedIndex];
    return YES;
}

- (BOOL)initTabWithMenu:(UIView *)menu body:(UIView *)body titles:(NSArray<NSString *> *)titles controllers:(NSArray<UIViewController *> *)controllers selectedIndex:(NSInteger)selectedIndex scrollEnabled:(BOOL)scrollEnabled {
    [self deinitTab];
    
    self.tabMenu = menu;
    self.tabBody = body;
    self.tabTitles = titles;
    self.tabControllers = controllers;
    self.tabSelectedIndex = selectedIndex;
    self.tabScrollEnabled = scrollEnabled;
    
    NSMutableArray<UIView *> *viewArray = [NSMutableArray new];
    for (UIViewController *controller in self.tabControllers) {
        [viewArray addObject:controller.view];
    }
    self.tabViews = viewArray;
    
    [self initMenu];
    [self initBody];
    [self.view layoutIfNeeded];
    [self selectTabAtIndex:selectedIndex];
    return YES;
}

- (void)initMenu {
    if (!self.tabMenu) {
        return;
    }
    
    UIView *menuContainerView = [UIView new];
    self.tabMenuContainerView = menuContainerView;
    [self.tabMenu addSubview:menuContainerView];
    [menuContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.right.bottom.equalTo(self.tabMenu);
    }];
    
    UIScrollView *menuScrollView = [UIScrollView new];
    menuScrollView.showsHorizontalScrollIndicator = NO;
    [menuContainerView addSubview:menuScrollView];
    [menuScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.right.bottom.equalTo(menuContainerView);
    }];
    for (UIGestureRecognizer *gestureRecognizer in menuScrollView.gestureRecognizers) {
        if (self.navigationController.interactivePopGestureRecognizer) {
            [gestureRecognizer requireGestureRecognizerToFail:self.navigationController.interactivePopGestureRecognizer];
        }
    }
    
    UIView *menuView = [UIView new];
    self.tabMenuView = menuView;
    [menuScrollView addSubview:menuView];
    [menuView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.right.bottom.equalTo(menuScrollView);
        make.height.equalTo(self.tabMenu);
    }];
    
    NSInteger menuCount = [self.tabTitles count];
    self.tabMenus = [NSMutableArray new];
    self.tabMenuTitles = [NSMutableArray new];
    self.tabMenuIndicators = [NSMutableArray new];
    self.tabMenuBadges = [NSMutableArray new];
    UIView *lastMenu = nil;
    for (int i = 0; i < menuCount; i++) {
        UIView *menu = [UIView new];
        [self.tabMenus addObject:menu];
        menu.tag = i;
        
        CGFloat titleWidth = ceil([self.tabTitles[i] sizeWithAttributes:@{NSFontAttributeName:self.tabMenuFont}].width);
        
        [menuView addSubview:menu];
        [menu mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(menuView);
            
            if (self.tabMenuPadding) {
                make.width.equalTo(@(titleWidth + 2 * self.tabMenuPadding));
            } else {
                make.width.greaterThanOrEqualTo(@(titleWidth + 2 * self.tabMenuMinimumPadding)).priorityHigh();
                make.width.equalTo(menuContainerView).multipliedBy(1.0f / menuCount).priorityMedium();
            }
        }];
        
        if (i == 0) {
            [menu mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(menuView);
            }];
        } else {
            [menu mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(lastMenu.mas_right);
            }];
        }
        
        if (i == (menuCount - 1)) {
            [menu mas_makeConstraints:^(MASConstraintMaker *make) {
                make.right.equalTo(menuView);
            }];
        }
        
        lastMenu = menu;
        
        UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleMenuTap:)];
        [menu addGestureRecognizer:recognizer];
        
        UILabel *title = [UILabel new];
        [self.tabMenuTitles addObject:title];
        title.text = self.tabTitles[i];
        title.font = self.tabMenuFont;
        title.textColor = self.tabMenuColor;
        title.numberOfLines = 0;
        title.textAlignment = NSTextAlignmentCenter;
        [menu addSubview:title];
        [title mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.centerY.offset(0);
            make.left.top.greaterThanOrEqualTo(menu).offset(0);
            make.right.bottom.lessThanOrEqualTo(menu).offset(0);
        }];
        
        UIView *indicator = [UIView new];
        CGFloat indicatorWidth = self.tabMenuIndicatorWidth ?: (titleWidth + 2 * self.tabMenuIndicatorPadding);
        if (indicatorWidth < 0) {
            indicatorWidth = 0;
        }
        [self.tabMenuIndicators addObject:indicator];
        [menu addSubview:indicator];
        [indicator mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.lessThanOrEqualTo(menu);
            make.width.equalTo(@(indicatorWidth)).priorityLow();
            make.centerX.equalTo(menu);
            make.bottom.equalTo(menu);
            make.height.equalTo(@(self.tabMenuIndicatorHeight));
        }];
        
        [self.tabMenuBadges addObject:[NSNull null]];
    }
    
}

- (void)handleMenuTap:(UITapGestureRecognizer *)recognizer {
    [self selectTabAtIndex:recognizer.view.tag];
}

- (void)initBody {
    if (!self.tabBody) {
        return;
    }
    
    UIView *bodyContainerView = [UIView new];
    self.tabBodyContainerView = bodyContainerView;
    [self.tabBody addSubview:bodyContainerView];
    [bodyContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.right.bottom.equalTo(self.tabBody);
    }];
    
    UIScrollView *bodyScrollView = [UIScrollView new];
    self.tabBodyScrollView = bodyScrollView;
    bodyScrollView.showsHorizontalScrollIndicator = NO;
    bodyScrollView.pagingEnabled = YES;
    bodyScrollView.scrollEnabled = self.tabScrollEnabled;
    bodyScrollView.delegate = self;
    [bodyContainerView addSubview:bodyScrollView];
    [bodyScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.right.bottom.equalTo(bodyContainerView);
    }];
    for (UIGestureRecognizer *gestureRecognizer in bodyScrollView.gestureRecognizers) {
        if (self.navigationController.interactivePopGestureRecognizer) {
            [gestureRecognizer requireGestureRecognizerToFail:self.navigationController.interactivePopGestureRecognizer];
        }
    }
    
    UIView *bodyView = [UIView new];
    [bodyScrollView addSubview:bodyView];
    [bodyView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.right.bottom.equalTo(bodyScrollView);
        make.height.equalTo(bodyContainerView);
    }];
    
    UIView *lastView = nil;
    NSInteger count = self.tabViews.count;
    for (int i = 0; i < count; i++) {
        UIView *view = self.tabViews[i];
        
        if (self.tabControllers.count) {
            [self addChildViewController:self.tabControllers[i]];
        }
        
        [bodyView addSubview:view];
        [view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(bodyView);
            make.width.equalTo(bodyContainerView);
        }];
        
        if (i == 0) {
            [view mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(bodyView);
            }];
        } else {
            [view mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(lastView.mas_right);
            }];
        }
        if (i == (count - 1)) {
            [view mas_makeConstraints:^(MASConstraintMaker *make) {
                make.right.equalTo(bodyView);
            }];
        }
        
        if (self.tabControllers.count) {
            [self.tabControllers[i] didMoveToParentViewController:self];
        }
        
        lastView = view;
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView != self.tabBodyScrollView) {
        return;
    }
    CGFloat contentOffsetX =  scrollView.contentOffset.x;
    CGFloat tabBodyWidth = self.tabBody.frame.size.width;
    
    if (contentOffsetX <= 0 || contentOffsetX >= (tabBodyWidth * (self.tabViews.count - 1))) {
        return;
    }
    
    NSInteger index = lround(floorf(contentOffsetX / tabBodyWidth));
    CGFloat ratio = contentOffsetX / tabBodyWidth - index;
    
    UIView *leftMenu = (index < self.tabMenus.count ? self.tabMenus[index] : nil);
    UIView *rightMenu = (index + 1 < self.tabMenus.count ? self.tabMenus[index + 1] : nil);
    
    CGRect leftMenuRect = leftMenu.frame;
    CGRect leftInnerIndicatorRect = leftMenu.subviews[1].frame;
    
    CGRect rightMenuRect = rightMenu.frame;
    CGRect rightInnerIndicatorRect = rightMenu.subviews[1].frame;
    
    CGRect leftMenuIndicatorRect = CGRectMake(
                                              leftMenuRect.origin.x + leftInnerIndicatorRect.origin.x,
                                              leftMenuRect.origin.y + leftInnerIndicatorRect.origin.y,
                                              leftInnerIndicatorRect.size.width,
                                              leftInnerIndicatorRect.size.height
                                              );
    
    CGRect rightMenuIndicatorRect = CGRectMake(
                                               rightMenuRect.origin.x + rightInnerIndicatorRect.origin.x,
                                               rightMenuRect.origin.y + rightInnerIndicatorRect.origin.y,
                                               rightInnerIndicatorRect.size.width,
                                               rightInnerIndicatorRect.size.height
                                               );
    
    CGRect menuIndicatorRect = CGRectMake(
                                          leftMenuIndicatorRect.origin.x * (1 - ratio) + rightMenuIndicatorRect.origin.x * ratio,
                                          leftMenuIndicatorRect.origin.y * (1 - ratio) + rightMenuIndicatorRect.origin.y * ratio,
                                          leftMenuIndicatorRect.size.width * (1 - ratio) + rightMenuIndicatorRect.size.width * ratio,
                                          leftMenuIndicatorRect.size.height * (1 - ratio) + rightMenuIndicatorRect.size.height * ratio
                                          );
    self.tabMenuIndicator.frame = menuIndicatorRect;
    
    UILabel *leftTitle = leftMenu.subviews[0];
    UILabel *rightTitle = rightMenu.subviews[0];
    
    UIColor *color = self.tabMenuColor;
    CGFloat red = 0;
    CGFloat green = 0;
    CGFloat blue = 0;
    CGFloat alpha = 0;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    
    UIColor *selectedColor = self.tabMenuSelectedColor;
    CGFloat selectedRed = 0;
    CGFloat selectedGreen = 0;
    CGFloat selectedBlue = 0;
    CGFloat selectedAlpha = 0;
    [selectedColor getRed:&selectedRed green:&selectedGreen blue:&selectedBlue alpha:&selectedAlpha];
    
    UIColor *leftColor = [UIColor colorWithRed:selectedRed * (1 - ratio) + red * ratio green:selectedGreen * (1 - ratio) + green * ratio blue:selectedBlue * (1 - ratio) + blue * ratio alpha:selectedAlpha * (1 - ratio) + alpha * ratio];
    UIColor *rightColor = [UIColor colorWithRed:selectedRed * ratio + red * (1 - ratio) green:selectedGreen * ratio + green * (1 - ratio) blue:selectedBlue * ratio + blue * (1 - ratio) alpha:selectedAlpha * ratio + alpha * (1 - ratio)];
    
    leftTitle.textColor = leftColor;
    rightTitle.textColor = rightColor;
    
    leftTitle.font = [self.tabMenuFont fontWithSize:self.tabMenuSelectedFont.pointSize * (1 - ratio) + self.tabMenuFont.pointSize * ratio];
    rightTitle.font = [self.tabMenuFont fontWithSize:self.tabMenuSelectedFont.pointSize * ratio + self.tabMenuFont.pointSize * (1 - ratio)];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView != self.tabBodyScrollView) {
        return;
    }
    CGFloat width = self.tabBody.frame.size.width;
    NSInteger index = lround(scrollView.contentOffset.x / width);
    
    if (index != self.tabSelectedIndex) {
        [self selectTabAtIndex:index];
    }
}

- (void)selectTabAtIndex:(NSInteger)index {
    if (index < 0) {
        return;
    }
    
    [self didDeselectTabAtIndex:self.tabSelectedIndex];
    
    UILabel *oldTitle = (self.tabSelectedIndex < self.tabMenus.count ?  self.tabMenus[self.tabSelectedIndex].subviews[0] : nil);
    oldTitle.textColor = self.tabMenuColor;
    oldTitle.font = self.tabMenuFont;
    UILabel *title = (index < self.tabMenus.count ? self.tabMenus[index].subviews[0] : nil);
    title.textColor = self.tabMenuSelectedColor;
    title.font = self.tabMenuSelectedFont;
    
    CGRect menuRect = (index < self.tabMenus.count ? self.tabMenus[index].frame : CGRectZero);
    CGRect innerIndicatorRect = (index < self.tabMenus.count ? self.tabMenus[index].subviews[1].frame : CGRectZero);
    CGRect menuIndicatorRect = CGRectMake(
                                          menuRect.origin.x + innerIndicatorRect.origin.x,
                                          menuRect.origin.y + innerIndicatorRect.origin.y,
                                          innerIndicatorRect.size.width,
                                          innerIndicatorRect.size.height
                                          );
    
    if (!self.tabMenuIndicator) {
        self.tabMenuIndicator = [[UIView alloc] initWithFrame:menuIndicatorRect];
        self.tabMenuIndicator.backgroundColor = self.tabMenuIndicatorColor;
        self.tabMenuIndicator.layer.cornerRadius = self.tabMenuIndicatorRadius;
        self.tabMenuIndicator.layer.masksToBounds = YES;
        [self.tabMenuView addSubview:self.tabMenuIndicator];
    } else {
        [UIView animateWithDuration:self.tabScrollEnabled ? 0.3f : 0.0f animations:^{
            self.tabMenuIndicator.frame = menuIndicatorRect;
        }];
    }
    
    UIScrollView *menuScrollView = (UIScrollView *)self.tabMenuView.superview;
    CGRect tabMenuRect = self.tabMenu.frame;
    
    CGRect menuScrollViewRect = CGRectMake(
                                           menuRect.origin.x - (tabMenuRect.size.width - menuRect.size.width) / 2,
                                           0,
                                           tabMenuRect.size.width,
                                           tabMenuRect.size.height
                                           );
    [menuScrollView scrollRectToVisible:menuScrollViewRect animated:self.tabScrollEnabled];
    
    
    self.tabBodyScrollView.contentSize = CGSizeMake(self.tabBodyScrollView.contentSize.width, self.tabBodyScrollView.frame.size.height);
    
    CGRect tabBodyRect = self.tabBody.frame;
    CGRect bodyScrollViewRect = CGRectMake(
                                           index * tabBodyRect.size.width,
                                           0,
                                           tabBodyRect.size.width,
                                           tabBodyRect.size.height
                                           );
    [self.tabBodyScrollView scrollRectToVisible:bodyScrollViewRect animated:NO];
    
    self.tabSelectedIndex = index;
    [self didSelectTabAtIndex:index];
}

- (void)setTitle:(NSString *)title forTabAtIndex:(NSInteger)index {
    if (index < self.tabMenus.count) {
        UIView *menu = self.tabMenus[index];
        UILabel *label = self.tabMenuTitles[index];
        label.text = title;
        UIView *indicator = self.tabMenuIndicators[index];
        CGFloat titleWidth = ceil([title sizeWithAttributes:@{NSFontAttributeName:self.tabMenuFont}].width);
        CGFloat indicatorWidth = self.tabMenuIndicatorWidth ?: (titleWidth + 2 * self.tabMenuIndicatorPadding);
        if (indicatorWidth < 0) {
            indicatorWidth = 0;
        }
        [indicator mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.width.lessThanOrEqualTo(menu);
            make.width.equalTo(@(indicatorWidth)).priorityLow();
            make.centerX.equalTo(menu);
            make.bottom.equalTo(menu);
            make.height.equalTo(@(self.tabMenuIndicatorHeight));
        }];
    }
}

- (void)setBadgeWithView:(UIView *)view width:(CGFloat)width height:(CGFloat)height offset:(CGPoint)offset forTabAtIndex:(NSInteger)index {
    if (index < self.tabMenus.count) {
        UIView *menu = self.tabMenus[index];
        UIView *title = self.tabMenuTitles[index];
        UIView *badge = self.tabMenuBadges[index];
        
        if (![badge isEqual:[NSNull null]]) {
            [badge removeFromSuperview];
        }
        
        if (view) {
            [menu addSubview:view];
            [view mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(title.mas_right).mas_offset(offset.x);
                make.bottom.equalTo(title.mas_top).mas_offset(offset.y);
                if (width) {
                    make.width.equalTo(@(width));
                }
                if (height) {
                    make.height.equalTo(@(height));
                }
            }];
            self.tabMenuBadges[index] = view;
        } else {
            self.tabMenuBadges[index] = [NSNull null];
        }
    }
}

- (void)didSelectTabAtIndex:(NSInteger)index {
}

- (void)didDeselectTabAtIndex:(NSInteger)index {
}

@end

