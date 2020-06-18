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

#import "UIImage+DFImageManagerWebP.h"

#if __has_include(<libwebp/webp/decode.h>)
    #import <libwebp/webp/decode.h>
#else
    @import libwebp;
#endif

@implementation UIImage (DFImageManagerWebP)

static void FreeImageData(void *info, const void *data, size_t size) {
    free((void *)data);
}

+ (UIImage *)df_imageWithWebPData:(NSData *)data scale:(CGFloat)scale {
    WebPDecoderConfig config;
    if (!WebPInitDecoderConfig(&config)) {
        return nil;
    }
    if (WebPGetFeatures(data.bytes, data.length, &config.input) != VP8_STATUS_OK) {
        return nil;
    }
    config.output.colorspace = config.input.has_alpha ? MODE_rgbA : MODE_RGB;
    config.options.use_threads = 1;
    if (WebPDecode(data.bytes, data.length, &config) != VP8_STATUS_OK) {
        return nil;
    }
    
    size_t width = (size_t)config.input.width;
    size_t height = (size_t)config.input.height;
    if (config.options.use_scaling) {
        width = (size_t)config.options.scaled_width;
        height = (size_t)config.options.scaled_height;
    }
    
    CGDataProviderRef provider =
    CGDataProviderCreateWithData(NULL, config.output.u.RGBA.rgba, config.output.u.RGBA.size, FreeImageData);
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = config.input.has_alpha ? kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast : 0;
    size_t components = config.input.has_alpha ? 4 : 3;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    CGImageRef imageRef = CGImageCreate(width, height, 8, components * 8, components * width, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
    
    CGColorSpaceRelease(colorSpaceRef);
    CGDataProviderRelease(provider);
    
    UIImage *image = [[UIImage alloc] initWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp];
    CGImageRelease(imageRef);
    
    return image;
}

+ (UIImage *)df_imageWithWebPData:(NSData *)data {
    return [self df_imageWithWebPData:data scale:1];
}

@end
