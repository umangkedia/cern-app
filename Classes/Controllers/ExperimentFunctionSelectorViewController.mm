//
//  ExperimentDetailTableViewController.m
//  CERN App
//
//  Created by Eamon Ford on 7/20/12.
//  Copyright (c) 2012 CERN. All rights reserved.
//

//Modified by Timur Pocheptsov.

#include <cassert>

#import "ExperimentFunctionSelectorViewController.h"
#import "EventDisplayViewController.h"
#import "PhotosGridViewController.h"
#import "NewsTableViewController.h"
#import "NewsGridViewController.h"
#import "ScrollSelector.h"
#import "DeviceCheck.h"
#import "AppDelegate.h"
#import "Constants.h"
#import "KeyVal.h"

//________________________________________________________________________________________
@interface ExperimentLIVEData : NSObject

- (id) initWithLIVEData : (NSDictionary *) data;

- (NSUInteger) numberOfRows;
- (NSString *) textForRow : (NSUInteger) row;

@end

@implementation ExperimentLIVEData

//________________________________________________________________________________________
- (id) initWithLIVEData : (NSDictionary *) data
{
   assert(data != nil && "initWithLIVEData, 'data' parameter is nil");
   
   self = [super init];

   return self;
}

//________________________________________________________________________________________
- (NSUInteger) numberOfRows
{
   return 0;
}

//________________________________________________________________________________________
- (NSUInteger) numberOfViewsForRow:(NSUInteger)row
{
   (void)row;
   return 0;
}

//________________________________________________________________________________________
- (NSString *) textForRow : (NSUInteger) row
{
   (void)row;
   return @"";
}

@end

//________________________________________________________________________________________
@interface LIVENews : ExperimentLIVEData {
   NSMutableArray *feeds;
   NSMutableArray *tweets;
   NSMutableArray *pages;
}

- (id) initWithLIVEData : (NSDictionary *) data;

- (NSUInteger) numberOfRows;
- (NSString *) textForRow : (NSUInteger) row;

@end

@implementation LIVENews

//________________________________________________________________________________________
- (id) initWithLIVEData : (NSDictionary *) data
{
   assert(data != nil && "initWithLIVEData, 'data' parameter is nil");
   
   if (self = [super initWithLIVEData : data]) {
      //
      if (id base = [data objectForKey : @"Feeds"]) {
         assert([base isKindOfClass : [NSDictionary class]] && "initWithLIVEData:, NSDictionary is expected for the key 'Feeds'");
         NSDictionary * const feedsSrc = (NSDictionary *)base;
         
         if ([feedsSrc count]) {
            feeds = [[NSMutableArray alloc] init];
            for (NSString *key in feedsSrc) {
               id val = [feedsSrc objectForKey : key];
               assert([val isKindOfClass:[NSString class]] && "value in a 'Feed's dictionary must be a string");
               KeyVal *newPair = [[KeyVal alloc] init];
               newPair.key = key;
               newPair.val = val;
               
               [feeds addObject : newPair];
            }
         }
      }
      //
      /*
      if (id base = [data objectForKey : @"Pages"]) {
         assert([base isKindOfClass : [NSArray class]] && "initWithLIVEData:, NSArray is expected for the key 'Pages'");
         NSArray * const pagesSrc = (NSArray *)base;
         
         if ([pagesSrc count]) {
            pages = [[NSMutableArray alloc] init];
            for (id page in pagesSrc) {
               //Check here, feed should be a string.
               assert([page isKindOfClass : [NSString class]] && "initWithLIVEData:, page must be of NSString type");
               [pages addObject : page];
            }
         }
      }
      */
      //
      /*
      if (id base = [data objectForKey : @"Tweets"]) {
         assert([base isKindOfClass : [NSArray class]] && "initWithLIVEData:, NSArray is expected for the key 'Tweets'");
         NSArray * const tweetsSrc = (NSArray *)base;
         
         if ([tweetsSrc count]) {
            feeds = [[NSMutableArray alloc] init];
            for (id tweet in tweetsSrc) {
               //Check here, feed should be a string.
               assert([tweet isKindOfClass : [NSString class]] && "initWithLIVEData:, tweet must be of NSString type");
               [tweets addObject : tweet];
            }
         }
      }
      */
   }

   return self;
}

