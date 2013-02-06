#import <UIKit/UIKit.h>

@protocol OverlayViewDelegate <NSObject>
@required
- (void) dismissOverlayView : (void (^)(BOOL finished)) block;
@end

@interface OverlayView : UIView

- (id) initWithFrame : (CGRect) frame;

@property (weak) id<OverlayViewDelegate> delegate;

@end