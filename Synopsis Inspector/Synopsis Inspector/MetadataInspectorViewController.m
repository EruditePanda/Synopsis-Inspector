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

@interface MetadataInspectorViewController ()

@property (weak) IBOutlet MetadataDominantColorsView* dominantColorView;
@property (weak) IBOutlet MetadataHistogramView* histogramView;

@end

@implementation MetadataInspectorViewController

@synthesize metadata;

- (NSDictionary*) metadata
{
    return metadata;
}

- (void) setMetadata:(NSDictionary *)dictionary
{
    metadata = dictionary;
    
    NSDictionary* synopsisData = [metadata valueForKey:@"mdta/info.v002.synopsis.metadata"];
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



@end
