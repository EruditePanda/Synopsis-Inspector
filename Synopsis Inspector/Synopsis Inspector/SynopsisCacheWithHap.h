//
//	SynopsisCacheWithHap.h
//	Synopsis-Framework
//
//	Created by vade on 1/15/18.
//	Copyright © 2018 v002. All rights reserved.
//

//#import <Synopsis/SynopsisMetadataItem.h>
//#import <CoreMedia/CMTime.h>

#import <Synopsis/SynopsisCache.h>




//typedef void (^SynopsisCacheCompletionHandler)(id _Nullable cachedValue, NSError * _Nullable error);
//typedef void (^SynopsisCacheImageCompletionHandler)(CGImageRef _Nullable cachedValue, NSError * _Nullable error);




@interface SynopsisCacheWithHap : NSObject

+ (instancetype _Nonnull ) sharedCache;

// Useful for subclasses to know if / when they should run expesive operations to fetch uncached results.
@property (readonly, atomic, assign) BOOL acceptNewOperations;

- (void) returnOnlyCachedResults;
- (void) returnCachedAndUncachedResults;

- (void) cachedGlobalMetadataForItem:(SynopsisMetadataItem* _Nonnull)metadataItem completionHandler:(SynopsisCacheCompletionHandler _Nullable )handler;
- (void) cachedImageForItem:(SynopsisMetadataItem* _Nonnull)metadataItem atTime:(CMTime)time completionHandler:(SynopsisCacheImageCompletionHandler _Nullable )handler;

@end
