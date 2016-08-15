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
@property (weak) IBOutlet CGLayerView* previewImageItem;
@property (weak) IBOutlet NSImageView* previewImageView;
@property (weak) IBOutlet NSTextField* nameField;
@property (weak) IBOutlet NSTextField* hashField;
@end

@implementation SynopsisCollectionViewItem

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
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
            
//            CGImageRef image = [imageGenerator copyCGImageAtTime:kCMTimeZero actualTime:NULL error:nil];
            //            [self buildImageForRepresentedObject:image];

            [imageGenerator generateCGImagesAsynchronouslyForTimes:@[ [NSValue valueWithCMTime:kCMTimeZero]] completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
                [self buildImageForRepresentedObject:image];
            }];
            
        }
        else
        {
            self.previewImageView.image = representedObject.cachedImage;

//            [self.previewImageItem setCGlayer:representedObject.cachedLayerRef];
        }
    }
}

- (void) buildImageForRepresentedObject:(CGImageRef)image
{
    SynopsisMetadataItem* representedObject = self.representedObject;

    //            if(image != NULL)
    //            {
    //                NSSize imageSize = (NSSize){CGImageGetWidth(image) , CGImageGetHeight(image)};
    //                CGRect imageRect = CGRectMake(0, 0, imageSize.width, imageSize.height);
    //
    //                CGImageRetain(image);
    //
    //                CGLayerRef imageLayerRef = CGLayerCreateWithContext(self.graphicsContext.CGContext, imageSize, NULL);
    //
    //                CGContextRef imageLayerContext = CGLayerGetContext(imageLayerRef);
    //
    //                CGContextSaveGState(imageLayerContext);
    //
    //                CGContextSetFillColorSpace(imageLayerContext, CGColorSpaceCreateDeviceRGB());
    //
    //                CGContextSetBlendMode(imageLayerContext, kCGBlendModeCopy);
    //
    //                CGContextDrawImage(imageLayerContext, imageRect, image);
    //
    //                CGContextFlush(imageLayerContext);
    //                CGContextRestoreGState(imageLayerContext);
    //
    //                [self.representedObject setCachedLayerRef:imageLayerRef];
    //                [self.previewImageItem setCGlayer:imageLayerRef];
    //
    //                CGLayerRelease(imageLayerRef);
    //                CGImageRelease(image);
    //            }
    if(image != NULL)
    {
        NSImage* nsImage = [[NSImage alloc] initWithCGImage:image size:NSZeroSize];
        
        dispatch_async(dispatch_get_main_queue(), ^(){
            representedObject.cachedImage = nsImage;
            self.previewImageView.image = nsImage;
        });
    }

}

@end
