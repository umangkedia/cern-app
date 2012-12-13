#import <cassert>

#import <UIKit/UIKit.h>

#import "ApplicationErrors.h"

namespace CernAPP
{

//________________________________________________________________________________________
void ShowErrorAlert(NSString *message, NSString *buttonTitle)
{
   UIAlertView * const alert = [[UIAlertView alloc] initWithTitle : @"CERN.app" message : message
                                delegate : nil cancelButtonTitle : buttonTitle otherButtonTitles : nil];
   [alert show];
}

}