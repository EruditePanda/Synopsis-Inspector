//
//  MetadataInspectorViewController.h
//  Synopsis Inspector
//
//  Created by vade on 8/22/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MetadataInspectorViewController : NSViewController

@property (weak,readwrite,nullable) SynopsisMetadataItem * metadataItem;
@property (readwrite, strong) NSDictionary* frameMetadata;

- (void) refresh;

@end
