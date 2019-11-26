//
//	SynopsisCacheWithHap.m
//	Synopsis-Framework
//
//	Created by vade on 1/15/18.
//	Copyright © 2018 v002. All rights reserved.
//
#import "SynopsisCacheWithHap.h"
#import <Synopsis/Synopsis.h>
#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#import <HapInAVFoundation/HapInAVFoundation.h>




@interface SynopsisCacheWithHap ()
@property (readwrite, strong) NSCache* cache;
@property (readwrite, strong) SynopsisMetadataDecoder* metadataDecoder;
@property (readwrite, strong) NSOperationQueue* cacheMetadataOperationQueue;
@property (readwrite, strong) NSOperationQueue* cacheMediaOperationQueue;
@property (readwrite, atomic, assign) BOOL acceptNewOperations;
@end




@implementation SynopsisCacheWithHap


+ (instancetype) sharedCache	{
	static SynopsisCacheWithHap* sharedCache = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedCache = [[SynopsisCacheWithHap alloc] init];
	});
	
	return sharedCache;
}

- (instancetype) init	{
	self = [super init];
	if (self)	{
		self.cache = [[NSCache alloc] init];
		self.acceptNewOperations = YES;
		// Metadata decoder isnt strictly thread safe
		// Use a serial queue
		self.metadataDecoder = [[SynopsisMetadataDecoder alloc] initWithVersion:kSynopsisMetadataVersionValue];
		self.cacheMetadataOperationQueue = [[NSOperationQueue alloc] init];
		self.cacheMetadataOperationQueue.maxConcurrentOperationCount = 1;
		self.cacheMetadataOperationQueue.qualityOfService = NSQualityOfServiceBackground;

		self.cacheMediaOperationQueue = [[NSOperationQueue alloc] init];
		self.cacheMediaOperationQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
		self.cacheMediaOperationQueue.qualityOfService = NSQualityOfServiceUserInitiated;
	}
	
	return self;
}

- (void) returnOnlyCachedResults	{
	NSLog(@"%s",__func__);
	self.acceptNewOperations = NO;
}

- (void) returnCachedAndUncachedResults	{
	NSLog(@"%s",__func__);
	self.acceptNewOperations = YES;
}

#pragma mark - Global Metadata

- (NSString*) globalMetadataKeyForItem:(SynopsisMetadataItem* _Nonnull)metadataItem	{
	return [@"GLOBAL-METADATA-" stringByAppendingString:metadataItem.url.absoluteString];
}

- (void) cachedGlobalMetadataForItem:(SynopsisMetadataItem* _Nonnull)metadataItem completionHandler:(SynopsisCacheCompletionHandler)handler	{
	NSBlockOperation* operation = [NSBlockOperation blockOperationWithBlock:^{

		NSDictionary* globalMetadata = nil;
		
		globalMetadata = [self.cache objectForKey:[self globalMetadataKeyForItem:metadataItem]];
		
		//	Generate metadata if we dont have it in the cache
		if(!globalMetadata && self.acceptNewOperations)	{
			NSArray* metadataItems = metadataItem.asset.metadata;
			for(AVMetadataItem* metadataItem in metadataItems)	{
				globalMetadata = [self.metadataDecoder decodeSynopsisMetadata:metadataItem];
				if(globalMetadata)
					break;
			}
			
			// Cache our result for next time
			if(globalMetadata)
				[self.cache setObject:globalMetadata forKey:[self globalMetadataKeyForItem:metadataItem]];
		}
		
		if(handler)	{
			handler(globalMetadata, nil);
		}
		
	}];
	
	[self.cacheMetadataOperationQueue addOperation:operation];
}

#pragma mark - Image

- (NSString*) imageKeyForItem:(SynopsisMetadataItem* _Nonnull)metadataItem atTime:(CMTime)time	{
	NSString* timeString = (NSString*)CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, time));
	return [NSString stringWithFormat:@"Image-%@-%@", timeString, metadataItem.url.absoluteString, nil];
}

- (void) cachedImageForItem:(SynopsisMetadataItem* _Nonnull)metadataItem atTime:(CMTime)time completionHandler:(SynopsisCacheImageCompletionHandler _Nullable )handler;	{
	NSLog(@"%s",__func__);
	NSBlockOperation* operation = [NSBlockOperation blockOperationWithBlock:^{

		NSString* key = [self imageKeyForItem:metadataItem atTime:time];

		CGImageRef cachedImage = NULL;
		cachedImage = (CGImageRef) CFBridgingRetain( [self.cache objectForKey:key] );

		if (cachedImage)	{
			if(handler)	{
				handler(cachedImage, nil);
			}
		}
		// Generate and cache if nil
		else if(!cachedImage && self.acceptNewOperations)	{
			NSLog(@"\tshould be generating image...");
			if ([metadataItem.asset containsHapVideoTrack]) {
				AVAssetHapImageGenerator	*imageGenerator = [AVAssetHapImageGenerator assetHapImageGeneratorWithAsset:metadataItem.asset];
				
				imageGenerator.maximumSize = CGSizeMake(300,300);
				
				[imageGenerator generateCGImagesAsynchronouslyForTimes:@[ [NSValue valueWithCMTime:kCMTimeZero]] completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error){

					if(error == nil && image != NULL)	{
						[self.cache setObject:(CGImageRetain(image)) forKey:key];

						if(handler)
							handler(image, nil);
					}
					else	{
						NSError* error = [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:nil];

						if(handler)
							handler(nil, error);
					}
				}];
			}
			else	{
				AVAssetImageGenerator* imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:metadataItem.asset];

				imageGenerator.apertureMode = AVAssetImageGeneratorApertureModeCleanAperture;
				imageGenerator.maximumSize = CGSizeMake(300, 300);
				imageGenerator.appliesPreferredTrackTransform = YES;

				[imageGenerator generateCGImagesAsynchronouslyForTimes:@[ [NSValue valueWithCMTime:kCMTimeZero]] completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error){

					if(error == nil && image != NULL)	{
						[self.cache setObject:(CGImageRetain(image)) forKey:key];

						if(handler)
							handler(image, nil);
					}
					else	{
						NSError* error = [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:nil];

						if(handler)
							handler(nil, error);
					}
				}];
			}
		}
	}];

	[self.cacheMediaOperationQueue addOperation:operation];
}


@end
