//
//  PrefsGeneralViewController.m
//  Synopsis Inspector
//
//  Created by testAdmin on 1/14/20.
//  Copyright © 2020 v002. All rights reserved.
//

#import "PrefsGeneralViewController.h"




@interface PrefsGeneralViewController ()
- (void) _populateThumbnailButtons;
@property (assign,readwrite) ThumbnailFrame thumbnailFrame;
@end




@implementation PrefsGeneralViewController


- (void) awakeFromNib	{
	//NSLog(@"%s",__func__);
	[self _populateThumbnailButtons];
}
- (IBAction) thumbnailButtonUsed:(id)sender	{
	//NSLog(@"%s",__func__);
	NSUserDefaults		*def = [NSUserDefaults standardUserDefaults];
	NSNumber			*tmpNum = nil;
	if (sender == firstFrameButton)	{
		tmpNum = [NSNumber numberWithInteger:ThumbnailFrame_First];
	}
	else if (sender == tenPercentButton)	{
		tmpNum = [NSNumber numberWithInteger:ThumbnailFrame_Ten];
	}
	else if (sender == fiftyPercentButton)	{
		tmpNum = [NSNumber numberWithInteger:ThumbnailFrame_Fifty];
	}
	
	if (tmpNum != nil)	{
		BOOL			postNotification = NO;
		if (self.thumbnailFrame != (ThumbnailFrame)[tmpNum intValue])	{
			postNotification = YES;
		}
		self.thumbnailFrame = (ThumbnailFrame)[tmpNum intValue];
		[def setObject:tmpNum forKey:kSynopsisInspectorThumbnailImageKey];
		[def synchronize];
		
		if (postNotification)	{
			[[NSNotificationCenter defaultCenter]
				postNotificationName:kSynopsisInspectorThumnailImageChangeName
				object:nil
				userInfo:nil];
		}
	}
}


- (void) _populateThumbnailButtons	{
	//NSLog(@"%s",__func__);
	NSUserDefaults		*def = [NSUserDefaults standardUserDefaults];
	NSNumber			*tmpNum = [def objectForKey:kSynopsisInspectorThumbnailImageKey];
	if (tmpNum == nil || [tmpNum intValue]==ThumbnailFrame_First)	{
		[firstFrameButton setIntValue:NSOnState];
		self.thumbnailFrame = ThumbnailFrame_First;
	}
	else if ([tmpNum intValue] == ThumbnailFrame_Ten)	{
		[tenPercentButton setIntValue:NSOnState];
		self.thumbnailFrame = ThumbnailFrame_Ten;
	}
	else if ([tmpNum intValue] == ThumbnailFrame_Fifty)	{
		[fiftyPercentButton setIntValue:NSOnState];
		self.thumbnailFrame = ThumbnailFrame_Fifty;
	}
}


@end
