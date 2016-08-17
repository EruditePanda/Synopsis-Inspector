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

@interface SynopsisCollectionViewItemView ()
@property (readwrite) AVPlayerLayer* playerLayer;
@end

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

- (instancetype) initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if(self)
    {
        self.playerLayer = [[AVPlayerLayer alloc] init];
        self.playerLayer.frame = self.layer.bounds;
        
        [self.layer addSublayer:self.playerLayer];
    }
    return self;
}

- (void) awakeFromNib
{
    self.playerLayer = [[AVPlayerLayer alloc] init];
    self.playerLayer.frame = self.layer.bounds;
    
    [self.layer addSublayer:self.playerLayer];
    
}

- (void) mouseEntered:(NSEvent *)theEvent
{
//    NSLog(@"Play");
    
    [self.playerLayer.player play];
}

- (void) mouseExited:(NSEvent *)theEvent
{
//    NSLog(@"Pause");
    [self.playerLayer.player pause];
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

-(void)updateTrackingAreas
{
    for(NSTrackingArea* trackingArea in self.trackingAreas)
    {
        [self removeTrackingArea:trackingArea];
    }
    
    int opts = (NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingAssumeInside);
    NSTrackingArea* trackingArea = [ [NSTrackingArea alloc] initWithRect:[self bounds]
                                                                 options:opts
                                                                   owner:self
                                                                userInfo:nil];
    [self addTrackingArea:trackingArea];
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
    [self updateTrackingAreas];
}


@end
