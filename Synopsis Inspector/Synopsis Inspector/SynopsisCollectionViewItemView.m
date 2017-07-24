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

@property (weak) IBOutlet SynopsisCollectionViewItem* item;
@property (readwrite) AVPlayerLayer* playerLayer;
@property (readwrite, weak) IBOutlet NSTextField* label;
@property (readwrite, assign) BOOL optimizingForScroll;
@end

@implementation SynopsisCollectionViewItemView

@synthesize borderColor = borderColor;

+ (id)defaultAnimationForKey:(NSString *)key
{
    static CABasicAnimation *basicAnimation = nil;
    if ([key isEqual:@"frameOrigin"])
    {
        if (basicAnimation == nil)
        {
            basicAnimation = [[CABasicAnimation alloc] init];
            [basicAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
        }
        return basicAnimation;
    }
    else
    {
        return [super defaultAnimationForKey:key];
    }
}

- (void) commonInit
{
    [self.layer addSublayer:self.label.layer];
    
    self.layer.backgroundColor = [NSColor clearColor].CGColor;
    
    AVPlayer* player = [[AVPlayer alloc] init];
    player.volume = 0;
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    self.playerLayer.frame = self.layer.bounds;
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    self.playerLayer.actions = @{@"contents" : [NSNull null], @"opacity" : [NSNull null]};
    self.playerLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
    self.playerLayer.backgroundColor = [NSColor clearColor].CGColor;
    
    [self.layer insertSublayer:self.playerLayer below:self.label.layer];
    
    self.imageLayer = [CALayer layer];
    self.imageLayer.frame = self.layer.bounds;
    self.imageLayer.contentsGravity = AVLayerVideoGravityResizeAspect;
    self.imageLayer.actions = @{@"contents" : [NSNull null]};
    self.imageLayer.autoresizingMask =  kCALayerWidthSizable | kCALayerHeightSizable;

    [self.layer insertSublayer:self.imageLayer below:self.playerLayer];
    
    [self.playerLayer addObserver:self forKeyPath:@"readyForDisplay" options:NSKeyValueObservingOptionNew context:NULL];
}

- (instancetype) initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if(self)
    {
        [self commonInit];
    }
    return self;
}

// If we lazily become ready to play, and we are not in optimize moment (scrolling) show then
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if(object == self.playerLayer)
    {
        if(self.playerLayer.readyForDisplay)
        {
            if(!self.optimizingForScroll)
            {
                self.playerLayer.opacity = 1.0;
            }
        }
        return;
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void) awakeFromNib
{
    [self commonInit];
}

- (void) beginOptimizeForScrolling
{
    self.playerLayer.opacity = 0.0;
    [self.playerLayer.player pause];
    self.optimizingForScroll = YES;
}

- (void) endOptimizeForScrolling
{
    self.optimizingForScroll = NO;
    if(self.playerLayer.readyForDisplay)
    {
        self.playerLayer.opacity = 1.0;
    }
}


- (void) setAspectRatio:(NSString*)aspect
{
    self.imageLayer.contentsGravity = aspect;
    self.playerLayer.videoGravity = aspect;
}

- (void) mouseEntered:(NSEvent *)theEvent
{
    [self.playerLayer.player play];
}

- (void) mouseMoved:(NSEvent *)theEvent
{
    [self.playerLayer.player play];
}

- (void) mouseExited:(NSEvent *)theEvent
{
    [self.playerLayer.player pause];
}

- (void) mouseDown:(NSEvent *)theEvent
{
    if(theEvent.clickCount > 1)
    {
        if([self.item isShowingPopOver])
            [self.item hidePopOver:nil];
        else
            [self.item showPopOver:nil];
    }
    else
        [super mouseDown:theEvent];
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
    
    int opts = (NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingAssumeInside | NSTrackingInVisibleRect);
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
    layer.borderWidth = BORDER_WIDTH;//(self.borderColor ? BORDER_WIDTH : 0.0);
    layer.cornerRadius = CORNER_RADIUS;
    layer.backgroundColor = [NSColor clearColor].CGColor; //(self.borderColor ? [NSColor lightGrayColor].CGColor : [NSColor grayColor].CGColor);
    [self updateTrackingAreas];
}

@end
