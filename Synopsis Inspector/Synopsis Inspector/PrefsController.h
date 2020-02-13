//
//  PrefsController.h
//  Synopsis Inspector
//
//  Created by testAdmin on 1/14/20.
//  Copyright © 2020 v002. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PrefsViewController.h"




@interface PrefsController : NSWindowController	{
}

+ (PrefsController *) global;

@property (weak) IBOutlet PrefsViewController* prefsViewController;

@end

