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
@property (weak) IBOutlet MetadataDominantColorsView* globalDominantColorView;
@property (weak) IBOutlet MetadataHistogramView* globalHistogramView;
@property (weak) IBOutlet MetadataFeatureVectorView* globalFeatureVectorView;
@property (weak) IBOutlet MetadataFeatureVectorView* globalProbabilityView;

@property (weak) IBOutlet NSTextField* frameDescriptors;
@property (weak) IBOutlet MetadataDominantColorsView* dominantColorView;
@property (weak) IBOutlet MetadataHistogramView* histogramView;
@property (weak) IBOutlet MetadataMotionView* motionView;

@property (weak) IBOutlet MetadataFeatureVectorView* featureVectorView;
@property (weak) IBOutlet MetadataSingleValueHistoryView* featureVectorHistory;
@property (weak) IBOutlet NSTextField* featureVectorHistoryCurrentValue;
@property (strong) SynopsisDenseFeature* lastFeatureVector;

@property (weak) IBOutlet MetadataFeatureVectorView* probabilityView;


@property (weak) IBOutlet MetadataSingleValueHistoryView* histogramHistory;
@property (weak) IBOutlet NSTextField* histogramHistoryCurrentValue;
@property (strong) SynopsisDenseFeature* lastHistogram;

@property (weak) IBOutlet NSTextField* metadataVersionNumber;
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
    
    NSDictionary* synopsisData = [frameMetadata valueForKey:kSynopsisMetadataIdentifier];
    NSDictionary* standard = [synopsisData valueForKey:kSynopsisStandardMetadataDictKey];
    NSArray* domColors = [standard valueForKey:kSynopsisStandardMetadataDominantColorValuesDictKey];
    NSArray* descriptions = [standard valueForKey:kSynopsisStandardMetadataDescriptionDictKey];

    NSMutableString* description = [NSMutableString new];
    
    for(NSString* desc in descriptions)
    {
        // Hack to make the description 'key' not have a comma
        if([desc hasSuffix:@":"])
        {
            [description appendString:[desc stringByAppendingString:@" "]];
        }
        else
        {
            [description appendString:[desc stringByAppendingString:@", "]];
        }
    }

    SynopsisDenseFeature* histogram = [standard valueForKey:kSynopsisStandardMetadataHistogramDictKey];

    SynopsisDenseFeature* feature = [standard valueForKey:kSynopsisStandardMetadataFeatureVectorDictKey];

    SynopsisDenseFeature* probability = [standard valueForKey:kSynopsisStandardMetadataProbabilitiesDictKey];

    
    float comparedHistograms = 0.0;
    float comparedFeatures = 0.0;
    
    if(self.lastFeatureVector && [self.lastFeatureVector featureCount] && [feature featureCount] && ([self.lastFeatureVector featureCount] == [feature featureCount]))
    {
        comparedFeatures = compareFeatureVector(self.lastFeatureVector, feature);
    }
    
    if(self.lastHistogram && histogram)
    {
        comparedHistograms = compareHistogtams(self.lastHistogram, histogram);
    }
    
    self.dominantColorView.dominantColorsArray = domColors;
    self.histogramView.histogram = histogram;
    self.featureVectorView.feature = feature;
    self.probabilityView.feature = probability;

    dispatch_async(dispatch_get_main_queue(), ^{
        
//        if(self.view.window.isVisible)
        {
            [self.featureVectorView updateLayer];
            [self.probabilityView updateLayer];

            [self.dominantColorView updateLayer];
            [self.histogramView updateLayer];
            
            [self.featureVectorHistory appendValue:@(comparedFeatures)];
            [self.featureVectorHistory updateLayer];
            
            [self.histogramHistory appendValue:@(comparedHistograms)];
            [self.histogramHistory updateLayer];
            
            if(description)
                self.frameDescriptors.stringValue = description;

        }
        self.featureVectorHistoryCurrentValue.floatValue = comparedFeatures;
        self.histogramHistoryCurrentValue.floatValue = comparedHistograms;
    });
    
    self.lastFeatureVector = feature;
    self.lastHistogram = histogram;
}

- (NSDictionary*) globalMetadata
{
    return globalMetadata;
}

- (void) setGlobalMetadata:(NSDictionary *)dictionary
{
    globalMetadata = dictionary;
    
    NSUInteger metadataVersion = [[globalMetadata valueForKey:kSynopsisMetadataVersionKey] unsignedIntegerValue];
    NSDictionary* standard = [globalMetadata valueForKey:kSynopsisStandardMetadataDictKey];
    NSArray* domColors = [standard valueForKey:kSynopsisStandardMetadataDominantColorValuesDictKey];
    NSArray* descriptions = [standard valueForKey:kSynopsisStandardMetadataDescriptionDictKey];
    SynopsisDenseFeature* probability = [standard valueForKey:kSynopsisStandardMetadataProbabilitiesDictKey];
    SynopsisDenseFeature* feature = [standard valueForKey:kSynopsisStandardMetadataFeatureVectorDictKey];
    SynopsisDenseFeature* histogram = [standard valueForKey:kSynopsisStandardMetadataHistogramDictKey];
    
    NSMutableString* description = [NSMutableString new];
    
    for(NSString* desc in descriptions)
    {
        // Hack to make the description 'key' not have a comma
        if([desc hasSuffix:@":"])
        {
            [description appendString:[desc stringByAppendingString:@" "]];
        }
        else
        {
            [description appendString:[desc stringByAppendingString:@", "]];
        }
    }

    self.globalDominantColorView.dominantColorsArray = domColors;
    self.globalHistogramView.histogram = histogram;
    self.globalFeatureVectorView.feature = feature;
    self.globalProbabilityView.feature = probability;

    dispatch_async(dispatch_get_main_queue(), ^{
        
        if(description)
            self.globalDescriptors.stringValue = description;
        
        self.metadataVersionNumber.stringValue = [NSString stringWithFormat:@"Metadata Version: %lu", (unsigned long)metadataVersion];
        
        [self.globalDominantColorView updateLayer];
        [self.globalHistogramView updateLayer];
        [self.globalFeatureVectorView updateLayer];
        [self.globalProbabilityView updateLayer];

    });
}

@end
