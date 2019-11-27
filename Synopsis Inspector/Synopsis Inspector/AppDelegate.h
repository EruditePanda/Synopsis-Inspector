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
}

@property (strong) NSString* sortStatus;
@property (strong) NSString* filterStatus;
@property (strong) NSString* correlationStatus;

@end