//________________________________________________________________________________________
- (NSUInteger) numberOfRows
{
   //Max. == 3 - feeds, tweets, pages.
   NSUInteger nRows = 0;
   if ([feeds count])
      ++nRows;
   if ([pages count])
      ++nRows;
   if ([tweets count])
      ++nRows;
   
   return nRows;
}

//________________________________________________________________________________________
- (NSString *) textForRow : (NSUInteger) row
{
   assert(([feeds count] > 0 || [pages count] > 0 || [tweets count] > 0) && "textForRow:, no data for experiment found");

   //I do not check row index and pages/tweets/feeds existance.

   if (!row) {
      if ([feeds count])
         return @"News";
      if ([pages count])
         return @"News pages";
      
      return @"Tweets";
   } else if (row == 1) {
      if ([pages count])
         return @"News pages";
      
      return @"Tweets";
   }

   return @"Tweets";
}

@end

//________________________________________________________________________________________
@interface EventDisplayData : ExperimentLIVEData

@end

@implementation EventDisplayData

@end

//________________________________________________________________________________________
@interface DAQData : ExperimentLIVEData

@end

@implementation DAQData


@end


#pragma mark - ExperimentFunctionSelectorViewController.

//________________________________________________________________________________________
@implementation ExperimentFunctionSelectorViewController {
   NSMutableArray *liveData;
}

//________________________________________________________________________________________
- (id) initWithStyle : (UITableViewStyle) style
{
   if (self = [super initWithStyle : style]) {
      // Custom initialization
   }
   
   return self;
}

//________________________________________________________________________________________
- (void) viewDidLoad
{
   [super viewDidLoad];
   // Uncomment the following line to preserve selection between presentations.
   // self.clearsSelectionOnViewWillAppear = NO;

   // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
   // self.navigationItem.rightBarButtonItem = self.editButtonItem;
   //NSLog(@"self.view is %@", self.view);
   
   //Here's a trick: usually, table view from storyboard is a top level view and
   //takes the full screen, but we need a space at the top to add a scroller.
  /*
   CGRect frame = self.view.frame;
   UIView *view = [[UIView alloc] initWithFrame : frame];
   
   UITableView *tableView = self.tableView;
   
   frame.origin = CGPointZero;
   CGRect topScrollerFrame = frame;
   topScrollerFrame.size.height = [ScrollSelector defaultHeight];
   
   ScrollSelector *selector = [[ScrollSelector alloc] initWithFrame : topScrollerFrame];
   [selector addItemNames : @[@"Feed one", @"Feed two", @"Feed three"]];
   
   frame.origin.y = [ScrollSelector defaultHeight];
   frame.size.height -= [ScrollSelector defaultHeight];
   tableView.frame = frame;

   [view addSubview : selector];
   [view addSubview : tableView];
   self.view = view;*/
}

