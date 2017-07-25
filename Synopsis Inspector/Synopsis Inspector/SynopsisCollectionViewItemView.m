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
{
}

@property (weak) IBOutlet SynopsisCollectionViewItem* item;

@property (readwrite, weak) IBOutlet NSTextField* label;
@property (readwrite, assign) BOOL optimizingForScroll;
@property (readwrite) CALayer* imageLayer;
@property (readwrite) AVPlayerHapLayer* playerLayer;

@end

@implementation SynopsisCollectionViewItemView

@synthesize borderColor = borderColor;

//+ (id)defaultAnimationForKey:(NSString *)key
//{
//    static CABasicAnimation *basicAnimation = nil;
//    if ([key isEqual:@"frameOrigin"])
//    {
//        if (basicAnimation == nil)
//        {
//            basicAnimation = [[CABasicAnimation alloc] init];
//            [basicAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
//        }
//        return basicAnimation;
//    }
//    else
//    {
//        return [super defaultAnimationForKey:key];
//    }
//}

- (void) commonInit
{
    self.layer.backgroundColor = [NSColor clearColor].CGColor;

    self.playerLayer = [AVPlayerHapLayer layer];
    self.playerLayer.frame = self.layer.bounds;
    self.playerLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
    self.playerLayer.asynchronous = NO;
    self.playerLayer.actions = @{@"contents" : [NSNull null], @"opacity" : [NSNull null]};
    
//    [self.layer addSublayer:self.playerLayer];
//    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
//    self.playerLayer.frame = self.layer.bounds;
//    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
//    self.playerLayer.backgroundColor = [NSColor blueColor].CGColor;
    
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

- (void) awakeFromNib
{
    [self commonInit];
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
                [self.playerLayer endOptimize];
            }
        }
    }
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}


- (void) beginOptimizeForScrolling
{
    self.optimizingForScroll = YES;
    [self.playerLayer beginOptimize];
}

- (void) endOptimizeForScrolling
{
    self.optimizingForScroll = NO;
    [self.playerLayer endOptimize];
}

- (void) setAspectRatio:(NSString*)aspect
{
    self.imageLayer.contentsGravity = aspect;
//    self.playerLayer.videoGravity = aspect;
}

- (void) mouseEntered:(NSEvent *)theEvent
{
    [self.playerLayer play];
}

- (void) mouseMoved:(NSEvent *)theEvent
{
    [self.playerLayer play];
}

- (void) mouseExited:(NSEvent *)theEvent
{
    [self.playerLayer pause];
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
