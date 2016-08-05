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
//    self.blendingMode = NSVisualEffectBlendingModeWithinWindow;
    [self.window setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameVibrantLight]];
    [self setMaterial:NSVisualEffectMaterialLight];
    // set our mask image'
//    self.maskImage = [NSImage imageNamed:NSImageNameActionTemplate];
//    self.maskImage = [NSImage imageWithSize:self.bounds.size flipped:NO drawingHandler:^BOOL(NSRect bounds)
//    {
//        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:bounds  xRadius:100 yRadius:100];
//        
//        [path fill];
//        return YES;
//        
//    }];
}
@end
