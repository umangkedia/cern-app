#import <cassert>

#import "TableNavigationController.h"
#import "ECSlidingViewController.h"
#import "StoryboardIdentifiers.h"
#import "Experiments.h"
#import "MenuItems.h"

using CernAPP::ItemStyle;

//Quite a simple non-interactive table cell.
@implementation GroupTitle {
   NSString *title;
}

//________________________________________________________________________________________
- (id) initWithTitle : (NSString *) aTitle
{
   if (self = [super init])
      title = aTitle;
   
   return self;
}

//________________________________________________________________________________________
- (BOOL) isSelectable
{
   //Never can be selected and a table view should never
   //highlight it.
   return NO;
}

//________________________________________________________________________________________
- (ItemStyle) itemStyle
{
   //It always has this style only.
   return ItemStyle::groupTitle;
}

//________________________________________________________________________________________
- (NSString *) itemText
{
   return title;
}

//________________________________________________________________________________________
- (UIImage *) itemImage
{
   //Noop at the moment.
   return nil;
}

@end

//This item can activate some data provider.
@implementation MenuItem {
   NSString *itemTitle;
   NSObject<ContentProvider> *contentProvider;
   BOOL isSelectable;
   ItemStyle itemStyle;
}

//________________________________________________________________________________________
- (id) initWithContentProvider : (NSObject<ContentProvider> *) provider
{
   assert(provider != nil && "initWithTitle:contentProvider:, parameter 'provider' is nil");
   
   if (self = [super init]) {
      itemTitle = [[NSString alloc]initWithFormat:@"   %@", provider.categoryName];// provider.categoryName;
      itemStyle = ItemStyle::childItem;
      contentProvider = provider;
      isSelectable = YES;//Enabled by default.
   }

   return self;
}

//________________________________________________________________________________________
- (BOOL) isSelectable
{
   return isSelectable;
}

//________________________________________________________________________________________
- (void) setIsSelectable : (BOOL) selectable
{
   isSelectable = selectable;
}

//________________________________________________________________________________________
- (ItemStyle) itemStyle
{
   return itemStyle;
}

//________________________________________________________________________________________
- (void) setItemStyle : (ItemStyle) style
{
   itemStyle = style;
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
   assert(isSelectable == YES && "itemPressedIn:, called for disabled item");
   assert(controller != nil && "itemPressedIn:, parameter 'controller' is nil");
   //Ask content provider to load correct view/controller.
   [contentProvider loadControllerTo : controller];
}

@end

@implementation MenuItemLIVE {
   CernAPP::LHCExperiment experiment;
   NSString *experimentName;
   BOOL isSelectable;
}

//________________________________________________________________________________________
- (id) initWithExperiment : (NSString *) name
{
   assert(name != nil && "initWithExperiment:, parameter 'name' is nil");

   if (self = [super init]) {
      experiment = CernAPP::ExperimentNameToEnum(name);
      experimentName = name;
      isSelectable = YES;
   }
   
   return self;
}

//________________________________________________________________________________________
- (BOOL) isSelectable
{
   return isSelectable;
}

//________________________________________________________________________________________
- (void) setIsSelectable : (BOOL) selectable
{
   isSelectable = selectable;
}

//________________________________________________________________________________________
- (ItemStyle) itemStyle
{
   return ItemStyle::childItem;
}

//________________________________________________________________________________________
- (NSString *) itemText
{
   return [[NSString alloc] initWithFormat:@"   %@", experimentName];
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