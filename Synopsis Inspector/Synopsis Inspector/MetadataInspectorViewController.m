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
#import "MetadataSingleValueHistoryView.h"

#import <Synopsis/Synopsis.h>

@interface MetadataInspectorViewController ()

@property (weak) IBOutlet NSTextField* globalDescriptors;
@property (weak) IBOutlet NSTextField* globalHash;
@property (weak) IBOutlet MetadataDominantColorsView* globalDominantColorView;
@property (weak) IBOutlet MetadataHistogramView* globalHistogramView;


@property (weak) IBOutlet MetadataDominantColorsView* dominantColorView;
@property (weak) IBOutlet MetadataHistogramView* histogramView;
@property (weak) IBOutlet MetadataMotionView* motionView;

@property (weak) IBOutlet MetadataSingleValueHistoryView* featureVectorHistory;
@property (weak) IBOutlet NSTextField* featureVectorHistoryCurrentValue;
@property (strong) NSArray* lastFeatureVector;

@property (weak) IBOutlet MetadataSingleValueHistoryView* histogramHistory;
@property (weak) IBOutlet NSTextField* histogramHistoryCurrentValue;
@property (strong) NSArray* lastHistogram;

@property (weak) IBOutlet MetadataSingleValueHistoryView* hashHistory;
@property (weak) IBOutlet NSTextField* hashHistoryCurrentValue;
@property (strong) NSString* lastHash;



@property (weak) IBOutlet NSButton* enableTrackerVisualizer;


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
    NSString* hash = [standard valueForKey:kSynopsisStandardMetadataPerceptualHashDictKey];

    NSArray* featureVector = [standard valueForKey:kSynopsisStandardMetadataFeatureVectorDictKey];

    float comparedHistograms = 0.0;
    float comparedFeatures = 0.0;
    float comparedHashes = 0.0;
    
    if(self.lastFeatureVector && self.lastFeatureVector.count && featureVector.count && (self.lastFeatureVector.count == featureVector.count))
    {
        comparedFeatures = compareFeatureVector(self.lastFeatureVector, featureVector);
        
        [self.featureVectorHistory appendValue:@(comparedFeatures)];
    }
    
    if(self.lastHistogram && histogram)
    {
        comparedHistograms = compareHistogtams(self.lastHistogram, histogram);
        [self.histogramHistory appendValue:@(comparedHistograms)];
    }
    
    if(self.lastHash && hash)
    {
        comparedHashes = compareFrameHashes(self.lastHash, hash);
        [self.hashHistory appendValue:@(comparedHashes)];
    }
    
    self.dominantColorView.dominantColorsArray = domColors;
    self.histogramView.histogramArray = histogram;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.dominantColorView updateLayer];
        [self.histogramView updateLayer];
        [self.featureVectorHistory updateLayer];
        [self.histogramHistory updateLayer];
        [self.hashHistory updateLayer];

        self.featureVectorHistoryCurrentValue.floatValue = comparedFeatures;
        self.histogramHistoryCurrentValue.floatValue = comparedHistograms;
        self.hashHistoryCurrentValue.floatValue = comparedHashes;
    });
    
    self.lastFeatureVector = featureVector;
    self.lastHistogram = histogram;
    self.lastHash = hash;
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
