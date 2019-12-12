//
//  MetadataDominantColorsView.m
//  Synopsis Inspector
//
//  Created by vade on 8/21/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import "MetadataDominantColorsView.h"
#import <Synopsis/Synopsis.h>

@interface MetadataDominantColorsView ()
@property (readwrite, strong) SynopsisDominantColorLayer* dominantColorLayer;
@end

@implementation MetadataDominantColorsView

- (void) awakeFromNib
{
    [super awakeFromNib];
    self.dominantColorLayer = [SynopsisDominantColorLayer layer];
    self.dominantColorLayer.frame = self.layer.bounds;
    
    [self.layer addSublayer:self.dominantColorLayer];
    
}

- (void) updateLayer
{
    self.dominantColorLayer.dominantColorsArray = self.dominantColorsArray;
    self.dominantColorLayer.frame = self.layer.bounds;
    [self.dominantColorLayer setNeedsDisplay];
}

@end
