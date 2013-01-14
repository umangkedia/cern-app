#import <UIKit/UIKit.h>

@class MenuItemsGroupView;
@class MenuItemView;

@interface MenuViewController : UIViewController {
   IBOutlet __weak UIScrollView *scrollView;
}

- (void) itemViewWasSelected : (MenuItemView *) view;
- (void) groupViewWasTapped : (MenuItemsGroupView *) view;
- (void) subGroupViewWasTapped : (MenuItemsGroupView *) view;

@end
