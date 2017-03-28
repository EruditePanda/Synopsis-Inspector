//
//  TSNELayout.h
//  Synopsis Inspector
//
//  Created by vade on 12/8/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Synopsis/Synopsis.h>

@interface TSNELayout : NSCollectionViewLayout

- (instancetype) initWithFeatures:(NSArray<SynopsisDenseFeature*>*)features NS_DESIGNATED_INITIALIZER;

@property (readwrite, assign) NSSize itemSize;

@end
