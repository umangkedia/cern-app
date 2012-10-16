//
//  NewsGridViewCell.h
//  CERN App
//
//  Created by Eamon Ford on 8/7/12.
//  Copyright (c) 2012 CERN. All rights reserved.
//

#import "AQGridViewCell.h"

namespace ROOT {
namespace CernApp {

enum GridCellStyle {
   iPadStyle,
   iPhoneStyle
};

}
}

@interface NewsGridViewCell : AQGridViewCell

- (id) initWithFrame : (CGRect)frame reuseIdentifier : (NSString *) aReuseIdentifier cellStyle : (ROOT::CernApp::GridCellStyle) style;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UIImageView *thumbnailImageView;

@end
