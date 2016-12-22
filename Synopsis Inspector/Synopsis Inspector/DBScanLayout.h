//
//  DBScanLayout.h
//  Synopsis Inspector
//
//  Created by vade on 12/21/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DBScanLayout : NSCollectionViewFlowLayout

- (instancetype) initWithData:(NSArray<NSArray<NSNumber*> *>*)data NS_DESIGNATED_INITIALIZER;

// An NSArray that contains arrays of indices
// IE: the top level object is an array (a cluster) and that cluster is an array of indices
@property (readonly) NSArray* clustersAndConstiuents;

@end
