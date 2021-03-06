//
//  CYDeviceManager.m
//  CameraBox
//
//  Created by Chenyan on 16/7/14.
//  Copyright © 2016年 chenyan. All rights reserved.
//

#import "CYDeviceManager.h"
#import <mach/mach.h>
#import "sys/utsname.h"
#import <CoreMotion/CoreMotion.h>

@interface CYDeviceManager () {
    
    CYDeviceOrientation _direction;
    
}
@end

static CMMotionManager *_motionManager;

//sensitive 灵敏度
static const float sensitive = 0.77;

@implementation CYDeviceManager

#pragma mark - 设备方向监听

- (instancetype)initWithDelegate:(id<DeviceOrientationDelegate>)delegate {
    self = [super init];
    if (self) {
        
        _delegate = delegate;
    }
    return self;
}

- (void)startOrientationUpdate {
    
    if (_motionManager == nil) {
        
        _motionManager = [[CMMotionManager alloc] init];
    }
    _motionManager.deviceMotionUpdateInterval = 1/5.f;
    if (_motionManager.deviceMotionAvailable) {
        
        [_motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue]
                                            withHandler: ^(CMDeviceMotion *motion, NSError *error){
                                                [self performSelectorOnMainThread:@selector(motionUpdated:) withObject:motion waitUntilDone:YES];
                                            }];
    }
}

- (void)stopOrientationUpdate {
    
    [_motionManager stopDeviceMotionUpdates];
}

- (CYDeviceOrientation)currentOrientation {
    if (_motionManager == nil) {
        
        _motionManager = [[CMMotionManager alloc] init];
    }
    if ([_motionManager isDeviceMotionAvailable]) {
        
        return [self orientationFromMotion:[_motionManager deviceMotion]];
    }
    return CYDeviceOrientationUnkown;
}

- (void)motionUpdated:(CMDeviceMotion *)motion{
    
    CYDeviceOrientation newOrientation = [self orientationFromMotion:motion];
    if (_direction != newOrientation) {
        
        _direction = newOrientation;
        if (self.delegate && [self.delegate respondsToSelector:@selector(deviceDidChangedToOrientation:)]) {
            [self.delegate deviceDidChangedToOrientation:_direction];
        }
    }
}


- (CYDeviceOrientation)orientationFromMotion:(CMDeviceMotion *)motion {
    
    double x = motion.gravity.x;
    double y = motion.gravity.y;
    
    if (y < 0) {
        if (fabs(y) > sensitive) {

            return CYDeviceOrientationPortrait;
        }
    }else {
        if (y > sensitive) {
 
            return CYDeviceOrientationUpsideDown;
        }
    }
    if (x < 0) {
        if (fabs(x) > sensitive) {
            
            return CYDeviceOrientationLandscapeRight;
        }
    }else {
        if (x > sensitive) {
            
            return CYDeviceOrientationLandscapeLeft;
        }
    }
    return CYDeviceOrientationUnkown;
}


#pragma mark - 其他系统相关功能
//获取设备内存信息，大小M
+ (NSUInteger)getDeviceTotalMemorySize{
    
    unsigned long long M = [NSProcessInfo processInfo].physicalMemory;
    return  M/1024/1024.0;
}

+ (NSUInteger)getDeviceAvailableMemorySize {
    vm_statistics_data_t vmStats;
    mach_msg_type_number_t infoCount = HOST_VM_INFO_COUNT;
    kern_return_t kernReturn = host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vmStats, &infoCount);
    if (kernReturn != KERN_SUCCESS)
    {
        return NSNotFound;
    }
    return ((vm_page_size * vmStats.free_count + vm_page_size * vmStats.inactive_count));
}

+ (CGFloat)getBatteryLevel {
    return [[UIDevice currentDevice] batteryLevel];
}

+ (NSString *)getOSVersonString {
    return [[UIDevice currentDevice] systemVersion];
}

