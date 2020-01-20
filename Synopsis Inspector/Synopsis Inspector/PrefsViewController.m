//
//  PrefsViewController.m
//  Synopsis Inspector
//
//  Created by testAdmin on 1/14/20.
//  Copyright © 2020 v002. All rights reserved.
//

#import "PrefsViewController.h"




@interface PrefsViewController ()
@property (readwrite, nonatomic, strong) PrefsGeneralViewController* preferencesGeneralViewController;
@property (readwrite, nonatomic, strong) PrefsFileViewController* preferencesFileViewController;
@property (weak) NSViewController* currentViewController;
@end




static NSInteger currentTag = 0;




@implementation PrefsViewController

- (void)viewDidLoad {
	//NSLog(@"%s",__func__);
	[super viewDidLoad];
	
	self.preferencesGeneralViewController = [[PrefsGeneralViewController alloc] initWithNibName:@"PrefsGeneralViewController" bundle:[NSBundle mainBundle]];
	self.preferencesFileViewController = [[PrefsFileViewController alloc] initWithNibName:@"PrefsFileViewController" bundle:[NSBundle mainBundle]];
	
	[self addChildViewController:self.preferencesGeneralViewController];

	[self.view addSubview:self.preferencesGeneralViewController.view];
	[self.preferencesGeneralViewController.view setFrame:self.view.bounds];
	
	self.currentViewController = self.preferencesGeneralViewController;


	//[self buildPresetMenu];
	
	//	make sure my child views get loaded
	NSView			*tmpView = nil;
	tmpView = self.preferencesGeneralViewController.view;
	tmpView = self.preferencesFileViewController.view;
	
}

#pragma mark -

- (IBAction)transitionToGeneral:(id)sender
{
	[self transitionToViewController:self.preferencesGeneralViewController tag:[sender tag]];
}

- (IBAction)transitionToFile:(id)sender
{
	[self transitionToViewController:self.preferencesFileViewController tag:[sender tag]];
}

- (void) transitionToViewController:(NSViewController*)viewController tag:(NSInteger)tag
{
	NSViewControllerTransitionOptions option = NSViewControllerTransitionSlideRight;
	if( tag > currentTag)
		option = NSViewControllerTransitionSlideLeft;

	currentTag = tag;
	
	// early bail if equality
	if(self.currentViewController == viewController)
		return;
	
	[self addChildViewController:viewController];
	
	// update frame to match source / dest
	[viewController.view setFrame:self.currentViewController.view.bounds];

	[self transitionFromViewController:self.currentViewController
					  toViewController:viewController
							   options:option
					 completionHandler:^{

						 [self.currentViewController removeFromParentViewController];
						 
						 self.currentViewController = viewController;
					 }];
}

@end
