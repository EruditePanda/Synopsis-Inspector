//
//  SynopsisMetadataItem.m
//  Synopslight
//
//  Created by vade on 7/28/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import "SynopsisMetadataItem.h"
#import "GZIP.h"

NSString* const kSynopsisPerceptualHashKey = @"info_v002_synopsis_perceptual_hash";
NSString* const kSynopsisDominantColorValuesKey = @"info_v002_synopsis_dominant_colors";
NSString* const kSynopsisHistogramKey = @"info_v002_synopsis_histogram";

@interface SynopsisMetadataItem ()
{
    CGLayerRef cachedLayerRef;
}
@property (readwrite, strong) AVURLAsset* urlAsset;
@property (readwrite, strong) NSDictionary* globalSynopsisMetadata;
@end

@implementation SynopsisMetadataItem

- (instancetype) initWithURL:(NSURL *)url
{
    self = [super initWithURL:url];
    if(self)
    {
        cachedLayerRef = NULL;
        self.urlAsset = [AVURLAsset URLAssetWithURL:url options:nil];

        NSArray* metadataItems = [self.urlAsset metadata];
        
        AVMetadataItem* synopsisMetadataItem = nil;
        
        for(AVMetadataItem* metadataItem in metadataItems)
        {
            if([metadataItem.identifier isEqualToString:@"mdta/info.v002.synopsis.metadata"])
            {
                synopsisMetadataItem = metadataItem;
                break;
            }
        }
        
        if(synopsisMetadataItem)
        {
            NSData* compressedDataDictionary = (NSData*)synopsisMetadataItem.value;
            
            if(compressedDataDictionary.length)
            {
                NSData* unzippedData = [compressedDataDictionary gunzippedData];
                
                if(unzippedData.length)
                {
                    self.globalSynopsisMetadata = [NSJSONSerialization JSONObjectWithData:unzippedData options:0 error:nil];
                }
            }
        }
    }
    
    
    
    return self;
}

- (void) setCachedLayerRef:(CGLayerRef)layerRef
{
    if(cachedLayerRef)
    {
        CGLayerRelease(cachedLayerRef);
        cachedLayerRef = NULL;
    }
    
    cachedLayerRef = CGLayerRetain(layerRef);
}

- (CGLayerRef) cachedLayerRef
{
    return cachedLayerRef;
}


- (id) valueForKey:(NSString *)key
{
    NSDictionary* standardDictionary = [self.globalSynopsisMetadata objectForKey:@"info.v002.Synopsis.OpenCVAnalyzer"];
    
    if([key isEqualToString:kSynopsisPerceptualHashKey])
    {
        return [standardDictionary objectForKey:@"Hash"];
    }

    if([key isEqualToString:kSynopsisDominantColorValuesKey])
    {
        return [standardDictionary objectForKey:@"DominantColors"];
    }

    if([key isEqualToString:kSynopsisHistogramKey])
    {
        return [standardDictionary objectForKey:@"Histogram"];
    }

    return [super valueForKey:key];
}

@end
