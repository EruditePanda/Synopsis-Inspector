//
//  MetadataDominantColorsView.m
//  Synopsis Inspector
//
//  Created by vade on 8/21/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import "MetadataDominantColorsView.h"


@implementation MetadataDominantColorsView

- (void) awakeFromNib
{
    self.layer.cornerRadius = 3.0;
//    self.layer.borderWidth = 1.0;
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
    for(CALayer* layer in [[self.layer sublayers] copy])
    {
        [layer removeFromSuperlayer];
    }
    
    NSUInteger totalColors = self.dominantColorsArray.count;
    CGFloat width = self.layer.bounds.size.width / (CGFloat)totalColors;
    CGSize size = (CGSize){width, self.layer.bounds.size.height};
    CGFloat initialOffset = (CGFloat)0.0;

    for(NSArray* colorArray in self.dominantColorsArray)
    {
        CALayer* colorLayer = [CALayer layer];

        // TODO: Do I need to enforce linear colorspace here?
        colorLayer.backgroundColor = [[NSColor colorWithRed:[colorArray[0] floatValue]
                                                                       green:[colorArray[1] floatValue]
                                                                        blue:[colorArray[2] floatValue]
                                                                       alpha:1.0] CGColor];

        colorLayer.frame = (CGRect){0, 0, size.width, size.height};
        colorLayer.position = (CGPoint){initialOffset + (width * 0.5), size.height * 0.5};
        
        //        colorLayer.borderColor
  
        initialOffset += width;
        
        [self.layer addSublayer:colorLayer];
    }
}

@end
