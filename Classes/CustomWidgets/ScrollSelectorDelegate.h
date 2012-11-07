#import <Foundation/Foundation.h>

@class ScrollSelector;

@protocol ScrollSelectorDelegate <NSObject>

- (void) item : (unsigned) item selectedIn : (ScrollSelector *) selector;

@end
