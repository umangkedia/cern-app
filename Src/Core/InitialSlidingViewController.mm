//
//  InitialSlidingViewController.m
//  ECSlidingViewController
//
//  Created by Michael Enriquez on 1/25/12.
//  Copyright (c) 2012 EdgeCase. All rights reserved.
//

//This class is a central for our app - it's our sliding view controller,
//which hosts everything else inside. The code modified and adapted for CERN.app
//by Timur Pocheptsov (and, probably, broken :).

#import <cassert>

#import "InitialSlidingViewController.h"
#import "MenuNavigationController.h"
#import "NewsTableViewController.h"
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

   for (id item in menuContents) {
      assert([item isKindOfClass : [NSDictionary class]] && "loadFirstNewsFeed:, item has a wrong type");
      NSDictionary * const itemDict = (NSDictionary *)item;
      
      id objBase = itemDict[@"Category name"];
      assert([objBase isKindOfClass : [NSString class]] &&
             "loadFirstNewsFeed:, 'Category Name' either not found, or has a wrong type");
   
      NSString * const catName = (NSString *)objBase;
      
      NSLog(@"got %@", catName);
      if (![catName isEqualToString : @"News"])
         continue;
      
      objBase = itemDict[@"Feeds"];
      if (objBase) {
         assert([objBase isKindOfClass : [NSArray class]] &&
                "loadFirstNewsFeed:, 'Feeds' has a wrong type");
         NSArray * const feeds = (NSArray *)objBase;
         for (id info in feeds) {
            assert([info isKindOfClass : [NSDictionary class]] &&
                   "loadFirstNewsFeed:, feed info must be a dictionary");
            NSDictionary * const feedInfo = (NSDictionary *)info;
            
            if (!feedInfo[@"Category name"]) {
               //Simple news feed does not have a 'Category name' property.
               assert([feedInfo[@"Name"] isKindOfClass : [NSString class]] &&
                      "loadFirstNewsFeed:, 'Name' not found or has a wrong type");
               assert([feedInfo[@"Url"] isKindOfClass : [NSString class]] &&
                      "loadFirstNewsFeed:, 'Url' not found or has a wrong type");
               
               tableController.navigationItem.title = (NSString *)feedInfo[@"Name"];
               [tableController.aggregator addFeedForURL : [NSURL URLWithString : (NSString *)feedInfo[@"Url"]]];

               return;
            }
         }
      }
   }
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

   //The very first view a user see - is a news table. We create a navigation controller
   //with such a table here, also, we have to add a news feed here.
   //Actually, feed info is in MENU.plist, but at this point menu is not created yet
   //(it'll be created by this first table navigation controller.


   MenuNavigationController * const top = (MenuNavigationController *)[storyboard instantiateViewControllerWithIdentifier :
                                                                       CernAPP::TableNavigationControllerNewsID];

   assert([top.topViewController isKindOfClass : [NewsTableViewController class]] &&
          "viewDidLoad:, top view controller is either nil or has a wrong type");

   [self loadFirstNewsFeed : (NewsTableViewController *)top.topViewController];
   self.topViewController = top;
}

//________________________________________________________________________________________
- (BOOL) shouldAutorotate
{
   if ([self underLeftShowing])
      return NO;

   return [self.topViewController shouldAutorotate];
}

//________________________________________________________________________________________
- (NSUInteger) supportedInterfaceOrientations
{
   if ([self underLeftShowing])
      return UIInterfaceOrientationMaskPortrait;

   return [self.topViewController supportedInterfaceOrientations];
}



@end
