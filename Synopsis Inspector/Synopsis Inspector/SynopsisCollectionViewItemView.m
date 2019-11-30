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
#define BORDER_WIDTH      1.0     // thickness of border when shown, in points

#define BGCOLOR 0.025
#define SELECTEDBGCOLOR 0.05

#define BORDERCOLOR 0.2
#define SELECTEDBORDERCOLOR 0.6




@interface SynopsisCollectionViewItemView ()	{
}

@property (weak) IBOutlet SynopsisCollectionViewItem* item;

//@property (strong) IBOutlet NSTextField* currentTimeFromStart;
//@property (strong) IBOutlet NSTextField* currentTimeToEnd;
@property (readwrite, weak) IBOutlet NSTextField* label;

@property (readwrite) CALayer* imageLayer;

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

- (BOOL) allowsVibrancy
{
    return NO;
}

- (void) commonInit
{
    self.layer.backgroundColor = [NSColor colorWithWhite:BGCOLOR alpha:1.0].CGColor;
    self.layer.borderColor = [NSColor colorWithWhite:BORDERCOLOR alpha:1.0].CGColor;
    self.layer.borderWidth = BORDER_WIDTH;//(self.borderColor ? BORDER_WIDTH : 0.0);
    self.layer.cornerRadius = CORNER_RADIUS;

    self.label.layer.opacity = 0.5;
    //self.currentTimeToEnd.layer.opacity = 0.0;
    //self.currentTimeFromStart.layer.opacity = 0.0;
    
    self.imageLayer = [CALayer layer];
    self.imageLayer.frame = self.layer.bounds;
    self.imageLayer.contentsGravity = kCAGravityResizeAspect;
    self.imageLayer.actions = @{@"contents" : [NSNull null]};
    self.imageLayer.autoresizingMask =  kCALayerWidthSizable | kCALayerHeightSizable;
    [self.layer addSublayer:self.imageLayer];
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
/*
- (void) setAspectRatio:(NSString*)aspect
{
    self.imageLayer.contentsGravity = aspect;
//    self.playerLayer.videoGravity = aspect;
}
*/
- (void) setSelected:(BOOL)selected
{
    if(selected)
    {
        self.layer.backgroundColor = [NSColor colorWithWhite:SELECTEDBGCOLOR alpha:1].CGColor;
        self.layer.borderColor = [NSColor colorWithWhite:SELECTEDBORDERCOLOR alpha:1].CGColor;
    }
    else
    {
        self.layer.backgroundColor = [NSColor colorWithWhite:BGCOLOR alpha:1].CGColor;
        self.layer.borderColor = [NSColor colorWithWhite:BORDERCOLOR alpha:1].CGColor;
    }

    [self setNeedsDisplay:YES];
}

- (void) setBorderColor:(NSColor*)color
{
}

- (NSColor*) borderColor
{
    return borderColor;
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
