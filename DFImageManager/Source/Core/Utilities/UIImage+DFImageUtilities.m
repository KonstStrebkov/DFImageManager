// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "UIImage+DFImageUtilities.h"

#if DF_IMAGE_MANAGER_GIF_AVAILABLE
#import "DFImageManagerKit+GIF.h"
#endif

#if DF_IMAGE_MANAGER_WEBP_AVAILABLE
#import "DFImageManagerKit+WebP.h"
#endif

@implementation UIImage (DFImageUtilities)

+ (nullable UIImage *)df_decodedImageWithData:(nonnull NSData *)data {
    if (!data.length) {
        return nil;
    }
#if DF_IMAGE_MANAGER_GIF_AVAILABLE
    if ([DFAnimatedImage isAnimatedGIFData:data]) {
        UIImage *image = [[DFAnimatedImage alloc] initWithAnimatedGIFData:data];
        if (image) {
            return image;
        }
    }
#endif
    
#if DF_IMAGE_MANAGER_WEBP_AVAILABLE
    UIImage *webpImage = [UIImage df_imageWithWebPData:data scale:[UIScreen mainScreen].scale];
    if (webpImage) {
        return webpImage;
    }
#endif
    return [[UIImage alloc] initWithData:data scale:[UIScreen mainScreen].scale];
}

+ (UIImage *)df_decompressedImage:(UIImage *)image {
    return [self df_decompressedImage:image scale:1.f];
}

+ (UIImage *)df_decompressedImage:(UIImage *)image targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode {
    CGSize bitmapSize = [image df_bitmapSize];
    CGFloat scaleWidth = targetSize.width / bitmapSize.width;
    CGFloat scaleHeight = targetSize.height / bitmapSize.height;
    CGFloat scale = contentMode == DFImageContentModeAspectFill ? MAX(scaleWidth, scaleHeight) : MIN(scaleWidth, scaleHeight);
    return [self df_decompressedImage:image scale:scale];
}

+ (UIImage *)df_decompressedImage:(UIImage *)image scale:(CGFloat)scale {
    if (!image) {
        return nil;
    }
    if (image.images) {
        return image;
    }
    CGImageRef imageRef = image.CGImage;
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
    if (scale < 1.f) {
        imageSize = CGSizeMake(imageSize.width * scale, imageSize.height * scale);
    }
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGContextRef contextRef = CGBitmapContextCreate(NULL, (size_t)imageSize.width, (size_t)imageSize.height, CGImageGetBitsPerComponent(imageRef), 0, colorSpaceRef, (kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast));
    if (colorSpaceRef) {
        CGColorSpaceRelease(colorSpaceRef);
    }
    if (!contextRef) {
        return image;
    }
    
    if (@available(iOS 10.0, *)) {
        if (scale < 1.f) {
            CGContextSetInterpolationQuality(contextRef, kCGInterpolationMedium);
        }
    }
    
    CGContextDrawImage(contextRef, (CGRect){CGPointZero, imageSize}, imageRef);
    CGImageRef decompressedImageRef = CGBitmapContextCreateImage(contextRef);
    CGContextRelease(contextRef);
    UIImage *decompressedImage = [UIImage imageWithCGImage:decompressedImageRef scale:image.scale orientation:image.imageOrientation];
    if (decompressedImageRef) {
        CGImageRelease(decompressedImageRef);
    }
    return decompressedImage;
}

+ (UIImage *)df_croppedImage:(UIImage *)image normalizedCropRect:(CGRect)inputCropRect {
    CGRect cropRect = inputCropRect;
    
    switch (image.imageOrientation) {
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            // do nothing
            break;
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            cropRect.origin.y = inputCropRect.origin.x;
            cropRect.origin.x = 1.f - inputCropRect.origin.y - inputCropRect.size.height;
            cropRect.size.width = inputCropRect.size.height;
            cropRect.size.height = inputCropRect.size.width;
            break;
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            cropRect.origin.x = 1.f - inputCropRect.origin.x - inputCropRect.size.width;
            cropRect.origin.y = 1.f - inputCropRect.origin.y - inputCropRect.size.height;
            break;
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            cropRect.origin.x = inputCropRect.origin.y;
            cropRect.origin.y = 1.f - inputCropRect.origin.x - inputCropRect.size.width;
            cropRect.size.width = inputCropRect.size.height;
            cropRect.size.height = inputCropRect.size.width;
            break;
        default:
            break;
    }
    
    CGSize imagePixelSize = CGSizeMake(CGImageGetWidth(image.CGImage), CGImageGetHeight(image.CGImage));
    CGRect imageCropRect = CGRectMake((CGFloat)floor(cropRect.origin.x * imagePixelSize.width),
                                      (CGFloat)floor(cropRect.origin.y * imagePixelSize.height),
                                      (CGFloat)floor(cropRect.size.width * imagePixelSize.width),
                                      (CGFloat)floor(cropRect.size.height * imagePixelSize.height));
    
    CGImageRef croppedImageRef = CGImageCreateWithImageInRect(image.CGImage, imageCropRect);
    UIImage *croppedImage = [UIImage imageWithCGImage:croppedImageRef scale:image.scale orientation:image.imageOrientation];
    CGImageRelease(croppedImageRef);
    return croppedImage;
}

+ (UIImage *)df_imageWithImage:(UIImage *)image cornerRadius:(CGFloat)cornerRadius {
    UIGraphicsBeginImageContextWithOptions(image.size, NO, 0);
    [[UIBezierPath bezierPathWithRoundedRect:(CGRect){CGPointZero, image.size} cornerRadius:cornerRadius] addClip];
    [image drawInRect:(CGRect){CGPointZero, image.size}];
    UIImage *processedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return processedImage;
}

- (CGSize)df_bitmapSize {
    CGImageRef imgRef = self.CGImage;
    CGSize srcSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
    
    UIImageOrientation orient = self.imageOrientation;
    switch (orient) {
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            srcSize = CGSizeMake(srcSize.height, srcSize.width);
            break;
        default:
            // NOP
            break;
    }
    
    return srcSize;
}

@end
