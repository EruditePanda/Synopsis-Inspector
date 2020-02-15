//
//  PrefsFileViewController.m
//  Synopsis Inspector
//
//  Created by testAdmin on 1/14/20.
//  Copyright © 2020 v002. All rights reserved.
//

#import "PrefsFileViewController.h"
#import "Constants.h"




@interface PrefsFileViewController ()

@end




@implementation PrefsFileViewController

- (instancetype)initWithNibName:(nullable NSNibName)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil
{
	//NSLog(@"%s",__func__);
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if(self)
	{
	}
	return self;
}

- (void) awakeFromNib
{
	//NSLog(@"%s",__func__);
	__weak PrefsFileViewController		*bss = self;
	[defaultFolderAbs setUserDefaultsKey:kSynopsisInspectorDefaultFolderPathKey];
	[defaultFolderAbs setDisabledLabelString:@"Discover All Local Media"];
	[defaultFolderAbs setCustomPathLabelString:@"Open Media Folder..."];
	[defaultFolderAbs setRecentPathLabelString:@"Recent Media Folders"];
	[defaultFolderAbs updateUI];
	[defaultFolderAbs setOpenPanelBlock:^(PrefsPathPickerAbstraction *inAbs)	{
		NSOpenPanel* openPanel = [NSOpenPanel openPanel];
		openPanel.canChooseDirectories = YES;
		openPanel.canCreateDirectories = YES;
		openPanel.canChooseFiles = NO;
		openPanel.message = @"Select Media Folder";
	
		[openPanel beginSheetModalForWindow:bss.view.window completionHandler:^(NSModalResponse result) {
			if(result == NSModalResponseOK)	{
				NSURL* outputFolderURL = [openPanel URL];
				[inAbs setPath:[outputFolderURL path]];
				//dispatch_async(dispatch_get_main_queue(), ^{
				//	[self updateOutputFolder:outputFolderURL];
				//});
			}
		}];
	}];
}


#pragma mark - Output Folder


- (BOOL) defaultFolderEnabled	{
	return [defaultFolderAbs enabled];
}
- (NSString *) defaultFolder	{
	return [defaultFolderAbs path];
}


@end
