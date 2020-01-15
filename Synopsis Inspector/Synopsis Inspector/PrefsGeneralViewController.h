//
//  PrefsGeneralViewController.h
//  Synopsis Inspector
//
//  Created by testAdmin on 1/14/20.
//  Copyright © 2020 v002. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Constants.h"




@interface PrefsGeneralViewController : NSViewController	{
	IBOutlet NSButton		*firstFrameButton;
	IBOutlet NSButton		*tenPercentButton;
	IBOutlet NSButton		*fiftyPercentButton;
}

- (IBAction) thumbnailButtonUsed:(id)sender;

@property (readonly) ThumbnailFrame thumbnailFrame;

@end

