//
//  MetadataMotionView.m
//  Synopsis Inspector
//
//  Created by vade on 8/23/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import "MetadataMotionView.h"

@interface MetadataMotionView ()
@property (readwrite) NSMutableOrderedSet<NSNumber*>* motion;
@end

#define maxCount 20

@implementation MetadataMotionView

-(void) awakeFromNib
{
    self.motion = [NSMutableOrderedSet new];
    [super awakeFromNib];
}

-(void)addMotion:(NSNumber *)motion
{
    [self.motion insertObject:motion atIndex:0];
    
    if(self.motion.count > maxCount)
        [self.motion removeObjectAtIndex:self.motion.count -1];
}

- (BOOL) wantsLayer
{
    return YES;
}

- (BOOL) wantsUpdateLayer
{
    return YES;
}

- (void) updateLayer
{

}

@end
