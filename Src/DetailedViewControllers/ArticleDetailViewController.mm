//
//  ArticleDetailViewController.m
//  CERN App
//
//  Created by Eamon Ford on 6/18/12.
//  Copyright (c) 2012 CERN. All rights reserved.
//

//Modified by Timur Pocheptsov.

#import "ArticleDetailViewController.h"
#import "ApplicationErrors.h"
#import "PictureButtonView.h"
#import "NSString+HTML.h"
#import "Reachability.h"
#import "AppDelegate.h"
#import "GCOAuth.h"

namespace {

enum class LoadStage : unsigned char {
   inactive,
   auth,
   rdbRequest,
   originalPageLoad,
   needRefresh
};

//________________________________________________________________________________________
CGFloat DefaultHTMLBodyFontSize()
{
   //Some number in a range [0, 20]

   NSUserDefaults * const defaults = [NSUserDefaults standardUserDefaults];
   if (id sz = [defaults objectForKey:@"HTMLBodyFontSize"]) {
      assert([sz isKindOfClass : [NSNumber class]] && "DefaultHTMLBodyFontSize, dictionary expected");
      return [(NSNumber *)sz floatValue];
   }
   
   return 0.f;
}

const NSUInteger fontIncreaseStep = 4;

}



@implementation ArticleDetailViewController {
   NSString *articleLink;
   UIActivityIndicatorView *spinner;
   
   Reachability *internetReach;
   //
   LoadStage stage;
   NSInteger status;
   NSMutableData *responseData;
   
   NSURLConnection *currentConnection;
   
   UIButton *zoomInBtn;
   UIButton *zoomOutBtn;
   
   NSUInteger zoomLevel;

   BOOL rdbLoaded;
   BOOL pageLoaded;
   
   OverlayView *sendOverlay;
   BOOL animatingOverlay;
}

@synthesize rdbView, pageView, rdbCache, title;

//It has to be included here, since the file can contain
//methods.
#import "Readability.h"

//________________________________________________________________________________________
- (void) reachabilityStatusChanged : (Reachability *) current
{
#pragma unused(current)
   using CernAPP::NetworkStatus;
   
   if (internetReach && [internetReach currentReachabilityStatus] == NetworkStatus::notReachable) {
      [rdbView stopLoading];
      [pageView stopLoading];

      if (currentConnection) {
         [currentConnection cancel];
         currentConnection = nil;
      }

      [self stopSpinner];

      if (stage != LoadStage::inactive) {
         //We show the message and change buttons
         //ONLY if view was loading at the time of this
         //reachability status change.
         stage = LoadStage::needRefresh;
         [self addWebBrowserButtons];
         CernAPP::ShowErrorAlert(@"Please, check network!", @"Close");
      }
   }
}

//________________________________________________________________________________________
- (id) initWithNibName : (NSString *) nibNameOrNil bundle : (NSBundle *) nibBundleOrNil
{
   if (self = [super initWithNibName : nibNameOrNil bundle : nibBundleOrNil]) {
      status = 200;
      stage = LoadStage::inactive;
   }

   return self;
}

//________________________________________________________________________________________
- (void) defaultsChanged : (NSNotification *) notification
{
    if ([notification.object isKindOfClass : [NSUserDefaults class]]) {
      NSUserDefaults * const defaults = (NSUserDefaults *)notification.object;
      if (id sz = [defaults objectForKey : @"HTMLBodyFontSize"]) {
         assert([sz isKindOfClass : [NSNumber class]] && "defaultsChanged:, GUIFontSize has a wrong type");

         const NSUInteger newZoom = NSUInteger([(NSNumber *)sz floatValue]) / fontIncreaseStep;
         if (newZoom != zoomLevel) {
            zoomLevel = newZoom;
            [self changeTextSize];
            
            zoomInBtn.enabled = zoomLevel < 5 ? YES : NO;
            zoomOutBtn.enabled = zoomLevel != 0 ? YES : NO;
         }       
      }
   }
}

//________________________________________________________________________________________
- (void) dealloc
{
   [internetReach stopNotifier];
   [[NSNotificationCenter defaultCenter] removeObserver : self];
}

