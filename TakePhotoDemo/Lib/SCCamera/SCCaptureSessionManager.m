//
//  SCCaptureSessionManager.m
//  SCCaptureCameraDemo
//
//  Created by chenyan on 14-1-16.
//  Copyright (c) 2014年 chenyan. All rights reserved.
//

#import "SCCaptureSessionManager.h"
#import <ImageIO/ImageIO.h>
#import "SCCommon.h"
#import "UIImage+Resize.h"

@interface SCCaptureSessionManager ()

@property (nonatomic, strong) UIView *preview;
 
@end

@implementation SCCaptureSessionManager


#pragma mark setup

- (instancetype)init {
    if (self = [super init]) {
        _scaleNum = 1.f;
        _preScaleNum = 1.f;
        
    }
    return self;
}

- (void)dealloc {
    
    [_session stopRunning];
    
    self.previewLayer = nil;
    self.session = nil;
    self.stillImageOutput = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)configureWithParentView:(UIView*)parentView previewRect:(CGRect)preivewRect {
    
    self.preview = parentView;
    
    //1、队列
    [self createQueue];
    
    //2、session
    [self addSession];
    
    //3、previewLayer
    [self addVideoPreviewLayerWithParentLayer:parentView.layer rect:preivewRect];

    //4、input (默认后置摄像头)
    [self addVideoInputLens:SCCaptureInputDeviceTypeBackLens];
    
    //5、output （默认是相机）
    [self addStillImageOutput];
}

/** 创建相机操作队列，防止阻塞主线程 */
- (void)createQueue {
	dispatch_queue_t sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
    self.sessionQueue = sessionQueue;
}

/** session */
- (void)addSession {
    AVCaptureSession *tmpSession = [[AVCaptureSession alloc] init];
    self.session = tmpSession;
    //设置质量（这个质量也会直接影响拍照预览图层的照片质量）
    if ([_session canSetSessionPreset:AVCaptureSessionPresetHigh]) {
        _session.sessionPreset=AVCaptureSessionPresetHigh;
    }
}

/** 创建相机的实时预览页面并添加到父图层
 *
 *  @param previewRect 在父图层中的frame
 */
- (void)addVideoPreviewLayerWithParentLayer:(CALayer *)parentLayer rect:(CGRect)previewRect {
    
    AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_session];
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    previewLayer.frame = previewRect;
    self.previewLayer = previewLayer;
    if (parentLayer) {
        [parentLayer addSublayer:previewLayer];
    }
}

/**
 *  添加输入设备
 *
 *  @param lensType 前或后摄像头
 */
- (void)addVideoInputLens:(SCCaptureInputDeviceType)lensType {
    
    NSArray *devices = [AVCaptureDevice devices];
    //前摄像头
    AVCaptureDevice *frontCamera;
    //后摄像头
    AVCaptureDevice *backCamera;
    
    for (AVCaptureDevice *device in devices) {
        
        SCDLog(@"InputDevice: %@", [device localizedName]);
        
        if ([device hasMediaType:AVMediaTypeVideo]) {

            if ([device position] == AVCaptureDevicePositionBack) {
                
                SCDLog(@"后摄像头");
                backCamera = device;
                
            }  else {
                
                SCDLog(@"前摄像头");
                frontCamera = device;
            }
        }
    }
    
    NSError *error = nil;
    switch (lensType) {
        case SCCaptureInputDeviceTypeBackLens: {
            
            AVCaptureDeviceInput *backFacingCameraDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:backCamera error:&error];
            if (!error) {
                if ([_session canAddInput:backFacingCameraDeviceInput]) {
                    [_session addInput:backFacingCameraDeviceInput];
                    self.inputDevice = backFacingCameraDeviceInput;
                    
                } else {
                    SCDLog(@"无法切换到后摄像头");
                }
            }
            break;
        }
        case SCCaptureInputDeviceTypeFrontLens: {
            
            AVCaptureDeviceInput *frontFacingCameraDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:frontCamera error:&error];
            if (!error) {
                if ([_session canAddInput:frontFacingCameraDeviceInput]) {
                    [_session addInput:frontFacingCameraDeviceInput];
                    self.inputDevice = frontFacingCameraDeviceInput;
                    
                } else {
                    SCDLog(@"无法切换到前摄像头");
                }
            }
            break;
        }
        default:
            break;
    }
}

