//
//  Created by Timur Pocheptsov on 11/7/12.
//  Copyright (c) 2012 Timur Pocheptsov. All rights reserved.
//

#import <cassert>
#import <cstdlib>

#import <QuartzCore/QuartzCore.h>

#import "LiveEventTableController.h"
#import "NewsTableViewController.h"
#import "MultiPageController.h"
#import "ScrollSelector.h"
#import "DeviceCheck.h"
#import "Constants.h"
#import "KeyVal.h"

namespace {

const CGFloat tbBtnHeight = 35.f;//24.5f;
const CGFloat tbBtnWidth = 35.f;//51.f;

}

@implementation MultiPageController {
   UIScrollView *navigationView;
   ScrollSelector *selector;
   
   //TODO: the name 'tableControllers' is not good anymore, I can have not only tables.
   NSMutableArray *tableControllers;
   BOOL autoScroll;
}

//________________________________________________________________________________________
- (BOOL) shouldAutorotate
{
   return NO;
}

//________________________________________________________________________________________
- (void) viewWillAppear:(BOOL)animated
{
   [self.navigationController setNavigationBarHidden : YES];
   [super viewWillAppear : animated];
}

//________________________________________________________________________________________
- (void) viewWillDisappear:(BOOL)animated
{
   [self.navigationController setNavigationBarHidden : NO];
   [super viewWillDisappear : animated];
}

//________________________________________________________________________________________
- (void)viewDidLoad
{
   [super viewDidLoad];
   if (self.view) {
      self.view.backgroundColor = [UIColor blackColor];
      
      const CGRect frame = self.view.frame;
      selector = [[ScrollSelector alloc] initWithFrame : CGRectMake(0, 0.f, frame.size.width, [ScrollSelector defaultHeight])];
      selector.layer.shadowColor = [UIColor blackColor].CGColor;
      selector.layer.shadowOpacity = 0.5f;
      selector.layer.shadowOffset = CGSizeMake(0.f, 5.f);
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
      
      UIButton *backButton = [UIButton buttonWithType : UIButtonTypeCustom];
      backButton.backgroundColor = [UIColor clearColor];
      backButton.frame = CGRectMake(5.f, ([ScrollSelector defaultHeight] - tbBtnHeight) / 2.f, tbBtnWidth, tbBtnHeight);
      [backButton setImage:[UIImage imageNamed:@"back_button_flat.png"] forState : UIControlStateNormal];
      backButton.alpha = 0.9f;
      [self.view addSubview : backButton];

      [backButton addTarget : self action : @selector(backButtonPressed) forControlEvents : UIControlEventTouchUpInside];

      [self.view bringSubviewToFront : selector];
      [self.view bringSubviewToFront : backButton];

      //This is the ugly hack for ugly API/Frameworks/logic by Apple.
      tableControllers = [[NSMutableArray alloc] init];
      
      autoScroll = NO;
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
   assert(items != nil && "setItems:, items parameter is nil");

   if ([items count]) {
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
      
      [[tableControllers objectAtIndex : 0] refresh];
   }
   //Now we had to initialize a lot of feed parsers.
}

//________________________________________________________________________________________
- (void) preparePagesFor : (NSMutableArray *) itemNames
{
   assert(itemNames != nil && "preparePagesFor:, itemNames parameter is nil");
   assert([itemNames count] && "preparePagesFor:, at least one item expected");

   navigationView.contentOffset = CGPointZero;
   navigationView.contentSize = CGSizeMake([itemNames count] * navigationView.frame.size.width, navigationView.frame.size.height);
   
   [selector addItemNames : itemNames];
   [tableControllers removeAllObjects];//???
}

//________________________________________________________________________________________
- (void) addPageFor : (UIViewController<PageController> *) controller
{
   assert(controller != nil && "addPageFor:, controller parameter is nil");
   
   CGRect newPageFrame = navigationView.frame;
   newPageFrame.origin.y = 0.f;
   newPageFrame.origin.x = [tableControllers count] * newPageFrame.size.width;

   //Geometry is an everlasting pain with UIKit and Interface Builder.
   if ([DeviceCheck deviceIsiPhone5])
      newPageFrame.size.height = 460;
   else
      newPageFrame.size.height = 368;

   controller.view.frame = newPageFrame;

   [tableControllers addObject : controller];
   [navigationView addSubview : controller.view];
}

#pragma mark - ScrollSelectorDelegate

//________________________________________________________________________________________
- (void) item : (unsigned int) item selectedIn : (ScrollSelector *) selector
{
   //Item was selected by scrolling the "selector wheel".
   const CGPoint newOffset = CGPointMake(item * navigationView.frame.size.width, 0.f);
   autoScroll = YES;
   [navigationView setContentOffset : newOffset animated : YES];

   UIViewController<PageController> * const nextController = (UITableViewController<PageController> *)[tableControllers objectAtIndex : item];
   assert(nextController != nil && "item:selectedIn:, controller not found for the page");
   
   if (!nextController.loaded)
      [nextController refresh];
}

#pragma mark - UIScrollViewDelegate

//________________________________________________________________________________________
- (void) scrollViewDidScroll : (UIScrollView *) view
{
   if (!autoScroll)
      [selector scrollToPos : navigationView.contentOffset.x / navigationView.contentSize.width];
}

//________________________________________________________________________________________
- (void) scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
   autoScroll = NO;
}

//________________________________________________________________________________________
- (void) scrollViewDidEndDecelerating : (UIScrollView *) sender
{
   //Page scrolled, adjust selector now.
   const unsigned page = navigationView.contentOffset.x / navigationView.frame.size.width;
   [selector setSelectedItem : page];

   UIViewController<PageController> * const nextController = (UITableViewController<PageController> *)[tableControllers objectAtIndex : page];

   assert(nextController != nil && "scrollViewDidEndDecelerating:, controller not found for the page");
   if (!nextController.loaded)
      [nextController refresh];
}

#pragma mark - Navigation.

//________________________________________________________________________________________
- (void) backButtonPressed
{
   [self.navigationController popViewControllerAnimated : YES];
}

//________________________________________________________________________________________
- (void) selectPage : (NSInteger) page
{
   assert(page < [tableControllers count] && "selectPage:, page number is out of bounds");

   UIViewController<PageController> *controller = (UIViewController<PageController> *)[tableControllers objectAtIndex : page];
   
   if (page) {
      const CGPoint offset = CGPointMake(page * navigationView.frame.size.width, 0.f);
      [navigationView setContentOffset : offset animated : NO];
   }
   
   [selector setSelectedItem : page];
   [controller refresh];
}

@end
