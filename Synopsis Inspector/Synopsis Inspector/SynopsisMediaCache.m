//
//  SynopsisInspectorMediaCache.m
//  Synopsis Inspector
//
//  Created by vade on 7/23/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import "SynopsisMediaCache.h"
#import "HapInAVFoundation.h"

#define SynopsisInspectorMediaCacheImageCost 1
#define SynopsisInspectorMediaCachePlayerCost 10

@interface SynopsisMediaCache ()

@property (readwrite, strong) NSOperationQueue* videoQueue;
@property (readwrite, strong) NSOperationQueue* imageQueue;
@property (readwrite, strong) NSCache* mediaCache;
@property (readwrite, strong) dispatch_queue_t metadataQueue;

@property (readwrite, strong) NSOpenGLContext* glContext;

@end

@implementation SynopsisMediaCache

+ (instancetype) sharedMediaCache
{
    static SynopsisMediaCache* sharedMediaCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMediaCache = [[SynopsisMediaCache alloc] init];
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

        self.metadataQueue = dispatch_queue_create("video.synopsis.inspector.mediacache.metadataqueue", DISPATCH_QUEUE_SERIAL);
        
        self.mediaCache = [[NSCache alloc] init];
        
        const NSOpenGLPixelFormatAttribute attributes[] = {
            NSOpenGLPFAOpenGLProfile,  NSOpenGLProfileVersionLegacy,
            NSOpenGLPFAAccelerated,
            NSOpenGLPFAColorSize, 32,
            NSOpenGLPFADepthSize, 24,
            NSOpenGLPFAAccelerated,
            NSOpenGLPFAAcceleratedCompute,
            NSOpenGLPFANoRecovery,
            (NSOpenGLPixelFormatAttribute)0,
        };
        
        NSOpenGLPixelFormat* pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];
        
        self.glContext = [[NSOpenGLContext alloc] initWithFormat:pixelFormat shareContext:nil];
    }
    
    return self;
}

#pragma mark - Image Caching

- (NSString*) imageKeyForMetadataItem:(SynopsisMetadataItem* _Nonnull)metadataItem
{
    return [@"IMAGE-" stringByAppendingString:metadataItem.url.absoluteString];
}

- (void) writeImageToCache:(_Nullable CGImageRef)image forKey:(nonnull id)key
{
    [self.mediaCache setObject:(__bridge id _Nullable)(image) forKey:key];
}

- (nullable CGImageRef) cachedImageForMetadataItem:(SynopsisMetadataItem* _Nonnull)metadataItem
{
    CGImageRef image = (CGImageRef)CFBridgingRetain([self.mediaCache objectForKey:[self imageKeyForMetadataItem:metadataItem]]);
    
    return image;
}

