#import <Foundation/Foundation.h>

//MenuItem is a cell in a special table view.
//It can be selectable or not.

#import "ContentProviders.h"

namespace CernAPP {

enum class ItemStyle {
   groupTitle,
   childItem
};

}

//Protocol for menu items (not a class, not to
//have stupid empty implementation)
@protocol MenuItemProtocol <NSObject>
@required

- (BOOL) isSelectable;
- (CernAPP::ItemStyle) itemStyle;

- (NSString *) itemText;
- (UIImage *) itemImage;

@optional
- (void) itemPressedIn : (UIViewController *) controller;

@end

//Never selectable, always with 'groupTitle' style.
@interface GroupTitle : NSObject<MenuItemProtocol>

- (id) initWithTitle : (NSString *) title;//No image yet.

- (BOOL) isSelectable;
- (CernAPP::ItemStyle) itemStyle;

- (NSString *) itemText;
- (UIImage *) itemImage;

@end

//This item corresponds to some content provider,
//when user taps such a item in a menu,
//content provider should load the correct view/controller.
@interface MenuItem : NSObject<MenuItemProtocol>

- (id) initWithContentProvider : (NSObject<ContentProvider> *) provider;

- (BOOL) isSelectable;
- (void) setIsSelectable : (BOOL) selectable;

- (CernAPP::ItemStyle) itemStyle;
- (void) setItemStyle : (CernAPP::ItemStyle) style;

- (NSString *) itemText;
- (UIImage *) itemImage;

- (void) itemPressedIn : (UIViewController *) controller;

@end

//
//Menu item to select an experiment in the "LIVE" section of a menu.
//Loads nested table view controller.
//
@interface MenuItemLIVE : NSObject<MenuItemProtocol>

- (id) initWithExperiment : (NSString *) name;

- (BOOL) isSelectable;
- (void) setIsSelectable : (BOOL) selectable;

- (CernAPP::ItemStyle) itemStyle;

- (NSString *) itemText;
- (UIImage *) itemImage;

- (void) itemPressedIn : (UIViewController *) controller;

@end
