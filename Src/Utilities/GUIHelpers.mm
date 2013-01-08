//
//  GUIHelpers.m
//  ECSlidingViewController
//
//  Created by Timur Pocheptsov on 1/1/13.
//
//

#import <cassert>

#import "GUIHelpers.h"

namespace CernAPP {

const CGFloat spinnerSize = 150.f;
const CGSize navBarBackButtonSize  = CGSizeMake(35.f, 35.f);
const CGFloat navBarHeight = 44.f;

//Menu.
const CGFloat groupMenuItemHeight = 44.f;
const CGFloat childMenuItemHeight = 30.f;

const CGRect menuButtonFrame = CGRectMake(0.f, 0.f, 35.f, 35.f);

//________________________________________________________________________________________
void ResetMenuButton(UIViewController *controller)
{
   assert(controller != nil && "ResetMenuButton, parameter 'controller' is nil");
   assert([controller respondsToSelector:@selector(revealMenu:)] &&
          "ResetMenuButton, controller must respond to 'revealMenu:' selector");
 
   UIButton * const backButton = [UIButton buttonWithType : UIButtonTypeCustom];
   backButton.backgroundColor = [UIColor clearColor];
   backButton.frame = menuButtonFrame;

   [backButton setImage : [UIImage imageNamed : @"menu.png"] forState : UIControlStateNormal];
   [backButton addTarget : controller action : @selector(revealMenu:) forControlEvents : UIControlEventTouchUpInside];
   controller.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]  initWithCustomView : backButton];
}


}
