

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CYCommon : NSObject

+ (UIImage*)createImageWithColor:(UIColor*)color size:(CGSize)imageSize;

+ (void)drawALineWithFrame:(CGRect)frame andColor:(UIColor*)color inLayer:(CALayer*)parentLayer;

+ (void)saveImageToPhotoAlbum:(UIImage*)image;

@end
