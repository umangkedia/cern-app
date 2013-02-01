#import "AppDelegate.h"

@implementation AppDelegate

@synthesize window = _window;

@synthesize OAuthToken, OAuthTokenSecret;

//________________________________________________________________________________________
- (BOOL) application : (UIApplication *) application didFinishLaunchingWithOptions : (NSDictionary *) launchOptions
{
   [[UIBarButtonItem appearance] setTintColor : [UIColor colorWithRed : 0.f green : 83.f / 255.f blue : 161.f / 255.f alpha : 1.f]];

   return YES;
}

//________________________________________________________________________________________
- (void) applicationWillResignActive : (UIApplication *) application
{
  /*
   Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
   Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
   */
}

//________________________________________________________________________________________
- (void) applicationDidEnterBackground : (UIApplication *) application
{
  /*
   Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
   If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
   */
}

//________________________________________________________________________________________
- (void) applicationWillEnterForeground : (UIApplication *) application
{
  /*
   Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
   */
}

//________________________________________________________________________________________
- (void) applicationDidBecomeActive : (UIApplication *) application
{
  /*
   Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
   */
}

//________________________________________________________________________________________
- (void) applicationWillTerminate : (UIApplication *) application
{
  /*
   Called when the application is about to terminate.
   Save data if appropriate.
   See also applicationDidEnterBackground:.
   */
}

@end
