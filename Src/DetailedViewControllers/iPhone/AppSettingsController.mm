//
//  AppSettingsController.m
//  CERN
//
//  Created by Timur Pocheptsov on 2/14/13.
//  Copyright (c) 2013 CERN. All rights reserved.
//

#import <cassert>

#import <QuartzCore/QuartzCore.h>

#import "AppSettingsController.h"

@implementation AppSettingsController

//________________________________________________________________________________________
- (void) defaultsChanged : (NSNotification *) notification
{
    if ([notification.object isKindOfClass : [NSUserDefaults class]]) {
      NSUserDefaults * const defaults = (NSUserDefaults *)notification.object;
      if (id sz = [defaults objectForKey : @"HTMLBodyFontSize"]) {
         assert([sz isKindOfClass : [NSNumber class]] && "defaultsChanged:, HTMLBodyFontSize has a wrong type");
         [rdbFontSizeSlider setValue : [(NSNumber *)sz floatValue]];
      } else if ((sz = [defaults objectForKey:@"GUIFontSize"])) {
         assert([sz isKindOfClass : [NSNumber class]] && "defaultsChanged:, GUIFontSize has a wrong type");
         [guiFontSizeSlider setValue : [(NSNumber *)sz floatValue]];
      }
   }
}

//________________________________________________________________________________________
- (id) initWithNibName : (NSString *) nibNameOrNil bundle : (NSBundle *) nibBundleOrNil
{
   if (self = [super initWithNibName : nibNameOrNil bundle : nibBundleOrNil]) {

   }

   return self;
}

//________________________________________________________________________________________
- (void) dealloc
{
   [[NSNotificationCenter defaultCenter] removeObserver : self];
}

//________________________________________________________________________________________
- (void) viewDidLoad
{
   [super viewDidLoad];
	// Do any additional setup after loading the view.
   //set group views.
   guiSettingsView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent : 0.5f];
   guiSettingsView.layer.cornerRadius = 10.f;
   
   rdbSettingsView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent : 0.5f];
   rdbSettingsView.layer.cornerRadius = 10.f;
   
   //Read defaults for the sliders.
   NSUserDefaults * const defaults = [NSUserDefaults standardUserDefaults];
   if (id sz = [defaults objectForKey : @"GUIFontSize"]) {
      assert([sz isKindOfClass : [NSNumber class]] && "viewDidLoad, 'GUIFontSize' has a wrong type");
      [guiFontSizeSlider setValue : [(NSNumber *)sz floatValue]];
   }

   if (id sz = [defaults objectForKey : @"HTMLBodyFontSize"]) {
      assert([sz isKindOfClass : [NSNumber class]] && "viewDidLoad, 'HTMLBodyFontSize' has a wrong type");
      [rdbFontSizeSlider setValue : [(NSNumber *)sz floatValue]];
   }
   
   [[NSNotificationCenter defaultCenter] addObserver : self selector : @selector(defaultsChanged:) name : NSUserDefaultsDidChangeNotification object : nil];
}

//________________________________________________________________________________________
- (void) didReceiveMemoryWarning
{
   [super didReceiveMemoryWarning];
   // Dispose of any resources that can be recreated.
}

#pragma mark - GUI events.

//_______________________________________________________________________________________
- (IBAction) donePressed : (id)sender
{
   [self dismissViewControllerAnimated : YES completion : nil];
}

//_______________________________________________________________________________________
- (IBAction) guiFontSizeChanged : (UISlider *) sender
{
   assert(sender != nil && "guiFontSizeChanged:, parameter 'sender' is nil");

   [[NSUserDefaults standardUserDefaults] setFloat : sender.value forKey : @"GUIFontSize"];
   [[NSUserDefaults standardUserDefaults] synchronize];
}

//________________________________________________________________________________________
- (IBAction) htmlFontSizeChanged : (UISlider *) sender
{
   assert(sender != nil && "htmlFontSizeChanged:, parameter 'sender' is nil");
   
   [[NSUserDefaults standardUserDefaults] setFloat : sender.value forKey : @"HTMLBodyFontSize"];
   [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Interface orientation.

//________________________________________________________________________________________
- (BOOL) shouldAutorotate
{
   return NO;
}

@end
