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
#import "MetadataInspectorViewController.h"
//#import "SynopsisMediaCache.h"
#import "HapInAVFoundation.h"

@interface SynopsisCollectionViewItem ()
{
}
// Strong because the Collectionview doesnt have a handle to these seperate xib resources when associating to the CollectionViewItem's view.
@property (strong) IBOutlet MetadataInspectorViewController* inspectorVC;
@property (strong) IBOutlet NSPopover* inspectorPopOver;

@property (weak) IBOutlet NSTextField* nameField;

@end

@implementation SynopsisCollectionViewItem

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do view setup here.
    
    self.nameField.layer.zPosition = 1.0;    
}

- (void) prepareForReuse
{
    [super prepareForReuse];

    SynopsisCollectionViewItemView* itemView = (SynopsisCollectionViewItemView*)self.view;
    itemView.currentTimeFromStart.stringValue = @"";
    itemView.currentTimeToEnd.stringValue = @"";
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
        [self asyncSetGlobalMetadata];
        
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
        
        SynopsisCollectionViewItemView* itemView = (SynopsisCollectionViewItemView*)self.view;
        itemView.currentTimeFromStart.stringValue = [NSString stringWithFormat:@"%02.f:%02.f:%02.f", 0.0, 0.0, 0.0];
        
        Float64 reminaingInSeconds = CMTimeGetSeconds(representedAsset.duration);
        Float64 reminaingHours = floor(reminaingInSeconds / (60.0 * 60.0));
        Float64 reminaingMinutes = floor(reminaingInSeconds / 60.0);
        Float64 reminaingSeconds = fmod(reminaingInSeconds, 60.0);
        
        itemView.currentTimeToEnd.stringValue = [NSString stringWithFormat:@"-%02.f:%02.f:%02.f", reminaingHours, reminaingMinutes, reminaingSeconds];
    }
}

- (void) asyncSetImage
{
    [[SynopsisCache sharedCache] cachedImageForItem:self.representedObject atTime:kCMTimeZero completionHandler:^(CGImageRef _Nullable image, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if(image)
                [self setViewImage:image];
            else
            {
                NSLog(@"null image from cache");
            }
        });
    }];
}

- (void) asyncSetGlobalMetadata
{
    // Cache and decode metadata in a background queue
    [[SynopsisCache sharedCache] cachedGlobalMetadataForItem:self.representedObject completionHandler:^(id  _Nullable cachedValue, NSError * _Nullable error) {
        
        NSDictionary* globalMetadata = (NSDictionary*)cachedValue;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.inspectorVC.globalMetadata = globalMetadata;
        });
    }];
}

- (void) setViewImage:(CGImageRef)image
{
    SynopsisCollectionViewItemView* view = (SynopsisCollectionViewItemView*)self.view;
    view.imageLayer.contents = (id) CFBridgingRelease(image);
}

- (void) setAspectRatio:(NSString*)aspect
{
//    SynopsisCollectionViewItemView* view = (SynopsisCollectionViewItemView*)self.view;
//    [view setAspectRatio:aspect];
}


- (IBAction)revealInFinder:(id)sender
{
    SynopsisMetadataItem* representedObject = self.representedObject;

    AVURLAsset* urlAsset = (AVURLAsset*)representedObject.asset;
    
    NSURL* url = urlAsset.URL;

    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[url]];
}

- (NSArray *)draggingImageComponents
{
    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext *oldContext = [NSGraphicsContext currentContext];
    
    SynopsisMetadataItem* representedObject = self.representedObject;

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


#pragma mark - PopOver

- (BOOL) isShowingPopOver
{
    return self.inspectorPopOver.shown;
}

- (IBAction)showPopOver:(id)sender
{
    [self.inspectorPopOver showRelativeToRect:[self.view bounds] ofView:self.view preferredEdge:NSRectEdgeMinY];
}

- (IBAction)hidePopOver:(id)sender
{
    [self.inspectorPopOver performClose:self];
}


@end
