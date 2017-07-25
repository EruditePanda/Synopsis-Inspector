//
//  SynopsisResultItem.h
//  Synopslight
//
//  Created by vade on 7/26/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>

@interface SynopsisCollectionViewItem : NSCollectionViewItem <AVPlayerItemMetadataOutputPushDelegate>


- (void) beginOptimizeForScolling;
- (void) endOptimizeForScrolling;

- (BOOL) isShowingPopOver;
- (IBAction)hidePopOver:(id)sender;
- (IBAction)showPopOver:(id)sender;

- (void) setAspectRatio:(NSString*)aspect;

@end
