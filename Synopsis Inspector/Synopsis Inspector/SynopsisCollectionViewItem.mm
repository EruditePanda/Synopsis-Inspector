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
#import "SynopsisMediaCache.h"
#import "HapInAVFoundation.h"

@interface SynopsisCollectionViewItem ()
{
}
// Strong because the Collectionview doesnt have a handle to these seperate xib resources when associating to the CollectionViewItem's view.
@property (strong) IBOutlet MetadataInspectorViewController* inspectorVC;
@property (strong) IBOutlet NSPopover* inspectorPopOver;

@property (weak) IBOutlet NSTextField* nameField;
@property (readwrite) SynopsisMetadataDecoder* metadataDecoder;

@end

@implementation SynopsisCollectionViewItem

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do view setup here.
    
    self.nameField.layer.zPosition = 1.0;
    
    self.metadataDecoder = [[SynopsisMetadataDecoder alloc] initWithVersion:kSynopsisMetadataVersionValue];
}

- (void) prepareForReuse
{
    [super prepareForReuse];

    SynopsisCollectionViewItemView* itemView = (SynopsisCollectionViewItemView*)self.view;
    itemView.currentTimeFromStart.stringValue = @"";
    itemView.currentTimeToEnd.stringValue = @"";

    [itemView setSelected:NO];
    [itemView beginOptimizeForScrolling];
    
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
        NSString* representedName = nil;
        
        AVURLAsset* representedAsset = representedObject.urlAsset;
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
        
        NSDictionary* globalMetadata = nil;
        
        NSArray* metadataItems = representedAsset.metadata;
        for(AVMetadataItem* metadataItem in metadataItems)
        {
            globalMetadata = [self.metadataDecoder decodeSynopsisMetadata:metadataItem];
            if(globalMetadata)
                break;
        }
        
        SynopsisCollectionViewItemView* itemView = (SynopsisCollectionViewItemView*)self.view;
        itemView.currentTimeFromStart.stringValue = [NSString stringWithFormat:@"%02.f:%02.f:%02.f", 0.0, 0.0, 0.0];
        
        Float64 reminaingInSeconds = CMTimeGetSeconds(representedAsset.duration);
        Float64 reminaingHours = floor(reminaingInSeconds / (60.0 * 60.0));
        Float64 reminaingMinutes = floor(reminaingInSeconds / 60.0);
        Float64 reminaingSeconds = fmod(reminaingInSeconds, 60.0);
        
        itemView.currentTimeToEnd.stringValue = [NSString stringWithFormat:@"-%02.f:%02.f:%02.f", reminaingHours, reminaingMinutes, reminaingSeconds];
        
//        [itemView.currentTimeFromStart sizeToFit];
//        [itemView.currentTimeToEnd sizeToFit];

        self.inspectorVC.globalMetadata = globalMetadata;
        self.nameField.stringValue = representedName;
//        [self.nameField sizeToFit];
        
        CGImageRef cachedImage = [[SynopsisMediaCache sharedMediaCache] cachedImageForMetadataItem:representedObject];
        if(cachedImage)
        {
            [self setViewImage:cachedImage];
        }
        else
        {
            SynopsisCollectionViewItemView* view = (SynopsisCollectionViewItemView*)self.view;
            view.imageLayer.contents = nil;

            [self beginOptimizeForScolling];
            
            [[SynopsisMediaCache sharedMediaCache] generateAndCacheStillImageAsynchronouslyForAsset:representedObject completionHandler:^(CGImageRef  _Nullable image, NSError * _Nullable error)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(image)
                        [self setViewImage:image];
                });
            }];
        }
    }
}

- (void) setViewImage:(CGImageRef)image
{
    SynopsisCollectionViewItemView* view = (SynopsisCollectionViewItemView*)self.view;
    view.imageLayer.contents = (id)CFBridgingRelease(image);
}

- (void) setAspectRatio:(NSString*)aspect
{
    SynopsisCollectionViewItemView* view = (SynopsisCollectionViewItemView*)self.view;
    [view setAspectRatio:aspect];
}

