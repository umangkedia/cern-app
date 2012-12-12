//
//  AppDelegate.h
//  CERN App
//
//  Created by Eamon Ford on 5/24/12.
//  Copyright (c) 2012 CERN. All rights reserved.
//

#import <UIKit/UIKit.h>

namespace CernAPP {

enum TabIndices {
    TabIndexNews,
    TabIndexAbout,
    TabIndexLive,
    TabIndexBulletin,
    TabIndexPhotos,
    TabIndexVideos,
    TabIndexJobs,
    TabIndexWebcasts
};

}


@interface AppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) UITabBarController *tabBarController;
@property (nonatomic, strong) NSArray *staticInfoDataSource;
@property (nonatomic, strong) NSMutableDictionary *tabsAlreadySetup;
@property (strong, nonatomic) UIWindow *window;

- (void) setupViewController : (UIViewController *) viewController atIndex : (int) index;

@end

namespace CernAPP {

bool HasConnection();

}