//________________________________________________________________________________________
- (void) viewDidAppear : (BOOL) animated
{
   [super viewDidAppear : animated];

   CGRect frame = self.view.frame;
   frame.origin = CGPoint();
   
   const CGFloat presetSize = DefaultHTMLBodyFontSize();
   assert(presetSize >= 0.f && presetSize <= 20.f && "viewDidAppear, unexpected text size from app settings");
   zoomLevel = unsigned(presetSize) / fontIncreaseStep;

   rdbView.frame = frame;
   pageView.frame = frame;
   
   rdbView.multipleTouchEnabled = YES;
   pageView.multipleTouchEnabled = YES;
   
   rdbLoaded = NO;
   pageLoaded = NO;

   status = 200;
   stage = LoadStage::inactive;

   if (rdbCache && rdbCache.length) {
      //
      [self switchToRdbView];
      [self loadReadabilityCache];
   } else {
      if (!spinner) {
         const CGFloat spinnerSize = 150.f;
         const CGPoint spinnerOrigin = CGPointMake(self.view.frame.size.width / 2 - spinnerSize / 2, self.view.frame.size.height / 2 - spinnerSize / 2);

         spinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(spinnerOrigin.x, spinnerOrigin.y, spinnerSize, spinnerSize)];
         spinner.color = [UIColor grayColor];
         [self.view addSubview : spinner];
      }
      
#ifndef READABILITY_CONTENT_API_DEFINED
      [self switchToPageView];
      [self startSpinner];
      [self loadOriginalPage];
#else
      [self switchToRdbView];
      [self startSpinner];
      [self loadHtmlFromReadability];
#endif
   }
}

//________________________________________________________________________________________
- (void) viewWillDisappear : (BOOL) animated
{
   [rdbView stopLoading];
   [pageView stopLoading];
   
   [self stopSpinner];
   
   if (currentConnection) {
      [currentConnection cancel];
      currentConnection = nil;
   }

   stage = LoadStage::inactive;
   status = 200;
}

//________________________________________________________________________________________
- (void) viewDidLoad
{
   [[NSNotificationCenter defaultCenter] addObserver : self selector : @selector(reachabilityStatusChanged:) name : CernAPP::reachabilityChangedNotification object : nil];
   internetReach = [Reachability reachabilityForInternetConnection];
   [internetReach startNotifier];
   
   [[NSNotificationCenter defaultCenter] addObserver : self selector : @selector(defaultsChanged:) name : NSUserDefaultsDidChangeNotification object : nil];
}

//________________________________________________________________________________________
- (void) setContentForArticle : (MWFeedItem *) article
{
   articleLink = article.link;
   title = article.title;
}

#pragma mark - UIWebViewDelegate protocol.

//________________________________________________________________________________________
- (BOOL) webView : (UIWebView *) webView shouldStartLoadWithRequest : (NSURLRequest *)request navigationType : (UIWebViewNavigationType) navigationType
{
   if (navigationType == UIWebViewNavigationTypeLinkClicked ) {
      [[UIApplication sharedApplication] openURL : [request URL]];
      return NO;
   }

   return YES;
}

//________________________________________________________________________________________
- (void) webView : (UIWebView *) webView didFailLoadWithError : (NSError *) error
{
#pragma unused(webView, error)

   //Web view by Apple is a piece of ...
   //You can first receive didFinishLoad, and later didFailWithError.
   //Or you can receive didFinishLoad many times.
   //Or some ugly mix of both.
   //So web-view delegate is quite a useless crap.

   [self stopSpinner];

   if (pageView.superview) {
      //We're loading an original web-page.
      if (stage != LoadStage::inactive)//didFinish was called already, ignore this error.
         stage = LoadStage::needRefresh;
   } else {
      //simply ignore for the moment.
      stage = LoadStage::inactive;
   }
   
   [self addWebBrowserButtons];
}

//________________________________________________________________________________________
- (void) webViewDidFinishLoad : (UIWebView *) webView
{
#pragma unused(webView)
   [self stopSpinner];

   stage = LoadStage::inactive;
   [self addWebBrowserButtons];
   
   if (pageView.superview)
      pageLoaded = YES;
   else {
      rdbLoaded = YES;
      [self changeTextSize];
   }
}

#pragma mark - Readability and web-view.

//________________________________________________________________________________________
- (void) startSpinner
{
   [spinner setHidden : NO];
   [spinner.superview bringSubviewToFront : spinner];
   [spinner startAnimating];
}

