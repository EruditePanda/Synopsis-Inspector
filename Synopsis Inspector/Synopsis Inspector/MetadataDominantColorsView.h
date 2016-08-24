//
//  MetadataDominantColorsView.h
//  Synopsis Inspector
//
//  Created by vade on 8/21/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MetadataLayerBackedView.h"

@interface MetadataDominantColorsView : MetadataLayerBackedView
@property (strong) NSArray* dominantColorsArray;
@end
