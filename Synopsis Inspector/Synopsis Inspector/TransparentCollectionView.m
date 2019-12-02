//
//  TransparentCollectionView.m
//  Synopsis Inspector
//
//  Created by vade on 8/27/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import "TransparentCollectionView.h"

@interface TransparentCollectionView ()
@end

@implementation TransparentCollectionView

//- (void) setFrame:(NSRect)frame
//{
//    // Fix a bug in our colleciton view not showing our horizontal scroller
//    if (frame.size.width != self.collectionViewLayout.collectionViewContentSize.width)
//    {
//
//        frame.size.width = self.collectionViewLayout.collectionViewContentSize.width;
//    }
//
//    [super setFrame:frame];
//}

//- (BOOL) isOpaque
//{
//    return NO;
//}
//
//- (BOOL) allowsVibrancy
//{
//    return YES;
//}

//
-(void)setFrameSize:(NSSize)newSize
{
    if ( !CGSizeEqualToSize(newSize,  self.collectionViewLayout.collectionViewContentSize))
    {
        newSize = self.collectionViewLayout.collectionViewContentSize;

        [self.enclosingScrollView.documentView setFrame: NSMakeRect(0,0,newSize.width, newSize.height) ];

        self.enclosingScrollView.autohidesScrollers = NO;
        self.enclosingScrollView.usesPredominantAxisScrolling = NO;

        if ( newSize.height > 0 )
        {
            self.enclosingScrollView.hasVerticalScroller = newSize.height > self.enclosingScrollView.frame.size.height;
            self.enclosingScrollView.verticalScroller.hidden = newSize.height <= self.enclosingScrollView.frame.size.height;
        }
        
        self.enclosingScrollView.hasHorizontalScroller = newSize.width > self.enclosingScrollView.frame.size.width;
        self.enclosingScrollView.horizontalScroller.hidden = newSize.width <= self.enclosingScrollView.frame.size.width;

        
//        self.enclosingScrollView.horizontalScroller.hidden = NO;
//        self.enclosingScrollView.hasHorizontalScroller = YES;
    }
    else
    {
        [super setFrameSize:newSize];
    }
}
//
//- (void) setFrame:(NSRect)frame
//{
//    // Fix a bug in our colleciton view not showing our horizontal scroller
//    if (frame.size.width != self.collectionViewLayout.collectionViewContentSize.width)
//    {
//        frame.size.width = self.collectionViewLayout.collectionViewContentSize.width;
//        self.enclosingScrollView.autohidesScrollers = NO;
//        self.enclosingScrollView.usesPredominantAxisScrolling = NO;
//        self.enclosingScrollView.horizontalScroller.hidden = NO;
//        self.enclosingScrollView.hasHorizontalScroller = YES;
//    }
//
//    [super setFrame:frame];
//}
//
//- (void) layout
//{
//
//    // Fix a bug in our colleciton view not showing our horizontal scroller
//    if (self.frame.size.width != self.collectionViewLayout.collectionViewContentSize.width)
//    {
//        //        self.trailingConstraint.constant = -self.collectionViewLayout.collectionViewContentSize.width;
//        [self setFrameSize:[self.collectionViewLayout collectionViewContentSize]];
//
//        self.enclosingScrollView.autohidesScrollers = NO;
//        self.enclosingScrollView.usesPredominantAxisScrolling = NO;
//        self.enclosingScrollView.horizontalScroller.hidden = NO;
//        self.enclosingScrollView.hasHorizontalScroller = YES;
//    }
//
//    [super layout];
//
//}

@end
