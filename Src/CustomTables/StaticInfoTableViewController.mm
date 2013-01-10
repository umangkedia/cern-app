//
//  StaticInfoTableViewController.m
//  CERN
//
//  Created by Timur Pocheptsov on 1/10/13.
//  Copyright (c) 2013 CERN. All rights reserved.
//

#import <cassert>

#import "StaticInfoTableViewController.h"
#import "ECSlidingViewController.h"
#import "MenuItemViews.h"
#import "GUIHelpers.h"

@implementation StaticInfoTableViewController {
   NSMutableArray *views;
}

@synthesize staticInfo;

//________________________________________________________________________________________
- (void) dealloc
{
   [views removeAllObjects];
}

//________________________________________________________________________________________
- (void) viewDidLoad
{
   [super viewDidLoad];

   assert(staticInfo && staticInfo.count > 0 && "viewDidLoad, staticInfo is either nil or is empty");
   scrollView.backgroundColor = [UIColor colorWithRed : 0.827f green : 0.853f blue : 0.862f alpha : 1.f];
   
   views = [[NSMutableArray alloc] init];
   
   for (id obj in staticInfo) {
      MenuTableItemView * const newView = [[MenuTableItemView alloc] initWithFrame : CGRectMake(0.f, 0.f, 100.f, 100.f)];
      [scrollView addSubview : newView];
      [views addObject : newView];
   }
}

//________________________________________________________________________________________
- (void) viewDidLayoutSubviews
{
   const CGRect frame = scrollView.frame;
   
   const CGFloat x = 10.f;
   const CGFloat addY = 10.f;
   CGFloat currentY = addY;
   CGFloat totalHeight = 0.f;
   
   
   for (MenuTableItemView * view in views) {
      CGRect newFrame = frame;
      newFrame.origin.y = currentY;
      newFrame.origin.x = x;
      newFrame.size.width -= 2 * x;
      newFrame.size.height = 100.f;//just a test.
      
      view.frame = newFrame;
      
      view.layer.cornerRadius = 10.f;
      view.layer.shadowColor = [UIColor darkGrayColor].CGColor;
      view.layer.shadowOpacity = 0.2f;
      view.layer.shadowOffset = CGSizeMake(0.5f, 0.5f);
      
      newFrame.origin = CGPointZero;
      view.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect : newFrame cornerRadius : 10.f].CGPath;
      view.layer.borderColor = [UIColor colorWithRed : 0.456f green : 0.472f blue : 0.492f alpha : 0.5f].CGColor;
      view.layer.borderWidth = 1.f;
      
      currentY += newFrame.size.height + addY;
      totalHeight = currentY;
   }
   
   [scrollView setContentSize : CGSizeMake(frame.size.width, totalHeight)];
}

//________________________________________________________________________________________
- (void) didReceiveMemoryWarning
{
   [super didReceiveMemoryWarning];
   // Dispose of any resources that can be recreated.
}

#pragma mark - Sliding menu.

//________________________________________________________________________________________
- (IBAction) revealMenu : (id) sender
{
#pragma unused(sender)
   [self.slidingViewController anchorTopViewTo : ECRight];
}

@end
