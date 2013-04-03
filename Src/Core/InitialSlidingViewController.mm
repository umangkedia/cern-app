//
//  InitialSlidingViewController.m
//  ECSlidingViewController
//
//  Created by Michael Enriquez on 1/25/12.
//  Copyright (c) 2012 EdgeCase. All rights reserved.
//

//This class is a central for our app - it's our sliding view controller,
//which hosts everything else inside. The code modified and adapted for CERN.app
//by Timur Pocheptsov.

#import <cassert>

#import "InitialSlidingViewController.h"
#import "MenuNavigationController.h"
#import "NewsTableViewController.h"
#import "NewsTileViewController.h"
#import "StoryboardIdentifiers.h"

@implementation InitialSlidingViewController

//________________________________________________________________________________________
- (void) loadFirstNewsFeed : (NewsTableViewController *) tableController
{
   assert(tableController != nil && "loadFirstNewsFeed:, parameter 'tableController' is nil");

   NSString * const path = [[NSBundle mainBundle] pathForResource : @"MENU" ofType : @"plist"];
   NSDictionary * const plistDict = [NSDictionary dictionaryWithContentsOfFile : path];
   assert(plistDict != nil && "viewDidLoad, no dictionary or MENU.plist found");

   id objBase = plistDict[@"Menu Contents"];
   assert([objBase isKindOfClass : [NSArray class]] &&
          "viewDidLoad, object for the key 'Menu Contents' was not found or has a wrong type");

   NSArray * const menuContents = (NSArray *)objBase;
   assert(menuContents.count != 0 && "viewDidLoad, menu contents array is empty");

   //We are looking either tweet or news feed in our list.
   NSDictionary *feedDict = nil;

   for (id item in menuContents) {
      assert([item isKindOfClass : [NSDictionary class]] && "loadFirstNewsFeed:, item in an array has a wrong type");
      NSDictionary * const menuItemDict = (NSDictionary *)item;

      id objBase = menuItemDict[@"Category name"];
      assert([objBase isKindOfClass : [NSString class]] &&
             "loadFirstNewsFeed:, 'Category Name' either not found, or has a wrong type");
   
      NSString * const catName = (NSString *)objBase;

      if ([catName isEqualToString : @"Feed"] || [catName isEqualToString : @"Tweet"]) {
         //It's a feed at the top level.
         feedDict = menuItemDict;
      } else if ([catName isEqualToString : @"Menu group"]) {
         //Scan the menu group for a tweet.
         assert([menuItemDict[@"Items"] isKindOfClass : [NSArray class]] &&
                "loadFirstNewsFeed:, 'Items' not found or has a wrong type");

         NSArray * const groupItems = (NSArray *)menuItemDict[@"Items"];
         for (id info in groupItems) {
            assert([info isKindOfClass : [NSDictionary class]] &&
                   "loadFirstNewsFeed:, item has a wrong type");

            NSDictionary * const childItemInfo = (NSDictionary *)info;
            assert([childItemInfo[@"Category name"] isKindOfClass : [NSString class]] &&
                   "'Category name' not found or has a wrong type");

            NSString * const childCategoryName = (NSString *)childItemInfo[@"Category name"];
            if ([childCategoryName isEqualToString : @"Feed"] || [childCategoryName isEqualToString : @"Tweet"]) {
               feedDict = childItemInfo;
               break;
            }
         }
      }

      if (feedDict)
         break;
   }

   assert(feedDict != nil && "loadFirstNewsFeed:, no feed/tweet found");
   
   assert([feedDict[@"Name"] isKindOfClass : [NSString class]] &&
          "loadFirstNewsFeed:, 'Name' not found or has a wrong type");
   assert([feedDict[@"Url"] isKindOfClass : [NSString class]] &&
          "loadFirstNewsFeed:, 'Url' not found or has a wrong type");
               
   tableController.navigationItem.title = (NSString *)feedDict[@"Name"];
   tableController.feedStoreID = (NSString *)feedDict[@"Name"];
   [tableController.aggregator addFeedForURL : [NSURL URLWithString : (NSString *)feedDict[@"Url"]]];
}

//________________________________________________________________________________________
- (void) viewDidLoad
{
   [super viewDidLoad];
  
   UIStoryboard *storyboard = nil;
  
   if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
      storyboard = [UIStoryboard storyboardWithName : @"iPhone" bundle : nil];
   else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
      storyboard = [UIStoryboard storyboardWithName : @"iPad" bundle : nil];

   assert(storyboard != nil && "viewDidLoad, storyboard is nil");

   MenuNavigationController * const top = (MenuNavigationController *)[storyboard instantiateViewControllerWithIdentifier :
                                                                       CernAPP::TableNavigationControllerNewsID];

   if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
      assert([top.topViewController isKindOfClass : [NewsTableViewController class]] &&
             "viewDidLoad:, top view controller is either nil or has a wrong type");

      //The very first view a user see - is a news table. We create a navigation controller
      //with such a table here, also, we have to add a news feed here.
      [self loadFirstNewsFeed : (NewsTableViewController *)top.topViewController];
   } else {
      //Special case, unfortunately: we do not have any interesting feeds with images and articles,
      //only CMS or ATLAS feeds or the CERN's bulletin. To be more neutral, let's use the Bulletin.
      
      assert([top.topViewController isKindOfClass:[NewsTileViewController class]] &&
             "viewDidLoad:, top view controller is either nil or has a wrong type");
      
      NewsTileViewController *tileController = (NewsTileViewController *)top.topViewController;
      tileController.navigationItem.title = @"Bulletin";
      //TODO: ID for cache!!!
      //[tileController.aggregator addFeedForURL : [NSURL URLWithString : @"http://cdsweb.cern.ch/rss?p=980__a%3ABULLETINNEWS%20or%20980__a%3ABULLETINNEWSDRAFT&ln=en"]];
      [tileController.aggregator addFeedForURL : [NSURL URLWithString : @"http://home.web.cern.ch/about/updates/feed"]];
   }

   self.topViewController = top;
}

//________________________________________________________________________________________
- (BOOL) shouldAutorotate
{
   if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {

      if ([self underLeftShowing])
         return NO;
      
      return [self.topViewController shouldAutorotate];
   }

   return YES;
}

//________________________________________________________________________________________
- (NSUInteger) supportedInterfaceOrientations
{
   if ([self underLeftShowing])
      return UIInterfaceOrientationMaskPortrait;

   return [self.topViewController supportedInterfaceOrientations];
}



@end
