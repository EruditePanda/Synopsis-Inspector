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
@property (readwrite) CALayer* redHistogram;
@property (readwrite) CALayer* greenHistogram;
@property (readwrite) CALayer* blueHistogram;
@property (readwrite) NSMutableArray<CALayer*>* rHistogramCALayers;
@property (readwrite) NSMutableArray<CALayer*>* gHistogramCALayers;
@property (readwrite) NSMutableArray<CALayer*>* bHistogramCALayers;
@property (readwrite, strong) NSImage* redImage;
@property (readwrite, strong) NSImage* greenImage;
@property (readwrite, strong) NSImage* blueImage;
@end



@implementation MetadataHistogramView

- (void) awakeFromNib
{
    [self setLayerUsesCoreImageFilters:YES];

    self.layer.cornerRadius = 3.0;
    self.layer.backgroundColor = [NSColor colorWithWhite:0.5 alpha:0.2].CGColor;
    
    self.rHistogramCALayers = [NSMutableArray arrayWithCapacity:256];
    self.gHistogramCALayers = [NSMutableArray arrayWithCapacity:256];
    self.bHistogramCALayers = [NSMutableArray arrayWithCapacity:256];
    
    NSSize size = (NSSize) {1, 1};
    
    self.redImage = [[NSImage alloc] initWithSize:size];
    [self.redImage lockFocus];
    [[NSColor redColor] drawSwatchInRect:NSMakeRect(0, 0, size.width, size.height)];
    [self.redImage unlockFocus];

    self.greenImage = [[NSImage alloc] initWithSize:size];
    [self.greenImage lockFocus];
    [[NSColor greenColor] drawSwatchInRect:NSMakeRect(0, 0, size.width, size.height)];
    [self.greenImage unlockFocus];

    self.blueImage = [[NSImage alloc] initWithSize:size];
    [self.blueImage lockFocus];
    [[NSColor blueColor] drawSwatchInRect:NSMakeRect(0, 0, size.width, size.height)];
    [self.blueImage unlockFocus];

//    CIFilter* addition = [CIFilter filterWithName:@"CIAdditionCompositing"];
//    [addition setDefaults];
    
    NSDictionary* actions = @{@"frame" : [NSNull null], @"position" : [NSNull null], @"frameSize" : [NSNull null], @"frameOrigin" : [NSNull null], @"bounds" : [NSNull null]};
    
    for(NSUInteger i = 0; i < 256; i++)
    {
        CALayer* rLayer = [CALayer layer];
        rLayer.contents = self.redImage;
        rLayer.minificationFilter = kCAFilterNearest;
        rLayer.magnificationFilter = kCAFilterNearest;
        rLayer.edgeAntialiasingMask = 0;
        rLayer.actions = actions;
        rLayer.frame = (CGRect){ 0,0, 1, 1};
        [self.rHistogramCALayers addObject:rLayer];
        
        CALayer* gLayer = [CALayer layer];
        gLayer.contents = self.greenImage;
        gLayer.minificationFilter = kCAFilterNearest;
        gLayer.magnificationFilter = kCAFilterNearest;
        gLayer.edgeAntialiasingMask = 0;
        gLayer.actions = actions;
        gLayer.frame = (CGRect){ {0,0}, {1, 1}};
        [self.gHistogramCALayers addObject:gLayer];

        CALayer* bLayer = [CALayer layer];
        bLayer.contents = self.blueImage;
        bLayer.minificationFilter = kCAFilterNearest;
        bLayer.magnificationFilter = kCAFilterNearest;
        bLayer.edgeAntialiasingMask = 0;
        bLayer.actions = actions;
        bLayer.frame = (CGRect){ {0,0}, {1, 1}};
        [self.bHistogramCALayers addObject:bLayer];
    }
    
    self.redHistogram = [CALayer layer];
    self.greenHistogram = [CALayer layer];
    self.blueHistogram = [CALayer layer];
    
    self.greenHistogram.compositingFilter = [CIFilter filterWithName:@"CIAdditionCompositing"];
    self.blueHistogram.compositingFilter = [CIFilter filterWithName:@"CIAdditionCompositing"];

    for(CALayer* layer in self.rHistogramCALayers)
    {
//        layer.zPosition = -1;
        [self.redHistogram addSublayer:layer];
    }
    
    for(CALayer* layer in self.gHistogramCALayers)
    {
//        layer.zPosition = 0;
//        layer.compositingFilter = addition;
        [self.greenHistogram addSublayer:layer];
    }
    
    for(CALayer* layer in self.bHistogramCALayers)
    {
//        layer.zPosition = 1;
        [self.blueHistogram addSublayer:layer];
    }
    
    [self.layer addSublayer:self.redHistogram];
    [self.layer addSublayer:self.greenHistogram];
    [self.layer addSublayer:self.blueHistogram];
    
//    try grouping layers into red green blue layers perhaps?
    
//    CIFilter* addition = [CIFilter filterWithName:@"CIAdditionCompositing"];
//    [addition setDefaults];
//    CALayer* fuckYou = [CALayer layer];
//    fuckYou.zPosition = 1;
//    fuckYou.contents = [NSImage imageNamed:@"AppIcon"];
//    fuckYou.compositingFilter =addition;
//    fuckYou.frame = self.layer.bounds;
//    [self.layer addSublayer:fuckYou];
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
//        rValueLayer.backgroundColor = [[NSColor redColor] CGColor];
//        gValueLayer.backgroundColor = [[NSColor greenColor] CGColor];
//        bValueLayer.backgroundColor = [[NSColor blueColor] CGColor];
//        
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
