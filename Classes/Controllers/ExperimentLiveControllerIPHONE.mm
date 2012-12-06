#include <cassert>

#import "ExperimentLiveControllerIPHONE.h"
#import "EventDisplayViewController.h"
#import "PhotosGridViewController.h"
#import "LiveEventTableController.h"
#import "MultiPageController.h"
#import "ContentProviders.h"
#import "GuiAdjustment.h"
#import "DeviceCheck.h"

#pragma mark - ExperimentLiveControllerIPHONE.

//________________________________________________________________________________________
@implementation ExperimentLiveControllerIPHONE {
   NSMutableArray *liveData; //Event displays, DAQs, news, etc.
}

@synthesize experiment;

//________________________________________________________________________________________
- (id) initWithStyle : (UITableViewStyle) style
{
   using namespace CernAPP;

   if (self = [super initWithStyle : style])
      experiment = LHCExperiment::LHC;
   
   return self;
}

//________________________________________________________________________________________
- (void) viewDidLoad
{
   [super viewDidLoad];
   CernAPP::ResetBackButton(self, @"back_button_flat.png");
}

#pragma mark - Methods to read "LIVE" data from the plist.

//________________________________________________________________________________________
- (bool) readNewsFeeds : (NSArray *) feeds
{
   assert(feeds != nil && "readNewsFeeds:, parameter 'feeds' is nil");

   bool result = false;
   
   for (id info in feeds) {
      assert([info isKindOfClass : [NSDictionary class]] && "readNewsFeed, feed info must be a dictionary");
      NSDictionary *feedInfo = (NSDictionary *)info;
      FeedProvider *provider = [[FeedProvider alloc] initWith : feedInfo];
      [liveData addObject : provider];
      result = true;
   }
   
   return result;
}

//________________________________________________________________________________________
- (bool) readNews : (NSDictionary *) dataEntry
{
   assert(dataEntry != nil && "readNews:, parameter 'dataEntry' is nil");

   id base = [dataEntry objectForKey : @"Category name"];
   assert(base != nil && [base isKindOfClass : [NSString class]] && "readNews:, string key 'Category name' was not found");

   bool result = false;
   
   NSString *catName = (NSString *)base;
   if ([catName isEqualToString : @"News"]) {
      if ((base = [dataEntry objectForKey : @"Feeds"])) {
         assert([base isKindOfClass : [NSArray class]] && "readNews:, object for 'Feeds' key must be of an array type");
         result = [self readNewsFeeds : (NSArray *)base];
      }

      if ((base = [dataEntry objectForKey : @"Tweets"])) {
         assert([base isKindOfClass : [NSArray class]] && "readNews:, object for 'Tweets' key must be of an array type");
         result |= [self readNewsFeeds : (NSArray *)base];
      }
   }
   
   return result;
}

//________________________________________________________________________________________
- (bool) readLIVEImages : (NSDictionary *) dataEntry
{
   assert(dataEntry != nil && "readLIVEImages, parameter 'dataEntry' is nil");

   if ([dataEntry objectForKey : @"Images"]) {
      assert([[dataEntry objectForKey : @"Images"] isKindOfClass : [NSArray class]] &&
             "readLIVEImages:, object for 'Images' key must be of NSArray type");

      NSArray *images = (NSArray *)[dataEntry objectForKey:@"Images"];
      assert([images count] && "readLIVEImages, array of images is empty");
      
      LiveEventsProvider * const provider = [[LiveEventsProvider alloc] initWith : images forExperiment : experiment];
      [liveData addObject : provider];
      
      if ([dataEntry objectForKey : @"Category name"]) {
         assert([[dataEntry objectForKey : @"Category name"] isKindOfClass : [NSString class]] &&
                "readLIVEImages, 'Category Name' for the data entry is not of NSString type");
         provider.categoryName = (NSString *)[dataEntry objectForKey : @"Category name"];
      }

      return true;
   }
   
   return false;
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
         
         if ([self readNews : data])
            continue;
         
         if ([self readLIVEImages : data])
            continue;
         
         //someting else can be here.
      }
   }
}

