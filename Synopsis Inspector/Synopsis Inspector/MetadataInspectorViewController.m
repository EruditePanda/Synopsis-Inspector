//
//  MetadataInspectorViewController.m
//  Synopsis Inspector
//
//  Created by vade on 8/22/16.
//  Copyright © 2016 v002. All rights reserved.
//

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
    
    NSDictionary* synopsisData = [frameMetadata valueForKey:@"mdta/info.v002.synopsis.metadata"];
    NSDictionary* standard = [synopsisData valueForKey:@"info.v002.Synopsis.OpenCVAnalyzer"];
    NSArray* domColors = [standard valueForKey:@"DominantColors"];

    NSArray* histogram = [standard valueForKey:@"Histogram"];

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
    
//    NSDictionary* synopsisData = [globalMetadata valueForKey:@"mdta/info.v002.synopsis.metadata"];
    NSDictionary* standard = [globalMetadata valueForKey:@"info.v002.Synopsis.OpenCVAnalyzer"];
    NSArray* domColors = [standard valueForKey:@"DominantColors"];
    NSArray* descriptions = [standard valueForKey:@"Description"];
    NSString* hash = [standard valueForKey:@"Hash"];
    
    NSArray* histogram = [standard valueForKey:@"Histogram"];
    
    NSMutableString* description = [NSMutableString new];
    
    for(NSString* desc in descriptions)
    {
        [description appendString:[desc stringByAppendingString:@", "]];
    }
    
    self.globalDominantColorView.dominantColorsArray = domColors;
    self.globalHistogramView.histogramArray = histogram;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.globalHash.stringValue = hash;
        self.globalDescriptors.stringValue = description;
        [self.globalDominantColorView updateLayer];
        [self.globalHistogramView updateLayer];
    });
}




@end
