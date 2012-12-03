#import <cassert>

#import "EventDisplayViewController.h"
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
   LiveEventTableController * const eventViewController = [mainStoryboard instantiateViewControllerWithIdentifier : LIVEEventTableViewControllerID];
   NSString * const experimentName = [NSString stringWithFormat : @"%s", ExperimentName(experiment)];
 
   if (experiment == LHCExperiment::ATLAS) {
      assert([liveEvents count] && "addPageWithContentTo:, no live events found");
      assert(sizeof CernAPP::imageBoundsForATLAS / sizeof(CGRect) == 2 && "addPageWithContentTo:, 2 images expected for ATLAS");

      NSArray * const names = @[@"Front view", @"Side view"];
      KeyVal * const pair = (KeyVal *)[liveEvents objectAtIndex : 0];
      [eventViewController setTableContentsFromImage : (NSString *)pair.val cellNames : names imageBounds : imageBoundsForATLAS experimentName : experimentName];
   } else if (experiment == LHCExperiment::LHCb) {
      assert([liveEvents count] && "addPageWithContentTo:, no live events found");
      NSArray * const names = @[@"Side view"];
      KeyVal * const pair = (KeyVal *)[liveEvents objectAtIndex : 0];
      [eventViewController setTableContentsFromImage : (NSString *)pair.val cellNames : names imageBounds : &imageBoundsForLHCb experimentName : experimentName];
   } else {
      [eventViewController setTableContents:liveEvents experimentName : experimentName];
   }
   
   [controller addPageFor : eventViewController];
}

//________________________________________________________________________________________
- (void) loadControllerTo : (UINavigationController *) controller
{
   [self loadControllerTo : controller selectedImage : 0];
}

//________________________________________________________________________________________
- (void) loadControllerTo : (UINavigationController *) controller selectedImage : (unsigned int) selected
{
   using namespace CernAPP;
   
   (void) selected;

   assert(controller != nil && "loadControllerTo:, parameter 'controller' is nil");
   
   UIStoryboard * const mainStoryboard = [UIStoryboard storyboardWithName : @"MainStoryboard_iPhone" bundle : nil];
   EventDisplayViewController * const eventViewController = [mainStoryboard instantiateViewControllerWithIdentifier : EventDisplayViewControllerID];
   
   switch (experiment) {
   case LHCExperiment::ATLAS:
      {
         NSDictionary * const frontView = [NSDictionary dictionaryWithObjectsAndKeys :
                                                        [NSValue valueWithCGRect : imageBoundsForATLAS[0]],
                                                        @"Rect", @"Front", @"Description", nil];
         NSDictionary * const sideView = [NSDictionary dictionaryWithObjectsAndKeys :
                                                       [NSValue valueWithCGRect : imageBoundsForATLAS[1]],
                                                       @"Rect", @"Side", @"Description", nil];

         NSArray * const boundaryRects = [NSArray arrayWithObjects : frontView, sideView, nil];
         [eventViewController addSourceWithDescription : nil URL : [NSURL URLWithString : @"http://atlas-live.cern.ch/live.png"] boundaryRects : boundaryRects];
      }
      break;
   case LHCExperiment::LHCb :
      {
         NSDictionary * const croppedView = [NSDictionary dictionaryWithObjectsAndKeys : [NSValue valueWithCGRect : imageBoundsForLHCb], @"Rect", @"Side view", @"Description", nil];
         NSArray *boundaryRects = [NSArray arrayWithObjects:croppedView, nil];
         KeyVal * const pair = (KeyVal *)[liveEvents objectAtIndex : 0];
         [eventViewController addSourceWithDescription : nil URL : [NSURL URLWithString : (NSString *)pair.val] boundaryRects:boundaryRects];
      }
      break;
   case LHCExperiment::CMS :
      for (KeyVal *pair in liveEvents)
         [eventViewController addSourceWithDescription : (NSString *)pair.key URL : [NSURL URLWithString : (NSString *)pair.val] boundaryRects : nil];
      break;
   default:
      assert(0 && "loadControllerTo:, wrong experiment");
   }

   eventViewController.title = [NSString stringWithFormat : @"%s", ExperimentName(experiment)];
   [controller pushViewController : eventViewController animated : YES];
}

@end
