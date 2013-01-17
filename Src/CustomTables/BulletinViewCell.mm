//
//  BulletinViewCell.m
//  CERN
//
//  Created by Timur Pocheptsov on 1/17/13.
//  Copyright (c) 2013 CERN. All rights reserved.
//

#import "BulletinViewCell.h"

@implementation BulletinViewCell

@synthesize cellLabel;

- (id)initWithStyle : (UITableViewCellStyle) style reuseIdentifier : (NSString *) reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
