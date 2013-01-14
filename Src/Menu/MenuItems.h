#import <Foundation/Foundation.h>

//MenuItem is a cell in a special table view.
//It can be selectable or not.

#import "ContentProviders.h"

@class MenuViewController;
@class MenuItemsGroupView;
@class MenuItemsGroup;
@class MenuItemView;

//Protocol for menu items (not a class, not to
//have stupid empty implementation)
@protocol MenuItemProtocol <NSObject>
@required

- (NSString *) itemText;
- (UIImage *) itemImage;

- (void) addMenuItemViewInto : (UIView *) parentView controller : (MenuViewController *) controller;
- (CGFloat) layoutItemViewWithHint : (CGRect) frameHint;
- (CGFloat) requiredHeight;

@optional
- (void) itemPressedIn : (UIViewController *) controller;

//Since itemView also has a reference to menu item, reference is weak.
@property (nonatomic) __weak MenuItemsGroup *menuGroup;
@property (nonatomic) __weak MenuItemView *itemView;

@end

//This item corresponds to some content provider,
//when user taps such a item in a menu,
//content provider should load the correct view/controller.
@interface MenuItem : NSObject<MenuItemProtocol>

- (id) initWithContentProvider : (NSObject<ContentProvider> *) provider;

- (NSString *) itemText;
- (UIImage *) itemImage;

- (void) addMenuItemViewInto : (UIView *) parentView controller : (MenuViewController *) controller;
- (CGFloat) layoutItemViewWithHint : (CGRect) frameHint;
- (CGFloat) requiredHeight;

- (void) itemPressedIn : (UIViewController *) controller;

@property (nonatomic) __weak MenuItemsGroup *menuGroup;
@property (nonatomic) __weak MenuItemView *itemView;

@end

//
//Menu item to select an experiment in the "LIVE" section of a menu.
//Loads nested table view controller.
//
@interface MenuItemLIVE : NSObject<MenuItemProtocol>

- (id) initWithExperiment : (NSString *) name;

- (NSString *) itemText;
- (UIImage *) itemImage;

- (void) addMenuItemViewInto : (UIView *) parentView controller : (MenuViewController *) controller;
- (CGFloat) layoutItemViewWithHint : (CGRect) frameHint;
- (CGFloat) requiredHeight;

- (void) itemPressedIn : (UIViewController *) controller;

@property (nonatomic) __weak MenuItemsGroup *menuGroup;
@property (nonatomic) __weak MenuItemView *itemView;

@end

//
//Different items in the "About CERN" sub-menu.
//
@interface MenuItemStaticInfo : NSObject<MenuItemProtocol>

- (id) initWithDictionary : (NSDictionary *) dict;

- (NSString *) itemText;
- (UIImage *) itemImage;

- (void) addMenuItemViewInto : (UIView *) parentView controller : (MenuViewController *) controller;
- (CGFloat) layoutItemViewWithHint : (CGRect) frameHint;
- (CGFloat) requiredHeight;

- (void) itemPressedIn : (UIViewController *) controller;

@property (nonatomic) __weak MenuItemsGroup *menuGroup;
@property (nonatomic) __weak MenuItemView *itemView;

@end

//
// Menu group - collapsing/expanding group of items.
//
@interface MenuItemsGroup : NSObject<MenuItemProtocol>

- (id) initWithTitle : (NSString *) title image : (UIImage *) image items : (NSArray *) items;

- (void) addMenuItemViewInto : (UIView *) parentView controller : (MenuViewController *) controller;
- (CGFloat) layoutItemViewWithHint : (CGRect) frameHint;
- (CGFloat) requiredHeight;

- (NSString *) itemText;
- (UIImage *) itemImage;

@property (nonatomic) BOOL collapsed;
@property (nonatomic) BOOL shrinkable;

- (NSUInteger) nItems;
- (MenuItem *) item : (NSUInteger) item;

@property (nonatomic) __weak MenuItemsGroupView *titleView;
@property (nonatomic) __weak UIView *containerView;
@property (nonatomic) __weak UIView *groupView;

//Menu group can contain expanding sub-groups.
@property (nonatomic) __weak MenuItemsGroup *parentGroup;

@end

//
//Simple non-interactive item without any title or image,
//just to separate different items.
//

@interface MenuSeparator : NSObject<MenuItemProtocol>

- (void) addMenuItemViewInto : (UIView *) parentView controller : (MenuViewController *) controller;
- (CGFloat) layoutItemViewWithHint : (CGRect) frameHint;
- (CGFloat) requiredHeight;

- (NSString *) itemText;
- (UIImage *) itemImage;

@property (nonatomic) __weak MenuItemView *itemView;

@end
