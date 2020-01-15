//
//  PrefsViewController.h
//  Synopsis Inspector
//
//  Created by testAdmin on 1/14/20.
//  Copyright © 2020 v002. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PrefsGeneralViewController.h"
#import "PrefsFileViewController.h"



@interface PrefsViewController : NSViewController

@property (readonly, nonatomic, strong) PrefsGeneralViewController* preferencesGeneralViewController;
@property (readonly, nonatomic, strong) PrefsFileViewController* preferencesFileViewController;

@end


