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
    [super awakeFromNib];
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

    for(NSColor* color in self.dominantColorsArray)
    {
        CALayer* colorLayer = [CALayer layer];

        // TODO: Do I need to enforce linear colorspace here?
        colorLayer.backgroundColor = color.CGColor;
        colorLayer.frame = (CGRect){0, 0, size.width, size.height};
        colorLayer.position = (CGPoint){initialOffset + (width * 0.5), size.height * 0.5};
        
        //        colorLayer.borderColor
  
        initialOffset += width;
        
        [self.layer addSublayer:colorLayer];
    }
}

@end
