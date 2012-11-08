#import <cassert>

#import <QuartzCore/QuartzCore.h>

#import "ScrollSelector.h"

namespace {

const CGFloat cellHeight = 40.f;

}

@implementation ScrollSelector {
   UIScrollView *contentScroll;
   unsigned selectedItem;
   
   CGFloat xPad;
   CGFloat cellWidth;
}

@synthesize delegate;

//____________________________________________________________________________________________________
+ (CGFloat) defaultHeight
{
   return cellHeight;
}

//____________________________________________________________________________________________________
- (void) calculateContentsGeometry
{
   const CGRect frame = contentScroll.frame;
   
   xPad = 0.2f * frame.size.width;
   cellWidth = 0.6f * frame.size.width;
}

//____________________________________________________________________________________________________
- (id) initWithFrame : (CGRect)frame
{
   if (self = [super initWithFrame : frame]) {
      self.backgroundColor = [UIColor blackColor];
   
      contentScroll = [[UIScrollView alloc] initWithFrame : CGRectMake(0., 0., frame.size.width, frame.size.height)];
      contentScroll.scrollEnabled = YES;
      contentScroll.pagingEnabled = NO;
      contentScroll.delegate = self;
      
      contentScroll.showsVerticalScrollIndicator = NO;
      contentScroll.showsHorizontalScrollIndicator = NO;
      contentScroll.decelerationRate = UIScrollViewDecelerationRateFast;
      
      contentScroll.backgroundColor = [UIColor clearColor ];//darkGrayColor];
      [self addSubview : contentScroll];
      
      [self calculateContentsGeometry];      
      
      CAGradientLayer *dropshadowLayer = [CAGradientLayer layer];
      dropshadowLayer.startPoint = CGPointMake(0.f, 0.f);
      dropshadowLayer.endPoint = CGPointMake(0.f, 1.f);
      dropshadowLayer.opacity = 1.f;
      dropshadowLayer.frame = CGRectMake(contentScroll.frame.origin.x, contentScroll.frame.origin.y, 
                                         contentScroll.frame.size.width, contentScroll.frame.size.height);

      //At the left and the right sides of scroller we have kind of a shadow,
      //to make it look like it's a cylinder (like picker, but horizontally oriented).
      CAGradientLayer *gradientLayer = [CAGradientLayer layer];
      gradientLayer.startPoint = CGPointMake(0.f, 0.f);
      gradientLayer.endPoint = CGPointMake(1.f, 0.f);
      gradientLayer.opacity = 1.f;
      gradientLayer.frame = CGRectMake(contentScroll.frame.origin.x, contentScroll.frame.origin.y, 
                                       contentScroll.frame.size.width, contentScroll.frame.size.height);
      //At least something is good about modern Obj-C - no need in explicit NSNumber creation for every literal.
      gradientLayer.locations = @[@0.0f, @0.35f, @0.65f, @1.0f];
      gradientLayer.colors = @[
                              (id)[[UIColor colorWithRed : 0.f green : 0.f blue : 0.f alpha : 0.95] CGColor],
                              (id)[[UIColor colorWithRed : 0.f green : 0.f blue : 0.f alpha : 0.] CGColor],
                              (id)[[UIColor colorWithRed : 0.f green : 0.f blue : 0.f alpha : 0.] CGColor],
                              (id)[[UIColor colorWithRed : 0.f green : 0.f blue : 0.f alpha : 0.95] CGColor]];
      [self.layer insertSublayer : gradientLayer above : dropshadowLayer];
   }

   return self;
}

//____________________________________________________________________________________________________
- (void) findSelectedItemAndAdjustOffset
{
   //After scroll ended, we have to re-adjust, so
   //that item which is near the center now is correctly centered (with animation).

   CGPoint offset = contentScroll.contentOffset;
   const CGFloat middleX = contentScroll.frame.size.width / 2;
   
   const CGFloat currentPos = middleX + offset.x - xPad;
   selectedItem = unsigned(currentPos / cellWidth);
   const CGFloat newPos = selectedItem * cellWidth + 0.5 * cellWidth;
   offset.x += newPos - currentPos;
   
   [contentScroll setContentOffset : offset animated : YES];
}

//____________________________________________________________________________________________________
- (void) setSelectedItem : (unsigned int) item
{
   selectedItem = item;
   const CGFloat middleX = contentScroll.frame.size.width / 2;
   const CGFloat x = xPad + selectedItem * cellWidth + 0.5f * cellWidth - middleX;

   [contentScroll setContentOffset : CGPointMake(x, 0.f) animated : YES];
}

//____________________________________________________________________________________________________
- (void) notify
{
   if ([delegate respondsToSelector:@selector(item:selectedIn:)])
      [delegate item : selectedItem selectedIn : self];
}

//____________________________________________________________________________________________________
- (void) scrollViewDidEndDecelerating : (UIScrollView *) sender
{
   const unsigned oldSelected = selectedItem;
   [self findSelectedItemAndAdjustOffset];
   if (oldSelected != selectedItem)
      [self notify];
}

//____________________________________________________________________________________________________
- (void) scrollViewDidEndDragging : (UIScrollView *) scrollView willDecelerate : (BOOL) decelerate
{
   if (!decelerate) {
      const unsigned oldSelected = selectedItem;
      [self findSelectedItemAndAdjustOffset];
      if (oldSelected != selectedItem)
         [self notify];
   }
}

#pragma mark - Picker's content management.

//____________________________________________________________________________________________________
- (void) addItemNames : (NSArray *) items
{
   assert(items != nil && "addItemNames:, 'items' parameter is nil");

   if (![items count])
      return;

   CGFloat currPos = xPad;
   NSEnumerator * const enumerator = [items objectEnumerator];

   UIFont *labelFont = [UIFont fontWithName:@"PT Sans" size : 18];
   assert(labelFont != nil && "addItemNames, labelFont was not found");

   for (NSString *itemName = [enumerator nextObject]; itemName; itemName = [enumerator nextObject]) {
      UILabel * const itemLabel = [[UILabel alloc] initWithFrame : CGRectMake(currPos, 0.f, cellWidth, cellHeight)];
      itemLabel.textAlignment = NSTextAlignmentCenter;
      itemLabel.text = itemName;
      itemLabel.numberOfLines = 1;
      itemLabel.clipsToBounds = YES;
      itemLabel.backgroundColor = [UIColor clearColor];
      itemLabel.textColor = [UIColor whiteColor];
      itemLabel.font = labelFont;
      [contentScroll addSubview : itemLabel];
      
      currPos += cellWidth;
   }

   contentScroll.contentSize = CGSizeMake(2 * xPad + [items count] * cellWidth, cellHeight);
   [self setSelectedItem : 0];
}

@end