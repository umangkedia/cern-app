//
//  NSDateFormatter+DateFromStringOfUnknownStyle.h
//  CERN App
//
//  Created by Eamon Ford on 7/6/12.
//  Copyright (c) 2012 CERN. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDateFormatter (DateFromStringOfUnknownFormat)
 
- (NSDate *)dateFromStringOfUnknownFormat:(NSString *)string;

@end
