//
//  CreditsViewController.m
//  CERN
//
//  Created by Timur Pocheptsov on 2/15/13.
//  Copyright (c) 2013 CERN. All rights reserved.
//

#import <cassert>

#import "CreditsViewController.h"

@implementation CreditsViewController {
   NSMutableAttributedString *text;
   UIColor *captionColor;
}

//________________________________________________________________________________________
- (id) initWithNibName : (NSString *) nibNameOrNil bundle : (NSBundle *) nibBundleOrNil
{
   if (self = [super initWithNibName : nibNameOrNil bundle : nibBundleOrNil]) {
      // Custom initialization
   }

   return self;
}

//________________________________________________________________________________________
- (void) viewDidLoad
{
   [super viewDidLoad];

   text = [[NSMutableAttributedString alloc] init];
   
   captionColor = [UIColor colorWithRed : 0.f green : 83.f / 255.f blue : 161.f / 255.f alpha : 1.f];

   //Now, let's fill our text view with info.
   [self addDevelopersInfo];
   
   textView.attributedText = text;
}

//________________________________________________________________________________________
- (void) didReceiveMemoryWarning
{
   [super didReceiveMemoryWarning];
   //Dispose of any resources that can be recreated.
}

//________________________________________________________________________________________
- (IBAction) donePressed : (id) sender
{
   [self dismissViewControllerAnimated : YES completion : nil];
}

#pragma mark - Compose the text.

//________________________________________________________________________________________
- (void) addDevelopersInfo
{
   //Info about developers can be, of course, read from a special file later :)
   NSAttributedString * const caption = [[NSAttributedString alloc] initWithString : @"\nDevelopers:\n"];
   const NSRange captionRange = NSMakeRange(text.length, caption.length);
   NSAttributedString * const developersInfo = [[NSAttributedString alloc] initWithString : @"\tEamon Ford,\n\tFons Rademakers,\n\tTimur Pocheptsov."];
   const NSRange devInfoRange = NSMakeRange(captionRange.location + captionRange.length, developersInfo.length);
   
   [text appendAttributedString : caption];
   [text appendAttributedString : developersInfo];

   //Let's do some nice formatting here!
   UIFont * const titleFont = [UIFont fontWithName : @"PTSans-Bold" size : 20.f];
   [text addAttribute : NSFontAttributeName value : titleFont range : captionRange];
   [text addAttribute : NSForegroundColorAttributeName value : captionColor range : captionRange];
   //
   UIFont * const textFont = [UIFont fontWithName : @"PTSans-Caption" size : 14.f];
   [text addAttribute : NSFontAttributeName value : textFont range : devInfoRange];
   [text addAttribute : NSForegroundColorAttributeName value : [UIColor blackColor] range : devInfoRange];
}

@end
