#import <cassert>

#import <AudioToolbox/AudioToolbox.h>
#import <QuartzCore/QuartzCore.h>

#import "ScrollSelector.h"

const CGFloat cellHeight = 44.f;
const CGFloat cellWidthRatio = 0.4;//40 % of the full view's width.

@implementation ScrollSelector {
   UIScrollView *contentScroll;
   NSUInteger selectedItem;
   
   CGFloat xPad;
   CGFloat cellWidth;
   
   SystemSoundID clickSound;
   NSUInteger itemsCount;
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

   cellWidth = cellWidthRatio * frame.size.width;
   xPad = (1.f - cellWidthRatio) / 2.f * frame.size.width;
}

//____________________________________________________________________________________________________
- (id) initWithFrame : (CGRect) frame
{
   if (self = [super initWithFrame : frame]) {
      //We make a scroller (who's gonna to replace the navigation bar) to be of a same color,
      //as a navigation bar (this color is defined by a background image).
      [self setBackgroundColor : [UIColor colorWithPatternImage : [UIImage imageNamed : @"navbarback.png"]]];
   
      contentScroll = [[UIScrollView alloc] initWithFrame : CGRectMake(0., 0., frame.size.width, frame.size.height)];
      contentScroll.scrollEnabled = YES;
      //We do paging ourselves.
      contentScroll.pagingEnabled = NO;
      contentScroll.delegate = self;
      
      contentScroll.showsVerticalScrollIndicator  = NO;
      contentScroll.showsHorizontalScrollIndicator = NO;
      contentScroll.decelerationRate = UIScrollViewDecelerationRateFast;
      
      contentScroll.backgroundColor = [UIColor clearColor ];
      [self addSubview : contentScroll];
      
      //Calculate contents geometry:
      cellWidth = cellWidthRatio * contentScroll.frame.size.width;
      xPad = (1.f - cellWidthRatio) / 2.f * contentScroll.frame.size.width;
      
      //Add gradients: left and right sides of scroller are in a shadow,
      //to make it look like a cylindric surface.
      CAGradientLayer * const dropShadowLayer = [CAGradientLayer layer];
      dropShadowLayer.startPoint = CGPointMake(0.f, 0.f);
      dropShadowLayer.endPoint = CGPointMake(0.f, 1.f);
      dropShadowLayer.opacity = 1.f;
      dropShadowLayer.frame = CGRectMake(contentScroll.frame.origin.x, contentScroll.frame.origin.y,
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
      gradientLayer.locations = @[@0.f, @0.35f, @0.65f, @1.f];
      gradientLayer.colors = @[//TODO: check how this works with ARC???
                              (id)[[UIColor colorWithRed : 0.f green : 0.f blue : 0.f alpha : 0.95] CGColor],
                              (id)[[UIColor colorWithRed : 0.f green : 0.f blue : 0.f alpha : 0.] CGColor],
                              (id)[[UIColor colorWithRed : 0.f green : 0.f blue : 0.f alpha : 0.] CGColor],
                              (id)[[UIColor colorWithRed : 0.f green : 0.f blue : 0.f alpha : 0.95] CGColor]];
      [self.layer insertSublayer : gradientLayer above : dropShadowLayer];
      
      //Sound initialization.
      clickSound = 0;
      NSString * const soundPath = [[NSBundle mainBundle] pathForResource : @"scrollerClick" ofType : @"wav"];
      if (soundPath)
         AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath : soundPath], &clickSound);
      else
         NSLog(@"ScrollSelector: NSBundle was not able to find scrollerClick.wav");
      
      itemsCount = 0;
   }

   return self;
}

//____________________________________________________________________________________________________
- (void) dealloc
{
   if (clickSound)//Can valid SystemSoundID be 0?
      AudioServicesDisposeSystemSoundID(clickSound);
}

#pragma mark - "Horizontal picker" emulation.

//____________________________________________________________________________________________________
- (void) findSelectedItemAndAdjustOffset
{
   //After scroll ended, we have to re-adjust, so
   //that item which is near the center now is correctly centered (with animation).

   CGPoint offset = contentScroll.contentOffset;
   const CGFloat middleX = contentScroll.frame.size.width / 2;
   
   const CGFloat currentPos = middleX + offset.x - xPad;
   selectedItem = NSUInteger(currentPos / cellWidth);
   const CGFloat newPos = selectedItem * cellWidth + 0.5 * cellWidth;
   offset.x += newPos - currentPos;
   
   [contentScroll setContentOffset : offset animated : YES];
}

//____________________________________________________________________________________________________
- (void) setSelectedItem : (NSUInteger) item
{
   //setSelectedItem is called externally, no sound played.
   selectedItem = item;

   const CGFloat middleX = contentScroll.frame.size.width / 2;
   const CGFloat x = xPad + selectedItem * cellWidth + 0.5f * cellWidth - middleX;

   [contentScroll setContentOffset : CGPointMake(x, 0.f) animated : YES];
}

//____________________________________________________________________________________________________
- (void) scrollToPos : (CGFloat) pos
{
   //This method is called externally by multi-page controller:
   //the user can scroll pages in controller directly, in this
   //case scroll-wheel should follow (just to make things look nice).
   const CGFloat x = (contentScroll.contentSize.width - 2 * xPad) * pos;
   [contentScroll setContentOffset : CGPointMake(x, 0.f) animated : NO];
}

//____________________________________________________________________________________________________
- (void) notify
{
   //New item was selected via the scroller.
   //Notify the delegate about this.
   
   if ([delegate respondsToSelector : @selector(item : selectedIn :)])
      [delegate item : selectedItem selectedIn : self];
}

//____________________________________________________________________________________________________
- (void) scrollViewDidEndDecelerating : (UIScrollView *) sender
{
   const NSUInteger oldSelected = selectedItem;
   [self findSelectedItemAndAdjustOffset];
   if (oldSelected != selectedItem) {
      [self playClick];
      [self notify];
   }
}

//____________________________________________________________________________________________________
- (void) scrollViewDidEndDragging : (UIScrollView *) scrollView willDecelerate : (BOOL) decelerate
{
   if (!decelerate) {
      const NSUInteger oldSelected = selectedItem;
      [self findSelectedItemAndAdjustOffset];

      if (oldSelected != selectedItem) {
         [self playClick];
         [self notify];
      }
   }
}

#pragma mark - Picker's content management.

//____________________________________________________________________________________________________
- (void) setLabelItemsWithText : (NSMutableArray *) items
{
   assert(items != nil && "addItemNames:, 'items' parameter is nil");

   if (![items count])
      return;

   for (UIView *v in [contentScroll subviews])
      [v removeFromSuperview];

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
   itemsCount = [items count];
}

//____________________________________________________________________________________________________
- (NSUInteger) itemsCount
{
   return itemsCount;
}

#pragma mark - Sound.

//____________________________________________________________________________________________________
- (void) playClick
{
   if (clickSound) //Not clear, can valid SystemSoundID be 0?
      AudioServicesPlaySystemSound(clickSound);
}


@end
