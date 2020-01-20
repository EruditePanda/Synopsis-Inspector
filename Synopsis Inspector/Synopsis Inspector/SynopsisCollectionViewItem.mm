//
//  SynopsisResultItem.m
//  Synopslight
//
//  Created by vade on 7/26/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import <Synopsis/Synopsis.h>
#import "SynopsisCollectionViewItem.h"
#import <AVFoundation/AVFoundation.h>
#import "SynopsisCollectionViewItemView.h"
#import "SynopsisCacheWithHap.h"
#import "AppDelegate.h"
#import "Constants.h"
#import "PrefsController.h"




@interface SynopsisCollectionViewItem ()
{
}

@property (weak) IBOutlet NSTextField* nameField;

@end




@implementation SynopsisCollectionViewItem


- (id) initWithCoder:(NSCoder *)c	{
	self = [super initWithCoder:c];
	if (self != nil)	{
		[[NSNotificationCenter defaultCenter]
			addObserver:self
			selector:@selector(thumbnailTimeChanged:)
			name:kSynopsisInspectorThumnailImageChangeName
			object:nil];
	}
	return self;
}
- (id) initWithNibName:(NSString *)n bundle:(NSBundle *)b	{
	self = [super initWithNibName:n bundle:b];
	if (self != nil)	{
		[[NSNotificationCenter defaultCenter]
			addObserver:self
			selector:@selector(thumbnailTimeChanged:)
			name:kSynopsisInspectorThumnailImageChangeName
			object:nil];
	}
	return self;
}
- (void) dealloc	{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do view setup here.
    
    self.nameField.layer.zPosition = 1.0;    
}


- (void) thumbnailTimeChanged:(NSNotification *)note	{
	[self asyncSetImage];
}
- (void) prepareForReuse
{
    [super prepareForReuse];

    SynopsisCollectionViewItemView* itemView = (SynopsisCollectionViewItemView*)self.view;
    //itemView.currentTimeFromStart.stringValue = @"";
    //itemView.currentTimeToEnd.stringValue = @"";
    [self setViewImage:nil];

    [itemView setSelected:NO];
//    [itemView beginOptimizeForScrolling];
    
    self.selected = NO;
}

- (void) setSelected:(BOOL)selected
{
    [super setSelected:selected];

    if(selected)
        self.view.layer.zPosition = 3.0;
    else
        self.view.layer.zPosition = 0.0;
    
    [(SynopsisCollectionViewItemView*)self.view setSelected:self.selected];

//    if(self.selected)
//    {
//        [(SynopsisCollectionViewItemView*)self.view setBorderColor:[NSColor grayColor]];
//    }
//    else
//    {
//        [(SynopsisCollectionViewItemView*)self.view setBorderColor:[NSColor clearColor]];
//    }
    
//    [self.view updateLayer];
}

- (void) setRepresentedObject:(SynopsisMetadataItem*)representedObject
{
    [super setRepresentedObject:representedObject];

    if(representedObject)
    {
        // Fire off heavy async operations first
        [self asyncSetImage];
        
        // Grab asset name, or use file name if not
        NSString* representedName = nil;
        
        AVURLAsset* representedAsset = (AVURLAsset*)representedObject.asset;
        NSArray<AVMetadataItem*>* commonMetadata = [AVMetadataItem metadataItemsFromArray:representedAsset.commonMetadata withLocale:[NSLocale currentLocale]];
        commonMetadata = [AVMetadataItem metadataItemsFromArray:commonMetadata filteredByIdentifier:AVMetadataCommonIdentifierTitle];
        if(commonMetadata.count)
        {
            representedName = commonMetadata[0].stringValue;
        }
        else
        {
             representedName = [[representedAsset.URL lastPathComponent] stringByDeletingPathExtension];
        }
        
        self.nameField.stringValue = representedName;
        
        //SynopsisCollectionViewItemView* itemView = (SynopsisCollectionViewItemView*)self.view;
        //itemView.currentTimeFromStart.stringValue = [NSString stringWithFormat:@"%02.f:%02.f:%02.f", 0.0, 0.0, 0.0];
        //Float64 reminaingInSeconds = CMTimeGetSeconds(representedAsset.duration);
        //Float64 reminaingHours = floor(reminaingInSeconds / (60.0 * 60.0));
        //Float64 reminaingMinutes = floor(reminaingInSeconds / 60.0);
        //Float64 reminaingSeconds = fmod(reminaingInSeconds, 60.0);
        //itemView.currentTimeToEnd.stringValue = [NSString stringWithFormat:@"-%02.f:%02.f:%02.f", reminaingHours, reminaingMinutes, reminaingSeconds];
    }
}

- (void) asyncSetImage
{
	//NSLog(@"%s ... %@",__func__,self.representedObject);
	SynopsisMetadataItem		*repObj = self.representedObject;
	CMTime				thumbnailTime = kCMTimeZero;
	ThumbnailFrame		thumbFrame = [PrefsController global].prefsViewController.preferencesGeneralViewController.thumbnailFrame;
	if (thumbFrame != ThumbnailFrame_First)	{
		AVAsset				*asset = repObj.asset;
		CMTime				duration = asset.duration;
		if (thumbFrame == ThumbnailFrame_Ten)	{
			thumbnailTime = CMTimeMakeWithSeconds(CMTimeGetSeconds(duration) * 0.10, duration.timescale);
		}
		else if (thumbFrame == ThumbnailFrame_Fifty)	{
			thumbnailTime = CMTimeMakeWithSeconds(CMTimeGetSeconds(duration) * 0.50, duration.timescale);
		}
	}
	
    [[SynopsisCacheWithHap sharedCache]
    	cachedImageForItem:repObj
    	atTime:thumbnailTime
    	completionHandler:^(CGImageRef _Nullable image, NSError * _Nullable error) {
			dispatch_async(dispatch_get_main_queue(), ^{
                //    if the represented object we're caching an image for is no longer this item's represented object (fast scrolling), bail
                if (repObj != self.representedObject)
                    return;

				if(image)	{
					[self setViewImage:image];
				}
				else
				{
					NSLog(@"null image from cache");
				}
			});
		}];
}

