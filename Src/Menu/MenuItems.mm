#import <cassert>

#import "StaticInfoScrollViewController.h"
#import "MenuNavigationController.h"
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

   MenuNavigationController * const topController =
         (MenuNavigationController *)[controller.storyboard instantiateViewControllerWithIdentifier : TableNavigationControllerLiveID];
 
   [topController setExperiment : CernAPP::ExperimentNameToEnum(experimentName)];

   [controller.slidingViewController anchorTopViewOffScreenTo : ECRight animations : nil onComplete:^{
      CGRect frame = controller.slidingViewController.topViewController.view.frame;
      controller.slidingViewController.topViewController = topController;
      controller.slidingViewController.topViewController.view.frame = frame;
      [controller.slidingViewController resetTopView];
   }];
}

@end

namespace {

enum class StaticInfoEntryType : char {
   unknown,
   linear,
   nested
};

}

@implementation MenuItemStaticInfo {
   NSString *itemName;
   NSDictionary *info;

   __weak NSArray *items;
   
   StaticInfoEntryType type;
}

@synthesize itemView;

//________________________________________________________________________________________
- (id) initWithDictionary : (NSDictionary *) dict
{
   assert(dict != nil && "initWithDictionary:, parameter 'dict' is nil");

   if (self = [super init]) {
      assert([[dict objectForKey : @"Title"] isKindOfClass : [NSString class]] &&
             "initWithDictionary:, 'Title' is not found or has a wrong type");
      itemName = (NSString *)[dict objectForKey : @"Title"];
      info = dict;
      
      type = StaticInfoEntryType::unknown;
   }
   
   return self;
}

//________________________________________________________________________________________
- (NSString *) itemText
{
   return itemName;
}

//________________________________________________________________________________________
- (UIImage *) itemImage
{
   //Noop at the moment.
   return nil;
}

//________________________________________________________________________________________
- (void) itemPressedIn : (UIViewController *) controller
{
   assert(controller != nil && "itemPressedIn:, parameter 'controller' is nil");
   
   if (type == StaticInfoEntryType::unknown) {
      id objBase = [info objectForKey : @"Items"];
      assert([objBase isKindOfClass : [NSArray class]] &&
             "itemPressedIn:, 'Items' is not found or has a wrong type");
      
      items = (NSArray *)objBase;
      assert(items.count != 0 && "itemPressedIn:, no static info found");

      assert([items[0] isKindOfClass : [NSDictionary class]] &&
             "itemPressedIn:, array of dictionaries expected");
      
      NSDictionary * const firstItem = (NSDictionary *)items[0];
      if ([firstItem objectForKey : @"Items"])
         type = StaticInfoEntryType::nested;
      else
         type = StaticInfoEntryType::linear;
   }
   
   using namespace CernAPP;
   
   if (type == StaticInfoEntryType::linear) {
      //
      MenuNavigationController * const topController = (MenuNavigationController *)[controller.storyboard instantiateViewControllerWithIdentifier : StaticInfoNavigationControllerID];
      [topController setStaticInfo : items withTitle : itemName];

      [controller.slidingViewController anchorTopViewOffScreenTo : ECRight animations : nil onComplete:^{
         CGRect frame = controller.slidingViewController.topViewController.view.frame;
         controller.slidingViewController.topViewController = topController;
         controller.slidingViewController.topViewController.view.frame = frame;
         [controller.slidingViewController resetTopView];
      }];
   } else {
      //Load a table first.
   }
}

@end

@implementation MenuItemsGroup {
   NSArray *items;
   NSString *title;
   UIImage *image;
   
   NSUInteger indexInMenu;
}

@synthesize collapsed, titleView, containerView, groupView;

//________________________________________________________________________________________
- (id) initWithTitle : (NSString *) aTitle image : (UIImage *) anImage items : (NSArray *) anItems index : (NSUInteger) index
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
      indexInMenu = index;
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
- (NSUInteger) index
{
   return indexInMenu;
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

@end


@implementation MenuSeparator

@synthesize itemView;

//________________________________________________________________________________________
- (NSString *) itemText
{
   return nil;
}

//________________________________________________________________________________________
- (UIImage *) itemImage
{
   return nil;
}

@end
