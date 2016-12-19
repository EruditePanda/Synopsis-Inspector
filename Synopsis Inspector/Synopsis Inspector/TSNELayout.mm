//
//  TSNELayout.m
//  Synopsis Inspector
//
//  Created by vade on 12/8/16.
//  Copyright © 2016 v002. All rights reserved.
//
#include <stdlib.h>
#include <stdio.h>
#include <vector>
#import "tsne.h"
#import "TSNELayout.h"

@interface TSNELayout ()
{
    TSNE tsne;
    double* X;
    double* Y;
    
    NSSize initialSize;

}
@property (nonatomic, readwrite, strong) NSArray<NSArray<NSNumber*> *>* data;
@property (nonatomic, readwrite, assign) NSUInteger dims;
@property (nonatomic, readwrite, assign) double perplexity;
@property (nonatomic, readwrite, assign) double theta;
@property (nonatomic, readwrite, assign) BOOL normalize;
@property (nonatomic, readwrite, assign) NSUInteger N;
@property (nonatomic, readwrite, assign) NSUInteger D;
@property (nonatomic, readwrite, assign) NSUInteger maxIterations;
@property (nonatomic, readwrite, assign) NSUInteger currentIteration;

// resultant points
@property (atomic, readwrite, strong) NSMutableArray* tsnePoints;

@end


@implementation TSNELayout

- (instancetype) init
{
    return [self initWithData:nil];
}

- (instancetype) initWithData:(NSArray<NSArray<NSNumber*> *>*)data
{
    self = [super init];
    if(self)
    {
        // Collectionview is 2D (for now?)
        self.dims = 2;
        self.perplexity = 10.0;
        self.theta = 0.0;
        self.normalize = YES;
        self.maxIterations = 1000;
        
        self.data = data;
        
        self.tsnePoints = [NSMutableArray new];
        
        // We need data.
        if(!self.data)
            return nil;
        
        // number of items in our data set
        self.N = data.count;
        
        // number of dimensions a single data point contains
        // Note, should be the same
        self.D = [(NSArray*)data[0] count];
        
        X = (double*) malloc(self.D * self.N * sizeof(double));
        Y = (double*) malloc(self.dims * self.N * sizeof(double));

        int idx = 0;
        for (int i = 0; i < self.N; i++)
        {
            for (int j = 0; j < self.D; j++)
            {
                X[idx] = [data[i][j] doubleValue];
                idx++;
            }
        }
        
        [self run];
        [self iterate];
    }
    
    return self;
}

- (void) dealloc
{
    free(X);
    free(Y);
}

- (void) run
{
    tsne.run(X, (int) self.N, (int) self.D, Y, (int) self.dims, self.perplexity, self.theta, 10, false, (int) self.maxIterations);
}

- (void) iterate
{
    // keep track of min for normalization
    // Our dims are 2, so we can use a CGPoint :X
    CGPoint min = CGPointMake(DBL_MAX, DBL_MAX);
    CGPoint max = CGPointMake(DBL_MIN, DBL_MIN);
    
    // unpack Y into tsnePoints
    [self.tsnePoints removeAllObjects];
    
    int idxY = 0;
    for (int i=0; i < self.N; i++)
    {
        CGPoint tsnePoint;
        tsnePoint.x = Y[idxY];
        tsnePoint.y = Y[idxY + 1];
        
        if (self.normalize)
        {
            if(tsnePoint.x < min.x)
                min.x = tsnePoint.x;
            
            if(tsnePoint.y < min.y)
                min.y = tsnePoint.y;
            
            if(tsnePoint.x > max.x)
                max.x = tsnePoint.x;
            
            if(tsnePoint.y > max.y)
                max.y = tsnePoint.y;
        }

        // our dims are always 2
        idxY += 2;

        [self.tsnePoints addObject:[NSValue valueWithPoint:NSPointFromCGPoint(tsnePoint)]];
    }
    
    // normalize if requested
    if (self.normalize)
    {
        for(NSUInteger i = 0; i < self.tsnePoints.count; i++)
        {
            NSValue* pointValue = self.tsnePoints[i];
            CGPoint normalizedCGPoint = NSPointToCGPoint([pointValue pointValue]);
            
            normalizedCGPoint.x = (normalizedCGPoint.x - min.x) / (max.x - min.x);
            normalizedCGPoint.y = (normalizedCGPoint.y - min.y) / (max.y - min.y);
            
            self.tsnePoints[i] = [NSValue valueWithPoint:NSPointFromCGPoint(normalizedCGPoint)];
        }
    }
    
    self.currentIteration = self.currentIteration + 1;
//    if (self.currentIteration == self.maxIterations)
//    {
////        finish();
//    }
    
//    return self.tsnePoints;
    
    NSLog(@"TSNE points: %@", self.tsnePoints);
}

