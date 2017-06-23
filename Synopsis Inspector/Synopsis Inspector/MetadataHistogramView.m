//
//  MetadataHistogramView.m
//  Synopsis Inspector
//
//  Created by vade on 8/22/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import "MetadataHistogramView.h"
#import <Quartz/Quartz.h>

@interface MetadataHistogramView ()
@property (readwrite) SynopsisHistogramLayer* histogramLayer;
@end

@implementation MetadataHistogramView

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    [self setLayerUsesCoreImageFilters:YES];

    self.histogramLayer = [SynopsisHistogramLayer layer];
    self.histogramLayer.frame = self.layer.bounds;
    
    [self.layer addSublayer:self.histogramLayer];
}

- (void) updateLayer
{
    self.histogramLayer.histogram = self.histogram;
    [self.histogramLayer setNeedsDisplay];
}

@end
