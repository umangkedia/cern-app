#import <UIKit/UIKit.h>

namespace CernAPP {

extern const CGRect defaultBackButtonRect;

//Reset a left button in a navigation item to a small square button with
//some background image.
void ResetBackButton(UIViewController *controller, NSString *imageName);

}
