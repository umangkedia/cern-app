#import <cassert>

#import "GuiAdjustment.h"

namespace CernAPP {

const CGRect defaultBackButtonRect = CGRectMake(0., 0., 35.f, 35.f);

//________________________________________________________________________________________
void ResetBackButton(UIViewController *controller, NSString *imageName)
{
   assert(controller != nil && "ResetBackButton, parameter 'controller' is nil");
   assert([controller respondsToSelector:@selector(backButtonPressed)] &&
          "ResetBackButton, controller must respond to 'backButtonPressed' selector");

   UIButton * const backButton = [UIButton buttonWithType : UIButtonTypeCustom];
   backButton.backgroundColor = [UIColor clearColor];
   backButton.frame = CGRectMake(0, 0, 35.f, 35.f);

   if (!imageName)
      imageName = @"back_button_flat.png";

   [backButton setImage : [UIImage imageNamed : imageName] forState : UIControlStateNormal];
   [backButton addTarget : controller action : @selector(backButtonPressed) forControlEvents : UIControlEventTouchUpInside];
   controller.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]  initWithCustomView : backButton];
}

}
