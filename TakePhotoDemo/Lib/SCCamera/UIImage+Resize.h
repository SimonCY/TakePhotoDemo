//
//  UIImage+Resize.h
//  SCCaptureCameraDemo
//
//  Created by Aevitx on 14-1-17.
//  Copyright (c) 2014年 Aevitx. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Resize)

- (UIImage *)croppedImage:(CGRect)bounds;


- (UIImage *)resizedImage:(CGSize)newSize
     interpolationQuality:(CGInterpolationQuality)quality;

- (UIImage *)resizedImageWithContentMode:(UIViewContentMode)contentMode
                                  bounds:(CGSize)bounds
                    interpolationQuality:(CGInterpolationQuality)quality;

- (UIImage *)resizedImage:(CGSize)newSize
                transform:(CGAffineTransform)transform
           drawTransposed:(BOOL)transpose
     interpolationQuality:(CGInterpolationQuality)quality;

- (CGAffineTransform)transformForOrientation:(CGSize)newSize;

- (UIImage *)fixOrientation;

- (UIImage *)rotatedByDegrees:(CGFloat)degrees;

/**
 *  按比例 缩放到指定的宽 或 指定的高。  isScaleHeight:是否缩放到指定的高。 yes，是。NO，否。
 *
 *  @param img           要缩放的图片
 *  @param h             缩放到指定的高的值
 *  @param w             缩放到指定的宽的值
 *  @param isScaleHeight 是否缩放到指定的高
 *
 *  @return 缩放后的尺寸
 */
-(CGSize)scaleImg:(UIImage*)img scaleToHeight:(CGFloat)h scaleToWidth:(CGFloat)w isScaleHeight:(BOOL)isScaleHeight;

@end
