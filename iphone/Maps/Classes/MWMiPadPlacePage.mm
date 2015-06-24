//
//  MWMiPadPlacePageView.m
//  Maps
//
//  Created by v.mikhaylenko on 18.05.15.
//  Copyright (c) 2015 MapsWithMe. All rights reserved.
//

#import "MWMiPadPlacePage.h"
#import "MWMPlacePageViewManager.h"
#import "MWMPlacePageActionBar.h"
#import "UIKitCategories.h"
#import "MWMBasePlacePageView.h"
#import "MWMBookmarkColorViewController.h"
#import "SelectSetVC.h"
#import "UIViewController+Navigation.h"
#import "MWMBookmarkDescriptionViewController.h"

extern CGFloat kBookmarkCellHeight;
static CGFloat const kLeftOffset = 12.;
static CGFloat const kTopOffset = 36.;

@interface MWMiPadPlacePageViewController : UIViewController

@end

@implementation MWMiPadPlacePageViewController

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [self.navigationController setNavigationBarHidden:YES];
  self.view.autoresizingMask = UIViewAutoresizingNone;
}

@end

@interface MWMiPadNavigationController : UINavigationController

@end

@implementation MWMiPadNavigationController

- (instancetype)initWithViews:(NSArray *)views
{
  MWMiPadPlacePageViewController * viewController = [[MWMiPadPlacePageViewController alloc] init];
  if (!viewController)
    return nil;
  [views enumerateObjectsUsingBlock:^(UIView * view, NSUInteger idx, BOOL *stop)
  {
    [viewController.view addSubview:view];
  }];
  self = [super initWithRootViewController:viewController];
  if (!self)
    return nil;
  [self setNavigationBarHidden:YES];
  [self.navigationBar setTranslucent:NO];
  self.view.autoresizingMask = UIViewAutoresizingNone;
  [self configureShadow];
  return self;
}

- (void)backTap:(id)sender
{
  [self popViewControllerAnimated:YES];
}

- (void)configureShadow
{
  CALayer * layer = self.view.layer;
  layer.masksToBounds = NO;
  layer.shadowColor = UIColor.blackColor.CGColor;
  layer.shadowRadius = 4.;
  layer.shadowOpacity = 0.24f;
  layer.shadowOffset = CGSizeMake(0., - 2.);
  layer.shouldRasterize = YES;
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
  viewController.view.frame = self.view.bounds;
  [super pushViewController:viewController animated:animated];
}

@end

@interface MWMiPadPlacePage ()

@property (strong, nonatomic) MWMiPadNavigationController * navigationController;

@end

@implementation MWMiPadPlacePage

- (void)configure
{
  [super configure];

  CGFloat const defaultWidth = 360.;
  CGFloat const actionBarHeight = 58.;
  CGFloat const defaultHeight = self.basePlacePageView.height + self.anchorImageView.height + actionBarHeight - 1;

  [self.manager addSubviews:@[self.navigationController.view] withNavigationController:self.navigationController];
  self.navigationController.view.frame = CGRectMake( -defaultWidth, self.topBound + kTopOffset, defaultWidth, defaultHeight);
  self.extendedPlacePageView.frame = CGRectMake(0., 0., defaultWidth, defaultHeight);
  self.anchorImageView.image = nil;
  self.anchorImageView.backgroundColor = [UIColor whiteColor];
  self.actionBar.width = defaultWidth;
  self.actionBar.origin = CGPointMake(0., defaultHeight - actionBarHeight);
}

- (void)show
{
  UIView * view = self.navigationController.view;
  [UIView animateWithDuration:0.2f animations:^
  {
    view.minX = kLeftOffset;
    view.alpha = 1.0;
  }];
}

- (void)dismiss
{
  UIView * view = self.navigationController.view;
  UIViewController * controller = self.navigationController;
  [UIView animateWithDuration:0.2f animations:^
  {
    view.maxX = 0.0;
    view.alpha = 0.0;
  }
  completion:^(BOOL finished)
  {
    [view removeFromSuperview];
    [controller removeFromParentViewController];
    [super dismiss];
  }];
}

- (void)willFinishEditingBookmarkTitle:(NSString *)title
{
  [super willFinishEditingBookmarkTitle:title];
  CGFloat const actionBarHeight = self.actionBar.height;
  CGFloat const defaultHeight = self.basePlacePageView.height + self.anchorImageView.height + actionBarHeight - 1;
  self.actionBar.origin = CGPointMake(0., defaultHeight - actionBarHeight);
  self.navigationController.view.height = defaultHeight;
}

- (void)addBookmark
{
  [super addBookmark];
  self.navigationController.view.height += kBookmarkCellHeight;
  self.extendedPlacePageView.height += kBookmarkCellHeight;
  self.actionBar.minY += kBookmarkCellHeight;
}

- (void)removeBookmark
{
  [super removeBookmark];
  self.navigationController.view.height -= kBookmarkCellHeight;
  self.extendedPlacePageView.height -= kBookmarkCellHeight;
  self.actionBar.minY -= kBookmarkCellHeight;
}

- (void)changeBookmarkColor
{
  MWMBookmarkColorViewController * controller = [[MWMBookmarkColorViewController alloc] initWithNibName:[MWMBookmarkColorViewController className] bundle:nil];
  controller.iPadOwnerNavigationController = self.navigationController;
  controller.placePageManager = self.manager;
  [self.navigationController pushViewController:controller animated:YES];
}

- (void)changeBookmarkCategory
{
  SelectSetVC * controller = [[SelectSetVC alloc] initWithPlacePageManager:self.manager];
  controller.iPadOwnerNavigationController = self.navigationController;
  [self.navigationController pushViewController:controller animated:YES];
}

- (void)changeBookmarkDescription
{
  MWMBookmarkDescriptionViewController * controller = [[MWMBookmarkDescriptionViewController alloc] initWithPlacePageManager:self.manager];
  controller.iPadOwnerNavigationController = self.navigationController;
  [self.navigationController pushViewController:controller animated:YES];
}

- (IBAction)didPan:(UIPanGestureRecognizer *)sender
{
  UIView * view = self.navigationController.view;
  UIView * superview = view.superview;

  view.minX += [sender translationInView:superview].x;
  view.minX = MIN(view.minX, kLeftOffset);
  [sender setTranslation:CGPointZero inView:superview];

  CGFloat const alpha = MAX(0.0, view.maxX) / (view.width + kLeftOffset);
  view.alpha = alpha;
  UIGestureRecognizerState const state = sender.state;
  if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateCancelled)
  {
    if (alpha < 0.8)
      [self.manager dismissPlacePage];
    else
      [self show];
  }
}

#pragma mark - Properties

- (MWMiPadNavigationController *)navigationController
{
  if (!_navigationController)
  {
    _navigationController = [[MWMiPadNavigationController alloc] initWithViews:@[self.extendedPlacePageView, self.actionBar]];
  }
  return _navigationController;
}

- (void)setTopBound:(CGFloat)topBound
{
  super.topBound = topBound;
  [UIView animateWithDuration:0.2f animations:^
  {
    self.navigationController.view.minY = topBound + kTopOffset;
  }];
}

@end