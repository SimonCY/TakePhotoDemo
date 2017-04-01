//
//  SCCaptureSessionManager.m
//  SCCaptureCameraDemo
//
//  Created by chenyan on 14-1-16.
//  Copyright (c) 2014年 chenyan. All rights reserved.
//

#import "SCCaptureSessionManager.h"
#import <ImageIO/ImageIO.h>

#import "UIImage+CYExtension.h"

@interface SCCaptureSessionManager ()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureFileOutputRecordingDelegate>

//预览图层将要添加到的View
@property (nonatomic, strong) UIView *parentView;
/** 预览图层 */
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;


/** 会话对象，执行输入设备和输出设备之间的数据传递 */
@property (nonatomic, strong) AVCaptureSession *session;


/** 会话处理队列 */
@property (nonatomic) dispatch_queue_t sessionQueue;
/** 当前摄像头取景方向 */
@property (nonatomic,assign) AVCaptureVideoOrientation videoOrientation;


//前摄像头
@property (nonatomic,strong) AVCaptureDevice* frontCamera;
//后摄像头
@property (nonatomic,strong) AVCaptureDevice* backCamera;
//麦克风
@property (nonatomic,strong) AVCaptureDevice* audioDevice;


/** 当前视频输入设备input(前或后摄像头input) */
@property (nonatomic, strong) AVCaptureDeviceInput *videoDeviceInput;
/** 当前音频输入设备input(音频input) */
@property (nonatomic, strong) AVCaptureDeviceInput *audioDeviceInput;



/** 照片输出流 */
@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;
/** 视频输出流 */
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutput;
/** 视频文件输出流 */
@property (nonatomic,strong) AVCaptureMovieFileOutput* movieFileOutput;



@property (nonatomic,copy) NSString* recordingMoviePath;

@property (nonatomic,weak) DidFinishRecordingBlock finishRecordingBlock;

@end


@implementation SCCaptureSessionManager

- (void)start {
    if (!self.session.isRunning) {
        [self.session startRunning];
    }
}

- (void)stop {
    if (self.session.isRunning) {
        [self.session stopRunning];
    }
}


#pragma mark setup

- (instancetype)init {
    if (self = [super init]) {
        _scaleNum = 1.f;
        _preScaleNum = 1.f;
        _videoOrientation = AVCaptureVideoOrientationPortrait;
    }
    return self;
}

- (void)dealloc {
    
    [_session stopRunning];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)configureWithParentView:(UIView*)parentView previewRect:(CGRect)preivewRect thumbPreviewRect:(CGRect)thumbPreviewRect {
    
    self.parentView = parentView;
    
    //1、队列
    [self createQueue];
    
    //2、session
    [self addSession];
    
    //3、previewLayer
    [self addVideoPreviewLayerWithParentLayer:parentView.layer rect:preivewRect];

    //4、videoinput (默认后置摄像头)
    [self addVideoInputLens:SCCaptureInputDeviceTypeBackLens];
    
    //5、audioinput
    [self addAudioInput];
    
    
    //6、stillImageoutput （默认是相机）
    [self addStillImageOutput];
    
    //7.videoOutput
    [self addMovieFileOutput];
    
    //6、thumbPreView
//    [self addThumbPreViewWithParentView:parentView thumbPreviewRect:thumbPreviewRect];
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
    
    NSError *error = nil;
    switch (lensType) {
        case SCCaptureInputDeviceTypeBackLens: {
            
            AVCaptureDeviceInput *backFacingCameraDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.backCamera error:&error];
            if (!error) {
                if ([_session canAddInput:backFacingCameraDeviceInput]) {
                    [_session addInput:backFacingCameraDeviceInput];
                    self.videoDeviceInput = backFacingCameraDeviceInput;
                    
                } else {
                    CYLog(@"无法切换到后摄像头");
                }
            }
            break;
        }
        case SCCaptureInputDeviceTypeFrontLens: {
            
            AVCaptureDeviceInput *frontFacingCameraDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.frontCamera error:&error];
            if (!error) {
                if ([_session canAddInput:frontFacingCameraDeviceInput]) {
                    [_session addInput:frontFacingCameraDeviceInput];
                    self.videoDeviceInput = frontFacingCameraDeviceInput;
                    
                } else {
                    CYLog(@"无法切换到前摄像头");
                }
            }
            break;
        }
        default:
            break;
    }
}

- (void)addAudioInput {
    NSError *error = nil;
    AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.audioDevice error:&error];
    if (!error) {
        if ([_session canAddInput:audioDeviceInput]) {
            [_session addInput:audioDeviceInput];
            self.audioDeviceInput = audioDeviceInput;
            
        } else {
            CYLog(@"无法添加麦克风");
        }
    }

}

