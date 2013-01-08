#import <Foundation/Foundation.h>

//MenuItem is a cell in a special table view.
//It can be selectable or not.

#import "ContentProviders.h"

@class MenuItemsGroupView;
@class MenuItemView;

//Protocol for menu items (not a class, not to
//have stupid empty implementation)
@protocol MenuItemProtocol <NSObject>
@required

- (NSString *) itemText;
- (UIImage *) itemImage;

@optional
- (void) itemPressedIn : (UIViewController *) controller;

//Since itemView also has a reference to menu item, reference is weak.
@property (nonatomic) __weak MenuItemView *itemView;

@end

//This item corresponds to some content provider,
//when user taps such a item in a menu,
//content provider should load the correct view/controller.
@interface MenuItem : NSObject<MenuItemProtocol>

- (id) initWithContentProvider : (NSObject<ContentProvider> *) provider;

- (NSString *) itemText;
- (UIImage *) itemImage;

- (void) itemPressedIn : (UIViewController *) controller;

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

- (void) itemPressedIn : (UIViewController *) controller;

@property (nonatomic) __weak MenuItemView *itemView;

@end


@interface MenuItemsGroup : NSObject<MenuItemProtocol>

- (id) initWithTitle : (NSString *) title image : (UIImage *) image items : (NSArray *) items index : (NSUInteger) index;

- (NSString *) itemText;
- (UIImage *) itemImage;

@property (nonatomic) BOOL collapsed;

- (NSUInteger) index;
- (NSUInteger) nItems;
- (MenuItem *) item : (NSUInteger) item;

@property (nonatomic) __weak MenuItemsGroupView *titleView;
@property (nonatomic) __weak UIView *containerView;
@property (nonatomic) __weak UIView *groupView;

@end
