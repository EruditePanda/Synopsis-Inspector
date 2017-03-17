//
//  SynopsisScrollView.m
//  Synopsis Inspector
//
//  Created by vade on 12/13/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import "SynopsisScrollView.h"

@implementation SynopsisScrollView

- (void) setHasVerticalScroller:(BOOL)hasVerticalScroller
{
    [super setHasVerticalScroller:YES];
}

- (void) setHasHorizontalScroller:(BOOL)hasVerticalScroller
{
    [super setHasHorizontalScroller:YES];
}

- (void) magnifyWithEvent:(NSEvent *)event
{
    [super magnifyWithEvent:event];
}

- (void) scrollWheel:(NSEvent *)event
{
//    NSUInteger flags = [event modifierFlags];
    
//    // if option or shift is pressed, we magnify, otherwise we scroll
//    if( (flags & NSAlternateKeyMask) || (flags & NSShiftKeyMask))
//    {
//        [self magnifyWithEvent:event];
//    }
//    else
    {
        [super scrollWheel:event];
    }
}

@end
