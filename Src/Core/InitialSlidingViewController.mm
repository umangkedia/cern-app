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
#import "StoryboardIdentifiers.h"

@implementation InitialSlidingViewController

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

   //Now, let's ask for the first (from the top of MENU.plist) news feed.
   [top addFeed : @"http://cms.web.cern.ch/news/category/265/rss.xml" withName : @"CMS News"];
   
   self.topViewController = top;
}

//________________________________________________________________________________________
- (BOOL) shouldAutorotateToInterfaceOrientation : (UIInterfaceOrientation) toInterfaceOrientation
{
   return YES;
}

@end
