//
//  SCCaptureCameraController.m
//  SCCaptureCameraDemo
//
//  Created by Aevitx on 14-1-16.
//  Copyright (c) 2016年 cy. All rights reserved.
//

#import "SCCaptureCameraController.h"
//相机
#import "SCCaptureSessionManager.h"
#import "SCCommon.h"
//依赖库
#import <Photos/Photos.h>
#import "SVProgressHUD.h"

#import <CoreMotion/CoreMotion.h>
//自定义
#import "CameraContentView.h"


//对焦框是否一直闪到对焦完成
#define SWITCH_SHOW_FOCUSVIEW_UNTIL_FOCUS_DONE 0
//对焦
#define ADJUSTINT_FOCUS @"adjustingFocus"
#define LOW_ALPHA   0.7f
#define HIGH_ALPHA  1.0f

@interface SCCaptureCameraController ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate,CameraContentViewDelegate>
{
    //对焦相关
    int alphaTimes;
    CGPoint currTouchPoint;
    UIImageView *_focusImageView;
}

@property (nonatomic, strong) SCCaptureSessionManager *captureManager;
/** 保存界面按钮的集合 （用处在于处理相机旋转方面）*/
@property (nonatomic, strong) NSMutableSet *cameraBtnSet;
/** 相机界面 */
@property (nonatomic,weak) CameraContentView* contentView;


@property (strong,nonatomic) CMMotionManager *motionManager;
@property (nonatomic,strong) NSMutableArray *images;
@end

@implementation SCCaptureCameraController

- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark - 陀螺仪相关
-(CMMotionManager *)motionManager {
    if (!_motionManager) {
        _motionManager = [[CMMotionManager alloc] init];
    }
    return _motionManager;
}

static CGFloat _rotationX = 0;
static CGFloat _rotationY = 0;
static CGFloat _rotationZ = 0;

- (void)pullByDeviceMotion {
    
    self.motionManager.deviceMotionUpdateInterval = 0.05;
    if (self.motionManager.gyroAvailable) {
        
        _rotationX = 0;
        _rotationY = 0;
        _rotationZ = 0;
        [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion * _Nullable motion, NSError * _Nullable error) {
            
//            _rotationX = _rotationX + self.motionManager.deviceMotionUpdateInterval * gyroData.rotationRate.x;
//            _rotationY = _rotationY + self.motionManager.deviceMotionUpdateInterval * motion.rotationRate.y;
//            _rotationZ = _rotationZ + self.motionManager.deviceMotionUpdateInterval * gyroData.rotationRate.z;
            _rotationX = atan2(motion.gravity.y, motion.gravity.z) + M_PI_2;
            _rotationY = 0;
            _rotationZ = atan2(motion.gravity.x, motion.gravity.y) - M_PI;
            
            while (_rotationX > M_PI) {
                _rotationX -= 2 * M_PI;
            }
            while (_rotationX < -M_PI) {
                _rotationX += 2 * M_PI;
            }
            
//            while (_rotationY > M_PI) {
//                _rotationY -= 2 * M_PI;
//            }
//            while (_rotationY < -M_PI) {
//                _rotationY += 2 * M_PI;
//            }
            
            while (_rotationZ > M_PI) {
                _rotationZ -= 2 * M_PI;
            }
            while (_rotationZ < -M_PI) {
                _rotationZ += 2 * M_PI;
            }
            
            preViewRota preRota = {_rotationX,_rotationY,_rotationZ};
            self.contentView.preRota = preRota;
            NSLog(@"x: %f \n y: %f \n z: %f\n",_rotationX,_rotationY,_rotationZ);
        }];
    }

}

- (void)stopUpdateMotion {
    [self.motionManager stopGyroUpdates];
    self.motionManager = nil;
}



#pragma mark - system
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];

    //初始化相机相关
    [self loadCamera];
    [self loadCameraUI];
    
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    
    [self pullByDeviceMotion];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [UIApplication sharedApplication].idleTimerDisabled =YES;

    //如果相机不可用 一切都不再继续
    [self isCameraAvailavle];
    
    
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    
    [self stopUpdateMotion];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
#if SWITCH_SHOW_FOCUSVIEW_UNTIL_FOCUS_DONE
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (device && [device isFocusPointOfInterestSupported]) {
        [device removeObserver:self forKeyPath:ADJUSTINT_FOCUS context:nil];
    }
#endif
    self.captureManager = nil;
}

