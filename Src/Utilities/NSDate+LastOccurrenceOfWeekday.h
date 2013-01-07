//
//  NSDate+LastOccurrenceOfWeekday.h
//  CERN App
//
//  Created by Eamon Ford on 7/30/12.
//  Copyright (c) 2012 CERN. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (LastOccurrenceOfWeekday)

- (NSDate *)nextOccurrenceOfWeekday:(int)targetWeekday;
- (NSDate *)midnight;

@end
