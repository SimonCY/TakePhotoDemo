//
//  CameraContentView.m
//  TakePhotoDemo
//
//  Created by RRTY on 16/11/10.
//  Copyright © 2016年 deepAI. All rights reserved.
//

#import "CameraContentView.h"

@interface CameraContentView()
@property (weak, nonatomic) IBOutlet UIButton *dismissBtn;
@property (weak, nonatomic) IBOutlet UIButton *takePhotoBtn;
@property (weak, nonatomic) IBOutlet UIButton *switchCameraBtn;
@property (weak, nonatomic) IBOutlet UIView *rotationPreView;

@end
@implementation CameraContentView
+ (instancetype)contentView {
    return [[[NSBundle mainBundle] loadNibNamed:@"CameraContentView" owner:nil options:nil] lastObject];
}

- (void)awakeFromNib {
    [super awakeFromNib];

    self.backgroundColor = [UIColor clearColor];
    [self.dismissBtn addTarget:self action:@selector(dismissBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.takePhotoBtn addTarget:self action:@selector(takePhotoBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.switchCameraBtn addTarget:self action:@selector(switchCameraBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    

}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.frame = [[UIScreen mainScreen]bounds];
}
#pragma mark - set

- (void)setPreRota:(preViewRota)preRota {
    _preRota = preRota;
 
    CABasicAnimation *animationX = [CABasicAnimation animation];
    animationX.keyPath = @"transform.rotation.x";
    animationX.toValue = [NSNumber numberWithFloat: -preRota.x];//[NSValue valueWithCATransform3D:CATransform3DMakeRotation(-preRota.x, 1, 0, 0)];
    animationX.removedOnCompletion = YES;
    animationX.fillMode = kCAFillModeForwards;
    animationX.duration = 0;
    
 
    CABasicAnimation *animationY = [CABasicAnimation animation];
    animationY.keyPath = @"transform.rotation.y";
    animationY.toValue = [NSNumber numberWithFloat: -preRota.y];//[NSValue valueWithCATransform3D:CATransform3DMakeRotation(-preRota.y, 0, 1, 0)];
    animationY.removedOnCompletion = YES;
    animationY.fillMode = kCAFillModeForwards;
    animationY.duration = 0;
    
 
    CABasicAnimation *animationZ = [CABasicAnimation animation];
    animationZ.keyPath = @"transform.rotation.z";
    animationZ.toValue = [NSNumber numberWithFloat: -preRota.z];//[NSValue valueWithCATransform3D:CATransform3DMakeRotation(-preRota.z, 0, 0, 1)];
    animationZ.removedOnCompletion = YES;
    animationZ.fillMode = kCAFillModeForwards;
    animationZ.duration = 0;
    
    //设置动画组
    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.animations = @[animationX,animationY, animationZ];
    group.duration = 0;
    group.removedOnCompletion = YES;
    group.fillMode = kCAFillModeForwards;
    
    [self.rotationPreView.layer addAnimation:group forKey:nil];
}
#pragma mark - clickevents
- (void)takePhotoBtnClicked:(UIButton *)btn {
    if (self.delegate && [self.delegate respondsToSelector:@selector(cameraContentView:didClickBtn:withType:)]) {
        [self.delegate cameraContentView:self didClickBtn:btn withType:CameraContentViewBtnTypeTakePhoto];
    }
}

- (void)dismissBtnClicked:(UIButton *)btn {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(cameraContentView:didClickBtn:withType:)]) {
        [self.delegate cameraContentView:self didClickBtn:btn withType:CameraContentViewBtnTypeDismiss];
    }
}
- (void)switchCameraBtnClicked:(UIButton *)btn {
    if (self.delegate && [self.delegate respondsToSelector:@selector(cameraContentView:didClickBtn:withType:)]) {
        [self.delegate cameraContentView:self didClickBtn:btn withType:CameraContentViewBtnTypeSwitchCamera];
    }
}
@end