//________________________________________________________________________________________
- (void) readLIVEData
{
   NSString * const path = [[NSBundle mainBundle] pathForResource : @"CERNLive" ofType : @"plist"];
   NSDictionary * const plistDict = [NSDictionary dictionaryWithContentsOfFile : path];
   assert(plistDict != nil && "readLIVEData:, no dictionary or CERNLive.plist found");

   if (!liveData)
      liveData = [[NSMutableArray alloc] init];
   else
      [liveData removeAllObjects];

   if (id base = [plistDict objectForKey : self.title]) {
      assert([base isKindOfClass : [NSArray class]] && "readLIVEData:, entry for experiment must have NSArray type");
      NSArray * const dataSource = (NSArray *)base;
      
      for (id arrayItem in dataSource) {
         assert([arrayItem isKindOfClass : [NSDictionary class]] && "readLIVEData:, array of dictionaries expected");
         NSDictionary * const data = (NSDictionary *)arrayItem;
         
         id base = [data objectForKey : @"Category name"];
         assert(base != nil && [base isKindOfClass : [NSString class]] && "readLIVEData:, string key 'Category name' was not found");
         
         NSString *catName = (NSString *)base;
         
         if ([catName isEqualToString : @"News"]) {
            LIVENews *news = [[LIVENews alloc] initWithLIVEData : data];
            if (news)
               [liveData addObject : news];
            else
               NSLog(@"LIVENews initialization failed for %@", self.title);

         } else if ([catName isEqualToString:@"Event display"]) {
            //NSLog(@"Event display found for %@", self.title);
         } else if ([catName isEqualToString:@"DAQ"]) {
            //NSLog(@"DAQ found for %@", self.title);
         } else {
            assert(0 && "readLIVEData, unknown data entry found");
         }
      }
   }
}

//________________________________________________________________________________________
- (void) viewWillAppear : (BOOL) animated
{
   self.navigationController.navigationBarHidden = NO;

   switch (self.experiment) {
      case ATLAS:
         self.title = @"ATLAS";
         break;
      case CMS:
         self.title = @"CMS";
         break;
      case ALICE:
         self.title = @"ALICE";
         break;
      case LHCb:
         self.title = @"LHCb";
         break;
      case LHC:
         self.title = @"LHC";
         break;
      default: break;
   }
   
   //
   [self readLIVEData];
}

//________________________________________________________________________________________
- (void) viewDidUnload
{
   [super viewDidUnload];
   // Release any retained subviews of the main view.
   // e.g. self.myOutlet = nil;   
}

//________________________________________________________________________________________
- (BOOL) shouldAutorotateToInterfaceOrientation : (UIInterfaceOrientation)interfaceOrientation
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return YES;
    else
        return (interfaceOrientation == UIInterfaceOrientationPortrait);

}

#pragma mark - Table view data source

//________________________________________________________________________________________
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
   return 1;
}

//________________________________________________________________________________________
- (NSInteger) tableView : (UITableView *) tableView numberOfRowsInSection : (NSInteger) section
{
   //TP: at the moment we have only "News" and "Event display" cells.
   if (self.experiment == LHC)
      return 1;
   
   return 2;
}

//________________________________________________________________________________________
- (UITableViewCell *) tableView : (UITableView *) tableView cellForRowAtIndexPath : (NSIndexPath *) indexPath
{
   static NSString *CellIdentifier = @"Cell";
   UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier : CellIdentifier];
   if (!cell)
      cell = [[UITableViewCell alloc] initWithStyle : UITableViewCellStyleDefault reuseIdentifier : CellIdentifier];

   switch (indexPath.row) {
      case 0:
         switch (self.experiment) {
            case ATLAS:
               cell.textLabel.text = @"ATLAS News";
               break;
            case CMS:
               cell.textLabel.text = @"CMS News";
               break;
            case ALICE:
               cell.textLabel.text = @"ALICE News";
               break;
            case LHCb:
               cell.textLabel.text = @"LHCb News";
               break;
            case LHC:
               cell.textLabel.text = @"LHC Data";
               default: break;
         }

         break;
      
      case 1:
         cell.textLabel.text = @"Event Display";
         break;
   }
   
   return cell;
}

#pragma mark - Table view delegate

