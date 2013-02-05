#import <UIKit/UIKit.h>

@protocol OverlayViewDelegate <NSObject>
@required
- (void) dismissOverlayView;
@end

@interface OverlayView : UIView

- (id) initWithFrame : (CGRect) frame;

@property (weak) id<OverlayViewDelegate> delegate;

@end