//相机是否可用  不可用给出提示
- (void)isCameraAvailavle {

    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [SVProgressHUD showErrorWithStatus:@"拍照功能不可用"];
        //此处应该不被注释掉
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
    
    //判断用户是否开启了相机权限
    AVAuthorizationStatus authStatus =  [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    PHAuthorizationStatus phStatus = [PHPhotoLibrary authorizationStatus];
    if (authStatus == AVAuthorizationStatusRestricted || authStatus ==AVAuthorizationStatusDenied || phStatus == PHAuthorizationStatusRestricted || phStatus == PHAuthorizationStatusDenied ){
        
            UIAlertController *choosePhotoAlert = [UIAlertController alertControllerWithTitle:@"提示" message:@"请为全景相机开放访问相机和相册权限" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *sure = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                if ([[UIApplication sharedApplication] canOpenURL:url]) {
                    [[UIApplication sharedApplication] openURL:url];
                }
            }];
            UIAlertAction *cancle = [UIAlertAction actionWithTitle:NSLocalizedString(@"取消", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                [self dismissViewControllerAnimated:YES completion:nil];
            }];
            [choosePhotoAlert addAction:sure];
            [choosePhotoAlert addAction:cancle];
            [self presentViewController:choosePhotoAlert animated:YES completion:nil];
    }
}

#pragma mark - 屏幕旋转
//屏幕旋转时调整视频预览图层的方向
-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    if ([self.captureManager respondsToSelector:@selector(willRotateToInterfaceOrientation:duration:)]) {
        [self.captureManager willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    }
}

//旋转后重新设置大小
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
    if ([self.captureManager respondsToSelector:@selector(didRotateFromInterfaceOrientation:)]) {
        [self.captureManager didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    }
}

#pragma mark - init
- (void)loadCameraUI {
    //相机按钮界面
    [self addContentView];
    //对焦框
    [self addFocusView];
    //捏合手势
    [self addPinchGesture];
}

- (void)loadCamera {
     CGRect preViewRect = CGRectMake(0,0, SC_APP_SIZE.width, SC_DEVICE_SIZE.height);
    //初始化session manager
    SCCaptureSessionManager *manager = [[SCCaptureSessionManager alloc] init];
    //初始化相机预览界面
    if (CGRectEqualToRect(preViewRect, CGRectZero)) {
        preViewRect = CGRectMake(0, 64, SC_APP_SIZE.width, SC_DEVICE_SIZE.height- 64);
    }
    [manager configureWithParentView:self.view previewRect:preViewRect thumbPreviewRect:CGRectMake(10, 50, 200,200)];
    self.captureManager = manager;
    //运行会话
    if (!self.captureManager.session.isRunning) {
        [self.captureManager.session startRunning];
    }
    
    //其他一些无聊的配置
    alphaTimes = -1;
    currTouchPoint = CGPointZero;
    self.cameraBtnSet = [[NSMutableSet alloc] init];
}

//相机界面
- (void)addContentView {
    CameraContentView *contentView = [CameraContentView contentView];
    contentView.delegate = self;
    [self.view addSubview:contentView];
    self.contentView = contentView;
}

//对焦的框
- (void)addFocusView {
    _focusImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"focus"]];
    _focusImageView.alpha = 0;
    [self.view addSubview:_focusImageView];
    
#if SWITCH_SHOW_FOCUSVIEW_UNTIL_FOCUS_DONE
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (device && [device isFocusPointOfInterestSupported]) {
        [device addObserver:self forKeyPath:ADJUSTINT_FOCUS options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
    }
#endif
}

//伸缩镜头的手势
- (void)addPinchGesture {
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    [self.view addGestureRecognizer:pinch];
}

#pragma mark - cameraContentViewDelegate
- (void)cameraContentView:(CameraContentView *)contentView didClickBtn:(UIButton *)btn withType:(CameraContentViewBtnType)btnType {
    switch (btnType) {
        case CameraContentViewBtnTypeDismiss:
            [self.navigationController popViewControllerAnimated:YES];
            break;
        case CameraContentViewBtnTypeTakePhoto:
            [self takePhotoBtnPressed:btn];
            break;
        case CameraContentViewBtnTypeSwitchCamera:
            [self switchCameraBtnPressed:btn];
            break;
        default:
            break;
    }
}

#pragma mark - cameraEvents
//伸缩镜头
- (void)handlePinch:(UIPinchGestureRecognizer*)gesture {
    [_captureManager pinchCameraView:gesture];
}

//切换前后摄像头按钮按钮
- (void)switchCameraBtnPressed:(UIButton*)sender {
    sender.selected = !sender.selected;
    [_captureManager switchCamera:sender.selected];
}

- (void)takePhotoBtnPressed:(UIButton *)sender {


    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [SVProgressHUD showErrorWithStatus:@"相机错误"];
        return;
    }
    
    [_captureManager takePicture:^(UIImage *stillImage) {

        NSData *data = UIImageJPEGRepresentation(stillImage, 1);
        UIImage *resultImg = [[UIImage alloc] initWithData:data];
        UIImageWriteToSavedPhotosAlbum(resultImg, nil, nil, nil);
        [SVProgressHUD showSuccessWithStatus:@"拍照成功"];
    }];
}

