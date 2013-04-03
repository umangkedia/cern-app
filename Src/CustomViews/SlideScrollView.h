#import <UIKit/UIKit.h>

@interface SlideScrollView : UIScrollView

//While scrolling content, hitTest should return nil if checkDragging == YES.
@property (nonatomic) BOOL checkDragging;

@end