//________________________________________________________________________________________
- (void) loadMultiPageControllerWithSelectedItem : (NSInteger) selected
{
   using namespace CernAPP;

   assert(selected >= 0 && "loadMultiPageControllerWithSelectedItem:, parameter selected must be non-negative");
   
   MultiPageController * const controller = [[MultiPageController alloc] initWithNibName : @"MultiPageController" bundle : nil];

   NSMutableArray * const itemNames = [[NSMutableArray alloc] init];
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
   using namespace CernAPP;

   self.navigationController.navigationBarHidden = NO;
   self.title = [NSString stringWithFormat : @"%s", ExperimentName(experiment)];

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
   
   assert(liveData && [liveData count] && "tableView:numberOfRowsInSection:, no LIVE data found");

   if (experiment == LHCExperiment::ALICE)
      return [liveData count] + 1;//There is no normal "Live Events" for ALICE.

   return [liveData count];
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
      assert(indexPath.row >= 0 && indexPath.row <= [liveData count] && "tableView:cellForRowAtIndexPath:, indexPath.row is out of bounds");
      
      if (indexPath.row < [liveData count]) {
         NSObject<ContentProvider> *provider = (NSObject<ContentProvider> *)[liveData objectAtIndex : indexPath.row];
         cell.textLabel.text = provider.categoryName;
      } else
         cell.textLabel.text = @"Live Events";

   } else {
      //TODO: at the moment, the new experimental controller/view is only for CMS.
      //<= : [liveData count] + 1 for event display.
      assert(indexPath.row >= 0 && indexPath.row < [liveData count] && "tableView:cellForRowAtIndexPath:, indexPath.row is out of bounds");
      
      NSObject<ContentProvider> * const provider = (NSObject<ContentProvider> *)[liveData objectAtIndex : indexPath.row];
      cell.textLabel.text = [provider categoryName];
   }

   return cell;
}

#pragma mark - Table view delegate

//________________________________________________________________________________________
- (void) pushEventDisplayForExperiment
{
   using namespace CernAPP;

   assert(experiment == LHCExperiment::ALICE && "pushEventDisplayForExperiment, can be called only for ALICE");

   UIStoryboard * const mainStoryboard = [UIStoryboard storyboardWithName : @"MainStoryboard_iPhone" bundle : nil];
   PhotosGridViewController *photosViewController = [mainStoryboard instantiateViewControllerWithIdentifier : ALICEPhotoGridViewControllerID];
   photosViewController.photoDownloader.url = [NSURL URLWithString : @"https://cdsweb.cern.ch/record/1305399/export/xm?ln=en"];
   [self.navigationController pushViewController : photosViewController animated : YES];
}

//________________________________________________________________________________________
- (void) tableView : (UITableView *) tableView didSelectRowAtIndexPath : (NSIndexPath *) indexPath
{
   using namespace CernAPP;

   [tableView deselectRowAtIndexPath : indexPath animated : NO];

   if (experiment == LHCExperiment::ALICE) {
      assert(indexPath.row >= 0 && indexPath.row <= [liveData count] && "tableView:didSelectRowAtIndexPath:, indexPath.row is out of bounds");
      
      if (indexPath.row < [liveData count])
         [self loadMultiPageControllerWithSelectedItem : indexPath.row];
      else
         [self pushEventDisplayForExperiment];
      
   } else {
      assert(indexPath.row >= 0 && indexPath.row < [liveData count] && "tableView:didSelectRowAtIndexPath:, indexPath.row is out of bounds");
      [self loadMultiPageControllerWithSelectedItem : indexPath.row];
   }
}

#pragma mark - Navigation (since we replace left navbarbutton).

//________________________________________________________________________________________
- (void) backButtonPressed
{
   [self.navigationController popViewControllerAnimated : YES];
}


@end