- (void)prepareLayout {
    [super prepareLayout];
    
    self.collectionView.enclosingScrollView.autohidesScrollers = NO;
    self.collectionView.enclosingScrollView.hasVerticalScroller = YES;
    self.collectionView.enclosingScrollView.hasHorizontalScroller = YES;
    self.collectionView.enclosingScrollView.horizontalScroller.hidden = NO;
    
    self.collectionView.enclosingScrollView.allowsMagnification = YES;
    self.collectionView.enclosingScrollView.maxMagnification = 1.0;
    self.collectionView.enclosingScrollView.minMagnification = 0.15;
//    self.collectionView.enclosingScrollView.magnification = 1.0;

    // We resize this value / make a square.
    NSRect clipBounds = [[self collectionView] frame];

    NSSize size = NSMakeSize(NSMaxY(clipBounds), NSMaxY(clipBounds) );
    
    initialSize = size;
}

- (NSSize)collectionViewContentSize
{
    self.collectionView.enclosingScrollView.horizontalScroller.hidden = NO;

    return initialSize;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(NSRect)newBounds
{
    // Our custom SlideLayouts show all items within the CollectionView's visible rect, and must recompute their layouts for a good fit when that rect changes.
    return NO;
}

// A layout derived from this base class always displays all items, within the visible rectangle.  So we can implement -layoutAttributesForElementsInRect: quite simply, by enumerating all item index paths and obtaining the -layoutAttributesForItemAtIndexPath: for each.  Our subclasses then just have to implement -layoutAttributesForItemAtIndexPath:.
- (NSArray *)layoutAttributesForElementsInRect:(NSRect)rect
{
    NSInteger itemCount = [[self collectionView] numberOfItemsInSection:0];
    NSMutableArray *layoutAttributesArray = [NSMutableArray arrayWithCapacity:itemCount];
    for (NSInteger index = 0; index < itemCount; index++)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
        NSCollectionViewLayoutAttributes *layoutAttributes = [self layoutAttributesForItemAtIndexPath:indexPath];
        if (layoutAttributes)
        {
            if(NSPointInRect(layoutAttributes.frame.origin, rect))
            {
                [layoutAttributesArray addObject:layoutAttributes];
            }
        }
    }
    return layoutAttributesArray;
}

- (NSCollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSInteger count = [[self collectionView] numberOfItemsInSection:0];
    if (count == 0) {
        return nil;
    }
    
    NSUInteger itemIndex = [indexPath item];
    NSPoint subviewCenter = [[self.tsnePoints objectAtIndex:itemIndex] pointValue];

//    NSRect clipBounds = [[self collectionView] bounds];
//    CGFloat mag =  1.0 / self.collectionView.enclosingScrollView.minMagnification;
    

    subviewCenter.x *= initialSize.width;
    subviewCenter.y *= initialSize.height ;
//    subviewCenter.x += clipBounds.origin.x ;
//    subviewCenter.y += clipBounds.origin.y ;
    
    NSRect itemFrame = NSMakeRect(subviewCenter.x - 0.5 * self.itemSize.width, subviewCenter.y - 0.5 * self.itemSize.height, self.itemSize.width, self.itemSize.height);
    
//    NSLog(@"itemFrame: %@", NSStringFromRect(itemFrame));

    NSCollectionViewLayoutAttributes *attributes = [[[self class] layoutAttributesClass] layoutAttributesForItemWithIndexPath:indexPath];
    [attributes setFrame:NSRectToCGRect(itemFrame)];
    [attributes setZIndex:[indexPath item]];
    return attributes;
}


@end
