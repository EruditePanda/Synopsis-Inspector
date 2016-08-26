//
//  TransparentView.m
//  Synopsis Inspector
//
//  Created by vade on 8/25/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import "TransparentView.h"

@implementation TransparentView

- (BOOL) isOpaque
{
    return NO;
}

- (BOOL) allowsVibrancy
{
    return YES;
}

@end
