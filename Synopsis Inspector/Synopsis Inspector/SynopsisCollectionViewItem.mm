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
    [self setViewImage:nil];

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
        // Fire off heavy async operations first
        [self asyncSetImage];
        [self asyncSetGlobalMetadata];
        
        // Grab asset name, or use file name if not
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
    [[SynopsisCache sharedCache] cachedImageForItem:self.representedObject completionHandler:^(id  _Nullable cachedValue, NSError * _Nullable error) {
        NSImage* image = (NSImage*)cachedValue;
        dispatch_async(dispatch_get_main_queue(), ^{
            if(image)
                [self setViewImage:image];
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

- (void) setViewImage:(NSImage*)image
{
    SynopsisCollectionViewItemView* view = (SynopsisCollectionViewItemView*)self.view;
    view.imageLayer.contents = image;
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

    [self asyncSetGlobalMetadata];
    [self asyncSetImage];
    
    if(view.playerLayer.player.currentItem.asset != representedObject.urlAsset)
    {
//        NSLog(@"Replace Player Item");
//        
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:view.playerLayer.player.currentItem];
        
        BOOL containsHap = [representedObject.urlAsset containsHapVideoTrack];

//        AVPlayerItem* item = [[SynopsisMediaCache sharedMediaCache] cachedPlayerItemForMetadataItem:representedObject];
//        if(item)
//        {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                if(item.outputs.count)
//                {
//                    AVPlayerItemMetadataOutput* metadataOutput = (AVPlayerItemMetadataOutput*)[item.outputs firstObject];
//                    [metadataOutput setDelegate:self queue:[SynopsisMediaCache sharedMediaCache].metadataQueue];
//                }
//
//                if(containsHap)
//                {
//                    [view.playerLayer replacePlayerItemWithHAPItem:item];
//                }
//                else
//                {
//                    [view.playerLayer replacePlayerItemWithItem:item];
//                }
//
//                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loopPlayback:) name:AVPlayerItemDidPlayToEndTimeNotification object:view.playerLayer.player.currentItem];
//
//                [view endOptimizeForScrolling];
//            });
//        }
//        else
        {
            
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
