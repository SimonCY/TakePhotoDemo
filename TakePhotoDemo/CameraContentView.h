//
//  CameraContentView.h
//  TakePhotoDemo
//
//  Created by RRTY on 16/11/10.
//  Copyright © 2016年 deepAI. All rights reserved.
//

#import <UIKit/UIKit.h>
@class CameraContentView;

typedef struct {
    CGFloat x;
    CGFloat y;
    CGFloat z;
} preViewRota;

typedef NS_ENUM(NSUInteger, CameraContentViewBtnType) {
    CameraContentViewBtnTypeDismiss,
    CameraContentViewBtnTypeTakePhoto,
    CameraContentViewBtnTypeSwitchCamera,
};



@protocol CameraContentViewDelegate <NSObject>

@optional
- (void)cameraContentView:(CameraContentView *)contentView didClickBtn:(UIButton *)btn withType:(CameraContentViewBtnType)btnType;

@end

@interface CameraContentView : UIView
@property (nonatomic,weak) id<CameraContentViewDelegate> delegate;

@property (nonatomic,assign) preViewRota preRota;

+ (instancetype)contentView;

@end
