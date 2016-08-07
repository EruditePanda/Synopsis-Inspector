//
//  CustomVisualEffectView.m
//  Synopsis
//
//  Created by vade on 5/18/15.
//  Copyright (c) 2015 metavisual. All rights reserved.
//

#import "CustomVisualEffectView.h"

@interface CustomVisualEffectView ()
@property (atomic, readwrite, assign) BOOL needsMaskResize;

@end

@implementation CustomVisualEffectView

- (void) awakeFromNib
{
    [self setState:NSVisualEffectStateActive];
    self.blendingMode = NSVisualEffectBlendingModeWithinWindow;
    [self.window setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameVibrantDark]];
    [self setMaterial:NSVisualEffectMaterialUltraDark];
}
@end
