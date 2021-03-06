//
//  MetadataFeatureVectorView.m
//  Synopsis Inspector
//
//  Created by vade on 6/22/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import "MetadataFeatureVectorView.h"
@interface MetadataFeatureVectorView ()
@property (readwrite, strong) SynopsisDenseFeatureLayer* featureLayer;
@end


@implementation MetadataFeatureVectorView

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    self.layer = [CALayer layer];

    self.featureLayer = [SynopsisDenseFeatureLayer layer];
    self.featureLayer.frame = self.layer.bounds;
    
    [self.layer addSublayer:self.featureLayer];
}

- (BOOL) wantsUpdateLayer
{
    return YES;
}

- (void) updateLayer
{
    self.featureLayer.feature = self.feature;
    self.featureLayer.frame = self.layer.bounds;
    [self.featureLayer setNeedsDisplay];
}

- (void)setFrameSize:(NSSize)n	{
	[super setFrameSize:n];
	
	[CATransaction begin];
	[CATransaction setDisableActions:YES];
	
	[self updateLayer];
	
	[CATransaction commit];
}

@end
