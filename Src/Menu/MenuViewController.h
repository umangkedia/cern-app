//This code is based on a code sample by Michael Enriquez (EdgeCase).
//Code was further developed/modified (and probably broken) by Timur Pocheptsov
//for CERN.app - to load our own menu we need.

#import <UIKit/UIKit.h>

@class MenuItemView;

@interface MenuViewController : UIViewController {
   IBOutlet __weak UIScrollView *scrollView;
}

- (void) itemViewWasSelected : (MenuItemView *) view;

@end
