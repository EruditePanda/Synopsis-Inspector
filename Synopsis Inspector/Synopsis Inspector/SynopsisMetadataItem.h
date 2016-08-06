//
//  SynopsisMetadataItem.h
//  Synopslight
//
//  Created by vade on 7/28/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

// Thin wrapper for NSMetadataItem to implement Key Value access to HFS + Extended attribute's (which Synopsis Can leverage)  

@interface SynopsisMetadataItem : NSMetadataItem

- (CGLayerRef) cachedLayerRef;
- (void) setCachedLayerRef:(CGLayerRef) layerRef;
@property (readwrite, strong) NSImage* cachedImage;

@property (readonly) AVURLAsset* urlAsset;
@end
