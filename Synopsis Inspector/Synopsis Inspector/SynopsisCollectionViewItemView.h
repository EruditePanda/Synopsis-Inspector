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
#import "HapInAVFoundation.h"

@interface SynopsisCollectionViewItemView : NSView
@property (readwrite) NSColor* borderColor;
@property (readonly) CALayer* imageLayer;
@property (readonly) AVPlayerHapLayer* playerLayer;

@property (readonly) NSTextField* currentTimeFromStart;
@property (readonly) NSTextField* currentTimeToEnd;

- (void) setAspectRatio:(NSString*)aspect;

- (void) beginOptimizeForScrolling;
- (void) endOptimizeForScrolling;

- (void) setSelected:(BOOL)selected;

@end
