//
//  DFImageRequestCaching.h
//  DFImageManager
//
//  Created by Алексей Ячменев on 04.09.15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@class DFImageRequest;

NS_ASSUME_NONNULL_BEGIN

typedef void (^DFImageRequestCachingCompletionHandler)(UIImage *__nullable image);


@protocol DFImageRequestCaching <NSObject>

- (nullable NSOperation *)loadCachedImageWithRequest:(DFImageRequest *)request completion:(nullable DFImageRequestCachingCompletionHandler)completion;

- (void)saveCachedImage:(UIImage *)image withRequest:(DFImageRequest *)request;

@end

NS_ASSUME_NONNULL_END
