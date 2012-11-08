#import <UIKit/UIKit.h>

#import "ScrollSelectorDelegate.h"

@interface ScrollSelector : UIView <UIScrollViewDelegate>

@property (nonatomic, weak) id<ScrollSelectorDelegate> delegate;

+ (CGFloat) defaultHeight;

- (void) addItemNames : (NSMutableArray *)items;
- (void) setSelectedItem : (unsigned) item;

@end
