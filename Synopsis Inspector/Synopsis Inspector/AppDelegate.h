//
//  AppDelegate.h
//  Synopslight
//
//  Created by vade on 7/26/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, NSMetadataQueryDelegate, NSTokenFieldDelegate>	{
	IBOutlet NSClipView		*clipView;
	IBOutlet NSView			*containerView;
	IBOutlet NSBox			*previewBox;
	IBOutlet NSTabView		*attribsTabView;
	IBOutlet NSSlider		*zoomSlider;
}

+ (id) global;

@property (strong) NSString* sortStatus;
@property (strong) NSString* filterStatus;
@property (strong) NSString* correlationStatus;

- (IBAction)bestMatchSortUsingSelectedCell:(id)sender;
- (IBAction)featureVectorSortUsingSelectedCell:(id)sender;
- (IBAction)probabilitySortUsingSelectedCell:(id)sender;
- (IBAction)histogramSortUsingSelectingCell:(id)sender;
- (IBAction)sortDominantColorsRGBUsingSelectingCell:(id)sender;
- (IBAction)sortDominantColorsHSBUsingSelectingCell:(id)sender;
- (IBAction)saturationSortUsingSelectedCell:(id)sender;
- (IBAction)hueSortUsingSelectedCell:(id)sender;
- (IBAction)brightnessSortUsingSelectedCell:(id)sender;

- (IBAction) zoomInUsed:(id)sender;
- (IBAction) zoomOutUsed:(id)sender;

- (IBAction) helpSlackChannel:(id)sender;
- (IBAction) helpReportABug:(id)sender;
- (IBAction) helpFAQ:(id)sender;

@end

