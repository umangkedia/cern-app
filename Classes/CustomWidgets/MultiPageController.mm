//
//  Created by Timur Pocheptsov on 11/7/12.
//  Copyright (c) 2012 Timur Pocheptsov. All rights reserved.
//

#import <cassert>
#import <cstdlib>

#import <QuartzCore/QuartzCore.h>

#import "LiveEventTableController.h"
#import "NewsTableViewController.h"
#import "StoryboardIdentifiers.h"
#import "MultiPageController.h"
#import "ScrollSelector.h"
#import "GuiAdjustment.h"
#import "DeviceCheck.h"
#import "KeyVal.h"

@implementation MultiPageController {
   UIScrollView *navigationView;
   ScrollSelector *selector;
   
   //TODO: the name 'tableControllers' is not good anymore, I can have not only tables.
   NSMutableArray *tableControllers;
   BOOL autoScroll;
   UIButton *backButton;
   UIButton *refreshButton;
   
   NSUInteger selectedPage;
}

//________________________________________________________________________________________
- (BOOL) shouldAutorotate
{
   return NO;
}

//________________________________________________________________________________________
- (void) viewWillAppear : (BOOL)animated
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
      
      //Some "eye candy" here: let's make a selector (who replaces the navigation bar in case of multi-page controller)
      //to drop a shadow.
      selector = [[ScrollSelector alloc] initWithFrame : CGRectMake(0, 0.f, frame.size.width, [ScrollSelector defaultHeight])];
      selector.layer.shadowColor = [UIColor blackColor].CGColor;
      selector.layer.shadowOpacity = 0.5f;
      selector.layer.shadowOffset = CGSizeMake(0.f, 5.f);

      [self.view addSubview : selector];
      //Items must be added into the selector.
      selector.delegate = self;
      
      CGRect tableFrame = CGRectMake(0., [ScrollSelector defaultHeight], 320.f, frame.size.height - [ScrollSelector defaultHeight]);
      //navigationView is a scroll view, all pages will be added into this scroll-view.
      navigationView = [[UIScrollView alloc] initWithFrame : tableFrame];
      navigationView.backgroundColor = [UIColor grayColor];
      navigationView.delegate = self;

      [self.view addSubview : navigationView];
      
      //We can have tables inside a scrollview,
      //these tables also have to process touches.
      navigationView.canCancelContentTouches = NO;
      navigationView.delaysContentTouches = YES;
      
      navigationView.contentOffset = CGPointZero;
      navigationView.contentSize = CGSizeMake(tableFrame.size.width * 5, tableFrame.size.height);//WTF 5???
      navigationView.showsHorizontalScrollIndicator = NO;
      navigationView.showsVerticalScrollIndicator = NO;
      navigationView.pagingEnabled = YES;

      //We do not have a navigation bar with left ('back') button,
      //but we still need something like this.
      backButton = [UIButton buttonWithType : UIButtonTypeCustom];
      backButton.backgroundColor = [UIColor clearColor];
      const CGSize &btnSize = CernAPP::navBarBackButtonSize;
      backButton.frame = CGRectMake(5.f, ([ScrollSelector defaultHeight] - btnSize.height) / 2.f, btnSize.width, btnSize.height);
      [backButton setImage : [UIImage imageNamed : @"back_button_flat.png"] forState : UIControlStateNormal];
      backButton.alpha = 0.9f;
      [self.view addSubview : backButton];

      [backButton addTarget : self action : @selector(backButtonPressed) forControlEvents : UIControlEventTouchUpInside];

      [self.view bringSubviewToFront : selector];
      [self.view bringSubviewToFront : backButton];

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
- (void) setNewsFeedControllersFor : (NSMutableArray *) items
{
   assert(items != nil && "setNewsFeedControllersFor:, items parameter is nil");

   if ([items count]) {
      //This method can be called (from AppDelegate) before
      //viewDidLoad, but I need views to be initialized.
      [self view];//This will force viewDidLoad, if it was not done yet.
      
      if ([tableControllers count])
         [tableControllers removeAllObjects];

      //Setup a "page selector".
      NSMutableArray * const titles = [[NSMutableArray alloc] init];
      for (id itemBase in items) {
         assert([itemBase isKindOfClass : [KeyVal class]] && "setNewsFeedControllersFor:, KeyVal expected");
         KeyVal *pair = (KeyVal *)itemBase;
         assert([pair.key isKindOfClass : [NSString class]] && "setNewsFeedControllersFor:, key expected to be a string");
         [titles addObject : pair.key];
      }
   
      [selector setLabelItemsWithText : titles];
      //[selector setNeedsDisplay];//???
      
      CGRect frame = navigationView.frame;
      frame.origin.y = 0;
      
      //Geometry is an everlasting pain with UIKit and Interface Builder.
      if ([DeviceCheck deviceIsiPhone5])
         frame.size.height = 460;
      else
         frame.size.height = 368;
      
      UIStoryboard * const mainStoryboard = [UIStoryboard storyboardWithName : @"MainStoryboard_iPhone" bundle : nil];
      assert(mainStoryboard != nil && "setItems:, storyboard is nil");
      
      for (KeyVal *pair in items) {
         NewsTableViewController * const newsViewController = [mainStoryboard instantiateViewControllerWithIdentifier : CernAPP::NewsTableViewControllerNoSequeID];
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
      
      selectedPage = 0;
      UIViewController<PageController> * const firstController = (UIViewController<PageController> *)[tableControllers objectAtIndex : 0];
      [self resetRefreshButtonForController : firstController];
      [firstController reloadPage];//TODO: Check, if I should do this here.
   }
}

//________________________________________________________________________________________
- (void) setupControllerForPages : (NSMutableArray *) pageNames
{
   assert(pageNames != nil && "setupControllerForPages:, parameter 'pageNames' is nil");
   assert([pageNames count] && "setupControllerForPages:, at least one item expected");

   navigationView.contentOffset = CGPointZero;
   navigationView.contentSize = CGSizeMake([pageNames count] * navigationView.frame.size.width, navigationView.frame.size.height);

   [selector setLabelItemsWithText : pageNames];
   [tableControllers removeAllObjects];
}

//________________________________________________________________________________________
- (void) addPageFor : (UIViewController<PageController> *) controller
{
   assert(controller != nil && "addPageFor:, parameter 'controller' is nil");
   assert([tableControllers count] < [selector itemsCount] &&
          "addPageFor: multi-page controller is full already");

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
- (void) item : (NSUInteger) item selectedIn : (ScrollSelector *) selector
{
   //Item was selected by scrolling the "selector wheel".
   const CGPoint newOffset = CGPointMake(item * navigationView.frame.size.width, 0.f);
   //When scrolling, scrollViewDidScroll SHOULD NOT update a scroller wheel, since
   //it was a scroller wheel who called us.
   autoScroll = YES;

   [navigationView setContentOffset : newOffset animated : YES];

   UIViewController<PageController> * const nextController = (UIViewController<PageController> *)[tableControllers objectAtIndex : item];
   assert(nextController != nil && "item:selectedIn:, controller not found for the page");
   
   [self resetRefreshButtonForController : nextController];
   
   if (!nextController.pageLoaded)
      [nextController reloadPage];
   
   selectedPage = item;
}

//________________________________________________________________________________________
- (UIViewController<PageController> *) selectedViewController
{
   assert(selectedPage < [tableControllers count] && "selectedViewController, selectedPage is out of range");
   return (UIViewController<PageController> *)[tableControllers objectAtIndex : selectedPage];
}

#pragma mark - UIScrollViewDelegate

//________________________________________________________________________________________
- (void) scrollViewDidScroll : (UIScrollView *) view
{
   //We need a nice "animation" - when user is scrolling pages,
   //selector 'wheel' at the top also should follow.
   if (!autoScroll)
      [selector scrollToPos : navigationView.contentOffset.x / navigationView.contentSize.width];
}

//________________________________________________________________________________________
- (void) scrollViewDidEndScrollingAnimation : (UIScrollView *) scrollView
{
   autoScroll = NO;
}

//________________________________________________________________________________________
- (void) scrollViewDidEndDecelerating : (UIScrollView *) sender
{
   //Page scrolled, adjust selector now.
   selectedPage = navigationView.contentOffset.x / navigationView.frame.size.width;
   [selector setSelectedItem : selectedPage];
   [selector playClick];

   UIViewController<PageController> * const nextController = (UITableViewController<PageController> *)[tableControllers objectAtIndex : selectedPage];

   [self resetRefreshButtonForController : nextController];

   assert(nextController != nil && "scrollViewDidEndDecelerating:, controller not found for the page");
   if (![nextController pageLoaded])
      [nextController reloadPage];
}

#pragma mark - Navigation.

//________________________________________________________________________________________
- (void) backButtonPressed
{
   [self.navigationController popViewControllerAnimated : YES];
}

//________________________________________________________________________________________
- (void) resetRefreshButtonForController : (UIViewController<PageController> *) controller
{
   assert(controller != nil && "resetRefreshButtonForController:, parameter 'controller' is nil");

   if (refreshButton) {
      [refreshButton removeFromSuperview];
      refreshButton = nil;
   }

   if ([controller respondsToSelector : @selector(needsRefreshButton)] && controller.needsRefreshButton) {
      refreshButton = [UIButton buttonWithType : UIButtonTypeCustom];
      refreshButton.backgroundColor = [UIColor clearColor];
      const CGSize &btnSize = CernAPP::navBarBackButtonSize;
      refreshButton.frame = CGRectMake(self.view.frame.size.width - btnSize.width - 5, ([ScrollSelector defaultHeight] - btnSize.height) / 2.f, btnSize.width, btnSize.height);
      [refreshButton setImage : [UIImage imageNamed : @"back_button_flat.png"] forState : UIControlStateNormal];
      refreshButton.alpha = 0.9f;
      [self.view addSubview : refreshButton];

      [refreshButton addTarget : controller action : @selector(reloadPageFromRefreshControl) forControlEvents : UIControlEventTouchUpInside];

      [self.view bringSubviewToFront : refreshButton];
   }
}

//________________________________________________________________________________________
- (void) scrollToPage : (NSInteger) page
{
   //This method is called, when MultiPageController is loaded by some table-view controller,
   //page == selected row.

   assert(page >= 0 && page < [tableControllers count] && "scrollToPage:, parameter 'page' is out of bounds");
   
   selectedPage = page;
   
   UIViewController<PageController> *controller = (UIViewController<PageController> *)[tableControllers objectAtIndex : page];
   if (page) {
      const CGPoint offset = CGPointMake(page * navigationView.frame.size.width, 0.f);
      [navigationView setContentOffset : offset animated : NO];
   }
   
   assert([selector itemsCount] == [tableControllers count] &&
          "scrollToPage:, inconsistent number of pages and items in a selector");
   [selector setSelectedItem : page];
   [self resetRefreshButtonForController : controller];
   [controller reloadPage];
}

#pragma mark  - GUI adjustment.

//________________________________________________________________________________________
- (void) hideBackButton : (BOOL) hide
{
   [backButton setHidden : hide];
}

@end
