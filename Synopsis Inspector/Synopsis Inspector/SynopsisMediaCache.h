//
//  SynopsisInspectorMediaCache.h
//  Synopsis Inspector
//
//  Created by vade on 7/23/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import <Synopsis/Synopsis.h>
#import <AppKit/AppKit.h>

typedef void (^SynopsisInspectorMediaCacheImageCompletionHandler)(CGImageRef _Nullable image, NSError * _Nullable error);

typedef void (^SynopsisInspectorMediaCachePlayerItemCompletionHandler)(AVPlayerItem* _Nullable item, NSError * _Nullable error);


@interface SynopsisMediaCache : NSObject

+ (instancetype _Nonnull ) sharedMediaCache;

@property (readonly, strong) dispatch_queue_t _Nonnull metadataQueue;

// Image Caching
- (void) generateAndCacheStillImageAsynchronouslyForAsset:(SynopsisMetadataItem* _Nonnull)metadataItem completionHandler:(SynopsisInspectorMediaCacheImageCompletionHandler _Nullable )completionHandler;

- (nullable CGImageRef) cachedImageForMetadataItem:(SynopsisMetadataItem* _Nonnull)metadataItem;

// Player Item Caching
- (void) generatePlayerItemAsynchronouslyForAsset:(SynopsisMetadataItem* _Nonnull)metadataItem completionHandler:(SynopsisInspectorMediaCachePlayerItemCompletionHandler _Nullable )completionHandler;

- (void) beginOptimize;
- (void) endOptimize;
//- (void) cancelAllPendingMediaOperations;

@end
