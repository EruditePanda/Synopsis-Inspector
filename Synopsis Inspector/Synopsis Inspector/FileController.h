//
//  FileController.h
//  Synopsis Inspector
//
//  Created by testAdmin on 11/27/19.
//  Copyright © 2019 v002. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AppDelegate;


NS_ASSUME_NONNULL_BEGIN




@interface FileController : NSObject <NSMetadataQueryDelegate>	{
	IBOutlet AppDelegate		*appDelegate;
}

- (IBAction) chooseInitialSearchMode:(id)sender;
- (IBAction) switchToLocalComputerSearchScope:(id)sender;

- (void) loadFilesInDirectory:(NSURL *)n;

@end




NS_ASSUME_NONNULL_END
