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
#import <HapInAVFoundation/HapInAVFoundation.h>

@class PlayerView;

@interface SynopsisCollectionViewItemView : NSView

@property (strong,readwrite) PlayerView * scrubView;
@property (readwrite) NSColor* borderColor;
@property (readonly) CALayer* imageLayer;

//@property (readonly) NSTextField* currentTimeFromStart;
//@property (readonly) NSTextField* currentTimeToEnd;

- (void) setSelected:(BOOL)selected;

@end
