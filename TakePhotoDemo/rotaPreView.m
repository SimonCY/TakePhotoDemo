//
//  rotaPreView.m
//  TakePhotoDemo
//
//  Created by RRTY on 16/11/14.
//  Copyright © 2016年 deepAI. All rights reserved.
//

#import "rotaPreView.h"

#define selfW 60
#define selfH 110

@interface rotaPreView()
@property (nonatomic,strong) UIView* screen;
@property (nonatomic,strong) UIView* homeButton;
@end
@implementation rotaPreView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.backgroundColor = [UIColor clearColor];
    
    self.layer.borderWidth = 2;
    self.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.layer.cornerRadius = 5;
    self.clipsToBounds = YES;
    
    self.screen = [[UIView alloc] init];
    self.screen.backgroundColor = [UIColor lightGrayColor];
    [self addSubview:self.screen];
    
    self.homeButton = [[UIView alloc] init];
    self.homeButton.backgroundColor = [UIColor clearColor];
    self.homeButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.homeButton.layer.borderWidth = 2;
    self.homeButton.layer.cornerRadius = selfW / 4 / 2.0;
    self.homeButton.clipsToBounds = YES;
    [self addSubview:self.homeButton];
    
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat margin = 5;
    
    CGFloat homeWH = selfW / 4;
    CGFloat homeY = selfH - margin - homeWH;
    CGFloat homeX = (selfW - homeWH) / 2;
    self.homeButton.frame = CGRectMake(homeX, homeY, homeWH, homeWH);
    
    CGFloat screenY = homeWH;
    CGFloat screenW = selfW - margin * 2;
    CGFloat screenH = selfH - screenY - margin * 2 - homeWH;
    CGFloat screenX = (selfW - screenW) / 2;
    self.screen.frame = CGRectMake(screenX, screenY, screenW, screenH);
    
}
@end