//________________________________________________________________________________________
- (void) stopSpinner
{
   if (spinner && spinner.isAnimating) {
      [spinner stopAnimating];
      [spinner setHidden : YES];
   }
}

//________________________________________________________________________________________
- (void) loadReadabilityCache
{
   assert(rdbCache != nil && rdbCache.length && "loadReadabilityCache, no cache");
   
   NSString * const cssPath = [[NSBundle mainBundle] pathForResource : @"ArticleCSS" ofType:@"css"];
   NSMutableString *htmlString = [NSMutableString stringWithFormat :
                                                @"<html><head><link rel='stylesheet' type='text/css' "
                                                "href='file://%@'></head><body></p></body></html><h1>%@</h1>%@<p class='read'>",
                                  cssPath, title, rdbCache];

   [rdbView loadHTMLString : htmlString baseURL : nil];
}

//________________________________________________________________________________________
- (void) loadHtmlFromReadability
{
   assert(currentConnection == nil && "loadHtmlFromReadability, connection is active");

   id delegateBase = [UIApplication sharedApplication].delegate;
   assert([delegateBase isKindOfClass : [AppDelegate class]] &&
          "loadHtmlFromReadability, app delegate has a wrong type");
   
   AppDelegate * const appDelegate = (AppDelegate *)delegateBase;
   if (appDelegate.OAuthToken && appDelegate.OAuthTokenSecret)
      //We try to re-use OAuth tokens (if they don't expire yet).
      [self readabilityParseHtml];
   else
      [self readabilityAuth];
}

//________________________________________________________________________________________
- (BOOL) extractAuthTokens
{
   assert(stage == LoadStage::auth && "extractAuthTokens, wrong stage");
   assert(responseData != nil && "extractAuthTokens, response data is nil");
   
   //Delegate.
   id delegateBase = [UIApplication sharedApplication].delegate;
   assert([delegateBase isKindOfClass : [AppDelegate class]] &&
          "extractAuthTokens, app delegate has a wrong type");
   AppDelegate * const appDelegate = (AppDelegate *)delegateBase;
   appDelegate.OAuthToken = nil, appDelegate.OAuthTokenSecret = nil;
   
   //Parse the responce.
   NSString *OAuthToken = nil;
   NSString *OAuthTokenSecret = nil;
   NSString *OAuthConfirm = nil;

   NSString * const response = [[NSString alloc] initWithData : responseData encoding : NSUTF8StringEncoding];
   NSArray * const components = [response componentsSeparatedByString : @"&"];
   
   for (NSString *component in components) {
      NSArray *pair = [component componentsSeparatedByString:@"="];
      assert(pair.count == 2);
      if ([(NSString *)pair[0] isEqualToString : @"oauth_token_secret"])
         OAuthTokenSecret = (NSString *)pair[1];
      else if ([(NSString *)pair[0] isEqualToString : @"oauth_token"])
         OAuthToken = (NSString *)pair[1];
      else if ([(NSString *)pair[0] isEqualToString : @"oauth_callback_confirmed"])
         OAuthConfirm = (NSString *)pair[1];
   }
   
   if (OAuthToken && OAuthTokenSecret && OAuthConfirm && [OAuthConfirm isEqualToString : @"true"]) {
      appDelegate.OAuthToken = OAuthToken;
      appDelegate.OAuthTokenSecret = OAuthTokenSecret;
      
      return YES;
   }
   
   return NO;
}

//________________________________________________________________________________________
- (void) loadOriginalPage
{
   assert(currentConnection == nil && "loadOriginalPage, has an active connection");

   using CernAPP::NetworkStatus;

   if (internetReach && [internetReach currentReachabilityStatus] == NetworkStatus::notReachable) {
      [self stopSpinner];
      CernAPP::ShowErrorAlert(@"Please, check network!", @"Close");
      stage = LoadStage::needRefresh;
      //Set a HUD with error message here!
      [self addWebBrowserButtons];//
   } else {
      //Load original page.
      assert(articleLink != nil && "loadOriginalPage, articleLink is nil");

      stage = LoadStage::originalPageLoad;
      NSURL * const url = [NSURL URLWithString : articleLink];
      NSURLRequest * const request = [NSURLRequest requestWithURL : url];
      [pageView loadRequest : request];
   }
}

#pragma mark - NSURLConnectionDelegate and NSURLConnectionDataDelegate.