#pragma mark 对焦事件相关
#if SWITCH_SHOW_FOCUSVIEW_UNTIL_FOCUS_DONE
//监听对焦是否完成了
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:ADJUSTINT_FOCUS]) {
        BOOL isAdjustingFocus = [[change objectForKey:NSKeyValueChangeNewKey] isEqualToNumber:[NSNumber numberWithInt:1] ];
        if (!isAdjustingFocus) {
            alphaTimes = -1;
        }
    }
}

- (void)showFocusInPoint:(CGPoint)touchPoint {
    
    [UIView animateWithDuration:0.1f delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        
        int alphaNum = (alphaTimes % 2 == 0 ? HIGH_ALPHA : LOW_ALPHA);
        self.focusImageView.alpha = alphaNum;
        alphaTimes++;
        
    } completion:^(BOOL finished) {
        
        if (alphaTimes != -1) {
            [self showFocusInPoint:currTouchPoint];
        } else {
            self.focusImageView.alpha = 0.0f;
        }
    }];
}
#endif

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    alphaTimes = -1;
    
    UITouch *touch = [touches anyObject];
    currTouchPoint = [touch locationInView:self.view];
    
    if (CGRectContainsPoint(_captureManager.previewLayer.frame, currTouchPoint) == NO) {
        return;
    }
    
    [_captureManager focusInPoint:currTouchPoint];
    
    //对焦框
    [_focusImageView setCenter:currTouchPoint];
    _focusImageView.transform = CGAffineTransformMakeScale(2.0, 2.0);
    
#if SWITCH_SHOW_FOCUSVIEW_UNTIL_FOCUS_DONE
    [UIView animateWithDuration:0.1f animations:^{
        _focusImageView.alpha = HIGH_ALPHA;
        _focusImageView.transform = CGAffineTransformMakeScale(1.0, 1.0);
    } completion:^(BOOL finished) {
        [self showFocusInPoint:currTouchPoint];
    }];
#else
    [UIView animateWithDuration:0.3f delay:0.f options:UIViewAnimationOptionAllowUserInteraction animations:^{
        _focusImageView.alpha = 1.f;
        _focusImageView.transform = CGAffineTransformMakeScale(1.0, 1.0);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.5f delay:0.5f options:UIViewAnimationOptionAllowUserInteraction animations:^{
            _focusImageView.alpha = 0.f;
        } completion:nil];
    }];
#endif
}

#pragma mark -- 图片的保存和处理
//清除已生成的图片
-(void)removeResultImg{
    NSFileManager *fm = [NSFileManager defaultManager];
    for (NSString *path in _images) {
        if( [fm fileExistsAtPath:path] ) {
            [fm removeItemAtPath:path error:nil];
        }
    }
    
}

/**
 *  切成正方形   只适合处理屏幕大小的图片（未缩放）
 */
- (UIImage *)cutImage:(UIImage *)sourceImage With:(CGRect)usebleRect{
    // CGImageCreateWithImageInRect只认像素
    
    
    CGFloat newX = 0;
    CGFloat newY = (sourceImage.size.height - sourceImage.size.width) / 2;
    CGFloat newW = sourceImage.size.width;
    CGFloat newH = newW;
    CGImageRef newImageRef = CGImageCreateWithImageInRect(sourceImage.CGImage, CGRectMake(newX,newY, newW , newH));
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
     CGImageRelease(newImageRef);
    NSLog(@"newImage size is %@ ,scale is %f",[NSValue valueWithCGSize:newImage.size],[UIScreen mainScreen].scale);

    if (newImage == nil) {
        NSLog(@"裁图失败");
    }
    return newImage;
}

/**
 *  用相机拍摄出来的照片含有EXIF信息，UIImage的imageOrientation属性指的就是EXIF中的orientation信息。如果我们忽略orientation信息，而直接对照片进行像素处理或者drawInRect等操作，得到的结果是翻转或者旋转90之后的样子。这是因为我们执行像素处理或者drawInRect等操作之后，imageOrientaion信息被删除了，imageOrientaion被重设为0，造成照片内容和imageOrientaion不匹配。所以，在对照片进行处理之前，先将照片旋转到正确的方向，并且返回的imageOrientaion为0。
 */
- (UIImage *)fixOrientation:(UIImage *)aImage {
    
    // No-op if the orientation is already correct
    if (aImage.imageOrientation == UIImageOrientationUp)
        return aImage;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, aImage.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, aImage.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, aImage.size.width, aImage.size.height,
                                             CGImageGetBitsPerComponent(aImage.CGImage), 0,
                                             CGImageGetColorSpace(aImage.CGImage),
                                             CGImageGetBitmapInfo(aImage.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (aImage.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.height,aImage.size.width), aImage.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.width,aImage.size.height), aImage.CGImage);
            break;  
    }  
    
    // And now we just create a new UIImage from the drawing context  
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);  
    UIImage *img = [UIImage imageWithCGImage:cgimg];  
    CGContextRelease(ctx);  
    CGImageRelease(cgimg);  
    return img;  
}



@end



