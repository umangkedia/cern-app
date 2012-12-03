#import <cassert>

#import "LiveEventTableController.h"
#import "NewsTableViewController.h"
#import "MultiPageController.h"
#import "ContentProviders.h"
#import "Constants.h"
#import "KeyVal.h"

namespace {

//ATLAS' "magic" to create images.

}


@implementation FeedProvider {
   NSString *feedName;
   NSString *feed;
}

//________________________________________________________________________________________
- (id) initWith : (NSDictionary *) feedInfo
{
   assert(feedInfo != nil && "initWith:, feedInfo parameter is nil");

   if (self = [super init]) {
      id base = [feedInfo objectForKey : @"Name"];
      assert(base != nil && [base isKindOfClass : [NSString class]] && "initWith:, object for 'Name' was not found or is not of string type");
      
      feedName = (NSString *)base;

      base = [feedInfo objectForKey : @"Url"];
      assert(base != nil && [base isKindOfClass : [NSString class]] && "initWith:, object for 'Url' was not found or is not of string type");
      
      feed = (NSString *)base;
   }
   
   return self;
}

//________________________________________________________________________________________
- (NSString *) categoryName
{
   return feedName;
}

//________________________________________________________________________________________
- (UIImage *) categoryImage
{
   return nil;
}

//________________________________________________________________________________________
- (void) addPageWithContentTo : (MultiPageController *) controller
{
   assert(controller != nil && "addPageWithContentTo:, controller parameter is nil");

   UIStoryboard * const mainStoryboard = [UIStoryboard storyboardWithName : @"MainStoryboard_iPhone" bundle : nil];
   assert(mainStoryboard != nil && "addPageWithContentTo:, storyboard is nil");


   NewsTableViewController *newsViewController = [mainStoryboard instantiateViewControllerWithIdentifier : kExperimentFeedTableViewController];
   //Storyboard generates an exception, if it's not able to create a controller.

   [newsViewController.aggregator addFeedForURL : [NSURL URLWithString : feed]];
   newsViewController.navigationControllerForArticle = controller.navigationController;
   
   [controller addPageFor : newsViewController];
}

//________________________________________________________________________________________
- (void) loadControllerTo : (UINavigationController *)controller
{
   //Noop.
}

@end

@implementation LiveEventsProvider {
   NSMutableArray *liveEvents;
   CernAPP::LHCExperiment experiment;
}

//________________________________________________________________________________________
- (id) initWith : (NSArray *) images forExperiment : (CernAPP::LHCExperiment) e
{
   using namespace CernAPP;

   assert(images != nil && "initWith:, images parameter is nil");
   
   if (self = [super init]) {
      liveEvents = [[NSMutableArray alloc] init];
   
      for (id base in images) {
         assert([base isKindOfClass : [NSDictionary class]] && "initWith:, array of dictionaries expected");
         
         NSDictionary * const imageInfo = (NSDictionary *)base;
         
         assert([[imageInfo objectForKey : @"Name"] isKindOfClass : [NSString class]] &&
                "initWith:, object for key 'Name' is either not found or has a wrong type");
         assert([[imageInfo objectForKey : @"Image"] isKindOfClass : [NSString class]] &&
                "initWith:, object for key 'Image' is either not found or has a wrong type");

         KeyVal * const imageDesc = [[KeyVal alloc] init];
         imageDesc.key = (NSString *)[imageInfo objectForKey : @"Name"];
         imageDesc.val = (NSString *)[imageInfo objectForKey : @"Image"];

         [liveEvents addObject : imageDesc];
      }
      
      experiment = e;
   }
   
   return self;
}

//________________________________________________________________________________________
- (NSString *) categoryName
{
   return @"Live Events";
}

//________________________________________________________________________________________
- (UIImage *) categoryImage
{
   return nil;
}

//________________________________________________________________________________________
- (void) addPageWithContentTo : (MultiPageController *) controller
{
   using namespace CernAPP;
   
   UIStoryboard * const mainStoryboard = [UIStoryboard storyboardWithName : @"MainStoryboard_iPhone" bundle : nil];
   LiveEventTableController * const eventViewController = [mainStoryboard instantiateViewControllerWithIdentifier : liveEventTableViewControllerID];
   NSString * const experimentName = [NSString stringWithFormat : @"%s", ExperimentName(experiment)];
 
   if (experiment == LHCExperiment::ATLAS) {
      assert([liveEvents count] && "addPageWithContentTo:, no live events found");
      assert(sizeof CernAPP::imageBoundsForATLAS / sizeof(CGRect) == 2 && "addPageWithContentTo:, 2 images expected for ATLAS");

      NSArray * const names = @[@"Front view", @"Side view"];
      KeyVal * const pair = (KeyVal *)[liveEvents objectAtIndex : 0];
      [eventViewController setTableContentsFromImage : (NSString *)pair.val cellNames : names imageBounds : imageBoundsForATLAS experimentName : @"ATLAS"];
   } else if (experiment == LHCExperiment::LHCb) {
      assert([liveEvents count] && "addPageWithContentTo:, no live events found");
      NSArray * const names = @[@"Side view"];
      KeyVal * const pair = (KeyVal *)[liveEvents objectAtIndex : 0];
      [eventViewController setTableContentsFromImage : (NSString *)pair.val cellNames : names imageBounds : &imageBoundsForLHCb experimentName : @"LHCb"];
   } else {
      [eventViewController setTableContents:liveEvents experimentName : experimentName];
   }
   
  [controller addPageFor : eventViewController];
}

//________________________________________________________________________________________
- (void) loadControllerTo : (UINavigationController *) controller
{
   (void) controller;
}

@end