//________________________________________________________________________________________
- (void) connection : (NSURLConnection *) connection didReceiveResponse : (NSURLResponse *) response
{
#pragma unused(connection)

   assert(stage == LoadStage::auth || stage == LoadStage::rdbRequest &&
          "connection:didReceiveResponse:, wrong stage");
   assert(response != nil && "connection:didReceiveResponse:, parameter 'response' is nil");

   if ([response isKindOfClass : [NSHTTPURLResponse class]])
      status = [(NSHTTPURLResponse *)response statusCode];
   else
      status = 200;//???

   if (!responseData)
      responseData = [[NSMutableData alloc] init];
   
   [responseData setLength : 0];
   
   if (status != 200) {
      [currentConnection cancel];
      currentConnection = nil;
      
      if (stage == LoadStage::auth) {
         //Load original page, we can not try authorization again (it can fail again and again).
         [self switchToPageView];
         [self loadOriginalPage];
      } else if (status == 401) {
         //Looks like our auth tokens expired.
         [self switchToRdbView];//select rdb view, if not yet.
         [self readabilityAuth];
      }
   }
}

//________________________________________________________________________________________
- (void) connection : (NSURLConnection *) connection didReceiveData : (NSData *) data
{
#pragma unused(connection)
   assert(stage == LoadStage::auth || stage == LoadStage::rdbRequest &&
          "connection:didReceiveData:, wrong stage");
   assert(responseData != nil && "connection:didReceiveData:, 'responseData' is nil");
   
   [responseData appendData : data];
}

//________________________________________________________________________________________
- (void) connectionDidFinishLoading : (NSURLConnection *) connection
{
   assert(stage == LoadStage::auth || stage == LoadStage::rdbRequest &&
          "connectionDidFinishLoading:, wrong stage");

   using CernAPP::NetworkStatus;

   currentConnection = nil;

   if (stage == LoadStage::auth) {
      //Ok, we, probably, received tokens, try to extract them.
      if ([self extractAuthTokens])
         [self readabilityParseHtml];
      else {
         [self switchToPageView];
         [self loadOriginalPage];
      }
   } else {
      //We, probably, have content parsed from Readability.
      if (![self extractReadabilityContent]) {
         [self switchToPageView];
         [self loadOriginalPage];
      }
   }
}

//________________________________________________________________________________________
- (void) connection : (NSURLConnection *) connection didFailWithError : (NSError *) error
{
#pragma unused(connection)

   assert(stage == LoadStage::auth || stage == LoadStage::rdbRequest &&
          "connection:didFailWithError:, wrong stage");
   
   currentConnection = nil;

   //Something is wrong with readability, either auth. failed
   //or readability parse stage, do not try anything else,
   //load the original page.
   [self loadOriginalPage];
}

#pragma mark - "Browser"
//________________________________________________________________________________________
- (void) changeTextSize
{
   const int fontSize = 44 + fontIncreaseStep * zoomLevel;
   NSString * const jsString = [[NSString alloc] initWithFormat : @"document.getElementsByTagName('body')[0].style.fontSize=%d", fontSize];
   [rdbView stringByEvaluatingJavaScriptFromString : jsString];
}

//________________________________________________________________________________________
- (void) sendArticle
{
   if (animatingOverlay)
      return;

   //Woo-hoo.
   CGRect frame = self.view.frame;
   frame.origin.x = 0.f;
   frame.size.height += 66;
   frame.origin.y = -frame.size.height;

   sendOverlay = [[OverlayView alloc] initWithFrame : frame];
   sendOverlay.delegate = self;
   
   [self addSendButtons];

   [self.navigationController.view addSubview : sendOverlay];
   
   frame.origin.y = 0.f;
   
   [UIView animateWithDuration : 0.25f animations : ^ {
      sendOverlay.frame = frame;
   } completion : nil];
}

//________________________________________________________________________________________
- (void) composeEmail
{
   if (![MFMailComposeViewController canSendMail]) {
      UIAlertView *alert = [[UIAlertView alloc] initWithTitle : @"Send e-mail:"
                                                message : @"Please, add your e-mail account in the device settings"
                                                delegate : nil
                                                cancelButtonTitle : @"Close"
                                                otherButtonTitles : nil];
      [alert show];
      return;
   }

   MFMailComposeViewController * mailComposer = [[MFMailComposeViewController alloc] init];
   [mailComposer setSubject:@"E-mail from CERN.app"];
   [mailComposer setMessageBody : articleLink isHTML : NO];
   mailComposer.mailComposeDelegate = self;

   [self presentViewController : mailComposer animated : YES completion : nil];
}

