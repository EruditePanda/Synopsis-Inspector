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
@end

@implementation SynopsisCollectionViewItem

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (void) prepareForReuse
{
    [super prepareForReuse];

    [(SynopsisCollectionViewItemView*)self.view setBorderColor:nil];
    self.selected = NO;
}

- (void) setSelected:(BOOL)selected
{
    [super setSelected:selected];
    
    if(self.selected)
    {
        [(SynopsisCollectionViewItemView*)self.view setBorderColor:[NSColor lightGrayColor]];
    }
    else
    {
        [(SynopsisCollectionViewItemView*)self.view setBorderColor:nil];
    }
    
    [self.view updateLayer];
}

- (void) setRepresentedObject:(SynopsisMetadataItem*)representedObject
{
//    NSAssert([representedObject isKindOfClass:[SynopsisMetadataItem class]], @"Only support SynopsisMetadataItems or NSMetadataItems");
    
    [super setRepresentedObject:representedObject];
    
    if(self.representedObject)
    {
        
        NSString* representedName = [self.representedObject valueForAttribute:(NSString*)kMDItemDisplayName];
        
        self.nameField.stringValue = representedName;
        
        SynopsisMetadataItem* representedObject = self.representedObject;
        
        if(representedObject.cachedImage == NULL)
        {
            AVAssetImageGenerator* imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:representedObject.urlAsset];
            
            imageGenerator.maximumSize = CGSizeMake(480, 320);
            imageGenerator.appliesPreferredTrackTransform = YES;
            

            [imageGenerator generateCGImagesAsynchronouslyForTimes:@[ [NSValue valueWithCMTime:kCMTimeZero]] completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
                [self buildImageForRepresentedObject:image];
            }];
            
        }
        else
        {
            self.view.layer.contents = representedObject.cachedImage;
        }
    }
}

- (void) buildImageForRepresentedObject:(CGImageRef)image
{
    SynopsisMetadataItem* representedObject = self.representedObject;

    if(image != NULL)
    {
        NSImage* nsImage = [[NSImage alloc] initWithCGImage:image size:NSZeroSize];
        
        dispatch_async(dispatch_get_main_queue(), ^(){
            representedObject.cachedImage = nsImage;
            self.view.layer.contents = representedObject.cachedImage;
        });
    }

}

@end