- (void) setViewImage:(CGImageRef)image
{
    SynopsisCollectionViewItemView* view = (SynopsisCollectionViewItemView*)self.view;
    view.imageLayer.contents = (id) CFBridgingRelease(image);
    [view setNeedsDisplay:YES];
}
/*
- (void) setAspectRatio:(NSString*)aspect
{
//    SynopsisCollectionViewItemView* view = (SynopsisCollectionViewItemView*)self.view;
//    [view setAspectRatio:aspect];
}
*/

- (IBAction)revealInFinder:(id)sender
{
    SynopsisMetadataItem* representedObject = self.representedObject;

    AVURLAsset* urlAsset = (AVURLAsset*)representedObject.asset;
    
    NSURL* url = urlAsset.URL;

    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[url]];
}

- (IBAction) contextualBestFitSort:(id)sender	{
	NSCollectionView	*parentView = [self collectionView];
	NSIndexPath			*tmpPath = [parentView indexPathForItem:self];
	[parentView deselectAll:nil];
	NSSet				*tmpSet = [NSSet setWithObject:tmpPath];
	[parentView selectItemsAtIndexPaths:tmpSet scrollPosition:NSCollectionViewScrollPositionTop];
	[[parentView delegate] collectionView:parentView didSelectItemsAtIndexPaths:tmpSet];
	[[AppDelegate global] bestMatchSortUsingSelectedCell:nil];
}
- (IBAction) contextualPredictionSort:(id)sender	{
	NSCollectionView	*parentView = [self collectionView];
	NSIndexPath			*tmpPath = [parentView indexPathForItem:self];
	[parentView deselectAll:nil];
	NSSet				*tmpSet = [NSSet setWithObject:tmpPath];
	[parentView selectItemsAtIndexPaths:tmpSet scrollPosition:NSCollectionViewScrollPositionTop];
	[[parentView delegate] collectionView:parentView didSelectItemsAtIndexPaths:tmpSet];
	[[AppDelegate global] probabilitySortUsingSelectedCell:nil];
}
- (IBAction) contextualFeatureSort:(id)sender	{
	NSCollectionView	*parentView = [self collectionView];
	NSIndexPath			*tmpPath = [parentView indexPathForItem:self];
	[parentView deselectAll:nil];
	NSSet				*tmpSet = [NSSet setWithObject:tmpPath];
	[parentView selectItemsAtIndexPaths:tmpSet scrollPosition:NSCollectionViewScrollPositionTop];
	[[parentView delegate] collectionView:parentView didSelectItemsAtIndexPaths:tmpSet];
	[[AppDelegate global] featureVectorSortUsingSelectedCell:nil];
}
- (IBAction) contextualHistogramSort:(id)sender	{
	NSCollectionView	*parentView = [self collectionView];
	NSIndexPath			*tmpPath = [parentView indexPathForItem:self];
	[parentView deselectAll:nil];
	NSSet				*tmpSet = [NSSet setWithObject:tmpPath];
	[parentView selectItemsAtIndexPaths:tmpSet scrollPosition:NSCollectionViewScrollPositionTop];
	[[parentView delegate] collectionView:parentView didSelectItemsAtIndexPaths:tmpSet];
	[[AppDelegate global] histogramSortUsingSelectingCell:nil];
}

- (NSArray *)draggingImageComponents
{
    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext *oldContext = [NSGraphicsContext currentContext];
    
    //SynopsisMetadataItem* representedObject = self.representedObject;

    // Image itemRootView.
    NSView *itemRootView = self.view;
    NSRect itemBounds = itemRootView.bounds;
    NSBitmapImageRep *bitmap = [itemRootView bitmapImageRepForCachingDisplayInRect:itemBounds];
    bitmap.alpha = YES;
    
    unsigned char *bitmapData = bitmap.bitmapData;
    if (bitmapData) {
        bzero(bitmapData, bitmap.bytesPerRow * bitmap.pixelsHigh);
    }
    
    // Draw our layer into our bitmap
    [itemRootView cacheDisplayInRect:itemBounds toBitmapImageRep:bitmap];

    // Work around SlideCarrierView layer contents not being rendered to bitmap.
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap]];
    // TODO: Fix dragging
//    [representedObject.cachedImage drawInRect:itemBounds fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    
    //[(SynopsisCollectionViewItemView*)self.view playerLayer].hidden = YES;

    NSImage *image = [[NSImage alloc] initWithSize:[bitmap size]];
    [image addRepresentation:bitmap];
    
   // [(SynopsisCollectionViewItemView*)self.view playerLayer].hidden = NO;
    
    NSDraggingImageComponent *component = [[NSDraggingImageComponent alloc] initWithKey:NSDraggingImageComponentIconKey];
    component.frame = itemBounds;
    component.contents = image;
    
    [NSGraphicsContext setCurrentContext:oldContext];
    [NSGraphicsContext restoreGraphicsState];

    return [NSArray arrayWithObject:component];
}



@end
