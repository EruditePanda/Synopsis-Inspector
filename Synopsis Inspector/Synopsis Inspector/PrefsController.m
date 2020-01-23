//
//  PrefsController.m
//  Synopsis Inspector
//
//  Created by testAdmin on 1/14/20.
//  Copyright © 2020 v002. All rights reserved.
//

#import "PrefsController.h"




PrefsController			*globalPrefsController = nil;




@interface PrefsController ()
- (void) generalInit;
@end




@implementation PrefsController


+ (PrefsController *) global	{
	if (globalPrefsController == nil)	{
		PrefsController		*asdf = [[PrefsController alloc] init];
		asdf = nil;
	}
	return globalPrefsController;
}


- (id) init	{
	self = [super initWithWindowNibName:[NSString stringWithFormat:@"%@",[[self class] className]]];
	if (self != nil)	{
		static dispatch_once_t		onceToken;
		dispatch_once(&onceToken, ^{
			globalPrefsController = self;
		});
		[self generalInit];
	}
	return self;
}
- (void) generalInit	{
	[self window];
}
- (void) dealloc	{
	//NSLog(@"%s",__func__);
}
- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}
- (void) awakeFromNib	{
	//NSLog(@"%s",__func__);
	[self.prefsViewController view];
}


@end
