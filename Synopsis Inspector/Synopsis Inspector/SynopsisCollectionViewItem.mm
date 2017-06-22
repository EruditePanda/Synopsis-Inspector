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

@interface SynopsisCollectionViewItem ()
{
}
// Strong because the Collectionview doesnt have a handle to these seperate xib resources when associating to the CollectionViewItem's view.
@property (strong) IBOutlet MetadataInspectorViewController* inspectorVC;
@property (strong) IBOutlet NSPopover* inspectorPopOver;

@property (weak) IBOutlet NSTextField* nameField;
@property (readwrite) AVPlayer* player;
@property (readwrite) AVPlayerItem* playerItem;
@property (readwrite) AVPlayerItemMetadataOutput* playerItemMetadataOutput;
@property (readwrite) SynopsisMetadataDecoder* metadataDecoder;
@property (readwrite) dispatch_queue_t backgroundQueue;

@end

@implementation SynopsisCollectionViewItem

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do view setup here.
    
    self.player = [[AVPlayer alloc] init];
    self.nameField.layer.zPosition = 1.0;
    
    self.playerItemMetadataOutput = [[AVPlayerItemMetadataOutput alloc] initWithIdentifiers:nil];
    
    self.backgroundQueue = dispatch_queue_create("info.synopsis.collectionviewitem.backgroundqueue", NULL);

    __weak typeof(self) weakSelf = self; // no retain loop
    [self.playerItemMetadataOutput setDelegate:weakSelf queue:weakSelf.backgroundQueue];
}

- (void) prepareForReuse
{
    [super prepareForReuse];

    [(SynopsisCollectionViewItemView*)self.view setBorderColor:nil];
    
    [self.player pause];
    [(SynopsisCollectionViewItemView*)self.view playerLayer].player = nil;
    [(SynopsisCollectionViewItemView*)self.view playerLayer].opacity = 0.0;
    
    self.selected = NO;
}

- (void) setSelected:(BOOL)selected
{
    [super setSelected:selected];
    
    if(self.selected)
    {
        [(SynopsisCollectionViewItemView*)self.view setBorderColor:[NSColor selectedControlColor]];
    }
    else
    {
        [(SynopsisCollectionViewItemView*)self.view setBorderColor:nil];
    }
    
    [self.view updateLayer];
}

- (void) setRepresentedObject:(SynopsisMetadataItem*)representedObject
{
    [super setRepresentedObject:representedObject];

    if(representedObject)
    {
//        NSString* representedName = [representedObject valueForAttribute:(NSString*)kMDItemFSName];
        
        NSDictionary* globalMetadata = nil;
        
        NSArray* metadataItems = representedObject.urlAsset.metadata;
        for(AVMetadataItem* metadataItem in metadataItems)
        {
            globalMetadata = [self.metadataDecoder decodeSynopsisMetadata:metadataItem];
            if(globalMetadata)
                break;
        }
        
        self.inspectorVC.globalMetadata = globalMetadata;
//        self.nameField.stringValue = representedName;
        
        if(representedObject.cachedImage == NULL)
        {
            SynopsisCollectionViewItemView* view = (SynopsisCollectionViewItemView*)self.view;

            view.imageLayer.contents = nil;
            view.playerLayer.player = nil;
            
            __weak typeof (self) weakself = self;
            dispatch_async(self.backgroundQueue, ^{

                if(weakself)
                {
                    __strong typeof (self) strongSelf = weakself;

                    AVAssetImageGenerator* imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:representedObject.urlAsset];
                    
                    imageGenerator.apertureMode = AVAssetImageGeneratorApertureModeCleanAperture;
                    imageGenerator.maximumSize = CGSizeMake(300, 300);
                    imageGenerator.appliesPreferredTrackTransform = YES;
                    
                    [imageGenerator generateCGImagesAsynchronouslyForTimes:@[ [NSValue valueWithCMTime:kCMTimeZero]] completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
                        [strongSelf buildImageForRepresentedObject:image];
                    }];
                }
            });
        }
        else
        {
            [self setViewImage];
        }
    }
}

- (void) buildImageForRepresentedObject:(CGImageRef)image
{
    if(image != NULL)
    {
        SynopsisMetadataItem* representedObject = self.representedObject;
        representedObject.cachedImage = image;

        dispatch_async(dispatch_get_main_queue(), ^(){
            
            [self setViewImage];
        });
    }
}

- (void) setViewImage
{
    SynopsisMetadataItem* representedObject = self.representedObject;
    SynopsisCollectionViewItemView* view = (SynopsisCollectionViewItemView*)self.view;
    view.imageLayer.contents = (id)representedObject.cachedImage;
}

- (void) beginOptimizeForScolling
{
    [self.player pause];
}

- (void) setAspectRatio:(NSString*)aspect
{
    SynopsisCollectionViewItemView* view = (SynopsisCollectionViewItemView*)self.view;
    [view setAspectRatio:aspect];
}


- (void) endOptimizeForScrolling
{
    SynopsisMetadataItem* representedObject = self.representedObject;
    if([(SynopsisCollectionViewItemView*)self.view playerLayer].player != self.player)
    {
        __weak typeof (self) weakself = self;
        dispatch_async(self.backgroundQueue, ^{
            
            if(weakself)
            {
                __strong typeof (self) strongSelf = weakself;
                
                if(strongSelf.playerItem)
                {
                    //                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] removeObserver:strongSelf name:AVPlayerItemDidPlayToEndTimeNotification object:strongSelf.playerItem];
                    //                });
                }
                
                strongSelf.playerItem = [AVPlayerItem playerItemWithAsset:representedObject.urlAsset];
                [[NSNotificationCenter defaultCenter] addObserver:strongSelf selector:@selector(loopPlayback:) name:AVPlayerItemDidPlayToEndTimeNotification object:strongSelf.playerItem];
                
                [[strongSelf.player currentItem] removeOutput:strongSelf.playerItemMetadataOutput];
                [strongSelf.player replaceCurrentItemWithPlayerItem:strongSelf.playerItem];
                [[strongSelf.player currentItem] addOutput:strongSelf.playerItemMetadataOutput];
                
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [(SynopsisCollectionViewItemView*)strongSelf.view playerLayer].player = strongSelf.player;
                    [(SynopsisCollectionViewItemView*)strongSelf.view playerLayer].opacity = 1.0;
                });
            }
        });
    }
}

- (void) loopPlayback:(NSNotification*)notification
{
    [self.player seekToTime:kCMTimeZero];
    [self.player play];
}

- (IBAction)revealInFinder:(id)sender
{
    NSURL* url = [NSURL fileURLWithPath:[self.representedObject valueForAttribute:(NSString*)kMDItemPath]];

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

#pragma mark - Metadata delete

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
