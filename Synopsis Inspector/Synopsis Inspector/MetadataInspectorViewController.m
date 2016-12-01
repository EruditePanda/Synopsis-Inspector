//
//  MetadataInspectorViewController.m
//  Synopsis Inspector
//
//  Created by vade on 8/22/16.
//  Copyright © 2016 v002. All rights reserved.
//
#import <Synopsis/Constants.h>
#import "MetadataInspectorViewController.h"
#import "MetadataDominantColorsView.h"
#import "MetadataHistogramView.h"
#import "MetadataMotionView.h"

@interface MetadataInspectorViewController ()

@property (weak) IBOutlet NSTextField* globalDescriptors;
@property (weak) IBOutlet NSTextField* globalHash;
@property (weak) IBOutlet MetadataDominantColorsView* globalDominantColorView;
@property (weak) IBOutlet MetadataHistogramView* globalHistogramView;


@property (weak) IBOutlet MetadataDominantColorsView* dominantColorView;
@property (weak) IBOutlet MetadataHistogramView* histogramView;
@property (weak) IBOutlet MetadataMotionView* motionView;

@end

@implementation MetadataInspectorViewController

@synthesize frameMetadata;
@synthesize globalMetadata;

- (NSDictionary*) frameMetadata
{
    return frameMetadata;
}

- (void) setFrameMetadata:(NSDictionary *)dictionary
{
    frameMetadata = dictionary;
    
    NSDictionary* synopsisData = [frameMetadata valueForKey:kSynopsislMetadataIdentifier];
    NSDictionary* standard = [synopsisData valueForKey:kSynopsisStandardMetadataDictKey];
    NSArray* domColors = [standard valueForKey:kSynopsisStandardMetadataDominantColorValuesDictKey];

    NSArray* histogram = [standard valueForKey:kSynopsisStandardMetadataHistogramDictKey];

    self.dominantColorView.dominantColorsArray = domColors;
    self.histogramView.histogramArray = histogram;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.dominantColorView updateLayer];
        [self.histogramView updateLayer];
    });
}

- (NSDictionary*) globalMetadata
{
    return globalMetadata;
}

- (void) setGlobalMetadata:(NSDictionary *)dictionary
{
    globalMetadata = dictionary;
    
//    NSDictionary* synopsisData = [globalMetadata valueForKey:@"mdta/info.synopsis.metadata"];
    NSDictionary* standard = [globalMetadata valueForKey:kSynopsisStandardMetadataDictKey];
    NSArray* domColors = [standard valueForKey:kSynopsisStandardMetadataDominantColorValuesDictKey];
    NSArray* descriptions = [standard valueForKey:kSynopsisStandardMetadataDescriptionDictKey];
    NSString* hash = [standard valueForKey:kSynopsisStandardMetadataPerceptualHashDictKey];
    
    NSArray* histogram = [standard valueForKey:kSynopsisStandardMetadataHistogramDictKey];
    
    NSMutableString* description = [NSMutableString new];
    
    for(NSString* desc in descriptions)
    {
        [description appendString:[desc stringByAppendingString:@", "]];
    }
    
    self.globalDominantColorView.dominantColorsArray = domColors;
    self.globalHistogramView.histogramArray = histogram;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if(hash)
            self.globalHash.stringValue = hash;
        
        if(description)
            self.globalDescriptors.stringValue = description;
        
        [self.globalDominantColorView updateLayer];
        [self.globalHistogramView updateLayer];
    });
}




@end
