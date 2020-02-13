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




static NSOperationQueue		*_scrubViewFadeOutQueue;
static NSOperationQueue		*_scrubViewFadeInQueue;
static SynopsisCollectionViewItemView		*_scrubViewTarget = nil;




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

+ (void) initialize	{
	static dispatch_once_t		onceToken;
	dispatch_once(&onceToken, ^{
		_scrubViewFadeOutQueue = [[NSOperationQueue alloc] init];
		_scrubViewFadeOutQueue.suspended = YES;
		_scrubViewFadeInQueue = [[NSOperationQueue alloc] init];
		_scrubViewFadeInQueue.suspended = YES;
	});
}
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

+ (void) fadeScrubViewIntoView:(SynopsisCollectionViewItemView *)n	{
	if (n == nil)
		return;
	
	//	lock- we want to manage all this fade out/fade in stuff tightly to prevent double-runs or overwriting
	@synchronized (self)	{
		//NSLog(@"%s ... %@",__func__,n.item.representedObject);
		//	if we're already targeting the passed view, bail
		if (_scrubViewTarget == n)
			return;
		
		//	immediately cancel any ops in the fade out/fade in queues
		_scrubViewFadeOutQueue.suspended = YES;
		_scrubViewFadeInQueue.suspended = YES;
		[_scrubViewFadeOutQueue cancelAllOperations];
		[_scrubViewFadeInQueue cancelAllOperations];
		
		//	update the scrub view target
		_scrubViewTarget = n;
		
		//	fetch some vars we'll need
		PlayerView		*globalScrubView = [[DataController global] scrubView];
		SynopsisMetadataItem		*viewMDItem = n.item.representedObject;
		AVAsset			*asset = viewMDItem.asset;
		
		//	queue up an animation that fades the view out of its current superview
		[_scrubViewFadeOutQueue addOperationWithBlock:^	{
			//NSLog(@"\tfade out queue executing for request on %@",viewMDItem);
			[NSAnimationContext
				runAnimationGroup:^(NSAnimationContext *context)	{
					context.duration = 0.5;
					globalScrubView.animator.alphaValue = 0.0;
				}
				completionHandler:^{
					//NSLog(@"\tfade out complete for request on %@",viewMDItem);
					//	if this completion handler is executing after aonther mouseover has occurred, bail
					if ([globalScrubView superview] == _scrubViewTarget)
						return;
					//	remove the scrub view from the superview
					[(SynopsisCollectionViewItemView *)[globalScrubView superview] setScrubView:nil];
					[globalScrubView removeFromSuperview];
				
					//	run the "scrub view fade in" queue
					_scrubViewFadeInQueue.suspended = NO;
				}];
		}];
		
		//	queue up an animation that fades the view in
		[_scrubViewFadeInQueue addOperationWithBlock:^{
			//NSLog(@"\tfade in queue executing on %@",viewMDItem);
			
			dispatch_async(dispatch_get_main_queue(), ^{
				//	tell the scrub view to load the new view's asset
				[globalScrubView loadAsset:asset];
				//	add the scrub view to the new target view
				[n addSubview:globalScrubView];
				n.scrubView = globalScrubView;
				//	position the scrub view in the new target view
				NSRect			videoRect = NSZeroRect;
				videoRect.size = [globalScrubView resolution];
				NSRect			scrubViewFrame = [VVSizingTool
					rectThatFitsRect:videoRect
					inRect:n.bounds
					sizingMode:VVSizingModeFit];
				[globalScrubView setFrame:scrubViewFrame];
				
				//	fade the scrub view in
				[NSAnimationContext
					runAnimationGroup:^(NSAnimationContext *context)	{
						context.duration = 0.5;
						globalScrubView.animator.alphaValue = 1.0;
					}
					completionHandler:^{
					}];
			});
		}];
		
		//	start the "scrub view fade out" queue (or just fade in if we don't need to fade out)
		//NSLog(@"\tbeginning process for request %@",viewMDItem);
		_scrubViewFadeOutQueue.suspended = NO;
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
	//NSLog(@"%s ... %@",__func__,self.item.representedObject);
	
	@synchronized (self)	{
	
		if (self.scrubView != nil)	{
			//NSLog(@"\treturning early, scrubView already exists...");
			return;
		}
		
		[SynopsisCollectionViewItemView fadeScrubViewIntoView:self];
		
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