//________________________________________________________________________________________
- (void) sendEmail
{
   void (^mailSenderBlock) (BOOL) = ^ (BOOL finished) {
      if (finished) {
         [sendOverlay removeFromSuperview];
         sendOverlay = nil;
         animatingOverlay = NO;
         [self composeEmail];
      }
   };
   
   [self dismissOverlayView : mailSenderBlock];
}

//________________________________________________________________________________________
- (void) flipWebViews
{
   const UIViewAnimationOptions transitionOptions = UIViewAnimationOptionTransitionFlipFromLeft;

   if (rdbView.superview) {
      //Switch to original web-page.
      [rdbView stopLoading];//?
      [UIView transitionFromView : rdbView toView : pageView duration : 1.f options : transitionOptions completion : ^(BOOL finished) {
         if (finished) {
            stage = LoadStage::inactive;
            if (!pageLoaded) {
               [self startSpinner];
               [self hideWebBrowserButtons];
               [self loadOriginalPage];
            } else
               [self addWebBrowserButtons];
         }
      }];

   } else {
      [pageView stopLoading];
      [UIView transitionFromView : pageView toView : rdbView duration : 1.f options : transitionOptions completion : ^(BOOL finished) {
         if (finished) {
            stage = LoadStage::inactive;
            if (!rdbLoaded) {
               [self startSpinner];
               [self loadReadabilityCache];
            } else
               [self addWebBrowserButtons];
         }
      }];      
   }
}

//________________________________________________________________________________________
- (void) zoomIn
{
   if (zoomLevel + 1 == 5)
      zoomInBtn.enabled = NO;

   zoomOutBtn.enabled = YES;

   ++zoomLevel;
   
   [[NSUserDefaults standardUserDefaults] setFloat : CGFloat(zoomLevel * fontIncreaseStep) forKey : @"HTMLBodyFontSize"];
   [[NSUserDefaults standardUserDefaults] synchronize];

   [self changeTextSize];   
}

//________________________________________________________________________________________
- (void) zoomOut
{
   if (zoomLevel - 1 == 0)
      zoomOutBtn.enabled = NO;

   zoomInBtn.enabled = YES;
   
   --zoomLevel;
   
   [[NSUserDefaults standardUserDefaults] setFloat : zoomLevel * fontIncreaseStep forKey : @"HTMLBodyFontSize"];
   [[NSUserDefaults standardUserDefaults] synchronize];
   
   [self changeTextSize];
}

//________________________________________________________________________________________
- (void) refresh
{

}

//________________________________________________________________________________________
- (void) sendTweet
{
   //
   [self dismissOverlayView : nil];
}

#pragma mark - GUI.

