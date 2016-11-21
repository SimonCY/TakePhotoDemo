//
//  CYDeviceManager.h
//  CameraBox
//
//  Created by Chenyan on 16/7/14.
//  Copyright © 2016年 chenyan. All rights reserved.
//

#import <UIKit/UIKit.h>

#ifndef KCOMMON_DEVICE_CATEGORY
#define KCOMMON_DEVICE_CATEGORY
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
#endif

@interface CYDeviceManager : NSObject

/** 获取设备总内存大小 mb */
+ (NSUInteger)getDeviceTotalMemorySize;
/** 获取设备可用内存大小 mb */
+ (NSUInteger)getDeviceAvailableMemorySize;

+ (CGFloat)getBatteryLevel;
+ (NSString *)getOSVersonString;
+ (DeviceCategory)getDeviceCategory;
@end
