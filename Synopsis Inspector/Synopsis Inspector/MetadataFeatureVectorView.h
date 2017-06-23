//
//  MetadataFeatureVectorView.h
//  Synopsis Inspector
//
//  Created by vade on 6/22/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Synopsis/Synopsis.h>

@interface MetadataFeatureVectorView : NSView
@property (readwrite, strong) SynopsisDenseFeature* feature;
@end
