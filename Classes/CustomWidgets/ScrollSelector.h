#import <UIKit/UIKit.h>

#import "ScrollSelectorDelegate.h"

@interface ScrollSelector : UIView <UIScrollViewDelegate>

@property (nonatomic, weak) id<ScrollSelectorDelegate> delegate;

+ (CGFloat) defaultHeight;

- (void) addItemNames : (NSArray *)items;
- (void) setSelectedItem : (unsigned) item;

@end
