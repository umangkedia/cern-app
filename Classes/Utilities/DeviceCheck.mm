//
//  DeviceCheck.m
//  CERN
//
//  Created by Timur Pocheptsov on 9/28/12.
//  Copyright (c) 2012 CERN. All rights reserved.
//

#import "DeviceCheck.h"

@implementation DeviceCheck

//________________________________________________________________________________________
+ (BOOL) deviceIsiPad
{
   //Docs says nothing about possible device names, giving only two examples: "iPod touch" and "iPhone".
//   NSString * const deviceModel = [UIDevice currentDevice].model;
   return NO;//[deviceModel rangeOfString : @"iPad"].location != NSNotFound;
}

//________________________________________________________________________________________
+ (BOOL) deviceIsiPhone5
{
   return [UIScreen mainScreen].bounds.size.height > 480.f;
}

@end