//________________________________________________________________________________________
- (void) pushNewsControllerInto : (UINavigationController *) navigationController fromStoryboard : (UIStoryboard *) mainStoryboard
         withTitle : (NSString *) title feed : (NSString *) feed
{
   //TP: added aux. function instead of duplicated (4 times!!!) code.
   
   //TODO: It can happen, that we'll need something mode complex than NSString to specify multiple feeds if we have them later.
   
   if ([DeviceCheck deviceIsiPad]) {
      NewsGridViewController *newsViewController = [mainStoryboard instantiateViewControllerWithIdentifier : kExperimentNewsViewController];
      newsViewController.title = title;
      [newsViewController.aggregator addFeedForURL:[NSURL URLWithString : feed]];
      [newsViewController refresh];
      [navigationController pushViewController : newsViewController animated : YES];                    
   } else {
      NewsTableViewController *newsViewController = [mainStoryboard instantiateViewControllerWithIdentifier : kExperimentNewsTableViewController];
      newsViewController.title = title;
      [newsViewController.aggregator addFeedForURL:[NSURL URLWithString : feed]];
      [newsViewController refresh];
      [navigationController pushViewController : newsViewController animated : YES];
   }
}

//________________________________________________________________________________________
- (void) pushNewsControllerForExperiment
{
   //TP: split ugly code in didSelectRowAtIndexPath into news/event displays functions (still ugly :)).

   UIStoryboard *mainStoryboard = nil;
   UINavigationController *navigationController = nil;
   
   if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
      AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
      mainStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPad" bundle:nil];
      navigationController = [appDelegate.tabBarController.viewControllers objectAtIndex:TabIndexLive];
      ExperimentsViewController *experimentsVC = (ExperimentsViewController *)navigationController.topViewController;
      [experimentsVC.popoverController dismissPopoverAnimated : YES];
   } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
      mainStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
      navigationController = self.navigationController;
   }
   
   switch (self.experiment) {
      case ATLAS: {
         [self pushNewsControllerInto : navigationController fromStoryboard : mainStoryboard
         withTitle : @"ATLAS News" feed : @"http://pdg2.lbl.gov/atlasblog/?feed=rss2"];
         break;
      }
      case CMS: {
         [self pushNewsControllerInto : navigationController fromStoryboard : mainStoryboard
         withTitle : @"CMS News" feed : @"http://cms.web.cern.ch/news/category/265/rss.xml"];
         break;
      }
      case ALICE: {
         //TP: on iPhone, replace NewsGridViewController with NewsTableViewController.
         [self pushNewsControllerInto : navigationController fromStoryboard : mainStoryboard
         withTitle : @"ALICE News" feed : @"http://alicematters.web.cern.ch/rss.xml"];
         break;
      }
      case LHCb: {
         [self pushNewsControllerInto : navigationController fromStoryboard : mainStoryboard
         withTitle : @"LHCb News" feed : @"https://twitter.com/statuses/user_timeline/92522167.rss"];//TP: twitter???
         break;
      }
      case LHC: {
         EventDisplayViewController *eventViewController = [mainStoryboard instantiateViewControllerWithIdentifier:kEventDisplayViewController];
         [eventViewController addSourceWithDescription:nil URL:[NSURL URLWithString:@"http://vistar-capture.web.cern.ch/vistar-capture/lhc1.png"] boundaryRects:nil];
         [eventViewController addSourceWithDescription:nil URL:[NSURL URLWithString:@"http://vistar-capture.web.cern.ch/vistar-capture/lhc3.png"] boundaryRects:nil];
         [eventViewController addSourceWithDescription:nil URL:[NSURL URLWithString:@"http://vistar-capture.web.cern.ch/vistar-capture/lhccoord.png"] boundaryRects:nil];
         eventViewController.title = @"LHC Data";
         [navigationController pushViewController:eventViewController animated:YES];
         break;
      }
      default: break;
   }
}

