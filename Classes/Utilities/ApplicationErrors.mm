#import <cassert>

#import <UIKit/UIKit.h>

#import "MultiPageController.h"
#import "ControllerUtilities.h"
#import "ApplicationErrors.h"

namespace CernAPP
{

//________________________________________________________________________________________
void ShowErrorAlert(NSString *message, NSString *buttonTitle)
{
   assert(message != nil && "ShowErrorAlert, parameter 'message' is nil");
   assert(buttonTitle != nil && "ShowErrorAlert, parameter 'buttonTitle' is nil");

   UIAlertView * const alert = [[UIAlertView alloc] initWithTitle : @"CERN.app" message : message
                                delegate : nil cancelButtonTitle : buttonTitle otherButtonTitles : nil];
   [alert show];
}

//________________________________________________________________________________________
void ShowErrorAlertIfTopLevel(NSString *message, NSString *buttonTitle, UIViewController *controller)
{
   assert(message != nil && "ShowErrorAlertIfTopLevel, parameter 'message' is nil");
   assert(buttonTitle != nil && "ShowErrorAlertIfTopLevel, parameter 'buttonTitle' is nil");
   assert(controller != nil && "ShowErrorAlertIfTopLevel, parameter 'controller' is nil");
   
   if (FindTopLevelViewController() == controller)
      ShowErrorAlert(message, buttonTitle);
}

}