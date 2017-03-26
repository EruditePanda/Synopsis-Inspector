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
    
    self.playerLayer = [[AVPlayerLayer alloc] init];
    self.playerLayer.frame = self.layer.bounds;
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    self.playerLayer.actions = @{@"contents" : [NSNull null]};
    self.playerLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
    
    [self.layer insertSublayer:self.playerLayer below:self.label.layer];
    
    self.imageLayer = [CALayer layer];
    self.imageLayer.frame = self.layer.bounds;
    self.imageLayer.contentsGravity = AVLayerVideoGravityResizeAspect;
    self.imageLayer.actions = @{@"contents" : [NSNull null]};
    self.imageLayer.autoresizingMask =  kCALayerWidthSizable | kCALayerHeightSizable;

    [self.layer insertSublayer:self.imageLayer below:self.playerLayer];
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

//-(NSMenu*) menuForEvent:(NSEvent *)event
//{
//    return self.contextualMenu;
//}


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
    layer.backgroundColor = [NSColor blackColor].CGColor; //(self.borderColor ? [NSColor lightGrayColor].CGColor : [NSColor grayColor].CGColor);
    [self updateTrackingAreas];
}

@end
