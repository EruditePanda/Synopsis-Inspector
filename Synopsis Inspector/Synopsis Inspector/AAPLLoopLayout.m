/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This is the "LoopLayout" class implementation.
*/

#import "AAPLLoopLayout.h"

@implementation AAPLLoopLayout

- (void)prepareLayout {
    [super prepareLayout];
    
    CGRect rect = NSMakeRect(0, 0, [self collectionViewContentSize].width, [self collectionViewContentSize].height);
    
    CGFloat halfItemWidth = 0.5 * self.itemSize.width;
    CGFloat halfItemHeight = 0.5 * self.itemSize.height;
    CGFloat radiusInset = sqrt(halfItemWidth * halfItemWidth + halfItemHeight * halfItemHeight);
    loopCenter = NSMakePoint(NSMidX(rect), NSMidY(rect));
    loopSize = NSMakeSize(0.5 * (rect.size.width - 2.0 * radiusInset), 0.5 * (rect.size.height - 2.0 * radiusInset));
}

- (NSSize)collectionViewContentSize
{
        NSRect clipBounds = [[[self collectionView] superview] bounds];
        return clipBounds.size; // Lay our slides out within the available area.
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(NSRect)newBounds
{
    // Our custom SlideLayouts show all items within the CollectionView's visible rect, and must recompute their layouts for a good fit when that rect changes.
    return YES;
}

// A layout derived from this base class always displays all items, within the visible rectangle.  So we can implement -layoutAttributesForElementsInRect: quite simply, by enumerating all item index paths and obtaining the -layoutAttributesForItemAtIndexPath: for each.  Our subclasses then just have to implement -layoutAttributesForItemAtIndexPath:.
- (NSArray *)layoutAttributesForElementsInRect:(NSRect)rect {
    NSInteger itemCount = [[self collectionView] numberOfItemsInSection:0];
    NSMutableArray *layoutAttributesArray = [NSMutableArray arrayWithCapacity:itemCount];
    for (NSInteger index = 0; index < itemCount; index++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
        NSCollectionViewLayoutAttributes *layoutAttributes = [self layoutAttributesForItemAtIndexPath:indexPath];
        if (layoutAttributes) {
            [layoutAttributesArray addObject:layoutAttributes];
        }
    }
    return layoutAttributesArray;
}

- (NSCollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger count = [[self collectionView] numberOfItemsInSection:0];
    if (count == 0) {
        return nil;
    }
    
    NSUInteger itemIndex = [indexPath item];
    CGFloat angleInRadians = ((CGFloat)itemIndex / (CGFloat)count) * (2.0 * M_PI);
    NSPoint subviewCenter;
    subviewCenter.x = loopCenter.x + loopSize.width * cos(angleInRadians);
    subviewCenter.y = loopCenter.y + loopSize.height * sin(2.0 * angleInRadians);
    NSRect itemFrame = NSMakeRect(subviewCenter.x - 0.5 * self.itemSize.width, subviewCenter.y - 0.5 * self.itemSize.height, self.itemSize.width, self.itemSize.height);
    
    NSCollectionViewLayoutAttributes *attributes = [[[self class] layoutAttributesClass] layoutAttributesForItemWithIndexPath:indexPath];
    [attributes setFrame:NSRectToCGRect(itemFrame)];
    [attributes setZIndex:[indexPath item]];
    return attributes;
}

@end
