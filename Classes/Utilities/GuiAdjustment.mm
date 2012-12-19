#import <cassert>

#import "ScrollSelector.h"
#import "GuiAdjustment.h"
#import "DeviceCheck.h"

namespace CernAPP {

const CGRect defaultBackButtonRect = CGRectMake(0., 0., 35.f, 35.f);
const CGSize navBarBackButtonSize  = CGSizeMake(35.f, 35.f);

//________________________________________________________________________________________
void ResetBackButton(UIViewController *controller, NSString *imageName)
{
   assert([DeviceCheck deviceIsiPad] == NO && "ResetBackButton, only for iPhone GUI");

   assert(controller != nil && "ResetBackButton, parameter 'controller' is nil");
   assert([controller respondsToSelector:@selector(backButtonPressed)] &&
          "ResetBackButton, controller must respond to 'backButtonPressed' selector");

   UIButton * const backButton = [UIButton buttonWithType : UIButtonTypeCustom];
   backButton.backgroundColor = [UIColor clearColor];
   backButton.frame = defaultBackButtonRect;

   if (!imageName)
      imageName = @"back_button_flat.png";

   [backButton setImage : [UIImage imageNamed : imageName] forState : UIControlStateNormal];
   [backButton addTarget : controller action : @selector(backButtonPressed) forControlEvents : UIControlEventTouchUpInside];
   controller.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]  initWithCustomView : backButton];
}

//________________________________________________________________________________________
void ResetRightNavigationButton(UIViewController *controller, NSString *imageName, SEL action)
{
   assert([DeviceCheck deviceIsiPad] == NO && "ResetRightNavigationButton, only for iPhone GUI");

   assert(controller != nil && "ResetRightNavigationButton, parameter 'controller' is nil");
   assert(imageName != nil && "ResetRightNavigationButton, parameter 'imageName' is nil");
   assert(action != nil && "ResetRightNavigationButton, parameter 'action' is nil");
   
   UIButton * const button = [UIButton buttonWithType : UIButtonTypeCustom];
   button.backgroundColor = [UIColor clearColor];
   button.frame = defaultBackButtonRect;
   
   const CGSize &btnSize = button.frame.size;
   button.frame = CGRectMake(320 - btnSize.width - 5, ([ScrollSelector defaultHeight] - btnSize.height) / 2.f, btnSize.width, btnSize.height);
   [button setImage : [UIImage imageNamed : imageName] forState : UIControlStateNormal];

   [button addTarget : controller action : action forControlEvents : UIControlEventTouchUpInside];
   controller.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]  initWithCustomView : button];
}

}
