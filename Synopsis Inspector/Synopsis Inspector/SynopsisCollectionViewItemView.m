//
//  SynopsisCollectionViewItemView.m
//  Synopsis Inspector
//
//  Created by vade on 8/15/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import "SynopsisCollectionViewItemView.h"
#import <QuartzCore/QuartzCore.h>

#define CORNER_RADIUS     6.0     // corner radius of the shape in points
#define BORDER_WIDTH      3.0     // thickness of border when shown, in points

@implementation SynopsisCollectionViewItemView

@synthesize borderColor = borderColor;

+ (id)defaultAnimationForKey:(NSString *)key {
    static CABasicAnimation *basicAnimation = nil;
    if ([key isEqual:@"frameOrigin"]) {
        if (basicAnimation == nil) {
            basicAnimation = [[CABasicAnimation alloc] init];
            [basicAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
        }
        return basicAnimation;
    } else {
        return [super defaultAnimationForKey:key];
    }
}

- (void) setBorderColor:(NSColor*)color
{
    borderColor = color;
    
    [self setNeedsDisplay:YES];
}

- (NSColor*) borderColor
{
    return borderColor;
}


- (BOOL)wantsUpdateLayer {
    return YES;
}

- (void)updateLayer {
    CALayer *layer = self.layer;
    layer.borderColor = self.borderColor.CGColor;
    layer.borderWidth = (self.borderColor ? BORDER_WIDTH : 0.0);
    layer.cornerRadius = CORNER_RADIUS;
    layer.backgroundColor = (self.borderColor ? [NSColor darkGrayColor].CGColor : nil);

}


@end