//________________________________________________________________________________________
- (void) addWebBrowserButtons
{
   if (stage == LoadStage::needRefresh) {
      //We have an error at some stage.
      if (rdbView.superview) {
         //Network connection was lost before I even tried to load
         //original page without readability.
         //I need ONLY refresh button.
         UIButton * const refreshBtn = [UIButton buttonWithType : UIButtonTypeCustom];
         [refreshBtn setBackgroundImage : [UIImage imageNamed:@"refresh.png"] forState : UIControlStateNormal];
         [refreshBtn addTarget : self action : @selector(refresh) forControlEvents : UIControlEventTouchUpInside];
         refreshBtn.frame = CGRectMake(0.f, 0.f, 22.f, 22.f);
         
         UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithCustomView : refreshBtn];//well, not a button but a group of them.
         self.navigationItem.rightBarButtonItem = backButton;
      } else {
         assert(pageView.superview && "addWebBrowserButton, neither rdbView nor pageView are visible");
         if (rdbLoaded) {
            //We have a readability processed data and can switch back to this view.
            //Thus we need 2 buttons: "refresh", "back to readability".
            UIButton * const refreshBtn = [UIButton buttonWithType : UIButtonTypeCustom];
            [refreshBtn setBackgroundImage : [UIImage imageNamed:@"refresh.png"] forState : UIControlStateNormal];
            [refreshBtn addTarget : self action : @selector(refresh) forControlEvents : UIControlEventTouchUpInside];
            refreshBtn.frame = CGRectMake(0.f, 0.f, 22.f, 22.f);
            
            UIButton * const flipBtn = [UIButton buttonWithType : UIButtonTypeCustom];
            [flipBtn setBackgroundImage:[UIImage imageNamed:@"bookmarks.png"] forState:UIControlStateNormal];
            [flipBtn addTarget : self action : @selector(flipWebViews) forControlEvents : UIControlEventTouchUpInside];
            flipBtn.frame = CGRectMake(28.f, 0.f, 22.f, 22.f);
            
            UIView * const parentView = [[UIView alloc] initWithFrame : CGRect()];
            parentView.frame = CGRectMake(0.f, 0.f, 50.f, 22.f);
            [parentView addSubview : flipBtn];
            [parentView addSubview : refreshBtn];
            
            UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithCustomView : parentView];//well, not a button but a group of them.
            self.navigationItem.rightBarButtonItem = backButton;
         } else {
            //Only one button.
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem : UIBarButtonSystemItemRefresh
                                                      target : self action : @selector(refresh)];
         }
      }
   } else {
      //No errors.
      if (rdbView.superview) {
         UIButton * const actionBtn = [UIButton buttonWithType : UIButtonTypeCustom];
         [actionBtn setBackgroundImage : [UIImage imageNamed : @"action.png"] forState : UIControlStateNormal];
         [actionBtn addTarget : self action : @selector(sendArticle) forControlEvents : UIControlEventTouchUpInside];
         actionBtn.frame = CGRectMake(0.f, 0.f, 22.f, 22.f);

         UIButton * const origPageBtn = [UIButton buttonWithType : UIButtonTypeCustom];
         [origPageBtn setBackgroundImage : [UIImage imageNamed : @"globe.png"] forState : UIControlStateNormal];
         [origPageBtn addTarget : self action : @selector(flipWebViews) forControlEvents : UIControlEventTouchUpInside];
         origPageBtn.frame = CGRectMake(28.f, 0.f, 22.f, 22.f);

         zoomInBtn = [UIButton buttonWithType : UIButtonTypeCustom];
         [zoomInBtn setBackgroundImage : [UIImage imageNamed : @"zoomin.png"] forState : UIControlStateNormal];
         [zoomInBtn addTarget : self action : @selector(zoomIn) forControlEvents : UIControlEventTouchUpInside];
         zoomInBtn.frame = CGRectMake(56.f, 0.f, 22.f, 22.f);
         
         zoomOutBtn = [UIButton buttonWithType : UIButtonTypeCustom];
         [zoomOutBtn addTarget : self action : @selector(zoomOut) forControlEvents : UIControlEventTouchUpInside];
         [zoomOutBtn setBackgroundImage : [UIImage imageNamed : @"zoomout.png"] forState : UIControlStateNormal];
         zoomOutBtn.frame = CGRectMake(84.f, 0.f, 22.f, 22.f);

         UIView * const parentView = [[UIView alloc] initWithFrame : CGRectMake(0.f, 0.f, 106.f, 22.f)];
         [parentView addSubview : actionBtn];
         [parentView addSubview : origPageBtn];
         [parentView addSubview : zoomInBtn];
         [parentView addSubview : zoomOutBtn];

         zoomInBtn.enabled = zoomLevel < 5 ? YES : NO;
         zoomOutBtn.enabled = zoomLevel != 0 ? YES : NO;
         
         UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithCustomView : parentView];//well, not a button but a group of them.
         self.navigationItem.rightBarButtonItem = backButton;
      } else {
         //"Send" button and "back to readability".
         if (rdbLoaded) {
            UIButton * const actionBtn = [UIButton buttonWithType : UIButtonTypeCustom];
            [actionBtn setBackgroundImage : [UIImage imageNamed : @"action.png"] forState : UIControlStateNormal];
            [actionBtn addTarget : self action : @selector(sendArticle) forControlEvents : UIControlEventTouchUpInside];
            actionBtn.frame = CGRectMake(0.f, 0.f, 22.f, 22.f);
            
            UIButton * const flipBtn = [UIButton buttonWithType : UIButtonTypeCustom];
            [flipBtn setBackgroundImage:[UIImage imageNamed:@"bookmarks.png"] forState : UIControlStateNormal];
            [flipBtn addTarget : self action : @selector(flipWebViews) forControlEvents : UIControlEventTouchUpInside];
            flipBtn.frame = CGRectMake(28.f, 0.f, 22.f, 22.f);
            
            UIView * const parentView = [[UIView alloc] initWithFrame : CGRect()];
            parentView.frame = CGRectMake(0.f, 0.f, 50.f, 22.f);
            [parentView addSubview : flipBtn];
            [parentView addSubview : actionBtn];
            
            UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithCustomView : parentView];//well, not a button but a group of them.
            self.navigationItem.rightBarButtonItem = backButton;
         } else {
            //Only send.
            UIButton * const actionBtn = [UIButton buttonWithType : UIButtonTypeCustom];
            [actionBtn setBackgroundImage : [UIImage imageNamed : @"action.png"] forState : UIControlStateNormal];
            [actionBtn addTarget : self action : @selector(sendArticle) forControlEvents : UIControlEventTouchUpInside];
            actionBtn.frame = CGRectMake(0.f, 0.f, 22.f, 22.f);

            UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithCustomView : actionBtn];//well, not a button but a group of them.
            self.navigationItem.rightBarButtonItem = backButton;
         }
      }
   }
}

