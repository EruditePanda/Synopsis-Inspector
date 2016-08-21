//
//  SynopsisResultItem.m
//  Synopslight
//
//  Created by vade on 7/26/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import "SynopsisCollectionViewItem.h"
#import <AVFoundation/AVFoundation.h>
#import "SynopsisMetadataItem.h"
#import "SynopsisCollectionViewItemView.h"
#import "CGLayerView.h"
#import "GZIP/GZIP.h"

@interface SynopsisCollectionViewItem ()
{
}
@property (strong) IBOutlet NSWindow* inspectorWindow;
@property (weak) IBOutlet NSTextField* nameField;
@property (readwrite) AVPlayer* player;
@property (readwrite) AVPlayerItem* playerItem;
@property (readwrite) AVPlayerItemMetadataOutput* playerItemMetadataOutput;
@end

@implementation SynopsisCollectionViewItem


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    self.player = [[AVPlayer alloc] init];
    self.nameField.layer.zPosition = 1.0;
    
   self.playerItemMetadataOutput = [[AVPlayerItemMetadataOutput alloc] initWithIdentifiers:nil];
    [self.playerItemMetadataOutput setDelegate:self queue:dispatch_get_global_queue(DISPATCH_QUEUE_SERIAL, 0)];
    
}

- (void) prepareForReuse
{
    [super prepareForReuse];

    [(SynopsisCollectionViewItemView*)self.view setBorderColor:nil];
    self.selected = NO;
    
    [self.player pause];
    [(SynopsisCollectionViewItemView*)self.view playerLayer].player = nil;
    [(SynopsisCollectionViewItemView*)self.view playerLayer].opacity = 0.0;
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
        NSString* representedName = [representedObject valueForAttribute:(NSString*)kMDItemFSName];
        
        self.nameField.stringValue = representedName;
        
        if(representedObject.cachedImage == NULL)
        {
            AVAssetImageGenerator* imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:representedObject.urlAsset];
            
            imageGenerator.apertureMode = AVAssetImageGeneratorApertureModeCleanAperture;
            imageGenerator.maximumSize = CGSizeMake(400, 200);
            imageGenerator.appliesPreferredTrackTransform = YES;

            [imageGenerator generateCGImagesAsynchronouslyForTimes:@[ [NSValue valueWithCMTime:kCMTimeZero]] completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
                [self buildImageForRepresentedObject:image];
            }];
            
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
        NSImage* nsImage = [[NSImage alloc] initWithCGImage:image size:NSZeroSize];
        representedObject.cachedImage = nsImage;

        dispatch_async(dispatch_get_main_queue(), ^(){
            
            [self setViewImage];
        });
    }
}

- (void) setViewImage
{
    SynopsisMetadataItem* representedObject = self.representedObject;
    SynopsisCollectionViewItemView* view = (SynopsisCollectionViewItemView*)self.view;
    view.imageLayer.contents = representedObject.cachedImage;
}

- (void) beginOptimizeForScolling
{
    [self.player pause];
}

- (void) endOptimizeForScrolling
{
    if(self.playerItem)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
    }
    
    SynopsisMetadataItem* representedObject = self.representedObject;
    if([(SynopsisCollectionViewItemView*)self.view playerLayer].player != self.player)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            
            self.playerItem = [AVPlayerItem playerItemWithAsset:representedObject.urlAsset];

            [[self.player currentItem] removeOutput:self.playerItemMetadataOutput];
            [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
            [[self.player currentItem] addOutput:self.playerItemMetadataOutput];

            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loopPlayback:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
                [(SynopsisCollectionViewItemView*)self.view playerLayer].player = self.player;
                [(SynopsisCollectionViewItemView*)self.view playerLayer].opacity = 1.0;
            });
            
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
    [representedObject.cachedImage drawInRect:itemBounds fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    
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

const NSString* kSynopsislMetadataIdentifier = @"mdta/info.v002.synopsis.metadata";

- (void)metadataOutput:(AVPlayerItemMetadataOutput *)output didOutputTimedMetadataGroups:(NSArray *)groups fromPlayerItemTrack:(AVPlayerItemTrack *)track
{
    NSMutableDictionary* metadataDictionary = [NSMutableDictionary dictionary];
    
    for(AVTimedMetadataGroup* group in groups)
    {
        for(AVMetadataItem* metadataItem in group.items)
        {
            NSString* key = metadataItem.identifier;
            
            id decodedJSON = [self decodeSynopsisMetadata:metadataItem];
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
    
//    self.latestMetadataDictionary = metadataDictionary;
}


- (id) decodeSynopsisMetadata:(AVMetadataItem*)metadataItem
{
    NSString* key = metadataItem.identifier;
    
    if([key isEqualToString:kSynopsislMetadataIdentifier])
    {
        // JSON
        //                // Decode our metadata..
        //                NSString* stringValue = (NSString*)metadataItem.value;
        //                NSData* dataValue = [stringValue dataUsingEncoding:NSUTF8StringEncoding];
        //                id decodedJSON = [NSJSONSerialization JSONObjectWithData:dataValue options:kNilOptions error:nil];
        //                if(decodedJSON)
        //                    [metadataDictionary setObject:decodedJSON forKey:key];
        
        //                // BSON:
        //                NSData* zipped = (NSData*)metadataItem.value;
        //                NSData* bsonData = [zipped gunzippedData];
        //                NSDictionary* bsonDict = [NSDictionary dictionaryWithBSON:bsonData];
        //                if(bsonDict)
        //                    [metadataDictionary setObject:bsonDict forKey:key];
        
        // GZIP + JSON
        NSData* zipped = (NSData*)metadataItem.value;
        NSData* json = [zipped gunzippedData];
        id decodedJSON = [NSJSONSerialization JSONObjectWithData:json options:kNilOptions error:nil];
        if(decodedJSON)
        {
            return decodedJSON;
        }
        
        return nil;
    }
    
    return nil;
}

@end
