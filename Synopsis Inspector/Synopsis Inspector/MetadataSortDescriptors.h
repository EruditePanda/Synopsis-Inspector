//
//  MetadataSortDescriptors.h
//  Synopslight
//
//  Created by vade on 7/28/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface SynopsisMetadataSortDescriptors : NSSortDescriptor


// See which two objects are closer to the relativeHash.
// This is used for perceptual sorting -
+ (NSSortDescriptor*)hashSortDescriptorRelativeTo:(NSString*)relativeHash;

+ (NSSortDescriptor*)colorSortDescriptorRelativeTo:(NSColor*)color;

@end
