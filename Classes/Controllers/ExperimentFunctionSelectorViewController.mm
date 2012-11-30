//
//  ExperimentDetailTableViewController.m
//  CERN App
//
//  Created by Eamon Ford on 7/20/12.
//  Copyright (c) 2012 CERN. All rights reserved.
//

#include <cassert>

#import "ExperimentFunctionSelectorViewController.h"
#import "EventDisplayViewController.h"
#import "PhotosGridViewController.h"
#import "NewsTableViewController.h"
#import "NewsGridViewController.h"
#import "MultiPageController.h"
#import "ScrollSelector.h"
#import "DeviceCheck.h"
#import "AppDelegate.h"
#import "Constants.h"


@implementation ExperimentFunctionSelectorViewController

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
         break;//do not read LIVE data for LHC for the moment.
      default: break;
   }
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
   return YES;
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
      default:
         assert(0 && "tableView:cellForRowAtIndexPath:, bad index");
   }
   
   return cell;
}

#pragma mark - Table view delegate

//________________________________________________________________________________________
- (void) pushNewsControllerInto : (UINavigationController *) navigationController fromStoryboard : (UIStoryboard *) mainStoryboard
         withTitle : (NSString *) title feed : (NSString *) feed
{
   NewsGridViewController *newsViewController = [mainStoryboard instantiateViewControllerWithIdentifier : kExperimentNewsViewController];
   newsViewController.title = title;
   [newsViewController.aggregator addFeedForURL:[NSURL URLWithString : feed]];
   [newsViewController refresh];
   [navigationController pushViewController : newsViewController animated : YES];                    
}

//________________________________________________________________________________________
- (void) pushNewsControllerForExperiment
{
   //TP: split ugly code in didSelectRowAtIndexPath into news/event displays functions (still ugly :)).

   UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPad" bundle:nil];
   AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
   UINavigationController *navigationController = [appDelegate.tabBarController.viewControllers objectAtIndex:TabIndexLive];
   ExperimentsViewController *experimentsVC = (ExperimentsViewController *)navigationController.topViewController;
   [experimentsVC.popoverController dismissPopoverAnimated : YES];
   
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
   AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
   UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPad" bundle:nil];
   UINavigationController *navigationController = [appDelegate.tabBarController.viewControllers objectAtIndex : TabIndexLive];
   ExperimentsViewController *experimentsVC = (ExperimentsViewController *)navigationController.topViewController;
   [experimentsVC.popoverController dismissPopoverAnimated : YES];   
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
   [tableView deselectRowAtIndexPath : indexPath animated : NO];

   if (!indexPath.row)
      [self pushNewsControllerForExperiment];
   else if (indexPath.row == 1)
      [self pushEventDisplayForExperiment];
}

@end
