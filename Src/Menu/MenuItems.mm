#import <cassert>

#import "StaticInfoScrollViewController.h"
#import "MenuNavigationController.h"
#import "ECSlidingViewController.h"
#import "StoryboardIdentifiers.h"
#import "MenuViewController.h"
#import "MenuItemViews.h"
#import "GUIHelpers.h"
#import "MenuItems.h"

using CernAPP::ItemStyle;

//This item can activate some data provider.
@implementation MenuItem {
   NSString *itemTitle;
   NSObject<ContentProvider> *contentProvider;
}

@synthesize itemView, menuGroup;

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
   return contentProvider.categoryImage;
}

//________________________________________________________________________________________
- (void) addMenuItemViewInto : (UIView *) parentView controller : (MenuViewController *) controller
{
   assert(parentView != nil && "addMenuItemViewInto:controller:, parameter 'parentView' is nil");
   assert(controller != nil && "addMenuItemViewInto:controller:, parameter 'controller' is nil");
   //
   MenuItemView * const newView = [[MenuItemView alloc] initWithFrame : CGRect() item : self
                                   style : ItemStyle::child controller : controller];
     
   itemView = newView;
   [parentView addSubview : newView];
}

//________________________________________________________________________________________
- (CGFloat) layoutItemViewWithHint : (CGRect) hint
{
   assert(itemView != nil && "layoutItemViewWithHint:, itemView is nil");

   hint.size.height = CernAPP::childMenuItemHeight;
   itemView.frame = hint;   
   [itemView layoutText];

   return CernAPP::childMenuItemHeight;
}

