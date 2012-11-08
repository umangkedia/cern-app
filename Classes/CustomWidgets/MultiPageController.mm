//
//  Created by Timur Pocheptsov on 11/7/12.
//  Copyright (c) 2012 Timur Pocheptsov. All rights reserved.
//

#import <cstdlib>

#import "MultiPageController.h"
#import "ScrollSelector.h"
#import "DeviceCheck.h"
#import "KeyVal.h"

@implementation MultiPageController {
   UIScrollView *navigationView;
   ScrollSelector *selector;
   UIPageControl *pageControl;
   NSMutableArray *tableControllers;
}

- (BOOL) shouldAutorotate
{
   return NO;
}

- (void)viewDidLoad
{
   [super viewDidLoad];
   if (self.view) {
      self.view.backgroundColor = [UIColor blueColor];
      
      const CGRect frame = self.view.frame;
      selector = [[ScrollSelector alloc] initWithFrame : CGRectMake(0.f, 0.f, frame.size.width, [ScrollSelector defaultHeight])];
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
   }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setItems : (NSMutableArray *) items
{
   NSMutableArray * const titles = [[NSMutableArray alloc] init];
   for (id itemBase in items) {
      assert([itemBase isKindOfClass : [KeyVal class]] && "setItems:, KeyVal expected");
      KeyVal *pair = (KeyVal *)itemBase;
      assert([pair.key isKindOfClass : [NSString class]] && "setItems:, key expected to be a string");
      [titles addObject : pair.key];
   }
   
   if (const NSUInteger nPages = [titles count]) {
      [selector addItemNames : titles];
      [selector setNeedsDisplay];
      
      //For the testing purpose, add dummy views into the navigationView.
      CGRect frame = navigationView.frame;
      frame.origin.y = 0;
      
      for (NSUInteger i = 0; i < nPages; ++i) {
         frame.origin.x = i * frame.size.width;
         UIView *fakeView = [[UIView alloc] initWithFrame : frame];
         fakeView.backgroundColor = [UIColor colorWithRed : (rand() % 256 / 256.f) green : (rand() % 256 / 256.f) blue : (rand() % 256) / 256.f alpha : 1.f];
         [navigationView addSubview : fakeView];
      }
      
      navigationView.contentOffset = CGPointZero;
      navigationView.contentSize = CGSizeMake([titles count] * frame.size.width, frame.size.height);
      
      if (nPages > 1) {
         [pageControl setNumberOfPages : nPages];
         pageControl.currentPage = 0;
         pageControl.hidden = NO;
      } else
         pageControl.hidden = YES;
   }
   //Now we had to initialize a lot of feed parsers.
}

#pragma mark - ScrollSelectorDelegate

- (void) item : (unsigned int) item selectedIn : (ScrollSelector *) selector
{
   //Item was selected by scrolling the "selector wheel".
   const CGPoint newOffset = CGPointMake(item * navigationView.frame.size.width, 0.f);
   [navigationView setContentOffset:newOffset animated : YES];
   pageControl.currentPage = item;
}

#pragma mark - UIScrollViewDelegate

- (void) scrollViewDidEndDecelerating : (UIScrollView *) sender
{
   //Page scrolled, adjust selector now.
   const unsigned page = navigationView.contentOffset.x / navigationView.frame.size.width;
   [selector setSelectedItem : page];
   pageControl.currentPage = page;
}

@end
