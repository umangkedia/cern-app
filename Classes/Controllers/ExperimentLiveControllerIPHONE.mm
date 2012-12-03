#include <cassert>

#import "ExperimentLiveControllerIPHONE.h"
#import "EventDisplayViewController.h"
#import "ExperimentsViewController.h"
#import "PhotosGridViewController.h"
#import "LiveEventTableController.h"
#import "NewsTableViewController.h"
#import "MultiPageController.h"
#import "ContentProviders.h"
#import "ScrollSelector.h"
#import "DeviceCheck.h"
#import "AppDelegate.h"
#import "Constants.h"

#pragma mark - ExperimentLiveControllerIPHONE.

//________________________________________________________________________________________
@implementation ExperimentLiveControllerIPHONE {
   NSMutableArray *news;//different news feeds, tweets, etc.
   NSMutableArray *liveEvents; //Event displays, DAQs, etc.
}

@synthesize experiment;

//________________________________________________________________________________________
- (id) initWithStyle : (UITableViewStyle) style
{
   using namespace CernAPP;

   if (self = [super initWithStyle : style]) {
      experiment = LHCExperiment::LHC;
   }
   
   return self;
}

//________________________________________________________________________________________
- (void) viewDidLoad
{
   [super viewDidLoad];
}

#pragma mark - Methods to read "LIVE" data from the plist.

//________________________________________________________________________________________
- (void) readNewsFeedsInfo : (NSArray *) feeds
{
   assert(feeds != nil && "readNewsFeedsInfo:, feeds parameter is nil");
   
   for (id info in feeds) {
      assert([info isKindOfClass : [NSDictionary class]] && "readLIVEData, feed info must be a dictionary");
      NSDictionary *feedInfo = (NSDictionary *)info;
      FeedProvider *provider = [[FeedProvider alloc] initWith : feedInfo];
      [news addObject : provider];
   }
}

//________________________________________________________________________________________
- (void) readLIVEEventsInfo : (NSArray *) images
{
   assert(images != nil && "readLIVEEventsInfo, images parameter is nil");
   LiveEventsProvider *eventProvider = [[LiveEventsProvider alloc] initWith : images forExperiment : experiment];
   [liveEvents addObject : eventProvider];
}

//________________________________________________________________________________________
- (void) readLIVEData
{
   NSString * const path = [[NSBundle mainBundle] pathForResource : @"CERNLive" ofType : @"plist"];
   NSDictionary * const plistDict = [NSDictionary dictionaryWithContentsOfFile : path];
   assert(plistDict != nil && "readLIVEData:, no dictionary or CERNLive.plist found");

   if (!news)
      news = [[NSMutableArray alloc] init];
   else
      [news removeAllObjects];

   if (!liveEvents)
      liveEvents = [[NSMutableArray alloc] init];
   else
      [liveEvents removeAllObjects];

   if (id base = [plistDict objectForKey : self.title]) {
      assert([base isKindOfClass : [NSArray class]] && "readLIVEData:, entry for experiment must have NSArray type");
      NSArray * const dataSource = (NSArray *)base;
      
      for (id arrayItem in dataSource) {
         assert([arrayItem isKindOfClass : [NSDictionary class]] && "readLIVEData:, array of dictionaries expected");
         NSDictionary * const data = (NSDictionary *)arrayItem;
         
         id base = [data objectForKey : @"Category name"];
         assert(base != nil && [base isKindOfClass : [NSString class]] && "readLIVEData:, string key 'Category name' was not found");
         
         NSString *catName = (NSString *)base;

         //Read news feeds, tweets.
         if ([catName isEqualToString : @"News"]) {
            if ((base = [data objectForKey : @"Feeds"])) {
               assert([base isKindOfClass : [NSArray class]] && "readLIVEData, object for 'Feeds' key must be of an array type");
               [self readNewsFeedsInfo : (NSArray *)base];
            }
            //Some nice code duplicaiton here :)
            if ((base = [data objectForKey : @"Tweets"])) {
               assert([base isKindOfClass : [NSArray class]] && "readLIVEData, object for 'Tweets' key must be of an array type");
               [self readNewsFeedsInfo : (NSArray *)base];
            }
         } else if ([catName isEqualToString : @"Event display"]) {
            if ((base = [data objectForKey : @"Images"])) {
               assert([base isKindOfClass : [NSArray class]] && "readLIVEData, object for 'Images' key must of an array type");
               [self readLIVEEventsInfo : (NSArray *)base];
            }
         } else if ([catName isEqualToString : @"DAQ"]) {
            //
         }
      }
   }
}