/** 添加相机输出设备 */
- (void)addStillImageOutput {
    
    AVCaptureStillImageOutput *tmpOutput = [[AVCaptureStillImageOutput alloc] init];
    //输出jpeg图像
    NSDictionary *outputSettings = @{AVVideoCodecKey : AVVideoCodecJPEG};
    tmpOutput.outputSettings = outputSettings;
    
    if ([_session canAddOutput:tmpOutput]) {
        
        [_session addOutput:tmpOutput];
        self.stillImageOutput = tmpOutput;
    }
    
}

- (void)addMovieFileOutput {
    AVCaptureMovieFileOutput *fileOutput = [[AVCaptureMovieFileOutput alloc] init];
    
    if ([_session canAddOutput:fileOutput]) {
        [_session addOutput:fileOutput];
        self.movieFileOutput = fileOutput;
    }
    
}

- (void)addThumbPreViewWithParentView:parentView thumbPreviewRect:(CGRect)thumbPreviewRect {
    
    
    // 视频输出
    AVCaptureVideoDataOutput *videoOut = [[AVCaptureVideoDataOutput alloc] init];
    [videoOut setAlwaysDiscardsLateVideoFrames:YES];
    [videoOut setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]}];
    [videoOut setSampleBufferDelegate:self queue:self.sessionQueue];
    if ([_session canAddOutput:videoOut]){
        [_session addOutput:videoOut];
        self.videoOutput = videoOut;
    }
    
    // 设置视频捕捉连接
    AVCaptureConnection *videoConnection = [videoOut connectionWithMediaType:AVMediaTypeVideo];
    videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    
    EAGLContext *context = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    _thumbPreView = [[GLKView alloc]initWithFrame:thumbPreviewRect context:context];
    [EAGLContext setCurrentContext:context];
    [parentView addSubview:_thumbPreView];
    _cicontext = [CIContext contextWithEAGLContext:context];
    
}

#pragma mark - videoOutput Delegate

/** 取得视频每帧静态图 */
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef) sampleBuffer fromConnection:(AVCaptureConnection *)connection {

    if (!_thumbPreView.superview) {
        return;
    }
    
    if ([UIDevice currentDevice].systemVersion.floatValue < 9) {
        [_thumbPreView removeFromSuperview];
        _thumbPreView = nil;
        return;
    }
    
     if (_thumbPreView.context != [EAGLContext currentContext]) {
        [EAGLContext setCurrentContext:_thumbPreView.context];
    }

    CVImageBufferRef imageRef = CMSampleBufferGetImageBuffer(sampleBuffer);
    CIImage *image = [CIImage imageWithCVImageBuffer:imageRef];
    [_thumbPreView bindDrawable];
    [_cicontext drawImage:image inRect:CGRectMake(0, 0, _thumbPreView.bounds.size.width * 2, _thumbPreView.bounds.size.height * 2) fromRect:image.extent];
    [_thumbPreView display];
}


#pragma mark - setter

- (void)setVideoOrientation:(AVCaptureVideoOrientation)videoOrientation {
    _videoOrientation = videoOrientation;
    
    AVCaptureConnection *stillImageConnection = [self findCaptureConnectionFromStillImageOutput];
    stillImageConnection.videoOrientation = videoOrientation;
    
    AVCaptureConnection *videoConnection = [self findCaptureConnectionFromVideoOutput];
    videoConnection.videoOrientation = videoOrientation;
    
    AVCaptureConnection *movieFileConnection = [self findCaptureConnectionFromMovieFileOutput];
    movieFileConnection.videoOrientation = videoOrientation;
    
    AVCaptureConnection *previewConnection = [self.previewLayer connection];
    previewConnection.videoOrientation = videoOrientation;
    
}


#pragma mark - camera actions

- (void)startRecording {
    if ([self.movieFileOutput isRecording]) return;
    
    self.recordingMoviePath = [self newMP4FilePath];
    [self.movieFileOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:self.recordingMoviePath] recordingDelegate:self];
}

- (void)stopRecording:(DidFinishRecordingBlock)block {
    
    if ([self.movieFileOutput isRecording]) {
        [self.movieFileOutput stopRecording];
        self.recordingMoviePath = nil;
        self.finishRecordingBlock  = block;
    }
}

/** 拍照 */
- (void)takePicture:(DidCapturePhotoBlock)block {
    AVCaptureConnection *videoConnection = [self findCaptureConnectionFromStillImageOutput];

    [videoConnection setVideoScaleAndCropFactor:_scaleNum];
    
    if (videoConnection.isVideoOrientationSupported) {
        videoConnection.videoOrientation = [self videoOrientation];
    }
    
   WEAKSELF_CY
    
    [_stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        
        if (imageDataSampleBuffer == NULL || error) {
            CYLog(@"取图片时发生错误");
        }
        
        //将imageDataSampleBuffer处理成image
        CFDictionaryRef exifAttachments = CMGetAttachment(imageDataSampleBuffer, kCGImagePropertyExifDictionary, NULL);
        if (exifAttachments) {
            CYLog(@"attachements: %@", exifAttachments);
        } else {
            CYLog(@"no attachments");
        }
    
        NSData *imageData = nil;
        if (imageDataSampleBuffer) {
            imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        }
        
        CYLog(@"image Size: %ld",imageData.length);
        UIImage *croppedImage = [[UIImage alloc] initWithData:imageData];
        
        CYLog(@"原图:%@", [NSValue valueWithCGSize:croppedImage.size]);

        //block、delegate、notification 3选1，传值
        if (block) {
            
            block(croppedImage);
        } else if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(didCapturePhoto:)]) {
            [weakSelf.delegate didCapturePhoto:croppedImage];
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
    if (!_videoDeviceInput) {
        CYLog(@"当前没有输入设备");
        return;
    }
    [_session beginConfiguration];
    [_session removeInput:_videoDeviceInput];
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
		CGPoint location = [gesture locationOfTouch:i inView:self.parentView];
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
        CYLog(@"final scale: %f", _scaleNum);
    }
}

