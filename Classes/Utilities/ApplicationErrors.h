//
//  ApplicationErrors.h
//  CERN
//
//  Created by Timur Pocheptsov on 12/13/12.
//  Copyright (c) 2012 CERN. All rights reserved.
//

@class UIViewController;
@class NSString;

namespace CernAPP {

void ShowErrorAlert(NSString *message, NSString *buttonTitle);
void ShowErrorAlertIfTopLevel(NSString *message, NSString *buttonTitle, UIViewController *controller);

}