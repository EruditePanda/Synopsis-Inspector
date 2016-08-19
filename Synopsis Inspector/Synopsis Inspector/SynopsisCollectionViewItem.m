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

@interface SynopsisCollectionViewItem ()
{
}
@property (weak) IBOutlet NSTextField* nameField;
@property (readwrite) AVPlayer* itemPlayer;
@end

@implementation SynopsisCollectionViewItem

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    self.itemPlayer = [[AVPlayer alloc] init];
    self.nameField.layer.zPosition = 1.0;
}

- (void) prepareForReuse
{
    [super prepareForReuse];

    [(SynopsisCollectionViewItemView*)self.view setBorderColor:nil];
    self.selected = NO;
    
    [self.itemPlayer pause];
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
        NSString* representedName = [representedObject valueForAttribute:(NSString*)kMDItemDisplayName];
        
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
    [self.itemPlayer pause];
}

- (void) endOptimizeForScrolling
{
    SynopsisMetadataItem* representedObject = self.representedObject;
    if([(SynopsisCollectionViewItemView*)self.view playerLayer].player != self.itemPlayer)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            
            AVPlayerItem* playerItem = [AVPlayerItem playerItemWithAsset:representedObject.urlAsset];
            [self.itemPlayer replaceCurrentItemWithPlayerItem:playerItem];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [(SynopsisCollectionViewItemView*)self.view playerLayer].player = self.itemPlayer;
                [(SynopsisCollectionViewItemView*)self.view playerLayer].opacity = 1.0;
            });
            
        });
    }
}


@end
