//
//  SynopsisResultItem.h
//  Synopslight
//
//  Created by vade on 7/26/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>

@interface SynopsisCollectionViewItem : NSCollectionViewItem

//- (void) setAspectRatio:(NSString*)aspect;

- (IBAction) contextualBestFitSort:(id)sender;
- (IBAction) contextualPredictionSort:(id)sender;
- (IBAction) contextualFeatureSort:(id)sender;
- (IBAction) contextualHistogramSort:(id)sender;

@end
