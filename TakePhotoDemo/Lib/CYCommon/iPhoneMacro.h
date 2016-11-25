
//
//  Created by chenyna on 14-1-25.
//  Copyright (c) 2014年 chenyan. All rights reserved.
//

#ifndef iPhoneMacro_h
#define iPhoneMacro_h

#ifdef __OBJC__



// Debug Log
#ifdef DEBUG
#define CYLog(...) NSLog(__VA_ARGS__)
#else
#define CYLog(...)
#endif


// 函数输出
#define LogFunc_CY CYLog(@"%s", __func__)


//weakself
#define WEAKSELF_CY __weak __typeof(&*self)weakSelf = self;

//color
#define RGBAColor_CY(r, g, b, a) [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:a]
#define RGBColor_CY(r, g, b)  RGBAColor_CY(r, g, b, 1)
// 随机色
#define RandomColor_CY CYRGBColor(arc4random_uniform(256), arc4random_uniform(256), arc4random_uniform(256))

//frame and size
#define SCREEN_BOUNDS_CY    [[UIScreen mainScreen] bounds]
#define DCREEN_SIZE_CY      [[UIScreen mainScreen] bounds].size
#define SCREEN_WIDTH_CY [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT_CY [UIScreen mainScreen].bounds.size.height

// 写入文件到桌面
#define WriteToFile_CY(data, name) [data writeToFile:[NSString stringWithFormat:@"/Users/chenyan/Desktop/%@.plist", name] atomically:YES]

#endif
#endif