//________________________________________________________________________________________
- (void) loadMultiPageControllerWithSelectedItem : (NSInteger) selected
{
   using namespace CernAPP;

   assert(selected >= 0 && "loadMultiPageControllerWithSelectedItem:, parameter selected must be non-negative");
   assert(experiment != LHCExperiment::LHC && "loadMultiPageControllerWithSelectedItem:, not implemented for LHC");
   
   MultiPageController * const controller = [[MultiPageController alloc] initWithNibName : @"MultiPageController" bundle : nil];

   NSMutableArray * const itemNames = [[NSMutableArray alloc] init];
   for (NSObject<ContentProvider> *provider in news)
      [itemNames addObject : [provider categoryName]];
   
   //As usually, special case.
   if (experiment != LHCExperiment::ALICE)
      [itemNames addObject : @"LIVE Events"];
   
   
   [self.navigationController pushViewController : controller animated : YES];
   [controller preparePagesFor : itemNames];

   for (NSObject<ContentProvider> *provider in news)
      [provider addPageWithContentTo : controller];
   
   //Now, as usually, non-generic part.
   if (experiment != LHCExperiment::ALICE) {
      assert([liveEvents count] && "loadMultiPageControllerWithSelectedItem:, no live events found");
      LiveEventsProvider *provider = (LiveEventsProvider *)[liveEvents objectAtIndex : 0];
      [provider addPageWithContentTo : controller];
   }
   
   [controller selectPage : selected];
}

//________________________________________________________________________________________
- (void) viewWillAppear : (BOOL) animated
{
   using namespace CernAPP;

   self.navigationController.navigationBarHidden = NO;
   self.title = [NSString stringWithFormat : @"%s", ExperimentName(experiment)];
   if (experiment != LHCExperiment::LHC)//LHC is not an experiment, we treat it in a special way.
      [self readLIVEData];
}

//________________________________________________________________________________________
- (void) viewDidUnload
{
   [super viewDidUnload];
}

//________________________________________________________________________________________
- (BOOL) shouldAutorotateToInterfaceOrientation : (UIInterfaceOrientation)interfaceOrientation
{
   return NO;
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
   using namespace CernAPP;
   
   if (experiment == LHCExperiment::LHC)
      return 1;
   
   assert(news && [news count] && "tableView:numberOfRowsInSection:, no LIVE data found");

   return [news count] + 1;//1 for event display (to be changed).
}

//________________________________________________________________________________________
- (UITableViewCell *) tableView : (UITableView *) tableView cellForRowAtIndexPath : (NSIndexPath *) indexPath
{
   using namespace CernAPP;

   static NSString *CellIdentifier = @"Cell";
   UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier : CellIdentifier];
   if (!cell)
      cell = [[UITableViewCell alloc] initWithStyle : UITableViewCellStyleDefault reuseIdentifier : CellIdentifier];

   if (experiment == LHCExperiment::ALICE) {
      //I hate this. Special case again.
      assert(indexPath.row >= 0 && indexPath.row <= [news count] && "tableView:cellForRowAtIndexPath:, indexPath.row is out of bounds");
      
      if (indexPath.row < [news count]) {
         NSObject<ContentProvider> *provider = (NSObject<ContentProvider> *)[news objectAtIndex : indexPath.row];
         cell.textLabel.text = provider.categoryName;
      } else
         cell.textLabel.text = @"Live Events";

   } else if (experiment != LHCExperiment::LHC) {
      //TODO: at the moment, the new experimental controller/view is only for CMS.
      //<= : [liveData count] + 1 for event display.
      assert(indexPath.row >= 0 && indexPath.row < [news count] + [liveEvents count] && "tableView:cellForRowAtIndexPath:, indexPath.row is out of bounds");
      
      NSObject<ContentProvider> *provider = nil;
      
      if (indexPath.row < [news count])
         provider = [news objectAtIndex : indexPath.row];
      else {
         const NSInteger row = indexPath.row - [news count];
         provider = [liveEvents objectAtIndex : row];
      }
      
      cell.textLabel.text = [provider categoryName];
   } else {
      //The special case for LHC.
      assert(indexPath.row == 0 && "tableView:cellForRowAtIndexPath:, intexPath.row is out of bounds");
      cell.textLabel.text = @"LHC Data";
   }

   return cell;
}

#pragma mark - Table view delegate

