//
//  SynopsisCollectionViewItemView.h
//  Synopsis Inspector
//
//  Created by vade on 8/15/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>
#import "SynopsisCollectionViewItem.h"
#import "SynopsisHAPPlayerLayer.h"

@interface SynopsisCollectionViewItemView : NSView
@property (readwrite) NSColor* borderColor;
@property (readonly) CALayer* imageLayer;
@property (readonly) SynopsisHAPPlayerLayer* playerLayer;

- (void) setAspectRatio:(NSString*)aspect;

- (void) beginOptimizeForScrolling;
- (void) endOptimizeForScrolling;

@end