- (void) generateAndCacheStillImageAsynchronouslyForAsset:(SynopsisMetadataItem* _Nonnull)metadataItem completionHandler:(SynopsisInspectorMediaCacheImageCompletionHandler _Nullable )completionHandler
{
    
    BOOL containsHap = [metadataItem.urlAsset containsHapVideoTrack];

    NSBlockOperation* blockOperation = nil;
    
    if(containsHap)
    {
        blockOperation = [NSBlockOperation blockOperationWithBlock:^{
            
            // This seems really stupid
            AVPlayerItem* item = [AVPlayerItem playerItemWithAsset:metadataItem.urlAsset];
            AVAssetTrack* hapAssetTrack = [[metadataItem.urlAsset hapVideoTracks] firstObject];

            AVPlayerItemHapDXTOutput* hapOutput = [[AVPlayerItemHapDXTOutput alloc] initWithHapAssetTrack:hapAssetTrack];
            hapOutput.suppressesPlayerRendering = YES;
            hapOutput.outputAsRGB =YES;

            [item addOutput:hapOutput];

            HapDecoderFrame* rgbFrame = [hapOutput allocFrameForTime:kCMTimeZero];
            
            if(rgbFrame)
            {
                NSData* rgbData = [NSData dataWithBytes:rgbFrame.rgbData length:rgbFrame.rgbDataSize];
                
                CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)rgbData);
//                CGColorSpaceRef cs = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGBLinear);
                CGColorSpaceRef cs =  CGColorSpaceCreateDeviceRGB();
                CGBitmapInfo info =  kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
                
                CGImageRef unscaledImage = CGImageCreate(rgbFrame.rgbImgSize.width,
                                                         rgbFrame.rgbImgSize.height,
                                                         8,
                                                         32,
                                                         rgbFrame.rgbImgSize.width * 4,
                                                         cs,
                                                         info,
                                                         provider,
                                                         NULL,
                                                         NO,
                                                         kCGRenderingIntentDefault);
                
                
                // resize CGImage
                size_t bitsPerComponent = CGImageGetBitsPerComponent(unscaledImage);
                size_t bytesPerRow = CGImageGetBytesPerRow(unscaledImage);
                
                CGContextRef context = CGBitmapContextCreate(NULL,
                                                             300,
                                                             300,
                                                             bitsPerComponent,
                                                             bytesPerRow,
                                                             cs,
                                                             info);
                
                CGRect rect = AVMakeRectWithAspectRatioInsideRect(rgbFrame.rgbImgSize, CGRectMake(0, 0, 300, 300));
                
                
                CGContextSetInterpolationQuality(context, kCGInterpolationLow);
                
                CGContextDrawImage(context, rect, unscaledImage);
                
                CGImageRef image = CGBitmapContextCreateImage(context);
                
                CGColorSpaceRelease(cs);
                CGImageRelease(unscaledImage);
                CGContextRelease(context);
                CGDataProviderRelease(provider);

                if(image)
                {
                    [self writeImageToCache: CFBridgingRetain((__bridge id _Nullable)(image)) forKey:[self imageKeyForMetadataItem:metadataItem] ];
                    
                    if(completionHandler)
                        completionHandler(image, nil);
                    
                    CGImageRelease(image);
                }
                
                else
                {
                    // TODO: ERRORS - No CGIMage created
                    NSError* error = [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:nil];
                    
                    if(completionHandler)
                        completionHandler(NULL, error);
                    
                }
            }
            else
            {
                // TODO: ERRORS - No HAP Frame
                NSError* error = [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:nil];
                
                if(completionHandler)
                    completionHandler(NULL, error);
                
            }
        }];
    }
    else
    {
        blockOperation = [NSBlockOperation blockOperationWithBlock:^{
            AVAssetImageGenerator* imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:metadataItem.urlAsset];
            
            imageGenerator.apertureMode = AVAssetImageGeneratorApertureModeCleanAperture;
            imageGenerator.maximumSize = CGSizeMake(300, 300);
            imageGenerator.appliesPreferredTrackTransform = YES;
            
            [imageGenerator generateCGImagesAsynchronouslyForTimes:@[ [NSValue valueWithCMTime:kCMTimeZero]] completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error){
                
                if(error == nil && image != NULL)
                {
                    [self writeImageToCache: CFBridgingRetain((__bridge id _Nullable)(image)) forKey:[self imageKeyForMetadataItem:metadataItem]];
                    
                    if(completionHandler)
                        completionHandler(image, nil);
                }
                else
                {
                    NSError* error = [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:nil];

                    if(completionHandler)
                        completionHandler(image, error);
                }
            }];
        }];
    }
    
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
       
        BOOL containsHap = [metadataItem.urlAsset containsHapVideoTrack];
        
        AVPlayerItem* item = [AVPlayerItem playerItemWithAsset:metadataItem.urlAsset];
        
        AVPlayerItemMetadataOutput* metadataOut = [[AVPlayerItemMetadataOutput alloc] initWithIdentifiers:nil];
        metadataOut.suppressesPlayerRendering = YES;
        [item addOutput:metadataOut];

        if(!containsHap)
        {
            NSDictionary* videoOutputSettings = @{(NSString*)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA),
                                                  (NSString*)kCVPixelBufferIOSurfacePropertiesKey : @{},
                                                  //                                              (NSString*)kCVPixelBufferIOSurfaceOpenGLFBOCompatibilityKey :@(YES),
                                                  //                                              (NSString*)kCVPixelBufferIOSurfaceOpenGLTextureCompatibilityKey :@(YES),
                                                  };
            
            AVPlayerItemVideoOutput* videoOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:videoOutputSettings];
            videoOutput.suppressesPlayerRendering = YES;
            [item addOutput:videoOutput];
        }
        else
        {
            AVAssetTrack* hapAssetTrack = [[metadataItem.urlAsset hapVideoTracks] firstObject];
            AVPlayerItemHapDXTOutput* hapOutput = [[AVPlayerItemHapDXTOutput alloc] initWithHapAssetTrack:hapAssetTrack];
            hapOutput.suppressesPlayerRendering = YES;
            hapOutput.outputAsRGB = NO;
            
            [item addOutput:hapOutput];
        }
        
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
