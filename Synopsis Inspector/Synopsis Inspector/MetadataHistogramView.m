//
//  MetadataHistogramView.m
//  Synopsis Inspector
//
//  Created by vade on 8/22/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import "MetadataHistogramView.h"

@interface MetadataHistogramView ()
@property (readwrite) NSMutableArray* rHistogramCALayers;
@property (readwrite) NSMutableArray* gHistogramCALayers;
@property (readwrite) NSMutableArray* bHistogramCALayers;

@end



@implementation MetadataHistogramView

- (void) awakeFromNib
{
    self.layer.cornerRadius = 3.0;
    
    self.rHistogramCALayers = [NSMutableArray arrayWithCapacity:256];
    self.gHistogramCALayers = [NSMutableArray arrayWithCapacity:256];
    self.bHistogramCALayers = [NSMutableArray arrayWithCapacity:256];
    
    for(NSUInteger i = 0; i < 256; i++)
    {
        CALayer* rLayer = [CALayer layer];
        rLayer.backgroundColor = [NSColor redColor].CGColor;
        rLayer.actions = @{@"frame" : [NSNull null], @"position" : [NSNull null], @"frameSize" : [NSNull null], @"frameOrigin" : [NSNull null], @"bounds" : [NSNull null]};
//        rLayer.opacity = 2.0 / 3.0;
//        rLayer.opaque = NO;
        rLayer.frame = (CGRect){ 0,0, 1, 1};
        [self.rHistogramCALayers addObject:rLayer];
        
        CALayer* gLayer = [CALayer layer];
        gLayer.backgroundColor = [NSColor greenColor].CGColor;
        gLayer.actions = @{@"frame" : [NSNull null], @"position" : [NSNull null], @"frameSize" : [NSNull null], @"frameOrigin" : [NSNull null], @"bounds" : [NSNull null]};
//        gLayer.opacity = 2.0 / 3.0;
//        gLayer.opaque = NO;
        gLayer.frame = (CGRect){ {0,0}, {1, 1}};
        
        [self.gHistogramCALayers addObject:gLayer];

        CALayer* bLayer = [CALayer layer];
        bLayer.backgroundColor = [NSColor blueColor].CGColor;
        bLayer.actions = @{@"frame" : [NSNull null], @"position" : [NSNull null], @"frameSize" : [NSNull null], @"frameOrigin" : [NSNull null], @"bounds" : [NSNull null]};
//        bLayer.opacity = 2.0 / 3.0;
//        bLayer.opaque = NO;
        bLayer.frame = (CGRect){ {0,0}, {1, 1}};

        [self.bHistogramCALayers addObject:bLayer];
    }
    
    for(CALayer* layer in self.rHistogramCALayers)
    {
        [self.layer addSublayer:layer];
    }
    
    for(CALayer* layer in self.gHistogramCALayers)
    {
        [self.layer addSublayer:layer];
    }
    
    for(CALayer* layer in self.bHistogramCALayers)
    {
        [self.layer addSublayer:layer];
    }
}

- (BOOL) wantsLayer
{
    return YES;
}

- (BOOL) wantsUpdateLayer
{
    return YES;
}

- (void) updateLayer
{
//    for(CALayer* layer in [[self.layer sublayers] copy])
//    {
//        [layer removeFromSuperlayer];
//    }
    
    CGFloat width = self.layer.bounds.size.width / (CGFloat)256.0;
    CGSize size = (CGSize){width, self.layer.bounds.size.height};
    CGFloat initialOffset = (CGFloat)0.0;
    
    NSUInteger binNumber = 0;
    for(NSArray* histogramBins in self.histogramArray)
    {
        NSNumber* rValue = histogramBins[0];
        NSNumber* gValue = histogramBins[1];
        NSNumber* bValue = histogramBins[2];
        
        CALayer* rValueLayer = self.rHistogramCALayers[binNumber];
        CALayer* gValueLayer = self.gHistogramCALayers[binNumber];
        CALayer* bValueLayer = self.bHistogramCALayers[binNumber];
        
        // TODO: Do I need to enforce linear colorspace here?
        rValueLayer.backgroundColor = [[NSColor redColor] CGColor];
        gValueLayer.backgroundColor = [[NSColor greenColor] CGColor];
        bValueLayer.backgroundColor = [[NSColor blueColor] CGColor];
        
        rValueLayer.frame = (CGRect){0, 0, size.width, size.height * rValue.floatValue};
        rValueLayer.position = (CGPoint){initialOffset + (width * 0.5), rValueLayer.frame.size.height * 0.5};

        gValueLayer.frame = (CGRect){0, 0, size.width, size.height * gValue.floatValue};
        gValueLayer.position = (CGPoint){initialOffset + (width * 0.5), gValueLayer.frame.size.height * 0.5};

        bValueLayer.frame = (CGRect){0, 0, size.width, size.height * bValue.floatValue};
        bValueLayer.position = (CGPoint){initialOffset + (width * 0.5), bValueLayer.frame.size.height * 0.5};

        initialOffset += width;
        binNumber++;
    }
}

@end
