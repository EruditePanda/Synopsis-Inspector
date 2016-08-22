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

@interface SynopsisCollectionViewItemView : NSView
@property (readwrite) NSColor* borderColor;
@property (readwrite) CALayer* imageLayer;
@property (readonly) AVPlayerLayer* playerLayer;


@end
