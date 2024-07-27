#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore2.h>
#import <QuartzCore/CAAnimation.h>
#import <IOSurface/IOSurface.h>
#import <UIKit/UIGraphics.h>
#import <Foundation/Foundation.h>

#import "UIImage+StackBlur.h"
#import "UIImage+Resize.h"
#import <QuartzCore/QuartzCore.h>

@interface UIImage (LiveBlur)
+(UIImage*)liveBlurForScreenWithQuality:(float)quality interpolation:(int)iQuality blurRadius:(float)radius;

@end