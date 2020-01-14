//
//  SynopsisCollectionViewItemView.m
//  Synopsis Inspector
//
//  Created by vade on 8/15/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import "SynopsisCollectionViewItemView.h"
#import <QuartzCore/QuartzCore.h>
#import "PlayerView.h"
#import <Synopsis/Synopsis.h>
#import <HapInAVFoundation/VVSizingTool.h>
#import "DataController.h"

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
	self.wantsLayer = YES;
	
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
    
    self.scrubView = nil;
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

- (void) updateLayer
{
	
	[super updateLayer];
	[self updateTrackingAreas];
	
}
- (void) updateTrackingAreas
{
	for(NSTrackingArea* trackingArea in self.trackingAreas)
	{
		[self removeTrackingArea:trackingArea];
	}
	
	int			opts = (NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInActiveApp | NSTrackingAssumeInside);
	NSTrackingArea		*trackingArea = [[NSTrackingArea alloc]
		initWithRect:[self bounds]
		options:opts
		owner:self
		userInfo:nil];
	
	[self addTrackingArea:trackingArea];
	
	[super updateTrackingAreas];
}
- (void) mouseEntered:(NSEvent *)event	{
	//NSLog(@"%s",__func__);
	
	@synchronized (self)	{
	
		if (self.scrubView != nil)	{
			//NSLog(@"\treturning early, scrubView already exists...");
			return;
		}
		
		PlayerView					*theScrubView = [[DataController global] scrubView];
		SynopsisMetadataItem		*myRepObj = self.item.representedObject;
		AVAsset						*myAsset = myRepObj.asset;
		
		//	this block will be executed when the "fade out" has completed
		void (^fadeOutCompletionHandler)(void) = ^(){
			//	when the fade-out has completed, remove the scrub view from the superview
			[(SynopsisCollectionViewItemView *)[theScrubView superview] setScrubView:nil];
			[theScrubView removeFromSuperview];
			//	tell the scrub view to load my asset
			[theScrubView loadAsset:myAsset];
			//	add the scrub view to me
			[self addSubview:theScrubView];
			self.scrubView = theScrubView;
			//	position the scrub view appropriately
			NSRect			videoRect = NSZeroRect;
			videoRect.size = [self.scrubView resolution];
			NSRect			scrubViewFrame = [VVSizingTool rectThatFitsRect:videoRect inRect:self.bounds sizingMode:VVSizingModeFit];
			[theScrubView setFrame:scrubViewFrame];
			
			//	fade the scrub view in...
			[NSAnimationContext
				runAnimationGroup:^(NSAnimationContext *context)	{
					//NSLog(@"\tfading the scrub view in...");
					context.duration = 0.5;
					theScrubView.animator.alphaValue = 1.0;
				}
				completionHandler:^{
					//NSLog(@"\tfinished fading the scrub view in...");
				}];
		};
		
		
		//	if the scrub view already has a superview, we have to fade it out before we can transfer it...
		if ([theScrubView superview] != nil)	{
			//	start an animation that fades out the scrub view
			[NSAnimationContext
				runAnimationGroup:^(NSAnimationContext *context)	{
					//NSLog(@"\tfading the scrub view out...");
					context.duration = 0.25;
					theScrubView.animator.alphaValue = 0.0;
				}
				completionHandler:^{
					fadeOutCompletionHandler();
				}];
		}
		//	else the scrub view doesn't have a superview yet- just run the completion handler, which fades it in...
		else	{
			fadeOutCompletionHandler();
		}
		
	}
}
- (void) mouseMoved:(NSEvent *)event
{
	@synchronized (self)	{
		if (self.scrubView != nil)
			[self.scrubView scrubViaEvent:event];
	}
}

- (void) setBorderColor:(NSColor*)color
{
}

- (NSColor*) borderColor
{
    return borderColor;
}
/*
- (BOOL) wantsLayer
{
    return YES;
}
*/
- (BOOL) wantsUpdateLayer
{
    return YES;
}

- (void)setFrameSize:(NSSize)n	{
	[super setFrameSize:n];
	
	[CATransaction begin];
	[CATransaction setDisableActions:YES];
	self.imageLayer.frame = self.layer.bounds;
	[CATransaction commit];
}

@end
