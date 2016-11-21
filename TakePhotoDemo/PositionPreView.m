//
//  PositionPreView.m
//  TakePhotoDemo
//
//  Created by RRTY on 16/11/14.
//  Copyright © 2016年 deepAI. All rights reserved.
//

#import "PositionPreView.h"

#define selfW 154.0
#define selfH 154.0

static CGFloat const strangleWidth = 5.0;

@implementation PositionPreView



- (void)drawRect:(CGRect)rect {
    // Drawing code
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(selfW / 2, selfH / 2)];
    [path addLineToPoint:CGPointMake(selfW / 2,0)];
    
    [path addLineToPoint:CGPointMake(selfW / 2 - strangleWidth / 2, strangleWidth / 5 * 4)];
    [path addLineToPoint:CGPointMake(selfW / 2 + strangleWidth / 2, strangleWidth / 5 * 4)];
    [path addLineToPoint:CGPointMake(selfW / 2, 0)];

    [path moveToPoint:CGPointMake(selfW / 2, selfH / 2)];
    [path addLineToPoint:CGPointMake(selfW, selfH / 2)];
    
    [path addLineToPoint:CGPointMake(selfW - strangleWidth / 5 * 4, selfH / 2 - strangleWidth / 2)];
    [path addLineToPoint:CGPointMake(selfW - strangleWidth / 5 * 4, selfH / 2 + strangleWidth / 2)];
    [path addLineToPoint:CGPointMake(selfW, selfH / 2)];
    
    [path moveToPoint:CGPointMake(selfW / 2, selfH / 2)];
    [path addLineToPoint:CGPointMake(selfW / 4, selfH / 4 * 3)];
    
    [path addLineToPoint:CGPointMake(selfW / 4, selfH / 4 * 3 - strangleWidth / 2)];
    [path addLineToPoint:CGPointMake(selfW / 4 + strangleWidth / 2, selfH / 4 * 3)];
    [path addLineToPoint:CGPointMake(selfW / 4, selfH / 4 * 3)];
    
    [path setLineWidth:1];
    [path setLineJoinStyle:kCGLineJoinMiter];
    [path setLineCapStyle:kCGLineCapRound];
    [[UIColor darkGrayColor] set];
    [path stroke];
    
    
    
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.backgroundColor = [UIColor clearColor];
}

@end