//________________________________________________________________________________________
- (void) pushEventDisplayForExperiment
{
   //Part for event display.
   using namespace CernAPP;
   
   UIStoryboard * const mainStoryboard = [UIStoryboard storyboardWithName : @"MainStoryboard_iPhone" bundle : nil];
   EventDisplayViewController * const eventViewController = [mainStoryboard instantiateViewControllerWithIdentifier : kEventDisplayViewController];

   switch (experiment) {
      case LHCExperiment::ATLAS: {
/*         CGRect frontViewRect = CGRectMake(2.0, 2.0, largeImageDimension, largeImageDimension);
         NSDictionary *frontView = [NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithCGRect:frontViewRect], @"Rect", @"Front", @"Description", nil];

         CGRect sideViewRect = CGRectMake(2.0+4.0+largeImageDimension, 2.0, smallImageDimension, smallImageDimension);
         NSDictionary *sideView = [NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithCGRect:sideViewRect], @"Rect", @"Side", @"Description", nil];

         NSArray *boundaryRects = [NSArray arrayWithObjects:frontView, sideView, nil];
         [eventViewController addSourceWithDescription:nil URL:[NSURL URLWithString:@"http://atlas-live.cern.ch/live.png"] boundaryRects:boundaryRects];
         eventViewController.title = @"ATLAS";*/
         break;
      }

      case LHCExperiment::CMS: {
         [eventViewController addSourceWithDescription:@"3D Tower" URL:[NSURL URLWithString:@"http://cmsonline.cern.ch/evtdisp/3DTower.png"] boundaryRects:nil];
         [eventViewController addSourceWithDescription:@"3D RecHit" URL:[NSURL URLWithString:@"http://cmsonline.cern.ch/evtdisp/3DRecHit.png"] boundaryRects:nil];
         [eventViewController addSourceWithDescription:@"Lego" URL:[NSURL URLWithString:@"http://cmsonline.cern.ch/evtdisp/Lego.png"] boundaryRects:nil];
         [eventViewController addSourceWithDescription:@"RhoPhi" URL:[NSURL URLWithString:@"http://cmsonline.cern.ch/evtdisp/RhoPhi.png"] boundaryRects:nil];
         [eventViewController addSourceWithDescription:@"RhoZ" URL:[NSURL URLWithString:@"http://cmsonline.cern.ch/evtdisp/RhoZ.png"] boundaryRects:nil];
         eventViewController.title = @"CMS";
         break;
      }

      case LHCExperiment::ALICE: {
         PhotosGridViewController *photosViewController = [mainStoryboard instantiateViewControllerWithIdentifier:kALICEPhotoGridViewController];
         photosViewController.photoDownloader.url = [NSURL URLWithString:@"https://cdsweb.cern.ch/record/1305399/export/xm?ln=en"];
         [self.navigationController pushViewController : photosViewController animated : YES];
         return;
      }

      case LHCExperiment::LHCb: {
         CGRect cropRect = CGRectMake(0.0, 66.0, 1685.0, 811.0);
         NSDictionary *croppedView = [NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithCGRect:cropRect], @"Rect", @"Side", @"Description", nil];

         NSArray *boundaryRects = [NSArray arrayWithObjects:croppedView, nil];
         [eventViewController addSourceWithDescription:nil URL:[NSURL URLWithString:@"http://lbcomet.cern.ch/Online/Images/evdisp.jpg"] boundaryRects:boundaryRects];
         eventViewController.title = @"LHCB";
         break;
      }

      default: break;
   }

   [self.navigationController pushViewController : eventViewController animated : YES];
}

//________________________________________________________________________________________
- (void) tableView : (UITableView *) tableView didSelectRowAtIndexPath : (NSIndexPath *) indexPath
{
   using namespace CernAPP;

   [tableView deselectRowAtIndexPath : indexPath animated : NO];

   if (experiment != LHCExperiment::LHC) {
      assert(indexPath.row >= 0 && "tableView:didSelectRowAtIndexPath:, indexPath.row is negative");//WTF??
      if (indexPath.row < [news count])
         [self loadMultiPageControllerWithSelectedItem:indexPath.row];
      else
         [self pushEventDisplayForExperiment];
   } else {
      //LHC is still a "special" case :(
      assert(indexPath.row == 0 && "tableView:didSelectRowAtIndexPath:, indexPath.row must be 0");
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

      assert(experiment == LHCExperiment::LHC && "pushNewsControllerForExperiment, must called ONLY for LHC");

      EventDisplayViewController *eventViewController = [mainStoryboard instantiateViewControllerWithIdentifier:kEventDisplayViewController];
      [eventViewController addSourceWithDescription : nil URL : [NSURL URLWithString : @"http://vistar-capture.web.cern.ch/vistar-capture/lhc1.png"] boundaryRects : nil];
      [eventViewController addSourceWithDescription : nil URL : [NSURL URLWithString : @"http://vistar-capture.web.cern.ch/vistar-capture/lhc3.png"] boundaryRects : nil];
      [eventViewController addSourceWithDescription : nil URL : [NSURL URLWithString : @"http://vistar-capture.web.cern.ch/vistar-capture/lhccoord.png"] boundaryRects : nil];
      eventViewController.title = @"LHC Data";
      [navigationController pushViewController : eventViewController animated : YES];
   }
}

@end