- (void) beginOptimizeForScolling
{
    SynopsisCollectionViewItemView* view = (SynopsisCollectionViewItemView*)self.view;
    [view.playerLayer.player pause];
}

- (void) endOptimizeForScrolling
{
    SynopsisMetadataItem* representedObject = self.representedObject;
    SynopsisCollectionViewItemView* view = (SynopsisCollectionViewItemView*)self.view;

    if(view.playerLayer.player.currentItem.asset != representedObject.urlAsset)
    {
//        NSLog(@"Replace Player Item");
//        
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:view.playerLayer.player.currentItem];
        
//        AVPlayerItem* item = [[SynopsisInspectorMediaCache sharedMediaCache] cachedPlayerItemForMetadataItem:representedObject];
//        if(item)
//        {
//            if(item.outputs.count)
//            {
//                AVPlayerItemMetadataOutput* metadataOutput = (AVPlayerItemMetadataOutput*)[item.outputs firstObject];
//                [metadataOutput setDelegate:self queue:self.backgroundQueue];
//            }
//            
//            [view.playerLayer.player replaceCurrentItemWithPlayerItem:item];
//            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loopPlayback:) name:AVPlayerItemDidPlayToEndTimeNotification object:view.playerLayer.player.currentItem];
//
//            [view endOptimizeForScrolling];
//        }
//        else
        {
            BOOL containsHap = [representedObject.urlAsset containsHapVideoTrack];
            
            [[SynopsisMediaCache sharedMediaCache] generatePlayerItemAsynchronouslyForAsset:representedObject completionHandler:^(AVPlayerItem * _Nullable item, NSError * _Nullable error) {
               
                if(item)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if(item.outputs.count)
                        {
                            AVPlayerItemMetadataOutput* metadataOutput = (AVPlayerItemMetadataOutput*)[item.outputs firstObject];
                            [metadataOutput setDelegate:self queue:[SynopsisMediaCache sharedMediaCache].metadataQueue];
                        }
                        
                        if(containsHap)
                        {
                            [view.playerLayer replacePlayerItemWithHAPItem:item];
                        }
                        else
                        {
                            [view.playerLayer replacePlayerItemWithItem:item];
                        }
                        
                        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loopPlayback:) name:AVPlayerItemDidPlayToEndTimeNotification object:view.playerLayer.player.currentItem];
                        
                        [view endOptimizeForScrolling];
                    });
                }
            }];
        }
    }
    
    else
    {
        [view endOptimizeForScrolling];
    }
}

- (void) loopPlayback:(NSNotification*)notification
{
    SynopsisCollectionViewItemView* view = (SynopsisCollectionViewItemView*)self.view;

    [view.playerLayer.player seekToTime:kCMTimeZero];
    [view.playerLayer.player play];
}

- (IBAction)revealInFinder:(id)sender
{
    SynopsisMetadataItem* representedObject = self.representedObject;

    NSURL* url = representedObject.urlAsset.URL;

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

#pragma mark - AVPlayerItemMetadataOutputPushDelegate

- (void)metadataOutput:(AVPlayerItemMetadataOutput *)output didOutputTimedMetadataGroups:(NSArray *)groups fromPlayerItemTrack:(AVPlayerItemTrack *)track
{
    NSMutableDictionary* metadataDictionary = [NSMutableDictionary dictionary];
    
    for(AVTimedMetadataGroup* group in groups)
    {
        for(AVMetadataItem* metadataItem in group.items)
        {
            NSString* key = metadataItem.identifier;
            
            id decodedJSON = [self.metadataDecoder decodeSynopsisMetadata:metadataItem];
            if(decodedJSON)
            {
                [metadataDictionary setObject:decodedJSON forKey:key];
            }
            else
            {
                id value = metadataItem.value;
                [metadataDictionary setObject:value forKey:key];
            }            
        }
    }
    
    if(self.inspectorVC)
    {
        [self.inspectorVC setFrameMetadata:metadataDictionary];
    }
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
