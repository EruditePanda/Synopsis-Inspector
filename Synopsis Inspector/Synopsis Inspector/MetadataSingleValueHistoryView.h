//
//  MetadataSingleValueHistoryView.h
//  Synopsis Inspector
//
//  Created by vade on 1/3/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import "MetadataLayerBackedView.h"

@interface MetadataSingleValueHistoryView : MetadataLayerBackedView
- (void) appendValue:(NSNumber*)value;
@end
