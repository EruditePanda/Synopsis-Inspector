//
//  TSNELayout.h
//  Synopsis Inspector
//
//  Created by vade on 12/8/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TSNELayout : NSCollectionViewLayout

// Data is an array of arrays of floats.
// Each Array contains features for a specific item. That sub-array is the feature array
// IE:
// item 1, histogram features.
// Item 2, histogram features.

// or
// Item 1, inception feature vector
// Item 2, inception feature vector
// etc.
// data must be float
- (instancetype) initWithData:(NSArray<NSArray<NSNumber*> *>*)data NS_DESIGNATED_INITIALIZER;

@property (readwrite, assign) NSSize itemSize;

@end
