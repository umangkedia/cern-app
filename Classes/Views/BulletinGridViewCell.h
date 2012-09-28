//
//  BulletinGridViewCell.h
//  CERN App
//
//  Created by Eamon Ford on 8/9/12.
//  Copyright (c) 2012 CERN. All rights reserved.
//

#import "AQGridViewCell.h"

@interface BulletinGridViewCell : AQGridViewCell
{
    UILabel *titleLabel;
    UILabel *descriptionLabel;
}
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *descriptionLabel;

@end
