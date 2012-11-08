//
//  Created by Timur Pocheptsov on 11/7/12.
//  Copyright (c) 2012 Timur Pocheptsov. All rights reserved.
//

#import <cstdlib>

#import "NewsTableViewController.h"
#import "MultiPageController.h"
#import "ScrollSelector.h"
#import "DeviceCheck.h"
#import "Constants.h"
#import "KeyVal.h"

@implementation MultiPageController {
   UIScrollView *navigationView;
   ScrollSelector *selector;
   UIPageControl *pageControl;
   NSMutableArray *tableControllers;
}

//________________________________________________________________________________________
- (BOOL) shouldAutorotate
{
   return NO;
}

//________________________________________________________________________________________
- (void)viewDidLoad
{
   [super viewDidLoad];
   if (self.view) {
      self.view.backgroundColor = [UIColor blackColor];
      
      const CGRect frame = self.view.frame;
      selector = [[ScrollSelector alloc] initWithFrame : CGRectMake(0.15 * frame.size.width, 0.f, 0.7 * frame.size.width, [ScrollSelector defaultHeight])];
      [self.view addSubview : selector];

      //Items must be added into the selector.
      selector.delegate = self;
      // Do any additional setup after loading the view, typically from a nib.

      CGRect tableFrame = CGRectMake(0., [ScrollSelector defaultHeight], 320.f, frame.size.height - [ScrollSelector defaultHeight]);

      navigationView = [[UIScrollView alloc] initWithFrame : tableFrame];
      navigationView.backgroundColor = [UIColor grayColor];
      navigationView.delegate = self;

      [self.view addSubview : navigationView];
      
      navigationView.canCancelContentTouches = NO;
      navigationView.delaysContentTouches = YES;
      navigationView.contentOffset = CGPointZero;
      navigationView.contentSize = CGSizeMake(tableFrame.size.width * 5, tableFrame.size.height);
      navigationView.showsHorizontalScrollIndicator = NO;
      navigationView.showsVerticalScrollIndicator = NO;
      navigationView.pagingEnabled = YES;
      
      //This is the ugly hack for ugly API/Frameworks/logic by Apple.
      if ([DeviceCheck deviceIsiPhone5])
         pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0.f, frame.size.height - 150, frame.size.width, 40.f)];
      else
         pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0.f, frame.size.height - 250, frame.size.width, 40.f)];

      pageControl.currentPageIndicatorTintColor = [UIColor redColor];
      pageControl.pageIndicatorTintColor = [UIColor blackColor];
      [self.view addSubview : pageControl];
      pageControl.hidden = YES;
      
      tableControllers = [[NSMutableArray alloc] init];
   }
}

//________________________________________________________________________________________
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//________________________________________________________________________________________
- (void) setItems : (NSMutableArray *) items
{
   if (const NSUInteger nPages = [items count]) {
      NSMutableArray * const titles = [[NSMutableArray alloc] init];
      
      for (id itemBase in items) {
         assert([itemBase isKindOfClass : [KeyVal class]] && "setItems:, KeyVal expected");
         KeyVal *pair = (KeyVal *)itemBase;
         assert([pair.key isKindOfClass : [NSString class]] && "setItems:, key expected to be a string");
         [titles addObject : pair.key];
      }
   
      [selector addItemNames : titles];
      [selector setNeedsDisplay];
      
      //For the testing purpose, add dummy views into the navigationView.
      CGRect frame = navigationView.frame;
      frame.origin.y = 0;
      
      UIStoryboard * const mainStoryboard = [UIStoryboard storyboardWithName : @"MainStoryboard_iPhone" bundle : nil];
      assert(mainStoryboard != nil && "setItems:, storyboard is nil");
      
      for (KeyVal *pair in items) {
         //
         NewsTableViewController *newsViewController = [mainStoryboard instantiateViewControllerWithIdentifier : kExperimentFeedTableViewController];
         //Actually, no need in assert - storyboard will generate an exception.
         assert(newsViewController != nil && "setItems:, no NewsTableViewController was found in a storyboard");
         //
         newsViewController.view.frame = frame;
         [tableControllers addObject : newsViewController];
         [navigationView addSubview : newsViewController.view];
         //
         [newsViewController.aggregator addFeedForURL : [NSURL URLWithString : (NSString *)pair.val]];
         newsViewController.navigationControllerForArticle = self.navigationController;
         //
         frame.origin.x += frame.size.width;
      }
      
      navigationView.contentOffset = CGPointZero;
      navigationView.contentSize = CGSizeMake([titles count] * frame.size.width, frame.size.height);
      
      if (nPages > 1) {
         [pageControl setNumberOfPages : nPages];
         pageControl.currentPage = 0;
         pageControl.hidden = NO;
      } else
         pageControl.hidden = YES;
      
//      NSLog(@""))
      [[tableControllers objectAtIndex : 0] refresh];
   }
   //Now we had to initialize a lot of feed parsers.
}

#pragma mark - ScrollSelectorDelegate

//________________________________________________________________________________________
- (void) item : (unsigned int) item selectedIn : (ScrollSelector *) selector
{
   //Item was selected by scrolling the "selector wheel".
   const CGPoint newOffset = CGPointMake(item * navigationView.frame.size.width, 0.f);
   [navigationView setContentOffset:newOffset animated : YES];
   pageControl.currentPage = item;

   NewsTableViewController *nextController = [tableControllers objectAtIndex : item];
   assert(nextController != nil && "item:selectedIn:, controller not found for the page");
   if (![nextController loaded])
      [nextController refresh];

}

#pragma mark - UIScrollViewDelegate

//________________________________________________________________________________________
- (void) scrollViewDidEndDecelerating : (UIScrollView *) sender
{
   //Page scrolled, adjust selector now.
   const unsigned page = navigationView.contentOffset.x / navigationView.frame.size.width;
   [selector setSelectedItem : page];
   pageControl.currentPage = page;
   
   NewsTableViewController *nextController = [tableControllers objectAtIndex : page];
   assert(nextController != nil && "scrollViewDidEndDecelerating:, controller not found for the page");
   if (![nextController loaded])
      [nextController refresh];
}

@end