/** 添加相机输出设备 */
- (void)addStillImageOutput {
    
    AVCaptureStillImageOutput *tmpOutput = [[AVCaptureStillImageOutput alloc] init];
    //输出jpeg图像
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey,nil];
    tmpOutput.outputSettings = outputSettings;
    
    if ([_session canAddOutput:tmpOutput]) {
        
        [_session addOutput:tmpOutput];
        self.stillImageOutput = tmpOutput;
    }
    
}

#pragma mark - set and get
- (AVCaptureFlashMode)flashMode {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    if (device.flashAvailable) {
        
        return device.flashMode;
    }
    return AVCaptureFlashModeOff;
}

#pragma mark - camera actions

/**
 * 拍照
 */
- (void)takePicture:(DidCapturePhotoBlock)block {
    AVCaptureConnection *videoConnection = [self findVideoConnection];

    [videoConnection setVideoScaleAndCropFactor:_scaleNum];
    
    [_stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        
        //将imageDataSampleBuffer处理成image
        CFDictionaryRef exifAttachments = CMGetAttachment(imageDataSampleBuffer, kCGImagePropertyExifDictionary, NULL);
        if (exifAttachments) {
            SCDLog(@"attachements: %@", exifAttachments);
        } else {
            SCDLog(@"no attachments");
        }
    
        NSData *imageData = nil;
        if (imageDataSampleBuffer) {
            imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        }
        
        SCDLog(@"image Size: %ld",imageData.length);
        UIImage *croppedImage = [[UIImage alloc] initWithData:imageData];
        
        SCDLog(@"原图:%@", [NSValue valueWithCGSize:croppedImage.size]);

        //block、delegate、notification 3选1，传值
        if (block) {
            
            block(croppedImage);
        } else if (self.delegate && [self.delegate respondsToSelector:@selector(didCapturePhoto:)]) {
            
            [self.delegate didCapturePhoto:croppedImage];
        } else {
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kCapturedPhotoSuccessfully object:croppedImage];
        }
    }];
}


/**
 *  切换前后摄像头
 *
 *  @param lensType 摄像头类型
 */
- (void)switchCamera:(SCCaptureInputDeviceType)lensType {
    if (!_inputDevice) {
        SCDLog(@"当前没有输入设备");
        return;
    }
    [_session beginConfiguration];
    [_session removeInput:_inputDevice];
    [self addVideoInputLens:lensType];
    [_session commitConfiguration];
}

/**
 *  根据scale参数拉近拉远镜头
 *
 *  @param scale 拉伸倍数
 */
- (void)pinchCameraViewWithScalNum:(CGFloat)scale {
    _scaleNum = scale;
    if (_scaleNum < MIN_PINCH_SCALE_NUM) {
        _scaleNum = MIN_PINCH_SCALE_NUM;
    } else if (_scaleNum > MAX_PINCH_SCALE_NUM) {
        _scaleNum = MAX_PINCH_SCALE_NUM;
    }
    [self doPinch];
    _preScaleNum = scale;
}

/**
 *  根据手势拉近拉远镜头
 *
 *  @param gesture 拉伸手势
 */
- (void)pinchCameraView:(UIPinchGestureRecognizer *)gesture {
    
    BOOL allTouchesAreOnThePreviewLayer = YES;
    
	NSUInteger numTouches = [gesture numberOfTouches], i;
	for ( i = 0; i < numTouches; ++i ) {
		CGPoint location = [gesture locationOfTouch:i inView:_preview];
		CGPoint convertedLocation = [_previewLayer convertPoint:location fromLayer:_previewLayer.superlayer];
		if ( ! [_previewLayer containsPoint:convertedLocation] ) {
			allTouchesAreOnThePreviewLayer = NO;
			break;
		}
	}
	
	if ( allTouchesAreOnThePreviewLayer ) {
		_scaleNum = _preScaleNum * gesture.scale;
        
        if (_scaleNum < MIN_PINCH_SCALE_NUM) {
            _scaleNum = MIN_PINCH_SCALE_NUM;
        } else if (_scaleNum > MAX_PINCH_SCALE_NUM) {
            _scaleNum = MAX_PINCH_SCALE_NUM;
        }
        
        [self doPinch];
	}
    
    if ([gesture state] == UIGestureRecognizerStateEnded ||
        [gesture state] == UIGestureRecognizerStateCancelled ||
        [gesture state] == UIGestureRecognizerStateFailed) {
        _preScaleNum = _scaleNum;
        SCDLog(@"final scale: %f", _scaleNum);
    }
}

