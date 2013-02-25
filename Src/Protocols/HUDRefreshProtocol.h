//
//  HUDRefreshProtocol.h
//  CERN
//
//  Created by Timur Pocheptsov on 2/25/13.
//  Copyright (c) 2013 CERN. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MBProgressHUD.h"

@protocol HUDRefreshProtocol<NSObject>
@required

@property (nonatomic, strong) MBProgressHUD *noConnectionHUD;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;

@end

namespace CernAPP {

void AddSpinner(UIViewController<HUDRefreshProtocol> *controller);
void ShowSpinner(UIViewController<HUDRefreshProtocol> *controller);
void HideSpinner(UIViewController<HUDRefreshProtocol> *controller);
void ShowErrorHUD(UIViewController<HUDRefreshProtocol> *controller, NSString *errorMessage);

}
