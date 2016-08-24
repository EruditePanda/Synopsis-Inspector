//
//  MetadataLayerBackedView.m
//  Synopsis Inspector
//
//  Created by vade on 8/23/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import "MetadataLayerBackedView.h"

@implementation MetadataLayerBackedView

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    self.layer.cornerRadius = 3.0;
    self.layer.backgroundColor = [NSColor colorWithWhite:0.5 alpha:0.2].CGColor;
    self.layer.borderColor = [NSColor colorWithWhite:0.5 alpha:0.5].CGColor;
    self.layer.borderWidth =  1.0;
}

- (BOOL) wantsLayer
{
    return YES;
}

- (BOOL) wantsUpdateLayer
{
    return YES;
}


@end
