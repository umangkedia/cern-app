//
//  NewsGridViewCell.m
//  CERN App
//
//  Created by Eamon Ford on 8/7/12.
//  Copyright (c) 2012 CERN. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "NewsGridViewCell.h"
#import "DeviceCheck.h"

namespace CernApp = ROOT::CernApp;

@implementation NewsGridViewCell
//@synthesize titleLabel, dateLabel, thumbnailImageView;

- (id) initWithFrame : (CGRect) frame reuseIdentifier : (NSString *) aReuseIdentifier cellStyle : (CernApp::GridCellStyle) cellStyle
{
    if (self = [super initWithFrame : frame reuseIdentifier : aReuseIdentifier]) {
        if ([DeviceCheck deviceIsiPad] || cellStyle == CernApp::iPadStyle) {
            //For the moment, I have two separate versions, later I'll make it more general
            //(as soon as we invent layout algorithm for iPad version).
            self.layer.borderColor = [UIColor whiteColor].CGColor;
            self.layer.borderWidth = 5.0;
            
            self.layer.shadowColor = [UIColor blackColor].CGColor;
            self.layer.shadowOffset = CGSizeMake(0.0, 1.0);
            self.layer.shadowRadius = 2.0;
            self.layer.shadowOpacity = 0.5;
            CGPathRef cellShadowPathRef = CGPathCreateWithRect(self.layer.frame, NULL);
            self.layer.shadowPath = cellShadowPathRef;
            CGPathRelease(cellShadowPathRef);
            self.contentView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
            
            self.thumbnailImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, frame.size.width, frame.size.height/2)];
            self.thumbnailImageView.contentMode = UIViewContentModeScaleAspectFill;
            self.thumbnailImageView.clipsToBounds = YES;

            UIView *innerContainerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, frame.size.width, frame.size.height/2)];
            innerContainerView.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
            innerContainerView.layer.shadowOpacity = 1.0;
            innerContainerView.layer.shadowRadius = 2.0;
            innerContainerView.layer.shadowColor = [UIColor blackColor].CGColor;
            CGPathRef imageShadowPathRef = CGPathCreateWithRect(innerContainerView.layer.frame, NULL);
            innerContainerView.layer.shadowPath = imageShadowPathRef;
            CGPathRelease(imageShadowPathRef);
            [innerContainerView addSubview:self.thumbnailImageView];
            
            UIView *outerContainerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, frame.size.width, (frame.size.height/2)+10.0f)];
            outerContainerView.clipsToBounds = YES;
            [outerContainerView addSubview:innerContainerView];
            [self.contentView addSubview:outerContainerView];
            
            self.dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(8.0+5.0, frame.size.height-25.0f, frame.size.width-16.0-10.0, 20.0)];
            self.dateLabel.font = [UIFont systemFontOfSize:12.0];
            self.dateLabel.textColor = [UIColor grayColor];
            self.dateLabel.shadowColor = [UIColor whiteColor];
            self.dateLabel.shadowOffset = CGSizeMake(0.0, 1.0);
            self.dateLabel.backgroundColor = [UIColor clearColor];
            [self.contentView addSubview:self.dateLabel];
            
            self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(8.0+5.0, self.thumbnailImageView.frame.size.height, frame.size.width-16.0-10.0, frame.size.height-(self.thumbnailImageView.frame.size.height+self.dateLabel.frame.size.height+5.0))];
            self.titleLabel.numberOfLines = 0;
            self.titleLabel.textColor = [UIColor darkGrayColor];
            self.titleLabel.shadowColor = [UIColor whiteColor];
            self.titleLabel.shadowOffset = CGSizeMake(0.0, 1.0);
            self.titleLabel.backgroundColor = [UIColor clearColor];
            [self.contentView addSubview:self.titleLabel];
        } else {
            self.layer.borderColor = [UIColor whiteColor].CGColor;
            self.contentView.backgroundColor = [UIColor colorWithWhite : 1.f alpha : 1.f];
            
            const CGRect thumbnailFrame = CGRectMake(0.f, 0.f, 0.8f * frame.size.height, 0.8f * frame.size.height);
            
            self.thumbnailImageView = [[UIImageView alloc] initWithFrame : thumbnailFrame];
            self.thumbnailImageView.contentMode = UIViewContentModeScaleAspectFill;
            self.thumbnailImageView.clipsToBounds = YES;
            [self.contentView addSubview : self.thumbnailImageView];
            
            self.dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(8.f + 5.f, frame.size.height-25.f, frame.size.width - 16.f - 10.f, 20.f)];
            self.dateLabel.font = [UIFont systemFontOfSize : 10.0];
            self.dateLabel.textColor = [UIColor grayColor];
            self.dateLabel.backgroundColor = [UIColor clearColor];
            [self.contentView addSubview : self.dateLabel];
            
            const CGRect titleFrame = CGRectMake(thumbnailFrame.origin.x + 4 + thumbnailFrame.size.width, 8,
                                                 frame.size.width - 4 - thumbnailFrame.size.width - 4, thumbnailFrame.size.height);
            self.titleLabel = [[UILabel alloc] initWithFrame : titleFrame];
            self.titleLabel.numberOfLines = 0;
            self.titleLabel.font = [UIFont systemFontOfSize : 11];
            self.titleLabel.textColor = [UIColor blackColor];
            self.titleLabel.backgroundColor = [UIColor clearColor];
            [self.contentView addSubview : self.titleLabel];
        }
    }

    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
