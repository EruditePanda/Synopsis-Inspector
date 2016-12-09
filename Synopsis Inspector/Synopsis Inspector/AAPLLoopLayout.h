/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This is the "LoopLayout" class declaration.
*/

#import <Cocoa/Cocoa.h>

// Positions items in an "infinity"-shaped loop, within the available area.
@interface AAPLLoopLayout : NSCollectionViewLayout
{
    NSPoint loopCenter;
    NSSize loopSize;
}

@property (readwrite, assign) NSSize itemSize;
@end
