#include <cassert>

#import "ExperimentLiveControllerIPHONE.h"
#import "EventDisplayViewController.h"
#import "PhotosGridViewController.h"
#import "NewsTableViewController.h"
#import "NewsGridViewController.h"
#import "MultiPageController.h"
#import "ContentProviders.h"
#import "ScrollSelector.h"
#import "DeviceCheck.h"
#import "AppDelegate.h"
#import "Constants.h"

#pragma mark - ExperimentLiveControllerIPHONE.

//________________________________________________________________________________________
@implementation ExperimentLiveControllerIPHONE {
   NSMutableArray *liveData;
   NSMutableArray *contentProviders;
}

@synthesize experiment;

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

         //Read news feeds, tweets.
         if ([catName isEqualToString : @"News"]) {
            if ((base = [data objectForKey : @"Feeds"])) {
               assert([base isKindOfClass : [NSArray class]] && "readLIVEData, object for 'Feeds' key must be of an array type");
               NSArray *feedProviders = (NSArray *)base;
               
               for (id info in feedProviders) {
                  assert([info isKindOfClass : [NSDictionary class]] && "readLIVEData, feed info must be a dictionary");
                  NSDictionary *feedInfo = (NSDictionary *)info;
                  FeedProvider *provider = [[FeedProvider alloc] initWith : feedInfo];
                  [liveData addObject : provider];
               }
            }
            
            //Some nice code duplicaiton here :)
            if ((base = [data objectForKey : @"Tweets"])) {
               assert([base isKindOfClass : [NSArray class]] && "readLIVEData, object for 'Tweets' key must be of an array type");
               NSArray *tweetProviders = (NSArray *)base;
               
               for (id info in tweetProviders) {
                  assert([info isKindOfClass : [NSDictionary class]] && "readLIVEData, feed info must be a dictionary");
                  NSDictionary *tweetInfo = (NSDictionary *)info;
                  FeedProvider *provider = [[FeedProvider alloc] initWith : tweetInfo];
                  [liveData addObject : provider];
               }
            }            
            
         } else if ([catName isEqualToString:@"Event display"]) {
            //
         } else if ([catName isEqualToString:@"DAQ"]) {
            //
         }
      }
   }
}

//________________________________________________________________________________________
- (void) loadMultiPageControllerWithSelectedItem : (NSInteger) selected
{
   //
   assert(selected >= 0 && "loadMultipageControllerWithSelectedItem:, parameter selected must be non-negative");
   
   MultiPageController * const controller = [[MultiPageController alloc] initWithNibName : @"MultiPageController" bundle : nil];

   NSMutableArray *itemNames = [[NSMutableArray alloc] init];
   for (NSObject<ContentProvider> *provider in liveData)
      [itemNames addObject : [provider categoryName]];
   
   [self.navigationController pushViewController : controller animated : YES];

   [controller preparePagesFor : itemNames];

   
   for (NSObject<ContentProvider> *provider in liveData)
      [provider addPageWithContentTo : controller];
   
   [controller selectPage : selected];
}

//________________________________________________________________________________________
- (void) viewWillAppear : (BOOL) animated
{
   self.navigationController.navigationBarHidden = NO;

   switch (experiment) {
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

   if (experiment != LHC)
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
   if (experiment == LHC)
      return 1;
   
   assert(liveData && [liveData count] && "tableView:numberOfRowsInSection:, no LIVE data found");

   return [liveData count] + 1;//1 for event display (to be changed).
}

//________________________________________________________________________________________
- (UITableViewCell *) tableView : (UITableView *) tableView cellForRowAtIndexPath : (NSIndexPath *) indexPath
{
   static NSString *CellIdentifier = @"Cell";
   UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier : CellIdentifier];
   if (!cell)
      cell = [[UITableViewCell alloc] initWithStyle : UITableViewCellStyleDefault reuseIdentifier : CellIdentifier];

   if (experiment != LHC) {
      //TODO: at the moment, the new experimental controller/view is only for CMS.
      //<= : [liveData count] + 1 for event display.
      assert(indexPath.row <= [liveData count] && "tableView:cellForRowAtIndexPath:, indexPath.row is out of bounds");
      
      if (indexPath.row < [liveData count]) {
         NSObject<ContentProvider> *provider = [liveData objectAtIndex : indexPath.row];
         cell.textLabel.text = [provider categoryName];
      } else
         cell.textLabel.text = @"Event Display";
      
      return cell;
   }

   //The special case for LHC.
   assert(indexPath.row == 0 && "tableView:cellForRowAtIndexPath:, intexPath.row is out of bounds");
   cell.textLabel.text = @"LHC Data";

   return cell;
}

#pragma mark - Table view delegate

//________________________________________________________________________________________
- (void) pushEventDisplayForExperiment
{
   //Part for event display.
   
   UIStoryboard * const mainStoryboard = [UIStoryboard storyboardWithName : @"MainStoryboard_iPhone" bundle : nil];
   EventDisplayViewController * const eventViewController = [mainStoryboard instantiateViewControllerWithIdentifier : kEventDisplayViewController];

   switch (experiment) {
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
         [self.navigationController pushViewController : photosViewController animated : YES];
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

   [self.navigationController pushViewController : eventViewController animated : YES];
}

//________________________________________________________________________________________
- (void) tableView : (UITableView *) tableView didSelectRowAtIndexPath : (NSIndexPath *) indexPath
{
   [tableView deselectRowAtIndexPath : indexPath animated : NO];

   if (experiment != LHC) {
      assert(indexPath.row >= 0 && "tableView:didSelectRowAtIndexPath:, indexPath.row is negative");//WTF??
      if (indexPath.row < [liveData count])
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

      assert(experiment == LHC && "pushNewsControllerForExperiment, must called ONLY for LHC");

      EventDisplayViewController *eventViewController = [mainStoryboard instantiateViewControllerWithIdentifier:kEventDisplayViewController];
      [eventViewController addSourceWithDescription : nil URL : [NSURL URLWithString : @"http://vistar-capture.web.cern.ch/vistar-capture/lhc1.png"] boundaryRects : nil];
      [eventViewController addSourceWithDescription : nil URL : [NSURL URLWithString : @"http://vistar-capture.web.cern.ch/vistar-capture/lhc3.png"] boundaryRects : nil];
      [eventViewController addSourceWithDescription : nil URL : [NSURL URLWithString : @"http://vistar-capture.web.cern.ch/vistar-capture/lhccoord.png"] boundaryRects : nil];
      eventViewController.title = @"LHC Data";
      [navigationController pushViewController : eventViewController animated : YES];
   }
}

//This is a temporary solution (well, ... all temporary hacks tend to become permanent :)) )
//For live event data we do not have any generic
//data structures or sources or data itself.
//So we do different and quite ugly tricks to
//have anything at all and still trying to fit this into the general picture.

//________________________________________________________________________________________
- (void) addLiveEventsPage
{
   //
}

@end