- (void)doPinch {
 
    AVCaptureConnection *videoConnection = [self findCaptureConnectionFromStillImageOutput];
    
    CGFloat maxScale = videoConnection.videoMaxScaleAndCropFactor;//videoScaleAndCropFactor这个属性取值范围是1.0-videoMaxScaleAndCropFactor。iOS5+才可以用
    if (_scaleNum > maxScale) {
        _scaleNum = maxScale;
    }
    if (_scaleNum < 1.f) {
        _scaleNum = 1.f;
    }
    
    //在拍照时做的这一步
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
		AVCaptureDevice *device = [_videoDeviceInput device];
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
			CYLog(@"对焦和曝光补偿设置错误%@", error);
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


#pragma mark ---------------private--------------

/** 取得当前闪光模式 */
- (AVCaptureFlashMode)flashMode {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    if (device.flashAvailable) {
        
        return device.flashMode;
    }
    return AVCaptureFlashModeOff;
}

/** 取得当前活跃的摄像头 */
- (AVCaptureDevice *)activeCamera {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (device) {
        CYLog(@"active camera : %@",device.localizedName);
        return device;
    }
    CYLog(@"there is no active camera");
    return nil;
}

/** 取得前摄像头 */
- (AVCaptureDevice *)frontCamera {
    
    NSArray *devices = [AVCaptureDevice devices];
    for (AVCaptureDevice *device in devices) {
        
        
        if ([device hasMediaType:AVMediaTypeVideo] && [device position] == AVCaptureDevicePositionFront) {
            CYLog(@"inputDevice:%@",device.localizedName);
            return device;
        }
    }
    CYLog(@"inputDevice: there is no front camera!");
    return nil;
}

/** 取得后摄像头 */
- (AVCaptureDevice *)backCamera {
    
    NSArray *devices = [AVCaptureDevice devices];
    for (AVCaptureDevice *device in devices) {
        
        if ([device hasMediaType:AVMediaTypeVideo] && [device position] == AVCaptureDevicePositionBack) {
            CYLog(@"inputDevice:%@",device.localizedName);
            return device;
        }
    }
    CYLog(@"inputDevice: there is no back camera!");
    return nil;
}
/** 取得当前声音输入设备 */
- (AVCaptureDevice *)audioDevice {
    [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    
    NSArray *devices = [AVCaptureDevice devices];
    for (AVCaptureDevice *device in devices) {
        
        if ([device hasMediaType:AVMediaTypeAudio]) {
            CYLog(@"inputDevice:%@",device.localizedName);
            return device;
        }
    }
    CYLog(@"inputDevice: there is no audio inputDevice!");
    return nil;
}

/** 得到相机输出的设备连接 （相机专用） */
- (AVCaptureConnection*)findCaptureConnectionFromStillImageOutput {
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

/** 得到视频输出的设备连接 （视频专用）*/
- (AVCaptureConnection*)findCaptureConnectionFromVideoOutput {
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in _videoOutput.connections) {
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


/** 得到视频输出的设备连接 （视频专用）*/
- (AVCaptureConnection*)findCaptureConnectionFromMovieFileOutput {
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in _movieFileOutput.connections) {
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

#pragma mark - 生成视频文件相关

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections {

}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    if (!error) {
        if (self.finishRecordingBlock) {
            self.finishRecordingBlock(outputFileURL);
        }
    } else {
        CYLog(@"录制失败");
    }
}


//生成caches目录下不带后缀名的一个以时间戳为名的新文件路径
- (NSString *)newTimeStrFilePath {
    
    //生成时间戳
    long recordTime = (NSInteger)[[NSDate date] timeIntervalSince1970]*1000;
    NSString *timeString = [NSString stringWithFormat:@"%ld",recordTime];
    
    //生成路径
    NSArray *CachesPaths =NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask,YES);
    NSString *filePath =[[CachesPaths objectAtIndex:0] stringByAppendingPathComponent:timeString];
    return filePath;
}

- (NSString *)newMP4FilePath{
    return [NSString stringWithFormat:@"%@.mp4",[self newTimeStrFilePath]];
}

@end
