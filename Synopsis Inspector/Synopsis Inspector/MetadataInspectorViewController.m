//
//  MetadataInspectorViewController.m
//  Synopsis Inspector
//
//  Created by vade on 8/22/16.
//  Copyright © 2016 v002. All rights reserved.
//
#import <Synopsis/Synopsis.h>
#import "MetadataInspectorViewController.h"
#import "MetadataDominantColorsView.h"
#import "MetadataHistogramView.h"
#import "MetadataMotionView.h"
#import "MetadataSingleValueHistoryView.h"
#import "MetadataFeatureVectorView.h"

@interface MetadataInspectorViewController ()

@property (weak) IBOutlet NSTextField* globalDescriptors;
@property (weak) IBOutlet NSTextField* globalHash;
@property (weak) IBOutlet MetadataDominantColorsView* globalDominantColorView;
@property (weak) IBOutlet MetadataHistogramView* globalHistogramView;

@property (weak) IBOutlet MetadataDominantColorsView* dominantColorView;
@property (weak) IBOutlet MetadataHistogramView* histogramView;
@property (weak) IBOutlet MetadataMotionView* motionView;

@property (weak) IBOutlet MetadataFeatureVectorView* featureVectorView;
@property (weak) IBOutlet MetadataSingleValueHistoryView* featureVectorHistory;
@property (weak) IBOutlet NSTextField* featureVectorHistoryCurrentValue;
@property (strong) SynopsisDenseFeature* lastFeatureVector;

@property (weak) IBOutlet MetadataSingleValueHistoryView* histogramHistory;
@property (weak) IBOutlet NSTextField* histogramHistoryCurrentValue;
@property (strong) SynopsisDenseFeature* lastHistogram;

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

    SynopsisDenseFeature* histogram = [standard valueForKey:kSynopsisStandardMetadataHistogramDictKey];
    NSString* hash = [standard valueForKey:kSynopsisStandardMetadataPerceptualHashDictKey];

    SynopsisDenseFeature* feature = [standard valueForKey:kSynopsisStandardMetadataFeatureVectorDictKey];

    float comparedHistograms = 0.0;
    float comparedFeatures = 0.0;
    float comparedHashes = 0.0;
    
    if(self.lastFeatureVector && [self.lastFeatureVector featureCount] && [feature featureCount] && ([self.lastFeatureVector featureCount] == [feature featureCount]))
    {
        comparedFeatures = compareFeatureVector(self.lastFeatureVector, feature);
    }
    
    if(self.lastHistogram && histogram)
    {
        comparedHistograms = compareHistogtams(self.lastHistogram, histogram);
    }
    
    if(self.lastHash && hash)
    {
        comparedHashes = compareFrameHashes(self.lastHash, hash);
    }
    
    self.dominantColorView.dominantColorsArray = domColors;
    self.histogramView.histogram = histogram;
    self.featureVectorView.feature = feature;

    dispatch_async(dispatch_get_main_queue(), ^{
        
//        if(self.view.window.isVisible)
        {
            [self.featureVectorView updateLayer];
            
            [self.dominantColorView updateLayer];
            [self.histogramView updateLayer];
            
            [self.featureVectorHistory appendValue:@(comparedFeatures)];
            [self.featureVectorHistory updateLayer];
            
            [self.histogramHistory appendValue:@(comparedHistograms)];
            [self.histogramHistory updateLayer];
            
            [self.hashHistory appendValue:@(comparedHashes)];
            [self.hashHistory updateLayer];
            
        }
        self.featureVectorHistoryCurrentValue.floatValue = comparedFeatures;
        self.histogramHistoryCurrentValue.floatValue = comparedHistograms;
        self.hashHistoryCurrentValue.floatValue = comparedHashes;
    });
    
    self.lastFeatureVector = feature;
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
    
    SynopsisDenseFeature* histogram = [standard valueForKey:kSynopsisStandardMetadataHistogramDictKey];
    
    NSMutableString* description = [NSMutableString new];
    
    for(NSString* desc in descriptions)
    {
        [description appendString:[desc stringByAppendingString:@", "]];
    }
    
    self.globalDominantColorView.dominantColorsArray = domColors;
    self.globalHistogramView.histogram = histogram;
    
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
