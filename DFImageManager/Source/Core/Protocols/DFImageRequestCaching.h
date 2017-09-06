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

typedef void (^DFImageRequestCachingCompletionHandler)(UIImage *__nullable image);


@protocol DFImageRequestCaching <NSObject>

- (NSOperation *)loadCachedImageWithRequest:(nonnull DFImageRequest *)request completion:(nullable DFImageRequestCachingCompletionHandler)completion;

- (void)saveCachedImage:(nonnull UIImage *)image withRequest:(nonnull DFImageRequest *)request;

@end
