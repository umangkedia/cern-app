//
//  DeviceCheck.m
//  CERN
//
//  Created by Timur Pocheptsov on 9/28/12.
//  Copyright (c) 2012 CERN. All rights reserved.
//

#import "DeviceCheck.h"

@implementation DeviceCheck

+ (BOOL) deviceIsiPad
{
   //Docs says nothing about possible device names, giving only two examples: "iPod touch" and "iPhone".
   NSString * const deviceModel = [UIDevice currentDevice].model;
   return [deviceModel rangeOfString:@"iPad"].location != NSNotFound;
}

@end