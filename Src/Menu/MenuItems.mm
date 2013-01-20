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

//Single menu item, can be standalone or a group member.
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
- (void) setIndent : (CGFloat) indent imageHint : (CGSize) imageHint
{
   assert(indent >= 0.f && "setIndent:imageHint:, parameter 'indent' is negative");
   assert(itemView != nil && "setIndent:imageHint:, itemView is nil");

   itemView.indent = indent;
   itemView.imageHint = imageHint;
}

//________________________________________________________________________________________
- (void) itemPressedIn : (UIViewController *) controller
{
   assert(controller != nil && "itemPressedIn:, parameter 'controller' is nil");
   //Ask content provider to load correct view/controller.
   [contentProvider loadControllerTo : controller];
}

@end

//
//A group of items, can be collapsed/expanded,
//can be at the top level of a menu or a
//nested sub-group in another group.
//

@implementation MenuItemsGroup {
   NSArray *items;
   NSString *title;
   UIImage *image;
}

@synthesize collapsed, shrinkable, titleView, containerView, groupView, parentGroup;

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
   if (!parentGroup)
      hint.size.height -= CernAPP::groupMenuItemHeight;
   else
      hint.size.height -= CernAPP::childMenuItemHeight;

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
   
   for (NSObject<MenuItemProtocol> *menuItem in items)
      hint.origin.y += [menuItem layoutItemViewWithHint : hint];
   
   totalHeight += hint.size.height;

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
- (void) setIndent : (CGFloat) indent imageHint : (CGSize) imageHint
{
   assert(indent >= 0.f && "setIndent:imageHint:, parameter 'indent' is negative");
   assert(titleView != nil && "setIndent:imageHint:, titleView is nil");
   
   titleView.indent = indent;
   titleView.imageHint = imageHint;
   
   CGFloat whRatio = 0.f;
   for (NSObject<MenuItemProtocol> *menuItem in items) {
      if (UIImage * const childImage = menuItem.itemImage) {
         const CGSize sz = childImage.size;
         assert(sz.width > 0.f && sz.height > 0.f &&
                "setIndent:imageHeight, child item has an invalid image size");
         if (sz.width / sz.height > whRatio)
            whRatio = sz.width / sz.height;
      }
   }
   
   CGSize childImageHint = {};
   if (whRatio) {
      childImageHint.width = CernAPP::childMenuItemImageHeight * whRatio;
      childImageHint.height = CernAPP::childMenuItemImageHeight;
   }

   indent += CernAPP::childMenuItemTextIndent;

   for (NSObject<MenuItemProtocol> *menuItem in items)
      [menuItem setIndent : indent imageHint : childImageHint];
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

//
//Item separator.
//

@implementation MenuSeparator

@synthesize itemView;

//________________________________________________________________________________________
- (void) addMenuItemViewInto : (UIView *) parentView controller : (MenuViewController *) controller
{
   assert(parentView != nil && "addMenuItemViewInto:controller:, parameter 'parentView' is nil");
   assert(parentView != nil && "addMenuItemViewInto:controller:, parameter 'controller' is nil");
   
   MenuItemView * const separatorView = [[MenuItemView alloc] initWithFrame : CGRect() item : nil style : ItemStyle::separator controller : controller];
   itemView = separatorView;
   [parentView addSubview : separatorView];
}

//________________________________________________________________________________________
- (CGFloat) layoutItemViewWithHint : (CGRect) frameHint
{
   assert(itemView != nil && "layoutItemViewWithHint:, itemView is nil");

   frameHint.size.height = CernAPP::separatorItemHeight;
   itemView.frame = frameHint;

   return CernAPP::separatorItemHeight;
}

//________________________________________________________________________________________
- (CGFloat) requiredHeight
{
   return CernAPP::separatorItemHeight;
}

//________________________________________________________________________________________
- (void) setIndent : (CGFloat) indent imageHint : (CGSize) imageHint
{
#pragma unused(indent, imageHint)
   //Noop - separator has no image, no text.
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
