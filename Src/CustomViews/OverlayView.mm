#import <QuartzCore/QuartzCore.h>

#import "OverlayView.h"

@implementation OverlayView

@synthesize delegate;

//________________________________________________________________________________________
- (id) initWithFrame : (CGRect) frame
{
   if (self = [super initWithFrame : frame]) {
      self.opaque = NO;
//      self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent : 0.8f];
      CALayer * const layer = self.layer;

      CAGradientLayer * const shineLayer = [CAGradientLayer layer];
      shineLayer.frame = layer.bounds;
      shineLayer.colors = @[(id)[UIColor colorWithRed : 0.f green : 0.f blue : 0.f alpha : 0.9].CGColor,
                            (id)[UIColor colorWithRed : 0.3f green : 0.3f blue : 0.3f alpha : 0.6].CGColor,
                            (id)[UIColor colorWithRed : 0.f green : 0.f blue : 0.f alpha : 0.9].CGColor];
      shineLayer.locations = @[@0.f, @0.5f, @1.f];
      [layer addSublayer : shineLayer];
      
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
