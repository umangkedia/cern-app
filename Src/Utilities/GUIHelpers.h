//Different GUI constants/aux. functions.

namespace CernAPP {

extern const CGFloat spinnerSize;
extern const CGSize navBarBackButtonSize;
extern const CGFloat navBarHeight;

//Menu.

CGFloat GroupMenuItemHeight();
CGFloat ChildMenuItemHeight();
CGFloat SeparatorItemHeight();

extern const CGFloat childMenuItemTextIndent;
extern NSString * const childMenuFontName;
extern NSString * const groupMenuFontName;
extern const CGFloat childTextColor[3];
extern const CGFloat childMenuFillColor[3];
extern const CGFloat menuBackgroundColor[4];
extern const CGFloat groupMenuItemImageHeight;
extern const CGFloat childMenuItemImageHeight;

extern const CGFloat menuWidthPad;//iPad only.

extern const CGFloat menuItemHighlightColor[2][4];

void GradientFillRect(CGContextRef ctx, const CGRect &rect, const CGFloat *gradientColor);

}
