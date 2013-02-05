#import "OverlayView.h"

@implementation OverlayView

@synthesize delegate;

//________________________________________________________________________________________
- (id) initWithFrame : (CGRect) frame
{
   if (self = [super initWithFrame : frame]) {
      self.opaque = NO;
      self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent : 0.8f];
      
      UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
      [self addGestureRecognizer : tapRecognizer];
   }
   
   return self;
}

//________________________________________________________________________________________
- (void) handleTap
{
   if (delegate)
      [delegate dismissOverlayView];
}

@end
