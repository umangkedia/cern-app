//
//  AppDelegate.m
//  CERN App
//
//  Created by Eamon Ford on 5/24/12.
//  Copyright (c) 2012 CERN. All rights reserved.
//

#import "AppDelegate.h"
#import "RSSAggregator.h"
#import "PhotosGridViewController.h"
#import "NewsGridViewController.h"
#import "NewsTableViewController.h"
#import "BulletinGridViewController.h"
#import "StaticInfoSelectorViewController.h"
#import "StaticInfoScrollViewController.h"
#import "WebcastsGridViewController.h"
//#import "NewsTableViewController.h"
#import "MultiPageController.h"
#import "DeviceCheck.h"
#import "Constants.h"
#import "KeyVal.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
//
   self.tabBarController = (UITabBarController *)self.window.rootViewController;
   self.tabBarController.delegate = self;
   self.tabBarController.moreNavigationController.delegate = self;
   self.tabBarController.customizableViewControllers = [NSArray array];
   self.tabsAlreadySetup = [NSMutableDictionary dictionary];
   [self setupViewController:[self.tabBarController.viewControllers objectAtIndex:TabIndexNews] atIndex:TabIndexNews];

   ((UIViewController *)[self.tabBarController.viewControllers objectAtIndex:TabIndexNews]).tabBarItem.image = [UIImage imageNamed : @"news"];
   ((UIViewController *)[self.tabBarController.viewControllers objectAtIndex:TabIndexLive]).tabBarItem.image = [UIImage imageNamed : @"live"];
   ((UIViewController *)[self.tabBarController.viewControllers objectAtIndex:TabIndexAbout]).tabBarItem.image = [UIImage imageNamed : @"about"];
   ((UIViewController *)[self.tabBarController.viewControllers objectAtIndex:TabIndexBulletin]).tabBarItem.image = [UIImage imageNamed : @"bulletin"];
   ((UIViewController *)[self.tabBarController.viewControllers objectAtIndex:TabIndexPhotos]).tabBarItem.image = [UIImage imageNamed : @"latestPhotos"];
   ((UIViewController *)[self.tabBarController.viewControllers objectAtIndex:TabIndexVideos]).tabBarItem.image = [UIImage imageNamed : @"latestVideos"];
   ((UIViewController *)[self.tabBarController.viewControllers objectAtIndex:TabIndexWebcasts]).tabBarItem.image = [UIImage imageNamed : @"webcasts"];
   ((UIViewController *)[self.tabBarController.viewControllers objectAtIndex:TabIndexJobs]).tabBarItem.image = [UIImage imageNamed : @"jobs"];

   [[UINavigationBar appearance] setTintColor : [UIColor clearColor]];
   [[UINavigationBar appearance] setBackgroundImage : [UIImage imageNamed : @"navbarback.png"] forBarMetrics:UIBarMetricsDefault];
   
//   [[UIBarButtonItem appearance] setTintColor : [UIColor clearColor]];
//   [[UIBarButtonItem appearance] setBackButtonBackgroundImage : [UIImage imageNamed : @"navbarback.png"] forState : UIControlStateNormal barMetrics : UIBarMetricsDefault];

   return YES;
}

- (void)tabBarController:(UITabBarController *)theTabBarController didSelectViewController:(UIViewController *)viewController
{
   int index = [theTabBarController.viewControllers indexOfObject:viewController];
   [self setupViewController:viewController atIndex:index];
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)showingViewController animated:(BOOL)animated
{
   UINavigationBar *morenavbar = navigationController.navigationBar;
   UINavigationItem *morenavitem = morenavbar.topItem;
   /* We don't need Edit button in More screen. */
   morenavitem.rightBarButtonItem = nil;

   // In order to figure out the index of the selected view controller, we have to search through tabBarController.viewControllers for a UINavigationController that has no topViewController, because the selected view controller got popped off its navigation stack.
   id checkIfNil = ^BOOL(id element, NSUInteger idx, BOOL *stop) {
     return [(UINavigationController *)element topViewController] == nil;
   };
   int index = [self.tabBarController.viewControllers indexOfObjectPassingTest:checkIfNil];
   [self setupViewController:showingViewController atIndex:index];
}