//________________________________________________________________________________________
- (void) pushEventDisplayForExperiment
{
   //Part for event display.
   
   UIStoryboard *mainStoryboard = nil;
   UINavigationController *navigationController = nil;
   
   if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
      AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
      mainStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPad" bundle:nil];
      navigationController = [appDelegate.tabBarController.viewControllers objectAtIndex : TabIndexLive];
      ExperimentsViewController *experimentsVC = (ExperimentsViewController *)navigationController.topViewController;
      [experimentsVC.popoverController dismissPopoverAnimated : YES];
   } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
      mainStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
      navigationController = self.navigationController;
   }
   
   EventDisplayViewController *eventViewController = [mainStoryboard instantiateViewControllerWithIdentifier:kEventDisplayViewController];

   switch (self.experiment) {
      case ATLAS: {
         CGFloat largeImageDimension = 764.0;
         CGFloat smallImageDimension = 379.0;

         CGRect frontViewRect = CGRectMake(2.0, 2.0, largeImageDimension, largeImageDimension);
         NSDictionary *frontView = [NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithCGRect:frontViewRect], @"Rect", @"Front", @"Description", nil];

         CGRect sideViewRect = CGRectMake(2.0+4.0+largeImageDimension, 2.0, smallImageDimension, smallImageDimension);
         NSDictionary *sideView = [NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithCGRect:sideViewRect], @"Rect", @"Side", @"Description", nil];

         NSArray *boundaryRects = [NSArray arrayWithObjects:frontView, sideView, nil];
         [eventViewController addSourceWithDescription:nil URL:[NSURL URLWithString:@"http://atlas-live.cern.ch/live.png"] boundaryRects:boundaryRects];
         eventViewController.title = @"ATLAS";
         break;
      }

      case CMS: {
         [eventViewController addSourceWithDescription:@"3D Tower" URL:[NSURL URLWithString:@"http://cmsonline.cern.ch/evtdisp/3DTower.png"] boundaryRects:nil];
         [eventViewController addSourceWithDescription:@"3D RecHit" URL:[NSURL URLWithString:@"http://cmsonline.cern.ch/evtdisp/3DRecHit.png"] boundaryRects:nil];
         [eventViewController addSourceWithDescription:@"Lego" URL:[NSURL URLWithString:@"http://cmsonline.cern.ch/evtdisp/Lego.png"] boundaryRects:nil];
         [eventViewController addSourceWithDescription:@"RhoPhi" URL:[NSURL URLWithString:@"http://cmsonline.cern.ch/evtdisp/RhoPhi.png"] boundaryRects:nil];
         [eventViewController addSourceWithDescription:@"RhoZ" URL:[NSURL URLWithString:@"http://cmsonline.cern.ch/evtdisp/RhoZ.png"] boundaryRects:nil];
         eventViewController.title = @"CMS";
         break;
      }

      case ALICE: {
         PhotosGridViewController *photosViewController = [mainStoryboard instantiateViewControllerWithIdentifier:kALICEPhotoGridViewController];
         photosViewController.photoDownloader.url = [NSURL URLWithString:@"https://cdsweb.cern.ch/record/1305399/export/xm?ln=en"];
         [navigationController pushViewController : photosViewController animated : YES];
         return;
      }

      case LHCb: {
         CGRect cropRect = CGRectMake(0.0, 66.0, 1685.0, 811.0);
         NSDictionary *croppedView = [NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithCGRect:cropRect], @"Rect", @"Side", @"Description", nil];

         NSArray *boundaryRects = [NSArray arrayWithObjects:croppedView, nil];
         [eventViewController addSourceWithDescription:nil URL:[NSURL URLWithString:@"http://lbcomet.cern.ch/Online/Images/evdisp.jpg"] boundaryRects:boundaryRects];
         eventViewController.title = @"LHCB";
         break;
      }

      default: break;
   }

   [navigationController pushViewController : eventViewController animated : YES];
}

//________________________________________________________________________________________
- (void) tableView : (UITableView *) tableView didSelectRowAtIndexPath : (NSIndexPath *) indexPath
{
   if (!indexPath.row)
      [self pushNewsControllerForExperiment];
   else if (indexPath.row == 1)
      [self pushEventDisplayForExperiment];
   
   [tableView deselectRowAtIndexPath : indexPath animated : NO];
   //else - something else if we have.
}

@end
