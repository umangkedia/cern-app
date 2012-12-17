//
//  ControllerUtilities.m
//  CERN
//
//  Created by Timur Pocheptsov on 12/17/12.
//  Copyright (c) 2012 CERN. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ControllerUtilities.h"
#import "MultiPageController.h"

namespace CernAPP {

//________________________________________________________________________________________
UIViewController *FindTopLevelViewController(UIViewController *root)
{
   if ([root isKindOfClass : [UINavigationController class]])
      return FindTopLevelViewController(((UINavigationController *)root).topViewController);
   else if ([root isKindOfClass : [UITabBarController class]])
      return FindTopLevelViewController(((UITabBarController *)root).selectedViewController);
   else if ([root isKindOfClass : [MultiPageController class]])
      return FindTopLevelViewController(((MultiPageController *)root).selectedViewController);

   return root;
}

//________________________________________________________________________________________
UIViewController *FindTopLevelViewController()
{
   UIWindow * const window = [[UIApplication sharedApplication] delegate].window;
   if (window) {
      UIViewController * const vcBase = window.rootViewController;
      if (vcBase)
         return FindTopLevelViewController(vcBase);
      
      NSLog(@"FindTopLevelViewController, rootViewController is nil");
   }
   
   return nil;
}

}