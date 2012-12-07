#import <Foundation/Foundation.h>

@class ScrollSelector;

@protocol ScrollSelectorDelegate <NSObject>
@required

- (void) item : (NSUInteger) item selectedIn : (ScrollSelector *) selector;

@end
