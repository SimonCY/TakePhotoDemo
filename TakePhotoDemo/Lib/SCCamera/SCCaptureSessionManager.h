//
//  SCCaptureSessionManager.h
//  SCCaptureCameraDemo
//
//  Created by chenyan on 14-1-16.
//  Copyright (c) 2014年 chenyan. All rights reserved.
//



#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "SCDefines.h"

@protocol SCCaptureSessionManager;

#define MAX_PINCH_SCALE_NUM   3.f
#define MIN_PINCH_SCALE_NUM   1.f

typedef void(^DidCapturePhotoBlock)(UIImage *stillImage);
typedef void(^DidCaptureSwitchFlashModeBlock)(AVCaptureFlashMode flashMode);


typedef NS_ENUM(NSUInteger, SCCaptureInputDeviceType) {
    SCCaptureInputDeviceTypeFrontLens = 0,          //前摄像头
    SCCaptureInputDeviceTypeBackLens,               //后摄像头
};

/* 待用---整合视频拍摄功能
typedef NS_ENUM(NSUInteger, SCCaptureOutputDeviceType) {
    SCCaptureOutputDeviceTypeStillImage,
    SCCaptureOutputDeviceTypeVideoFile,
};
*/

@protocol SCCaptureSessionManager <NSObject>
@optional
- (void)didCapturePhoto:(UIImage*)stillImage;
@end


@interface SCCaptureSessionManager : NSObject

/** 会话处理队列 */
@property (nonatomic) dispatch_queue_t sessionQueue;

/** 会话对象，执行输入设备和输出设备之间的数据传递 */
@property (nonatomic, strong) AVCaptureSession *session;

/** 输入设备（前或者后摄像头） */
@property (nonatomic, strong) AVCaptureDeviceInput *inputDevice;

/** 照片输出流 */
@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;

/** 预览图层 */
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;


/* --------------pinch相关------------- */
@property (nonatomic, assign, readonly) CGFloat preScaleNum;
@property (nonatomic, assign, readonly) CGFloat scaleNum;
/* ----------------------------------- */

@property (nonatomic, assign) id <SCCaptureSessionManager> delegate;


/** 初始化实时预览界面 */
- (void)configureWithParentView:(UIView*)parentView previewRect:(CGRect)preivewRect;

/** 拍照 */
- (void)takePicture:(DidCapturePhotoBlock)block;

/** 切换前后摄像头 */
- (void)switchCamera:(SCCaptureInputDeviceType)lensType;

/** 焦距调节 */
- (void)pinchCameraViewWithScalNum:(CGFloat)scale;
- (void)pinchCameraView:(UIPinchGestureRecognizer*)gesture;

/** 切换闪光灯模式 默认是关闭  */
- (void)switchFlashMode:(DidCaptureSwitchFlashModeBlock)block;

/** 对焦 */
- (void)focusInPoint:(CGPoint)devicePoint;


-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration;
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation;

@end