+ (DeviceCategory)getDeviceCategory{
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceString = [NSString stringWithCString:systemInfo.machine encoding:NSASCIIStringEncoding];
    if ([deviceString isEqualToString:@"iPhone1,1"]) return DeviceCategoryIPhone2G;
    if ([deviceString isEqualToString:@"iPhone1,2"]) return DeviceCategoryIPhone3G;
    if ([deviceString isEqualToString:@"iPhone2,1"]) return DeviceCategoryIPhone3GS;
    if ([deviceString isEqualToString:@"iPhone3,1"]) return DeviceCategoryIPhone4;
    if ([deviceString isEqualToString:@"iPhone3,2"]) return DeviceCategoryIPhone4;
    if ([deviceString isEqualToString:@"iPhone3,3"]) return DeviceCategoryIPhone4;
    if ([deviceString isEqualToString:@"iPhone4,1"]) return DeviceCategoryIPhone4s;
    if ([deviceString isEqualToString:@"iPhone5,1"]) return DeviceCategoryIPhone5;
    if ([deviceString isEqualToString:@"iPhone5,2"]) return DeviceCategoryIPhone5;
    if ([deviceString isEqualToString:@"iPhone5,3"]) return DeviceCategoryIPhone5c;
    if ([deviceString isEqualToString:@"iPhone5,4"]) return DeviceCategoryIPhone5c;
    if ([deviceString isEqualToString:@"iPhone6,1"]) return DeviceCategoryIPhone5s;
    if ([deviceString isEqualToString:@"iPhone6,2"]) return DeviceCategoryIPhone5s;
    if ([deviceString isEqualToString:@"iPhone7,1"]) return DeviceCategoryIPhone6Plus;
    if ([deviceString isEqualToString:@"iPhone7,2"]) return DeviceCategoryIPhone6;
    if ([deviceString isEqualToString:@"iPhone8,1"]) return DeviceCategoryIPhone6s;
    if ([deviceString isEqualToString:@"iPhone8,2"]) return DeviceCategoryIPhone6sPlus;
    if ([deviceString isEqualToString:@"iPhone8,4"]) return DeviceCategoryIPhoneSE;
    if ([deviceString isEqualToString:@"iPhone9,1"]) return DeviceCategoryIPhone7;
    if ([deviceString isEqualToString:@"iPhone9,2"]) return DeviceCategoryIPhone7Plus;
    
    if ([deviceString isEqualToString:@"iPad1,1"]) return DeviceCategoryIPad1G;
    if ([deviceString isEqualToString:@"iPad2,1"]) return DeviceCategoryIPad2;
    if ([deviceString isEqualToString:@"iPad2,2"]) return DeviceCategoryIPad2;
    if ([deviceString isEqualToString:@"iPad2,3"]) return DeviceCategoryIPad2;
    if ([deviceString isEqualToString:@"iPad2,4"]) return DeviceCategoryIPad2;
    if ([deviceString isEqualToString:@"iPad2,5"]) return DeviceCategoryIPadMini1G;
    if ([deviceString isEqualToString:@"iPad2,6"]) return DeviceCategoryIPadMini1G;
    if ([deviceString isEqualToString:@"iPad2,7"]) return DeviceCategoryIPadMini1G;
    if ([deviceString isEqualToString:@"iPad3,1"]) return DeviceCategoryIPad3;
    if ([deviceString isEqualToString:@"iPad3,2"]) return DeviceCategoryIPad3;
    if ([deviceString isEqualToString:@"iPad3,3"]) return DeviceCategoryIPad3;
    if ([deviceString isEqualToString:@"iPad3,4"]) return DeviceCategoryIPad4;
    if ([deviceString isEqualToString:@"iPad3,5"]) return DeviceCategoryIPad4;
    if ([deviceString isEqualToString:@"iPad3,6"]) return DeviceCategoryIPad4;
    if ([deviceString isEqualToString:@"iPad4,1"]) return DeviceCategoryIPadAir;
    if ([deviceString isEqualToString:@"iPad4,2"]) return DeviceCategoryIPadAir;
    if ([deviceString isEqualToString:@"iPad4,3"]) return DeviceCategoryIPadAir;
    if ([deviceString isEqualToString:@"iPad4,4"]) return DeviceCategoryIPadMini2G;
    if ([deviceString isEqualToString:@"iPad4,5"]) return DeviceCategoryIPadMini2G;
    if ([deviceString isEqualToString:@"iPad4,6"]) return DeviceCategoryIPadMini2G;
    
    if ([deviceString isEqualToString:@"i386"])    return DeviceCategoryIPhoneSimulator;
    if ([deviceString isEqualToString:@"x86_64"])  return DeviceCategoryIPhoneSimulator;
    
    
    return DeviceCategoryOther;
}

@end
