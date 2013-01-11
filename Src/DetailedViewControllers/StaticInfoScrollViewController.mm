//
//  PageContainingViewController.m
//  CERN App
//
//  Created by Eamon Ford on 7/26/12.
//  Copyright (c) 2012 CERN. All rights reserved.
//

//Modified by Timur Pocheptsov.


#import "StaticInfoScrollViewController.h"
#import "StaticInfoItemViewController.h"
#import "ECSlidingViewController.h"
#import "StoryboardIdentifiers.h"


@implementation StaticInfoScrollViewController

@synthesize dataSource;

//________________________________________________________________________________________
- (id) initWithCoder : (NSCoder *) aDecoder
{
   return self = [super initWithCoder : aDecoder];
}

//________________________________________________________________________________________
- (StaticInfoItemViewController *) viewControllerForPage : (NSUInteger) page
{
   using namespace CernAPP;

   assert(page < dataSource.count && "viewControllerForPage:, parameter 'page' is out of bounds");

   UIStoryboard * const mainStoryboard = [UIStoryboard storyboardWithName : @"iPhone" bundle : nil];
   StaticInfoItemViewController * const detailViewController = [mainStoryboard instantiateViewControllerWithIdentifier : StaticInfoItemViewControllerID];
   detailViewController.staticInfo = [dataSource objectAtIndex : page];
    
   return detailViewController;
}

//________________________________________________________________________________________
- (void) viewDidLoad
{
   [super viewDidLoad];
   
   //Create children views for static info entries and add them into the scroll view.
   assert(dataSource != nil && dataSource.count != 0 &&
          "viewDidLoad:, dataSource is either nil or empty");
   
   pageControl.numberOfPages = dataSource.count;
   scrollView.backgroundColor = [UIColor clearColor];
   self.view.backgroundColor = [UIColor blackColor];

   for (NSUInteger i = 0, e = dataSource.count; i < e; ++i) {
      StaticInfoItemViewController *detailViewController = [self viewControllerForPage: i ];
      [self addChildViewController : detailViewController];
      [scrollView addSubview : detailViewController.view];
      [detailViewController didMoveToParentViewController : self];
   }
}

//________________________________________________________________________________________
- (void) viewDidLayoutSubviews
{
   //Now layout static info item views in a scrollview.
   const CGFloat deviceViewWidth = scrollView.frame.size.width;

   for (NSUInteger i = 0, e = self.childViewControllers.count; i < e; ++i) {
      StaticInfoItemViewController *detailViewController = (StaticInfoItemViewController *)[self.childViewControllers objectAtIndex : i];
      const CGFloat detailViewX = i * deviceViewWidth;
      detailViewController.view.frame = CGRectMake(detailViewX, 0.f, deviceViewWidth, scrollView.frame.size.height);
      [detailViewController.view setNeedsDisplay];
   }

   scrollView.contentSize = CGSizeMake(deviceViewWidth * self.childViewControllers.count, scrollView.frame.size.height);
}

//________________________________________________________________________________________
- (void) scrollViewDidScroll : (UIScrollView *) sender
{
   const CGFloat pageWidth = scrollView.frame.size.width;
   const int page = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
   assert(page >= 0 && page < self.childViewControllers.count && "scrollViewDidScroll:, page is out of bounds");

   pageControl.currentPage = page;
}

//________________________________________________________________________________________
- (IBAction) revealMenu : (id) sender
{
#pragma unused(sender)
   [self.slidingViewController anchorTopViewTo : ECRight];
}

@end