//________________________________________________________________________________________
- (CGFloat) requiredHeight
{
   return CernAPP::childMenuItemHeight;
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

@synthesize itemView, menuGroup;

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
- (void) addMenuItemViewInto : (UIView *) parentView controller : (MenuViewController *) controller
{
   assert(parentView != nil && "addMenuItemViewInto:controller:, parameter 'parentView' is nil");
   assert(controller != nil && "addMenuItemViewInto:controller:, parameter 'controller' is nil");
   //
   MenuItemView * const newView = [[MenuItemView alloc] initWithFrame : CGRect() item : self
                                   style : ItemStyle::child controller : controller];
     
   itemView = newView;
   [parentView addSubview : newView];
}

//________________________________________________________________________________________
- (CGFloat) layoutItemViewWithHint : (CGRect) hint
{
   assert(itemView != nil && "layoutItemViewWithHint:, itemView is nil");

   hint.size.height = CernAPP::childMenuItemHeight;
   itemView.frame = hint;
   [itemView layoutText];

   return CernAPP::childMenuItemHeight;
}

//________________________________________________________________________________________
- (CGFloat) requiredHeight
{
   return CernAPP::childMenuItemHeight;
}

//________________________________________________________________________________________
- (void) itemPressedIn : (UIViewController *) controller
{
   assert(controller != nil && "itemPressedIn:, parameter 'controller' is nil");

   using namespace CernAPP;

   MenuNavigationController * const topController =
         (MenuNavigationController *)[controller.storyboard instantiateViewControllerWithIdentifier : TableNavigationControllerLiveID];
 
   [topController setExperiment : CernAPP::ExperimentNameToEnum(experimentName)];

   [controller.slidingViewController anchorTopViewOffScreenTo : ECRight animations : nil onComplete : ^ {
      CGRect frame = controller.slidingViewController.topViewController.view.frame;
      controller.slidingViewController.topViewController = topController;
      controller.slidingViewController.topViewController.view.frame = frame;
      [controller.slidingViewController resetTopView];
   }];
}

@end

@implementation MenuItemStaticInfo {
   NSDictionary *info;
}

@synthesize itemView, menuGroup;

//________________________________________________________________________________________
- (id) initWithDictionary : (NSDictionary *) dict
{
   assert(dict != nil && "initWithDictionary:, parameter 'dict' is nil");

   if (self = [super init]) {
      assert([dict[@"Title"] isKindOfClass : [NSString class]] &&
             "initWithDictionary:, 'Title' is not found or has a wrong type");
      assert([dict[@"Items"] isKindOfClass : [NSArray class]] &&
             "initWithDictionary:, 'Items' is not found or has a wrong type");
      info = dict;
   }
   
   return self;
}

//________________________________________________________________________________________
- (NSString *) itemText
{
   assert(info != nil && "itemText, info is nil");//With Obj-C you can skip "constructor".
   assert([info[@"Title"] isKindOfClass : [NSString class]] &&
           "initWithDictionary:, 'Title' is not found or has a wrong type");

   return (NSString *)info[@"Title"];
}

//________________________________________________________________________________________
- (UIImage *) itemImage
{
   //Noop at the moment.
   return nil;
}

//________________________________________________________________________________________
- (void) addMenuItemViewInto : (UIView *) parentView controller : (MenuViewController *) controller
{
   assert(parentView != nil && "addMenuItemViewInto:controller:, parameter 'parentView' is nil");
   assert(controller != nil && "addMenuItemViewInto:controller:, parameter 'controller' is nil");
   //
   MenuItemView * const newView = [[MenuItemView alloc] initWithFrame : CGRect() item : self
                                   style : ItemStyle::child controller : controller];
     
   itemView = newView;
   [parentView addSubview : newView];
}

//________________________________________________________________________________________
- (CGFloat) layoutItemViewWithHint : (CGRect) frameHint
{
   assert(itemView != nil && "layoutItemViewWithHint:, itemView is nil");

   frameHint.size.height = CernAPP::childMenuItemHeight;
   itemView.frame = frameHint;
   
   [itemView layoutText];

   return CernAPP::childMenuItemHeight;
}

//________________________________________________________________________________________
- (CGFloat) requiredHeight
{
   return CernAPP::childMenuItemHeight;
}

//________________________________________________________________________________________
- (void) itemPressedIn : (UIViewController *) controller
{
   assert(controller != nil && "itemPressedIn:, parameter 'controller' is nil");
   assert(info != nil && "itemPressedIn:, info is nil");
   assert([info[@"Title"] isKindOfClass : [NSString class]] &&
          "itemPressedIn:, 'Title' not found or has a wrong type");
   assert([info[@"Items"] isKindOfClass : [NSArray class]] &&
          "itemPressedIn:, 'Items' not found or has a wrong type");

   using namespace CernAPP;
   MenuNavigationController * const topController =
                  (MenuNavigationController *)[controller.storyboard instantiateViewControllerWithIdentifier :
                                                                     StaticInfoNavigationControllerID];

   [topController setStaticInfo : (NSArray *)info[@"Items"] withTitle : (NSString *)info[@"Title"]];

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
}

@synthesize collapsed, shrinkable, nestedItemState, titleView, containerView, groupView, parentGroup;

//________________________________________________________________________________________
- (id) initWithTitle : (NSString *) aTitle image : (UIImage *) anImage items : (NSArray *) anItems
{
   assert(aTitle != nil && "initWithTitle:image:items:, parameter 'aTitle' is nil");
   //image can be nil.
   assert(anItems != nil && "initWithTitle:image:items:, parameter 'anItems' is nil");
   assert(anItems.count != 0 && "initWithTitle:image:items:, number of items must be > 0");
   
   if (self = [super init]) {
      title = aTitle;
      image = anImage;
      items = anItems;
      collapsed = NO;//Opened by default.      
      shrinkable = YES;
      parentGroup = nil;
   }

   return self;
}

//________________________________________________________________________________________
- (void) addMenuItemViewInto : (UIView *) parentView controller : (MenuViewController *) controller
{
   assert(parentView != nil && "addMenuItemViewInto:controller:, parameter 'parentView' is nil");
   assert(controller != nil && "addMenuItemViewInto:controller:, parameter 'controller' is nil");
   
   UIView * const newContainerView = [[UIView alloc] initWithFrame : CGRect()];
   newContainerView.clipsToBounds = YES;
   UIView * const newGroupView = [[UIView alloc] initWithFrame : CGRect()];
   [newContainerView addSubview : newGroupView];
   [parentView addSubview : newContainerView];
         
   for (NSObject<MenuItemProtocol> *item in items) {
      assert([item respondsToSelector:@selector(addMenuItemViewInto:controller:)] &&
             "addMenuItemViewInto:controller:, child item must reposng to 'addMenuItemViewInto:controller: method'");

      [item addMenuItemViewInto : newGroupView controller : controller];
      
      if ([item respondsToSelector:@selector(menuGroup)])
         item.menuGroup = self;
   }

   MenuItemsGroupView * const menuGroupView = [[MenuItemsGroupView alloc] initWithFrame : CGRect()
                                               item : self controller : controller];
   [parentView addSubview : menuGroupView];
         
   titleView = menuGroupView;
   containerView = newContainerView;
   groupView = newGroupView;
}

//________________________________________________________________________________________
- (CGFloat) layoutItemViewWithHint : (CGRect) hint
{
   assert(titleView != nil && "layoutItemViewWithHint:, titleView is nil");
   assert(containerView != nil && "layoutItemViewWithHint:, containerView is nil");
   assert(groupView != nil && "layouItemViewWithHint:, containerView is nil");
   
   CGFloat totalHeight = 0.f;
   
   if (!parentGroup)
      hint.size.height = CernAPP::groupMenuItemHeight;
   else
      hint.size.height = CernAPP::childMenuItemHeight;
   
   titleView.frame = hint;
   [titleView layoutText];
   
   totalHeight += hint.size.height;
   hint.origin.y += hint.size.height;

   hint.size.height = [self requiredHeight];
   containerView.frame = hint;

   if (!collapsed) {
      hint.origin = CGPoint();
      titleView.discloseImageView.transform = CGAffineTransformMakeRotation(0.f);
   } else {
      hint.origin.y = -hint.size.height;
      groupView.alpha = 0.f;//well, this is not a layout actually, but ok.
   }

   groupView.frame = hint;
   
   //Layout sub-views.
   hint.origin = CGPoint();
   
   for (NSObject<MenuItemProtocol> *menuItem in items) {
      const CGFloat add = [menuItem layoutItemViewWithHint : hint];
      hint.origin.y += add;
      totalHeight += add;
   }

   if (collapsed) {
      if (parentGroup)
         return CernAPP::childMenuItemHeight;
      else
         return CernAPP::groupMenuItemHeight;
   }

   return totalHeight;
}

//________________________________________________________________________________________
- (CGFloat) requiredHeight
{
   //The height required by this menu as it's in open state now.
   CGFloat totalHeight = 0.f;

   if (!parentGroup)
      totalHeight = CernAPP::groupMenuItemHeight;
   else
      totalHeight = CernAPP::childMenuItemHeight;
   
   //If it's open, also calculate the height of sub-items.
   for (NSObject<MenuItemProtocol> *menuItem in items) {
      if ([menuItem isKindOfClass : [MenuItemsGroup class]]) {
         //For the nested sub-group, we calculate its total height only if its open.
         MenuItemsGroup * const subGroup = (MenuItemsGroup *)menuItem;
         if (!subGroup.collapsed)
            totalHeight += [menuItem requiredHeight];
         else
            totalHeight += CernAPP::childMenuItemHeight;
      } else
         totalHeight += [menuItem requiredHeight];
   }
   
   return totalHeight;
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

@end


@implementation MenuSeparator

@synthesize itemView;

//________________________________________________________________________________________
- (void) addMenuItemViewInto : (UIView *) parentView controller : (MenuViewController *) controller
{
   assert(parentView != nil && "addMenuItemViewInto:controller:, parameter 'parentView' is nil");
   assert(parentView != nil && "addMenuItemViewInto:controller:, parameter 'controller' is nil");
   
   MenuItemView * const separatorView = [[MenuItemView alloc] initWithFrame:CGRect() item : nil style : ItemStyle::separator controller : controller];
   itemView = separatorView;
   [parentView addSubview : separatorView];
}

//________________________________________________________________________________________
- (CGFloat) layoutItemViewWithHint : (CGRect) frameHint
{
   assert(itemView != nil && "layoutItemViewWithHint:, itemView is nil");

   frameHint.size.height = CernAPP::childMenuItemHeight;
   itemView.frame = frameHint;

   return CernAPP::childMenuItemHeight;
}

//________________________________________________________________________________________
- (CGFloat) requiredHeight
{
   return CernAPP::childMenuItemHeight;
}

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