- (void)setupViewController:(UIViewController *)viewController atIndex:(int)index
{
    // Only set up each view controller once, and then never do it again.
    if ([[self.tabsAlreadySetup objectForKey:[NSNumber numberWithInt:index]] boolValue])
        return;
    else
        [self.tabsAlreadySetup setObject:[NSNumber numberWithBool:YES] forKey:[NSNumber numberWithInt:index]];

    
    if ([viewController respondsToSelector:@selector(viewControllers)]) {
        viewController = [[(id)viewController viewControllers] objectAtIndex:0];
    }
    
    switch (index) {
        case TabIndexNews: {
            // Populate the general News view controller with news feeds
            if ([DeviceCheck deviceIsiPad]) {
               [((NewsGridViewController *)viewController).aggregator addFeedForURL : [NSURL URLWithString:@"http://feeds.feedburner.com/CernCourier"]];
               [(NewsGridViewController *)viewController refresh];
            } else {
               //
               NSMutableArray *feeds = [[NSMutableArray alloc] init];
               
               assert([viewController isKindOfClass : [MultiPageController class]] &&
                      "setupViewController:atIndex:, viewController must have MultiPageController type");
               
               KeyVal *pair = [[KeyVal alloc] init];
               pair.key = @"CERN Courier";
               pair.val = @"http://feeds.feedburner.com/CernCourier";
               [feeds addObject : pair];
               
               pair = [[KeyVal alloc] init];
               pair.key = @"Announcements";
               pair.val = @"http://home.web.cern.ch/cern-people/announcements/feed";
               [feeds addObject : pair];
               
               pair = [[KeyVal alloc] init];
               pair.key = @"For students";
               pair.val = @"http://home.web.cern.ch/students-educators/updates/feed";
               [feeds addObject : pair];
               
               pair = [[KeyVal alloc] init];
               pair.key = @"Updates";
               pair.val = @"http://home.web.cern.ch/cern-people/updates/feed";
               [feeds addObject : pair];
               
               MultiPageController *mpController = (MultiPageController *)viewController;

               [mpController setItems : feeds];
               [mpController hideBackButton : YES];
            }

            break;
        }
        case TabIndexAbout: {
            NSString *path = [[NSBundle mainBundle] pathForResource:@"StaticInformation" ofType:@"plist"];
            NSDictionary *plistDict = [NSDictionary dictionaryWithContentsOfFile:path];
            self.staticInfoDataSource = [plistDict objectForKey:@"Root"];
            
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
                StaticInfoSelectorViewController *selectorViewController = (StaticInfoSelectorViewController *)[[self.tabBarController.viewControllers objectAtIndex:TabIndexAbout] topViewController];
                selectorViewController.tableDataSource = self.staticInfoDataSource;
                
            } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                NSArray *defaultRecords = [[self.staticInfoDataSource objectAtIndex:0] objectForKey:@"Items"];
                StaticInfoScrollViewController *scrollViewController = [self.tabBarController.viewControllers objectAtIndex:TabIndexAbout];
                scrollViewController.dataSource = defaultRecords;
                [scrollViewController refresh];
            }
            
            break;
        }
        case TabIndexLive: {
            break;
        }
        case TabIndexBulletin: {
            BulletinGridViewController *bulletinViewController = (BulletinGridViewController *)viewController;
            [bulletinViewController.aggregator addFeedForURL:[NSURL URLWithString:@"http://cdsweb.cern.ch/rss?p=980__a%3ABULLETINNEWS%20or%20980__a%3ABULLETINNEWSDRAFT&ln=en"]];
            [bulletinViewController refresh];

            break;
        }
        case TabIndexPhotos: {
            // Initialize the photos view controller with a photo downloader object
            ((PhotosGridViewController *)viewController).photoDownloader.url = [NSURL URLWithString:@"http://cdsweb.cern.ch/search?ln=en&cc=Photos&p=&f=&action_search=Search&c=Photos&c=&sf=&so=d&rm=&rg=10&sc=1&of=xm"];
            break;
        }
        case TabIndexVideos: {
            break;
        }
        case TabIndexJobs: {
            [((NewsGridViewController *)viewController).aggregator addFeedForURL:[NSURL URLWithString:@"https://ert.cern.ch/browse_www/wd_portal_rss.rss?p_hostname=ert.cern.ch"]];
            [(NewsGridViewController *)viewController refresh];
            break;
        }
        case TabIndexWebcasts: {
            break;
        }
        default:
            break;
    }
}


@end
