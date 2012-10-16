//
//  ExperimentsViewController.m
//  CERN App
//
//  Created by Eamon Ford on 6/20/12.
//  Copyright (c) 2012 CERN. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "ExperimentFunctionSelectorViewController.h"
#import "ExperimentsViewController.h"
#import "DeviceCheck.h"
#import "Constants.h"

#define CMS_BUTTON 0
#define LHCB_BUTTON 1
#define ATLAS_BUTTON 2
#define ALICE_BUTTON 3

@implementation ExperimentsViewController

@synthesize mapImageView, shadowImageView, atlasButton, cmsButton, aliceButton, lhcbButton, lhcButton, popoverController;

//________________________________________________________________________________________
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
   self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
   if (self) {
      self.mapImageView.backgroundColor = [UIColor clearColor];
      self.mapImageView.opaque = NO;
      self.shadowImageView.backgroundColor = [UIColor clearColor];
      self.shadowImageView.opaque = NO;
   }

   return self;
}

//________________________________________________________________________________________
- (void)viewDidLoad
{
}

//________________________________________________________________________________________
- (void)viewDidAppear:(BOOL)animated
{
   // Fade in the shadow graphic
   [UIView animateWithDuration : 0.5f animations:^{self.shadowImageView.alpha = 1.f;}];
}

//________________________________________________________________________________________
- (void)viewWillAppear:(BOOL)animated
{
   self.shadowImageView.alpha = 0.f;
   
   self.navigationController.navigationBarHidden = YES;
   [self setupVisualsForOrientation:[UIApplication sharedApplication].statusBarOrientation withDuration : 0.];
}

//________________________________________________________________________________________
- (void)viewWillDisappear:(BOOL)animated
{
   self.navigationController.navigationBarHidden = NO;
}

//________________________________________________________________________________________
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
   if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
      return YES;
   else
      return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

//________________________________________________________________________________________
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
   [self setupVisualsForOrientation:toInterfaceOrientation withDuration:duration];
}

//________________________________________________________________________________________
- (void)setupVisualsForOrientation:(UIDeviceOrientation)orientation withDuration:(NSTimeInterval)duration
{
    CATransition *transition = [CATransition animation];
    transition.duration = duration;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    transition.type = kCATransitionFade;
    [self.mapImageView.layer addAnimation:transition forKey:nil];
    
    // We have to hardcode the coordinates of each button on the screen for each device orientation. Yes, this is horrible
    // but it's really the only way to do it.
   
    //TP: I'm pretty sure, there are over 9000 ways to make it right way instead of this hardcoded nightmare ;)
   
    if (UIDeviceOrientationIsPortrait(orientation)) {

        const BOOL deviceIsIPhone5 = [DeviceCheck deviceIsiPhone5];
       
        self.mapImageView.image = [UIImage imageNamed:@"mapPortrait"];//This does not work correctly???
        self.shadowImageView.image = [UIImage imageNamed:@"mapShadowPortrait"];
       
        if ([DeviceCheck deviceIsiPhone5]) {
            self.mapImageView.image = [UIImage imageNamed : @"mapPortrait-568h@2x~iphone"];
            self.shadowImageView.image = [UIImage imageNamed : @"mapShadowPortrait-568h@2x~iphone"];
        }
       
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            //568 image was not scaled, I can not calculate this shift from sizes,
            //that's why it's ... elegantly hardcoded :))))
            const CGFloat yShift = deviceIsIPhone5 ? 35.f : 0.f;
        
            const CGFloat sideLength = 44.f;
            self.atlasButton.frame = CGRectMake(168.0, 244.0 + yShift, sideLength, sideLength);
            self.cmsButton.frame = CGRectMake(61.0, 308.0 + yShift, sideLength, sideLength);
            self.aliceButton.frame = CGRectMake(235.0, 260.0 + yShift, sideLength, sideLength);
            self.lhcbButton.frame = CGRectMake(87.0, 241.0 + yShift, sideLength, sideLength);
            self.lhcButton.frame = CGRectMake(220.0, 310.0 + yShift, sideLength, sideLength);
            
        } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            float sideLength = 85.0;
            self.atlasButton.frame = CGRectMake(422.0, 548.0, sideLength, sideLength);
            self.cmsButton.frame = CGRectMake(157.0, 705.0, sideLength, sideLength);
            self.aliceButton.frame = CGRectMake(569.0, 596.0, sideLength, sideLength);
            self.lhcbButton.frame = CGRectMake(226.0, 555.0, sideLength, sideLength);
            self.lhcButton.frame = CGRectMake(543.0, 710.0, sideLength, sideLength);
        }
    } else {
        self.mapImageView.image = [UIImage imageNamed:@"mapLandscape"];
        self.shadowImageView.image = [UIImage imageNamed:@"mapShadowLandscape"];
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            float sideLength = 85.0;
            self.atlasButton.frame = CGRectMake(567.0, 448.0, sideLength, sideLength);
            self.cmsButton.frame = CGRectMake(295.0, 599.0, sideLength, sideLength);
            self.aliceButton.frame = CGRectMake(744.0, 480.0, sideLength, sideLength);
            self.lhcbButton.frame = CGRectMake(371.0, 439.0, sideLength, sideLength);
            self.lhcButton.frame = CGRectMake(706.0, 601.0, sideLength, sideLength);
        }
    }
}

//________________________________________________________________________________________
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
   ExperimentFunctionSelectorViewController *viewController = [segue destinationViewController];

   // Since viewController.experiment is an ExperimentType enum, it will be an integer between 0 and 3. So the button tags in the storyboard are just set to match the enum types.
   viewController.experiment = ((UIButton *)sender).tag;
}

//________________________________________________________________________________________
- (IBAction)buttonTapped:(UIButton *)sender
{
   if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
      ExperimentFunctionSelectorViewController *viewController = [[UIStoryboard storyboardWithName:@"MainStoryboard_iPad" bundle:nil] instantiateViewControllerWithIdentifier:kExperimentFunctionSelectorViewIdentifier];
      viewController.experiment = sender.tag;
      self.popoverController = [[UIPopoverController alloc] initWithContentViewController:viewController];
      self.popoverController.popoverContentSize = CGSizeMake(320, 200);
      //show the popover next to the annotation view (pin)
      [self.popoverController presentPopoverFromRect:sender.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
   }
}

@end
