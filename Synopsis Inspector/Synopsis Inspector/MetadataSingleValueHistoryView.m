//
//  MetadataSingleValueHistoryView.m
//  Synopsis Inspector
//
//  Created by vade on 1/3/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import "MetadataSingleValueHistoryView.h"

@interface MetadataSingleValueHistoryView ()

@property (readwrite) NSMutableArray<NSNumber*>* singleValueHistory;
@property (readwrite) NSMutableArray<CALayer*>* valueHistoryCALayers;
@property (readwrite) CALayer* historyLayer;
@property (readwrite) NSImage* layerImage;

@end


@implementation MetadataSingleValueHistoryView

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    self.singleValueHistory = [NSMutableArray arrayWithCapacity:256];
    self.valueHistoryCALayers = [NSMutableArray arrayWithCapacity:256];
    
    NSSize size = (NSSize) {1, 1};

    self.layerImage = [[NSImage alloc] initWithSize:size];
    [self.layerImage lockFocus];
    [[NSColor lightGrayColor] drawSwatchInRect:NSMakeRect(0, 0, size.width, size.height)];
    [self.layerImage unlockFocus];

    
    NSDictionary* actions = @{@"frame" : [NSNull null], @"position" : [NSNull null], @"frameSize" : [NSNull null], @"frameOrigin" : [NSNull null], @"bounds" : [NSNull null]};
    
    // a layer per bin value
    for(NSUInteger i = 0; i < 256; i++)
    {
        CALayer* layer = [CALayer layer];
        layer.contents = self.layerImage;
        layer.minificationFilter = kCAFilterNearest;
        layer.magnificationFilter = kCAFilterNearest;
        layer.edgeAntialiasingMask = 0;
        layer.actions = actions;
        layer.frame = (CGRect){ 0,0, 1, 1};
        [self.valueHistoryCALayers addObject:layer];
    }
    
    self.historyLayer = [CALayer layer];
    
    for(CALayer* layer in self.valueHistoryCALayers)
    {
        [self.historyLayer addSublayer:layer];
    }
    
    [self.layer addSublayer:self.historyLayer];
}

- (void) appendValue:(NSNumber*)value
{
    [self.singleValueHistory insertObject:value atIndex:0];
    
    while(self.singleValueHistory.count > 256)
    {
        [self.singleValueHistory removeLastObject];
    }
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
    NSUInteger valueIndex = 0;
    for(NSNumber* value in self.singleValueHistory)
    {
        
        CALayer* valueLayer = self.valueHistoryCALayers[valueIndex];
        if(valueLayer)
        {
            valueLayer.frame = (CGRect){0, 0, size.width, size.height * value.floatValue};
            valueLayer.position = (CGPoint){initialOffset + (width * 0.5), valueLayer.frame.size.height * 0.5};
        }
        initialOffset += width;
    
        valueIndex++;
    }
}

@end
