//
//  CYDeviceManager.h
//  CameraBox
//
//  Created by Chenyan on 16/7/14.
//  Copyright © 2016年 chenyan. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef enum{
    //iPhone
    DeviceCategoryIPhone2G,
    DeviceCategoryIPhone3G,
    DeviceCategoryIPhone3GS,
    DeviceCategoryIPhone4 = 0,
    DeviceCategoryIPhone4s,
    DeviceCategoryIPhone5,
    DeviceCategoryIPhone5s,
    DeviceCategoryIPhone5c,
    DeviceCategoryIPhone6,
    DeviceCategoryIPhone6Plus,
    DeviceCategoryIPhone6s,
    DeviceCategoryIPhone6sPlus,
    DeviceCategoryIPhoneSE,
    DeviceCategoryIPhone7,
    DeviceCategoryIPhone7Plus,
    //iPad
    DeviceCategoryIPad1G,
    DeviceCategoryIPad2,
    DeviceCategoryIPadMini1G,
    DeviceCategoryIPad3,
    DeviceCategoryIPad4,
    DeviceCategoryIPadAir,
    DeviceCategoryIPadMini2G,
    //other
    DeviceCategoryIPhoneSimulator,
    DeviceCategoryOther
}DeviceCategory;

typedef NS_ENUM(NSInteger,CYDeviceOrientation) {
    CYDeviceOrientationUnkown,
    CYDeviceOrientationPortrait,
    CYDeviceOrientationUpsideDown,
    CYDeviceOrientationLandscapeRight,
    CYDeviceOrientationLandscapeLeft,
};

//此监听设备方向变化的回调关闭系统转屏时也会生效，但是功能比较单一，最适合在相机界面旋转上使用
@protocol DeviceOrientationDelegate <NSObject>

- (void)deviceDidChangedToOrientation:(CYDeviceOrientation)orientation;

@end


@interface CYDeviceManager : NSObject

@property(nonatomic,strong)id<DeviceOrientationDelegate>delegate;

- (instancetype)initWithDelegate:(id<DeviceOrientationDelegate>)delegate;
/** 开启方向监听 */
- (void)startOrientationUpdate;
/** 结束方向监听 */
- (void)stopOrientationUpdate;
/** 获取当前设备方向，未开启监听也可正常获取 */
- (CYDeviceOrientation)currentOrientation;


/** 获取设备总内存大小 mb */
+ (NSUInteger)getDeviceTotalMemorySize;
/** 获取设备可用内存大小 mb */
+ (NSUInteger)getDeviceAvailableMemorySize;
/** 电量 */
+ (CGFloat)getBatteryLevel;

/** 系统版本 */
+ (NSString *)getOSVersonString;
+ (DeviceCategory)getDeviceCategory;
@end
