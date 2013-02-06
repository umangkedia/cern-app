//
//  BtnView.m
//  FBT
//
//  Created by Timur Pocheptsov on 2/5/13.
//  Copyright (c) 2013 Timur Pocheptsov. All rights reserved.
//

#import <cassert>

#import <QuartzCore/QuartzCore.h>

#import "PictureButtonView.h"

@implementation PictureButtonView {
   UIImage *pict;
   __weak NSObject *target;
   SEL selector;
}

//________________________________________________________________________________________
- (id) initWithFrame : (CGRect)frame image : (UIImage *) image;
{
   if (self = [super initWithFrame : frame]) {
      // Initialization code
      pict = image;
      self.backgroundColor = [UIColor clearColor];
      /*
      CALayer * const layer = self.layer;
      layer.cornerRadius = 8.0f;
      layer.masksToBounds = YES;
      layer.borderWidth = 1.0f;
      layer.borderColor = [UIColor colorWithWhite:1.f alpha : 0.2f].CGColor;

      CAGradientLayer * const shineLayer = [CAGradientLayer layer];
      shineLayer.frame = layer.bounds;
      shineLayer.colors = @[(id)[UIColor colorWithWhite:1.0f alpha:0.4f].CGColor, (id)[UIColor colorWithWhite:1.0f alpha:0.2f].CGColor,
                            (id)[UIColor colorWithWhite:0.75f alpha:0.2f].CGColor, (id)[UIColor colorWithWhite:0.4f alpha:0.2f].CGColor,
                            (id)[UIColor colorWithWhite:1.0f alpha:0.4f].CGColor];
      shineLayer.locations = @[@0.f, @0.5f, @0.5f, @0.8f, @1.f];
      [layer addSublayer : shineLayer];*/
      
      UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
      [self addGestureRecognizer : tapRecognizer];
   }

   return self;
}

//________________________________________________________________________________________
- (void) addTarget : (NSObject *) aTarget selector : (SEL) aSelector
{
   assert(aTarget != nil && "addTarget:selector:, parameter 'target' is nil");
   assert(aSelector != nil && "addTarget:selector:, parameter 'aSelector' is nil");
   
   target = aTarget;
   selector = aSelector;
}

//________________________________________________________________________________________
- (void) handleTap
{
   if (target)//Not simply performSelector to suppress ARC's warning.
      [target performSelector : selector withObject : nil afterDelay : 0];

}

//________________________________________________________________________________________
- (void) drawRect : (CGRect)rect
{
//   [pict drawInRect : CGRectMake(rect.origin.x + 20, rect.origin.y + 20, rect.size.width - 40, rect.size.height - 40)];
   [pict drawInRect : rect];
}

@end