//________________________________________________________________________________________
- (void) addSendButtons
{
   assert(sendOverlay != nil && "addSendButtons, sendOverlay is nil");
   
   //Harcoded geometry :) But it's ... ok :)
   CGRect frame = CGRectMake(10.f, 60.f, 80.f, 80.f);

   PictureButtonView * const twBtn = [[PictureButtonView alloc] initWithFrame : frame image : [UIImage imageNamed : @"Twitter.png"]];
   [twBtn addTarget : self selector : @selector(sendTweet)];
   [sendOverlay addSubview : twBtn];
   
   frame.origin.x = 100.f;
   PictureButtonView * const fbBtn = [[PictureButtonView alloc] initWithFrame : frame image : [UIImage imageNamed : @"Facebook.png"]];
   [fbBtn addTarget : self selector : @selector(sendTweet)];
   [sendOverlay addSubview : fbBtn];
   
   frame.origin.x = 190.f;
   PictureButtonView * const emBtn = [[PictureButtonView alloc] initWithFrame : frame image : [UIImage imageNamed : @"Email-01.png"]];
   [emBtn addTarget : self selector : @selector(sendEmail)];
   [sendOverlay addSubview : emBtn];

}

//________________________________________________________________________________________
- (void) hideWebBrowserButtons
{
   self.navigationItem.rightBarButtonItem = nil;
}

//________________________________________________________________________________________
- (void) switchToPageView
{
   //Non-animated switch.
   if (rdbView.superview)
      [rdbView removeFromSuperview];
   if (!pageView.superview)
      [self.view addSubview : pageView];
   
   if (!spinner.hidden)
      [spinner.superview bringSubviewToFront : spinner];
}

//________________________________________________________________________________________
-(void) switchToRdbView
{
   //Non-animated switch.
   if (pageView.superview)
      [pageView removeFromSuperview];
   if (!rdbView.superview)
      [self.view addSubview : rdbView];

   if (!spinner.hidden)
      [spinner.superview bringSubviewToFront : spinner];
}

#pragma mark - OverlayViewDelegate

//________________________________________________________________________________________
- (void) dismissOverlayView : (void (^)(BOOL finished)) block
{
   //block MUST remove sendOverlay view (but I can not check/force it).
   animatingOverlay = YES;

   CGRect frame = sendOverlay.frame;

   frame.origin.y = -frame.size.height;

   if (block) {
      [UIView animateWithDuration : 0.25f animations : ^ {
          sendOverlay.frame = frame;
       }
       completion : block];
   } else {
      [UIView animateWithDuration : 0.25f animations : ^ {
         sendOverlay.frame = frame;
       } completion:^(BOOL finished) {
          if (finished) {
             [sendOverlay removeFromSuperview];
             sendOverlay = nil;
             animatingOverlay = NO;
          }
       }];
   }
}

#pragma mark - MFMailComposeViewController delegate

//___________________________________________________________
- (void) mailComposeController : (MFMailComposeViewController *)controller didFinishWithResult : (MFMailComposeResult)result error : (NSError *)error
{
   [self becomeFirstResponder];//???
   [self dismissViewControllerAnimated : YES completion : nil];
}

@end
