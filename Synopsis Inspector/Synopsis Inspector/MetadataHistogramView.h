//
//  MetadataHistogramView.h
//  Synopsis Inspector
//
//  Created by vade on 8/22/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MetadataLayerBackedView.h"
#import <Synopsis/Synopsis.h>

@interface MetadataHistogramView : MetadataLayerBackedView
@property (strong) SynopsisDenseFeature* histogram;
@end
