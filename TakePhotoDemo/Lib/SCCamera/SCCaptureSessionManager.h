//
//  SCCaptureSessionManager.h
//  SCCaptureCameraDemo
//
//  Created by chenyan on 14-1-16.
//  Copyright (c) 2014年 chenyan. All rights reserved.
//

/**
 *  vender four frameworks:
 
 *  1、CoreMedia.framework
 *  2、QuartzCore.framework
 *  3、AVFoundation.framework
 *  4、ImmageIO.framework
 */


#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import "iPhoneMacro.h"



@protocol SCCaptureSessionManager;

#define MAX_PINCH_SCALE_NUM   3.f
#define MIN_PINCH_SCALE_NUM   1.f

typedef void(^DidCapturePhotoBlock)(UIImage *stillImage);
typedef void(^DidFinishRecordingBlock)(NSURL *fileUrl);
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

#define kCapturedPhotoSuccessfully              @"caputuredPhotoSuccessfully"

@protocol SCCaptureSessionManager <NSObject>
@optional
- (void)didCapturePhoto:(UIImage*)stillImage;
@end


@interface SCCaptureSessionManager : NSObject





/** 照片输出流 */
@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;

/** 视频输出流 */
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutput;

/** 视频文件输出流 */
@property (nonatomic,strong) AVCaptureMovieFileOutput* movieFileOutput;





/* ---------------------------pinch相关------------------ */
@property (nonatomic, assign, readonly) CGFloat preScaleNum;

@property (nonatomic, assign, readonly) CGFloat scaleNum;
/* ------------------------------------------------------ */

@property (nonatomic, assign) id <SCCaptureSessionManager> delegate;


/* --------------------------thumbPreview相关------------------ */

@property (nonatomic,strong) GLKView* thumbPreView;

@property (nonatomic,strong) CIContext* cicontext;

/* ------------------------------------------------------ */

/** 初始化实时预览界面 */
- (void)configureWithParentView:(UIView*)parentView previewRect:(CGRect)preivewRect thumbPreviewRect:(CGRect)thumbPreviewRect;

/** 启动相机会话 */
- (void)start;
/** 停止相机会话 */
- (void)stop;

/** 拍照 */
- (void)takePicture:(DidCapturePhotoBlock)block;

/** 录像 (注意：录像的时候不能进行切换摄像头操作)*/
- (void)startRecording;
/** 停止录像 */
- (void)stopRecording:(DidFinishRecordingBlock)block;

/** 切换前后摄像头 */
- (void)switchCamera:(SCCaptureInputDeviceType)lensType;

/** 焦距调节 */
- (void)pinchCameraViewWithScalNum:(CGFloat)scale;
- (void)pinchCameraView:(UIPinchGestureRecognizer*)gesture;

/** 切换闪光灯模式 默认是关闭  */
- (void)switchFlashMode:(DidCaptureSwitchFlashModeBlock)block;

/** 对焦 */
- (void)focusInPoint:(CGPoint)devicePoint;


@end