- (void)doPinch {
 
    AVCaptureConnection *videoConnection = [self findVideoConnection];
    
    CGFloat maxScale = videoConnection.videoMaxScaleAndCropFactor;//videoScaleAndCropFactor这个属性取值范围是1.0-videoMaxScaleAndCropFactor。iOS5+才可以用
    if (_scaleNum > maxScale) {
        _scaleNum = maxScale;
    }
    if (_scaleNum < 1.f) {
        _scaleNum = 1.f;
    }
    
    //
//    videoConnection.videoScaleAndCropFactor = _scaleNum;
    
    //缩放预览图层尺寸
    [CATransaction begin];
    [CATransaction setAnimationDuration:.025];
    [_previewLayer setAffineTransform:CGAffineTransformMakeScale(_scaleNum, _scaleNum)];
    [CATransaction commit];
}

/**
 *  切换闪光灯模式
 */
- (void)switchFlashMode:(DidCaptureSwitchFlashModeBlock)block {
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    [device lockForConfiguration:nil];
    
    if ([device hasFlash]) {

        if (device.flashMode == AVCaptureFlashModeOff) {
            device.flashMode = AVCaptureFlashModeOn;
            
        } else if (device.flashMode == AVCaptureFlashModeOn) {
            device.flashMode = AVCaptureFlashModeAuto;
            
        } else if (device.flashMode == AVCaptureFlashModeAuto) {
            device.flashMode = AVCaptureFlashModeOff;
            
        }
        
        
        if (block) {
            block(device.flashMode);
        }
        
    } else {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示信息" message:@"您的设备没有闪光灯功能" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
        [alert show];
    }
    
    [device unlockForConfiguration];
}

/**
 *  点击后对焦
 */
- (void)focusInPoint:(CGPoint)devicePoint {
    if (CGRectContainsPoint(_previewLayer.bounds, devicePoint) == NO) {
        return;
    }
    //坐标转换
    devicePoint = [self convertToPointOfInterestFromViewCoordinates:devicePoint];
    //自动对焦自动曝光补偿
	[self focusWithMode:AVCaptureFocusModeAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:YES];
}

- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange {
    
	dispatch_async(_sessionQueue, ^{
		AVCaptureDevice *device = [_inputDevice device];
		NSError *error = nil;
		if ([device lockForConfiguration:&error])
		{
			if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:focusMode])
			{
				[device setFocusMode:focusMode];
				[device setFocusPointOfInterest:point];
			}
			if ([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:exposureMode])
			{
				[device setExposureMode:exposureMode];
				[device setExposurePointOfInterest:point];
			}
			[device setSubjectAreaChangeMonitoringEnabled:monitorSubjectAreaChange];
			[device unlockForConfiguration];
		}
		else
		{
			SCDLog(@"对焦和曝光补偿设置错误%@", error);
		}
	});
}

- (void)subjectAreaDidChange:(NSNotification *)notification {
    
	CGPoint devicePoint = CGPointMake(.5, .5);
	[self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:NO];
}

/**
 *  外部的point转换为camera需要的point(外部point/相机页面的frame)
 *
 *  @param viewCoordinates 外部的point
 *
 *  @return 相对位置的point
 */
- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates {
    CGPoint pointOfInterest = CGPointMake(.5f, .5f);
    CGSize frameSize = _previewLayer.bounds.size;
    
    AVCaptureVideoPreviewLayer *videoPreviewLayer = self.previewLayer;
    
    if([[videoPreviewLayer videoGravity]isEqualToString:AVLayerVideoGravityResize]) {
        pointOfInterest = CGPointMake(viewCoordinates.y / frameSize.height, 1.f - (viewCoordinates.x / frameSize.width));
    } else {
        CGRect cleanAperture;
        for(AVCaptureInputPort *port in [[self.session.inputs lastObject]ports]) {
            if([port mediaType] == AVMediaTypeVideo) {
                cleanAperture = CMVideoFormatDescriptionGetCleanAperture([port formatDescription], YES);
                CGSize apertureSize = cleanAperture.size;
                CGPoint point = viewCoordinates;
                
                CGFloat apertureRatio = apertureSize.height / apertureSize.width;
                CGFloat viewRatio = frameSize.width / frameSize.height;
                CGFloat xc = .5f;
                CGFloat yc = .5f;
                
                if([[videoPreviewLayer videoGravity]isEqualToString:AVLayerVideoGravityResizeAspect]) {
                    if(viewRatio > apertureRatio) {
                        CGFloat y2 = frameSize.height;
                        CGFloat x2 = frameSize.height * apertureRatio;
                        CGFloat x1 = frameSize.width;
                        CGFloat blackBar = (x1 - x2) / 2;
                        if(point.x >= blackBar && point.x <= blackBar + x2) {
                            xc = point.y / y2;
                            yc = 1.f - ((point.x - blackBar) / x2);
                        }
                    } else {
                        CGFloat y2 = frameSize.width / apertureRatio;
                        CGFloat y1 = frameSize.height;
                        CGFloat x2 = frameSize.width;
                        CGFloat blackBar = (y1 - y2) / 2;
                        if(point.y >= blackBar && point.y <= blackBar + y2) {
                            xc = ((point.y - blackBar) / y2);
                            yc = 1.f - (point.x / x2);
                        }
                    }
                } else if([[videoPreviewLayer videoGravity]isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
                    if(viewRatio > apertureRatio) {
                        CGFloat y2 = apertureSize.width * (frameSize.width / apertureSize.height);
                        xc = (point.y + ((y2 - frameSize.height) / 2.f)) / y2;
                        yc = (frameSize.width - point.x) / frameSize.width;
                    } else {
                        CGFloat x2 = apertureSize.height * (frameSize.height / apertureSize.width);
                        yc = 1.f - ((point.x + ((x2 - frameSize.width) / 2)) / x2);
                        xc = point.y / frameSize.height;
                    }
                    
                }
                
                pointOfInterest = CGPointMake(xc, yc);
                break;
            }
        }
    }
    return pointOfInterest;
}

//- (void)saveImageToPhotoAlbum:(UIImage*)image {
//    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
//}
//
//- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
//    if (error != NULL) {
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"出错了!" message:@"存不了T_T" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
//        [alert show];
//    } else {
//        SCDLog(@"保存成功111");
//    }
//}


#pragma mark ---------------private--------------

/** 根据设备方向获取相机方向 */
- (AVCaptureVideoOrientation)avOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation {
    AVCaptureVideoOrientation result = (AVCaptureVideoOrientation)deviceOrientation;
    if ( deviceOrientation == UIDeviceOrientationLandscapeLeft )
        result = AVCaptureVideoOrientationLandscapeRight;
    else if ( deviceOrientation == UIDeviceOrientationLandscapeRight )
        result = AVCaptureVideoOrientationLandscapeLeft;
    return result;
}

//屏幕旋转时调整视频预览图层的方向
-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    AVCaptureConnection *captureConnection=[self.previewLayer connection];
    captureConnection.videoOrientation = (AVCaptureVideoOrientation)toInterfaceOrientation;
}

//旋转后重新设置大小
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    self.previewLayer.frame= self.preview.bounds;
}


/** 得到设备连接 */
- (AVCaptureConnection*)findVideoConnection {
    AVCaptureConnection *videoConnection = nil;
	for (AVCaptureConnection *connection in _stillImageOutput.connections) {
		for (AVCaptureInputPort *port in connection.inputPorts) {
			if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
				videoConnection = connection;
				break;
			}
		}
		if (videoConnection) {
            break;
        }
	}
    return videoConnection;
}



@end
