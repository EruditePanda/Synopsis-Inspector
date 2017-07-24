//
//  SynopsisInspectorMediaCache.m
//  Synopsis Inspector
//
//  Created by vade on 7/23/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import "SynopsisInspectorMediaCache.h"

#define SynopsisInspectorMediaCacheImageCost 1
#define SynopsisInspectorMediaCachePlayerCost 10

@interface SynopsisInspectorMediaCache ()

@property (readwrite, strong) NSOperationQueue* videoQueue;
@property (readwrite, strong) NSOperationQueue* imageQueue;
@property (readwrite, strong) NSCache* mediaCache;

@end

@implementation SynopsisInspectorMediaCache

+ (instancetype) sharedMediaCache
{
    static SynopsisInspectorMediaCache* sharedMediaCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMediaCache = [[SynopsisInspectorMediaCache alloc] init];
    });
    
    return sharedMediaCache;
}

- (instancetype) init
{
    self = [super init];
    if(self)
    {
        self.imageQueue = [[NSOperationQueue alloc] init];
        self.imageQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
        self.imageQueue.qualityOfService = NSQualityOfServiceBackground;
        
        self.videoQueue = [[NSOperationQueue alloc] init];
        self.videoQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
        self.videoQueue.qualityOfService = NSQualityOfServiceBackground;

        self.mediaCache = [[NSCache alloc] init];
    }
    
    return self;
}

#pragma mark - Image Caching

- (NSString*) imageKeyForMetadataItem:(SynopsisMetadataItem* _Nonnull)metadataItem
{
    return [@"IMAGE-" stringByAppendingString:metadataItem.url.absoluteString];
}

- (void) writeImageToCache:(_Nullable CGImageRef)image forKey:(nonnull id)key cost:(NSUInteger)cost
{
    [self.mediaCache setObject:(__bridge id _Nullable)(image) forKey:key cost:cost];
}

- (nullable CGImageRef) cachedImageForMetadataItem:(SynopsisMetadataItem* _Nonnull)metadataItem
{
    CGImageRef image = (CGImageRef)CFBridgingRetain([self.mediaCache objectForKey:[self imageKeyForMetadataItem:metadataItem]]);
    
    return image;
}

- (void) generateAndCacheStillImageAsynchronouslyForAsset:(SynopsisMetadataItem* _Nonnull)metadataItem completionHandler:(SynopsisInspectorMediaCacheImageCompletionHandler _Nullable )completionHandler
{    
    NSBlockOperation* blockOperation = [NSBlockOperation blockOperationWithBlock:^{
        AVAssetImageGenerator* imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:metadataItem.urlAsset];
        
        imageGenerator.apertureMode = AVAssetImageGeneratorApertureModeCleanAperture;
        imageGenerator.maximumSize = CGSizeMake(300, 300);
        imageGenerator.appliesPreferredTrackTransform = YES;
        
        [imageGenerator generateCGImagesAsynchronouslyForTimes:@[ [NSValue valueWithCMTime:kCMTimeZero]] completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error){
            
            if(error == nil && image != NULL)
            {
                [self writeImageToCache: CFBridgingRetain((__bridge id _Nullable)(image)) forKey:[self imageKeyForMetadataItem:metadataItem] cost:SynopsisInspectorMediaCacheImageCost];
                
                if(completionHandler)
                    completionHandler(image, nil);
            }
            else
            {
                if(completionHandler)
                    completionHandler(image, nil);
            }
        }];
    }];
    
    [self.imageQueue addOperation:blockOperation];
    
}

#pragma mark - Player Item Caching

- (NSString*) playerItemKeyForMetadataItem:(SynopsisMetadataItem* _Nonnull)metadataItem
{
    return [@"PLAYERITEM-" stringByAppendingString:metadataItem.url.absoluteString];
}

- (void) writePlayerItemToCache:(AVPlayerItem*)playerItem forKey:(nonnull id)key cost:(NSUInteger)cost
{
    [self.mediaCache setObject:playerItem forKey:key cost:cost];
}

- (AVPlayerItem*) cachedPlayerItemForMetadataItem:(SynopsisMetadataItem* _Nonnull)metadataItem
{
    AVPlayerItem* item = (AVPlayerItem*)[self.mediaCache objectForKey:[self playerItemKeyForMetadataItem:metadataItem]];
    
    if(item)
        NSLog(@"PlayerItem Cache Hit");
    else
        NSLog(@"PlayerItem Cache Miss");
    
    return item;
}

- (void) generatePlayerItemAsynchronouslyForAsset:(SynopsisMetadataItem* _Nonnull)metadataItem completionHandler:(SynopsisInspectorMediaCachePlayerItemCompletionHandler _Nullable )completionHandler
{
    NSBlockOperation* blockOperation = [NSBlockOperation blockOperationWithBlock:^{
       
        AVPlayerItem* item = [AVPlayerItem playerItemWithAsset:metadataItem.urlAsset];
        AVPlayerItemMetadataOutput* metdataOut = [[AVPlayerItemMetadataOutput alloc] initWithIdentifiers:nil];
        [item addOutput:metdataOut];
        
        if(item)
        {
            // WE NEED TO SOLVE THE ISSUE OF PLAYER ITEMS BEING VENDED TO THE DIFFERENT PLAYERS IF WERE GOING TO CACHE THEM
//            [self writePlayerItemToCache:item forKey:[self playerItemKeyForMetadataItem:metadataItem] cost:SynopsisInspectorMediaCachePlayerCost];

            if(completionHandler)
            {
                completionHandler(item, nil);
            }
        }
        else
        {
            if(completionHandler)
            {
                NSError* error = [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:nil];
                
                completionHandler(item, error);
            }
        }
        
    }];
    
    [self.videoQueue addOperation:blockOperation];
}

#pragma mark -

- (void) beginOptimize
{
    [self.videoQueue cancelAllOperations];
    [self.videoQueue setSuspended:YES];
}

- (void) endOptimize
{
    [self.videoQueue setSuspended:NO];
}



@end
