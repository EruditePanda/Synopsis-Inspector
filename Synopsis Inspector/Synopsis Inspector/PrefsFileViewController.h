//
//  PrefsFileViewController.h
//  Synopsis Inspector
//
//  Created by testAdmin on 1/14/20.
//  Copyright © 2020 v002. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PrefsPathPickerAbstraction.h"




@interface PrefsFileViewController : NSViewController	{
	IBOutlet PrefsPathPickerAbstraction		*defaultFolderAbs;
}

- (BOOL) defaultFolderEnabled;
- (NSString *) defaultFolder;

@end

