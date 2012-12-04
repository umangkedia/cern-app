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
- (void) setCategoryName : (NSString *) name
{
   feedName = name;
}

//________________________________________________________________________________________
- (UIImage *) categoryImage
{
   return nil;
}

//________________________________________________________________________________________
- (void) addPageWithContentTo : (MultiPageController *) controller
{
   assert(controller != nil && "addPageWithContentTo:, parameter 'controller' is nil");

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

@synthesize categoryName;

//________________________________________________________________________________________
- (CGRect) readImageBounds : (NSDictionary *) dict
{
   assert(dict != nil && "readImageBounds:, parameter 'dict' is nil");
   
   CGRect imageRect = {};
   
   id base = [dict objectForKey : @"cropX"];
   assert([base isKindOfClass : [NSNumber class]] &&
          "readImageBounds, object for the key 'cropX' not found or not an NSNumber");
   imageRect.origin.x = [(NSNumber *)base integerValue];//take as floating point number?
   
   base = [dict objectForKey : @"cropY"];
   assert([base isKindOfClass : [NSNumber class]] &&
          "readImageBounds, object for the key 'cropY' not found or not an NSNumber");
   imageRect.origin.y = [(NSNumber *)base integerValue];//take as floating point number?

   base = [dict objectForKey : @"cropW"];
   assert([base isKindOfClass : [NSNumber class]] &&
          "readImageBounds, object for the key 'cropW' not found or not an NSNumber");
   imageRect.size.width = [(NSNumber *)base integerValue];//take as floating point number?

   base = [dict objectForKey : @"cropH"];
   assert([base isKindOfClass : [NSNumber class]] &&
          "readImageBounds, object for the key 'cropH' not found or not an NSNumber");
   imageRect.size.height = [(NSNumber *)base integerValue];//take as floating point number?

   assert(imageRect.size.width > 0 && imageRect.size.height > 0 &&
          "readImageBounds, invalid image rectangle");

   return imageRect;
}

//________________________________________________________________________________________
- (void) readSingleImage : (NSDictionary *) imageDict
{
   assert(imageDict != nil && "readSingleImage:, parameter 'imageDict' is nil");
   assert(liveEvents != nil && "readSingleImage:, liveEvents is nil");
   assert([[imageDict objectForKey : @"Name"] isKindOfClass : [NSString class]] &&
          "readSingleImage:, object for key 'Name' not found or not of NSString type");
   assert([[imageDict objectForKey : @"Image"] isKindOfClass : [NSString class]] &&
          "readSingleImage:, object for key 'Image' not found or not of NSString type");
   
   CGRect imageBounds = {};
   
   //Let's check, if we have to crop an image.
   if (id obj = [imageDict objectForKey : @"Bounds"]) {
      assert([obj isKindOfClass : [NSDictionary class]] &&
             "readSingleImage:, object for key 'Bounds' must be a dictionary");
      
      imageBounds = [self readImageBounds : (NSDictionary *)obj];
   }
   
   LiveImageData *imageData = [[LiveImageData alloc] initWithName : (NSString *)[imageDict objectForKey : @"Name"]
                                                     url : (NSString *)[imageDict objectForKey : @"Image"]
                                                     bounds : imageBounds];
   [liveEvents addObject : imageData];
}

//________________________________________________________________________________________
- (void) readImageSet : (NSDictionary *) imageDict
{
   assert(imageDict != nil && "readImageSet:, parameter 'imageDict' is nil");
   assert(liveEvents != nil && "readImageSet:, liveEvents is nil");
   
   id base = [imageDict objectForKey : @"nImages"];
   assert([base isKindOfClass:[NSNumber class]] &&
          "readImageSet, object for key 'nImages' not found or is not a NSNumber");
   const NSInteger nImages = [(NSNumber *)base integerValue];
   assert(nImages > 0 && "readImageSet:, nImages must be a positive number");
   
   base = [imageDict objectForKey : @"Bounds"];
   assert([base isKindOfClass : [NSArray class]] &&
          "readImageSet, object for key 'Bounds' not found or is not a NSArray");
   NSArray * const bounds = (NSArray *)base;
   
   base = [imageDict objectForKey : @"Names"];
   assert([base isKindOfClass : [NSArray class]] &&
          "readImageSet, object for key 'Names' not found or is not a NSArray");
   NSArray * const names = (NSArray *)base;

   assert([names count] == [bounds count] && [names count] == nImages &&
          "readImageSet, inconsistent number of elements and bounds/names");
   
   base = [imageDict objectForKey : @"Image"];
   assert([base isKindOfClass : [NSString class]] &&
          "readImageSet, object for key 'Image' not found or not a NSString");

   NSString * const url = (NSString *)base;
   
   NSMutableArray *imageSet = [[NSMutableArray alloc] init];
   for (NSInteger i = 0; i < nImages; ++i) {
      base = [bounds objectAtIndex : i];
      assert([base isKindOfClass : [NSDictionary class]] &&
             "readImageSet:, image bounds must be NSDictionary");
      
      const CGRect imageBounds = [self readImageBounds : (NSDictionary *)base];
      assert([[names objectAtIndex : i] isKindOfClass : [NSString class]] &&
             "readImageSet:, sub-image names must be a NSString");

      LiveImageData * imageData = [[LiveImageData alloc] initWithName : (NSString *)[names objectAtIndex : i]
                                                         url : url bounds : imageBounds];
      [imageSet addObject : imageData];
   }
   
   [liveEvents addObject : imageSet];
}

//________________________________________________________________________________________
- (id) initWith : (NSArray *) images forExperiment : (CernAPP::LHCExperiment) e
{
   using namespace CernAPP;

   assert(images != nil && "initWith:, parameter 'images' is nil");
   
   if (self = [super init]) {
      categoryName = @"Live Events";//Probably, will be reset externally.
      liveEvents = [[NSMutableArray alloc] init];
   
      for (id base in images) {
         assert([base isKindOfClass : [NSDictionary class]] &&
                "initWith:forExperiment:, array of dictionaries expected");
         
         NSDictionary * const data = (NSDictionary *)base;
         assert([[data objectForKey : @"Category Name"] isKindOfClass : [NSString class]] &&
                "initWith:forExperiment:, object for 'Category Name' not found or is not of NSString type");

         NSString * const cat = (NSString *)[data objectForKey : @"Category Name"];
         if ([cat isEqualToString : @"SingleImage"])
            [self readSingleImage : data];
         else if ([cat isEqualToString : @"ImageSet"])
            [self readImageSet : data];
         else {
            assert(0 && "initWith:forExperiment:, unknown type of entry found");
         }
      }
      
      experiment = e;
   }
   
   return self;
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
   NSString * const experimentName = [NSString stringWithFormat : @"%s", ExperimentName(experiment)];
   
   if ([liveEvents count] == 1 && [[liveEvents objectAtIndex : 0] isKindOfClass : [LiveImageData class]]) {
      //For such an image we just load "event display" view directly into the multi-page controller.
      EventDisplayViewController * const eventViewController = [mainStoryboard instantiateViewControllerWithIdentifier : EventDisplayViewControllerID];
      //
      LiveImageData *liveData = (LiveImageData *)[liveEvents objectAtIndex : 0];
      if (liveData.bounds.size.width) {
         NSDictionary * const dict = [NSDictionary dictionaryWithObjectsAndKeys : [NSValue valueWithCGRect : liveData.bounds],
                                                                                  @"Rect", liveData.imageName, @"Description", nil];
         NSArray * const imageData = [NSArray arrayWithObject : dict];
         [eventViewController addSourceWithDescription : nil URL : [NSURL URLWithString : liveData.url] boundaryRects : imageData];
      } else {
         [eventViewController addSourceWithDescription : liveData.imageName URL : [NSURL URLWithString : liveData.url] boundaryRects : nil];
      }
      
      //
      [controller addPageFor : eventViewController];
   } else {
      LiveEventTableController * const eventViewController = [mainStoryboard instantiateViewControllerWithIdentifier : LIVEEventTableViewControllerID];
      [eventViewController setTableContents : liveEvents experimentName : experimentName];
      eventViewController.provider = self;
      eventViewController.navController = controller.navigationController;
      [controller addPageFor : eventViewController];
   }
}

//________________________________________________________________________________________
- (void) loadControllerTo : (UINavigationController *) controller
{
   [self loadControllerTo : controller selectedImage : 0];
}

//________________________________________________________________________________________
- (void) loadControllerTo : (UINavigationController *) controller selectedImage : (NSInteger) selected
{
   using namespace CernAPP;
   
   assert(controller != nil && "loadControllerTo:, parameter 'controller' is nil");
   //assert(selected >= 0 && selected < [liveEvents count] && "loadControllerTo:, parameter 'selected' is out of bounds");
   
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
   
   if (selected)
      [eventViewController scrollToPage : selected];
}

@end

//
@implementation LiveImageData

@synthesize imageName, url, image,bounds;

//________________________________________________________________________________________
- (id) initWithName : (NSString *) name url : (NSString *) imageUrl bounds : (CGRect) imageBounds
{
   if (self = [super init]) {
      imageName = name;
      url = imageUrl;
      image = nil;//to be loaded yet!
      bounds = imageBounds;
   }
   
   return self;
}

@end