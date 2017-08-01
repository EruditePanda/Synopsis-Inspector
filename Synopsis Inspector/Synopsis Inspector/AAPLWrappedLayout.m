/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This is the "WrappedLayout" class implementation.
*/

#import "AAPLWrappedLayout.h"
//#import "AAPLSlideLayout.h"         // for X_PADDING, Y_PADDING
//#import "AAPLSlideCarrierView.h"    // for SLIDE_WIDTH, SLIDE_HEGIHT

@implementation AAPLWrappedLayout

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setItemSize:NSMakeSize(300, 300)];
        [self setMinimumInteritemSpacing:10];
        [self setMinimumLineSpacing:10];
        [self setSectionInset:NSEdgeInsetsMake(10, 10, 10, 10)];
    }
    return self;
}

- (void) prepareLayout
{
    [super prepareLayout];
    
    self.collectionView.enclosingScrollView.hasVerticalScroller = YES;
    self.collectionView.enclosingScrollView.verticalScroller.hidden = NO;

    self.collectionView.enclosingScrollView.hasHorizontalScroller = NO;
    self.collectionView.enclosingScrollView.verticalScroller.hidden = YES;
    self.collectionView.enclosingScrollView.autohidesScrollers = YES;
//        
    self.collectionView.enclosingScrollView.animator.magnification = 1.0;
    self.collectionView.enclosingScrollView.animator.allowsMagnification = NO;
    self.collectionView.enclosingScrollView.animator.maxMagnification = 1.0;
    self.collectionView.enclosingScrollView.animator.minMagnification = 1.0;
}

- (NSSize) collectionViewContentSize
{
    NSSize size = [super collectionViewContentSize];
    return size;
}

- (NSCollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSCollectionViewLayoutAttributes *attributes = [super layoutAttributesForItemAtIndexPath:indexPath];
//    [attributes setZIndex:[indexPath item]];
    return attributes;
}

- (NSArray *)layoutAttributesForElementsInRect:(NSRect)rect {
    NSArray *layoutAttributesArray = [super layoutAttributesForElementsInRect:rect];
    for (NSCollectionViewLayoutAttributes *attributes in layoutAttributesArray) {
        [attributes setZIndex:[[attributes indexPath] item]];
    }
    return layoutAttributesArray;
}

@end
