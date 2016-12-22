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

- (BOOL) isOpaque
{
    return NO;
}

- (BOOL) allowsVibrancy
{
    return YES;
}

- (void) setFrame:(NSRect)frame
{
    // Fix a bug in our colleciton view not showing our horizontal scroller
    if (frame.size.width != self.collectionViewLayout.collectionViewContentSize.width)
    {
        
        frame.size.width = self.collectionViewLayout.collectionViewContentSize.width;
    }

    [super setFrame:frame];
    
}

- (void) layout
{
    [super layout];

    // Fix a bug in our colleciton view not showing our horizontal scroller
    if (self.frame.size.width != self.collectionViewLayout.collectionViewContentSize.width)
    {
        //        self.trailingConstraint.constant = -self.collectionViewLayout.collectionViewContentSize.width;
        [self setFrameSize:[self.collectionViewLayout collectionViewContentSize]];
    }
}

@end
