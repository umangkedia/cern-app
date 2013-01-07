#import <cassert>

#import "TableNavigationController.h"
#import "ECSlidingViewController.h"
#import "StoryboardIdentifiers.h"
#import "MenuItems.h"

//This item can activate some data provider.
@implementation MenuItem {
   NSString *itemTitle;
   NSObject<ContentProvider> *contentProvider;
}

//________________________________________________________________________________________
- (id) initWithContentProvider : (NSObject<ContentProvider> *) provider
{
   assert(provider != nil && "initWithTitle:contentProvider:, parameter 'provider' is nil");
   
   if (self = [super init]) {
      itemTitle = provider.categoryName;// provider.categoryName;
      contentProvider = provider;
   }

   return self;
}

//________________________________________________________________________________________
- (NSString *) itemText
{
   return itemTitle;
}

//________________________________________________________________________________________
- (UIImage *) itemImage
{
   //No images at the moment.
   return nil;
}

//________________________________________________________________________________________
- (void) itemPressedIn : (UIViewController *) controller
{
   assert(controller != nil && "itemPressedIn:, parameter 'controller' is nil");
   //Ask content provider to load correct view/controller.
   [contentProvider loadControllerTo : controller];
}

@end

@implementation MenuItemLIVE {
   NSString *experimentName;
}

//________________________________________________________________________________________
- (id) initWithExperiment : (NSString *) name
{
   assert(name != nil && "initWithExperiment:, parameter 'name' is nil");

   if (self = [super init])
      experimentName = name;
   
   return self;
}

//________________________________________________________________________________________
- (NSString *) itemText
{
   return experimentName;
}

//________________________________________________________________________________________
- (UIImage *) itemImage
{
   return nil;
}

//________________________________________________________________________________________
- (void) itemPressedIn : (UIViewController *) controller
{
   assert(controller != nil && "itemPressedIn:, parameter 'controller' is nil");

   using namespace CernAPP;

   TableNavigationController * const topController =
         (TableNavigationController *)[controller.storyboard instantiateViewControllerWithIdentifier : TableNavigationControllerLiveID];
 
   [topController setExperiment : CernAPP::ExperimentNameToEnum(experimentName)];

   [controller.slidingViewController anchorTopViewOffScreenTo : ECRight animations : nil onComplete:^{
      CGRect frame = controller.slidingViewController.topViewController.view.frame;
      controller.slidingViewController.topViewController = topController;
      controller.slidingViewController.topViewController.view.frame = frame;
      [controller.slidingViewController resetTopView];
   }];
}

@end

@implementation MenuItemsGroup {
   NSArray *items;
   NSString *title;
   UIImage *image;
   BOOL collapsed;
}

@synthesize collapsed;

//________________________________________________________________________________________
- (id) initWithTitle : (NSString *) aTitle image : (UIImage *) anImage items : (NSArray *) anItems
{
   assert(aTitle != nil && "initWithTitle:image:items, parameter 'aTitle' is nil");
   //image can be nil.
   assert(anItems != nil && "initWithTitle:image:items, parameter 'anItems' is nil");
   assert(anItems.count != 0 && "initWithTitle:image:items, number of items must be > 0");
   
   if (self = [super init]) {
      title = aTitle;
      image = anImage;
      items = anItems;
      collapsed = NO;//Opened by default.
   }
   
   return self;
}

//________________________________________________________________________________________
- (NSString *) itemText
{
   return title;
}

//________________________________________________________________________________________
- (UIImage *) itemImage
{
   return image;
}

//________________________________________________________________________________________
- (NSUInteger) nItems
{
   return items.count;
}

//________________________________________________________________________________________
- (MenuItem *) item : (NSUInteger) item;
{
   assert(item < items.count && "viewForItem:, parameter 'item' is out of bounds");
   return items[item];
}

//________________________________________________________________________________________
- (void) itemPressedIn : (UIViewController *) controller
{
   //Either collapse or expand a group.
   NSLog(@"collapse or expand a group");
}

@end
