//
//  StaticInfoViewController.m
//  CERN App
//
//  Created by Eamon Ford on 7/17/12.
//  Copyright (c) 2012 CERN. All rights reserved.
//

#import <cassert>

#import <QuartzCore/QuartzCore.h>

#import "StaticInfoItemViewController.h"
#import "DeviceCheck.h"

@implementation StaticInfoItemViewController

@synthesize staticInfo;

//________________________________________________________________________________________
- (id)initWithNibName : (NSString *) nibNameOrNil bundle : (NSBundle *) nibBundleOrNil
{
   return self = [super initWithNibName : nibNameOrNil bundle : nibBundleOrNil];
}

//________________________________________________________________________________________
- (void) viewDidLoad
{
   [super viewDidLoad];
/*
   UITapGestureRecognizer * const singleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget : self action : @selector(handleSingleTap:)];
   [self.view addGestureRecognizer : singleFingerTap];

   // Move all of our subviews into a container view which will have the rounded corners

   CGRect viewFrame = self.view.frame;
   if ([DeviceCheck deviceIsiPad])
      viewFrame.origin = CGPointZero;
   else
      viewFrame = self.scrollView.frame;

   UIView *roundedView = [[UIView alloc] initWithFrame : viewFrame];
   roundedView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
   roundedView.layer.cornerRadius = 10.0;
   roundedView.clipsToBounds = YES;

   if ([DeviceCheck deviceIsiPad]) {
      for (UIView *subview in self.view.subviews) {
         [subview removeFromSuperview];
         [roundedView addSubview : subview];
      }
   } else {
      [self.scrollView removeFromSuperview];
      CGRect scrollViewFrame = viewFrame;
      scrollViewFrame.origin = CGPointZero;
      self.scrollView.frame = scrollViewFrame;
      [roundedView addSubview : self.scrollView];
   }
   
   [self.view addSubview : roundedView];


   self.scrollView.backgroundColor = [UIColor colorWithWhite : 0.9f alpha : 1.f];

   if ([DeviceCheck deviceIsiPad]) {
      self.view.layer.shadowOpacity = 0.5;
      self.view.layer.shadowRadius = 2.0;
      self.view.layer.shadowOffset = CGSizeMake(0.0, 1.0);
      CGPathRef shadowPathRef = [UIBezierPath bezierPathWithRoundedRect:self.view.frame cornerRadius:10.0].CGPath;
      self.view.layer.shadowPath = shadowPathRef;
      self.view.layer.cornerRadius = 10.f;
      self.view.layer.shadowColor = [UIColor blackColor].CGColor;

      self.imageView.layer.borderColor = [UIColor blackColor].CGColor;
      self.imageView.layer.borderWidth = 1.f;
   }
  
   if ([DeviceCheck deviceIsiPad])
      [self setAndPositionInformation];*/
}
/*
//________________________________________________________________________________________
- (void) viewDidLayoutSubviews
{
   //TP: now we fix layout, broken by UIKit.
   if (![DeviceCheck deviceIsiPad])
      [self setAndPositionInformation];
}
*/
//________________________________________________________________________________________
- (void) setAndPositionInformation
{
   // Set the image, and position it right below the title label
 /*  NSString * const imageName = [self.staticInfo objectForKey : @"Image"];
   UIImage * const image = [UIImage imageNamed : imageName];
   self.imageView.image = image;

   // Set the title label and resize it accordingly
   NSString *title = [self.staticInfo objectForKey : @"Title"];
   self.navigationItem.title = title;
   self.titleLabel.text = title;

   const CGSize titleSize = [title sizeWithFont : self.titleLabel.font constrainedToSize : CGSizeMake(self.titleLabel.frame.size.width, CGFLOAT_MAX)];

   NSString * const description = [self.staticInfo objectForKey:@"Description"];
   CGSize descriptionSize = [description sizeWithFont : self.descriptionLabel.font constrainedToSize : CGSizeMake(self.descriptionLabel.frame.size.width, CGFLOAT_MAX)];

   if ([DeviceCheck deviceIsiPad]) {
      //This code below worked incorrectly for iPhone (both 3.5 and 4.5).
      titleLabel.frame = CGRectMake(titleLabel.frame.origin.x, self.imageView.frame.origin.y+self.imageView.frame.size.height+8.0f, titleLabel.frame.size.width, titleSize.height);
      // Set the description label and resize it accordingly, and also position it right below the image view
      NSString *description = [self.staticInfo objectForKey:@"Description"];
      descriptionLabel.frame = CGRectMake(descriptionLabel.frame.origin.x, titleLabel.frame.origin.y+titleLabel.frame.size.height+8.0f, descriptionLabel.frame.size.width, descriptionSize.height);
      self.descriptionLabel.text = description;
      // Set the content size of the scrollview
      self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, self.descriptionLabel.frame.origin.y+self.descriptionLabel.frame.size.height);
   } else {
      titleLabel.frame = CGRectMake(titleLabel.frame.origin.x, self.imageView.frame.size.height + 8.0f, titleLabel.frame.size.width, titleSize.height);
      // Set the description label and resize it accordingly, and also position it right below the image view
      descriptionLabel.frame = CGRectMake(descriptionLabel.frame.origin.x, titleLabel.frame.origin.y + titleLabel.frame.size.height + 8.0f, descriptionLabel.frame.size.width, descriptionSize.height);
      self.descriptionLabel.text = description;
   }

   // Set the content size of the scrollview
   self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, self.descriptionLabel.frame.origin.y+self.descriptionLabel.frame.size.height);*/
}

//________________________________________________________________________________________
- (void) handleSingleTap : (UITapGestureRecognizer *) recognizer 
{
  /* CGPoint touchLocation = [recognizer locationInView : self.view];
   // If the photo was tapped, display it fullscreen
   if (CGRectContainsPoint(self.imageView.frame, touchLocation)) {
      MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
      UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:browser];
      navigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;

      [self presentViewController : navigationController animated : YES completion : nil];
   } else {
      // Otherwise if the tap was anywhere else on the view, dismiss the view
      //[self dismissModalViewControllerAnimated : YES];
      [self dismissViewControllerAnimated : YES completion : nil];
   }*/
}

/*
#pragma mark - MWPhotoBrowserDelegate methods

//________________________________________________________________________________________
- (NSUInteger) numberOfPhotosInPhotoBrowser : (MWPhotoBrowser *) photoBrowser
{
    return 1;
}

//________________________________________________________________________________________
- (MWPhoto *) photoBrowser : (MWPhotoBrowser *) photoBrowser photoAtIndex : (NSUInteger) index
{
    UIImage *photo = [UIImage imageNamed:[self.staticInfo objectForKey:@"Image"]];
    return [MWPhoto photoWithImage:photo];
}
*/

@end
