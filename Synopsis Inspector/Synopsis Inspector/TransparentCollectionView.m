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

//- (BOOL) translatesAutoresizingMaskIntoConstraints
//{
//    return NO;
//}

- (void) setFrame:(NSRect)frame
{

    if (frame.size.width != self.collectionViewLayout.collectionViewContentSize.width)
    {
        
        frame.size.width = self.collectionViewLayout.collectionViewContentSize.width;
    }

    [super setFrame:frame];
    
//    NSLog(@"CollectionView setFrame: %@", NSStringFromRect(frame));
}
////
//-(void)setFrameSize:(NSSize)newSize{
//    
//    [super setFrameSize:newSize];
////    NSLog(@"CollectionView setFrameSize: %@", CGSizeCreateDictionaryRepresentation(newSize));
//}

//- (void) updateConstraints
//{
////    NSLog(@"CollectionView updateConstraints");
//
//    [super updateConstraints];
//    
//}

- (void) layout
{
//    NSLog(@"CollectionView layout");

    [super layout];

    
    if (self.frame.size.width != self.collectionViewLayout.collectionViewContentSize.width)
    {
        //        self.trailingConstraint.constant = -self.collectionViewLayout.collectionViewContentSize.width;
        [self setFrameSize:[self.collectionViewLayout collectionViewContentSize]];
    }

    //
}

@end
