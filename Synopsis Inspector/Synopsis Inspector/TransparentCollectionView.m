//
//  TransparentCollectionView.m
//  Synopsis Inspector
//
//  Created by vade on 8/27/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import "TransparentCollectionView.h"

@interface TransparentCollectionView ()
@property (weak) IBOutlet NSLayoutConstraint* trailingConstraint;
@end

@implementation TransparentCollectionView

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
//-(void)setFrameSize:(NSSize)newSize
//{
//    if (newSize.width != self.collectionViewLayout.collectionViewContentSize.width)
//    {
//        newSize.width = self.collectionViewLayout.collectionViewContentSize.width;
//        
//        self.enclosingScrollView.autohidesScrollers = NO;
//        self.enclosingScrollView.usesPredominantAxisScrolling = NO;
//        self.enclosingScrollView.horizontalScroller.hidden = NO;
//        self.enclosingScrollView.hasHorizontalScroller = YES;
//    }
//    
//    [super setFrameSize:newSize];
//}
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
//    
//}
//
//- (void) layout
//{
//    [super layout];
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
//}

@end
