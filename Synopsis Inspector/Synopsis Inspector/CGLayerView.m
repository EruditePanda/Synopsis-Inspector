//
//  CGLayerView.m
//  Synopslight
//
//  Created by vade on 8/3/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import "CGLayerView.h"

@interface CGLayerView ()
{
    CGLayerRef layer;
}

@end

@implementation CGLayerView

- (void) setCGlayer:(CGLayerRef)l
{
    [self setWantsLayer:YES];
    if(layer)
    {
        CGLayerRelease(layer);
        layer = NULL;
    }
    
    layer = CGLayerRetain(l);
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    if(layer != NULL)
    {
        CGColorSpaceRef cspace = CGColorSpaceCreateDeviceRGB();
        [[NSGraphicsContext currentContext] saveGraphicsState];
        
        CGContextRef context = [NSGraphicsContext currentContext].CGContext;
        
        CGContextSetBlendMode(context, kCGBlendModeCopy);
        CGContextSetFillColorSpace(context, cspace);
        
        CGContextDrawLayerInRect(context, self.bounds, layer);

        CGContextFlush(context);
        
        [[NSGraphicsContext currentContext] restoreGraphicsState];
        
        CGColorSpaceRelease(cspace);

    }
}

@end
