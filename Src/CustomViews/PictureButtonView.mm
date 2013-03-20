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
   [pict drawInRect : rect];
}

@end
