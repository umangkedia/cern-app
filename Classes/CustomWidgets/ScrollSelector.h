#import <UIKit/UIKit.h>

#import "ScrollSelectorDelegate.h"

//
//ScrollSelector is a small 'widget', emulating a
//"horizontal picker" view (UIKit has only huge vertical picker).
//It's a view with a nested scroll-view. Scroll-view itself can
//contain children views (only labels at the moment).
//The user can 'rotate' this 'wheel' selecting different items.
//

@interface ScrollSelector : UIView <UIScrollViewDelegate>

+ (CGFloat) defaultHeight;

- (id) initWithFrame : (CGRect) frame;

//Array of strings - text for labels, placed in a scroller.
//TODO: At the moment you can only set all items in one call,
//no way to add them one by one.
- (void) setLabelItemsWithText : (NSMutableArray *) items;

//External code can select some item programmatically.
- (void) setSelectedItem : (NSUInteger) item;

//Item is not selected, but wheel is scrolling,
//pos is a percent of a total scroller's 'length'.
//This method is for external code, to ask scroller
//to follow some external animation (see MultiPageController).
- (void) scrollToPos : (CGFloat) pos;

- (NSUInteger) itemsCount;
- (void) playClick;

@property (nonatomic, weak) id<ScrollSelectorDelegate> delegate;

@end
