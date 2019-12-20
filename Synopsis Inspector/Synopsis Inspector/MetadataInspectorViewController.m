//
//	MetadataInspectorViewController.m
//	Synopsis Inspector
//
//	Created by vade on 8/22/16.
//	Copyright © 2016 v002. All rights reserved.
//
#import <Synopsis/Synopsis.h>
#import "MetadataInspectorViewController.h"
#import "MetadataDominantColorsView.h"
#import "MetadataHistogramView.h"
#import "MetadataMotionView.h"
#import "MetadataSingleValueHistoryView.h"
#import "MetadataFeatureVectorView.h"
#import "PlayerView.h"
#import "SynopsisCacheWithHap.h"


@interface MetadataInspectorViewController ()

@property (readwrite, strong) NSDictionary* globalMetadata;

@property (readwrite, strong) dispatch_queue_t metadataQueue;

@property (weak) IBOutlet NSCollectionView* collectionView;

@property (weak) IBOutlet NSBox * previewBox;
@property (weak) IBOutlet PlayerView * playerView;
//@property (strong,readwrite) NSLayoutConstraint * previewViewHeightConstraint;

@property (weak) IBOutlet NSTextField* globalDescriptors;
@property (weak) IBOutlet MetadataDominantColorsView* globalDominantColorView;
@property (weak) IBOutlet MetadataHistogramView* globalHistogramView;
@property (weak) IBOutlet MetadataFeatureVectorView* globalFeatureVectorView;
@property (weak) IBOutlet MetadataFeatureVectorView* globalProbabilityView;

@property (weak) IBOutlet MetadataFeatureVectorView* globalDTWFeatureVectorView;
@property (weak) IBOutlet MetadataFeatureVectorView* globalDTWProbabilityView;


@property (weak) IBOutlet MetadataDominantColorsView* dominantColorView;
@property (weak) IBOutlet MetadataHistogramView* histogramView;
@property (weak) IBOutlet MetadataMotionView* motionView;

@property (weak) IBOutlet MetadataFeatureVectorView* featureVectorView;
//@property (weak) IBOutlet MetadataSingleValueHistoryView* featureVectorHistory;
//@property (weak) IBOutlet NSTextField* featureVectorHistoryCurrentValue;
@property (strong) SynopsisDenseFeature* lastFeatureVector;

@property (weak) IBOutlet MetadataFeatureVectorView* probabilityView;


//@property (weak) IBOutlet MetadataSingleValueHistoryView* histogramHistory;
//@property (weak) IBOutlet NSTextField* histogramHistoryCurrentValue;
@property (strong) SynopsisDenseFeature* lastHistogram;

@property (weak) IBOutlet NSTextField* metadataVersionNumber;
@property (weak) IBOutlet NSButton* enableTrackerVisualizer;

@end




@implementation MetadataInspectorViewController


- (void) awakeFromNib	{
	self.metadataQueue = dispatch_queue_create("metadataqueue", DISPATCH_QUEUE_SERIAL);
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidFinishLaunching:) name:NSApplicationDidFinishLaunchingNotification object:nil];
}
- (void) applicationDidFinishLaunching:(NSNotification *)note	{
	//	we need to add these constraints when the app finishes launching because if we add them before the app delegate sets up the other constraints on its UI items, we get an autolayout error.  because apparently the order of constraints matters.
	//self.previewViewHeightConstraint = [self.playerView.heightAnchor constraintEqualToAnchor:self.playerView.widthAnchor multiplier:0.25 constant:0];
	//self.previewViewHeightConstraint.active = true;
}

@synthesize frameMetadata;

- (NSDictionary*) frameMetadata
{
	return frameMetadata;
}

- (void) setFrameMetadata:(NSDictionary *)dictionary
{
	frameMetadata = dictionary;
	
    NSUInteger metadataVersion = myMetadataItem.metadataVersion;

    // Because Per Frame Metadata is vended by our AVPlayerItemMetadataOutput - which outouts all timed metadata
    // method call - we aggregate all metadata into a single dictionary with keys for each metadata identifier
    // This if we may want to support other timed metadata in the future that isnt synopsis metadata
    // Therefore there is an 'additional' key we need to fetch, the kSynopsisMetadataIdentifier
    
    NSDictionary* synopsisMetadata = frameMetadata[kSynopsisMetadataIdentifier];

    NSString* sampleKey = SynopsisKeyForMetadataTypeVersion(SynopsisMetadataTypeSample, metadataVersion);

    NSDictionary* sampleMetadata = [synopsisMetadata valueForKey:sampleKey];
    
	NSArray* domColors = [sampleMetadata valueForKey: SynopsisKeyForMetadataIdentifierVersion(SynopsisMetadataIdentifierVisualDominantColors, metadataVersion)];
//	NSArray* descriptions = [sampleMetadata valueForKey:SynopsisKeyForMetadataIdentifierVersion(SynopsisMetadataIdentifierGlobalVisualDescription, metadataVersion)];

//	NSMutableString* description = [NSMutableString new];
//
//	for(NSString* desc in descriptions)
//	{
//		// Hack to make the description 'key' not have a comma
//		if([desc hasSuffix:@":"])
//		{
//			[description appendString:[desc stringByAppendingString:@" "]];
//		}
//		else
//		{
//			[description appendString:[desc stringByAppendingString:@", "]];
//		}
//	}

	SynopsisDenseFeature* histogram = [sampleMetadata valueForKey: SynopsisKeyForMetadataIdentifierVersion(SynopsisMetadataIdentifierVisualHistogram, metadataVersion) ];

	SynopsisDenseFeature* feature = [sampleMetadata valueForKey: SynopsisKeyForMetadataIdentifierVersion(SynopsisMetadataIdentifierVisualEmbedding, metadataVersion) ];

	SynopsisDenseFeature* probability = [sampleMetadata valueForKey: SynopsisKeyForMetadataIdentifierVersion(SynopsisMetadataIdentifierVisualProbabilities, metadataVersion) ];

	
	float comparedHistograms = 0.0;
	float comparedFeatures = 0.0;
	
	if(self.lastFeatureVector && [self.lastFeatureVector featureCount] && [feature featureCount] && ([self.lastFeatureVector featureCount] == [feature featureCount]))
	{
		//comparedFeatures = compareFeatureVector(self.lastFeatureVector, feature);
		comparedFeatures = compareFeaturesCosineSimilarity(self.lastFeatureVector, feature);
	}
	
	if(self.lastHistogram && histogram)
	{
		comparedHistograms = compareHistogtams(self.lastHistogram, histogram);
	}
	
	self.dominantColorView.dominantColorsArray = domColors;
	self.histogramView.histogram = histogram;
	self.featureVectorView.feature = feature;
	self.probabilityView.feature = probability;

	dispatch_async(dispatch_get_main_queue(), ^{
		
//		  if(self.view.window.isVisible)
		{
			[self.featureVectorView updateLayer];
			[self.probabilityView updateLayer];

			[self.dominantColorView updateLayer];
			[self.histogramView updateLayer];
			
			//[self.featureVectorHistory appendValue:@(comparedFeatures)];
			//[self.featureVectorHistory updateLayer];
			
			//[self.histogramHistory appendValue:@(comparedHistograms)];
			//[self.histogramHistory updateLayer];
			
//			if(description)
//				self.frameDescriptors.stringValue = description;

		}
		//self.featureVectorHistoryCurrentValue.floatValue = comparedFeatures;
		//self.histogramHistoryCurrentValue.floatValue = comparedHistograms;
	});
	
	self.lastFeatureVector = feature;
	self.lastHistogram = histogram;
}

@synthesize metadataItem=myMetadataItem;
- (void) setMetadataItem:(SynopsisMetadataItem *)n	{
	//	update my local metadata item ivar
	myMetadataItem = n;
	
	//	get the actual metadata for the passed metadata item
	[[SynopsisCacheWithHap sharedCache] cachedGlobalMetadataForItem:n completionHandler:^(id	 _Nullable cachedValue, NSError * _Nullable error) {
        NSLog(@"Pointer to cachedValue: %p", cachedValue);
        self.globalMetadata = cachedValue;
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[self refresh];
			
			// Set up our video player to the currently selected item
	
			//	DO NOT use this 'loadAsset' method- if you do, the UI won't update to display the metadata
			//[self.playerView loadAsset:n.asset];
	
			//NSArray				*vidTracks = [n.asset tracksWithMediaType:AVMediaTypeVideo];
			//AVAssetTrack		*vidTrack = (vidTracks==nil || vidTracks.count<1) ? nil : [vidTracks objectAtIndex:0];
			//CGSize				tmpSize = (vidTrack==nil) ? CGSizeMake(1,1) : [vidTrack naturalSize];
			//if (self.previewViewHeightConstraint != nil)	{
			//	[self.playerView removeConstraint:self.previewViewHeightConstraint];
			//	self.previewViewHeightConstraint = nil;
			//	self.previewViewHeightConstraint = [self.playerView.heightAnchor constraintEqualToAnchor:self.playerView.widthAnchor multiplier:tmpSize.height/tmpSize.width constant:0];
			//	self.previewViewHeightConstraint.active = true;
			//}
	
	
	
			if(self.playerView.playerLayer.player.currentItem.asset != n.asset)
			{
				BOOL containsHap = [n.asset containsHapVideoTrack];
		
				AVPlayerItem* item = [AVPlayerItem playerItemWithAsset:n.asset];
		
				AVPlayerItemMetadataOutput* metadataOut = [[AVPlayerItemMetadataOutput alloc] initWithIdentifiers:nil];
				metadataOut.suppressesPlayerRendering = YES;
				[item addOutput:metadataOut];
		
				if(!containsHap)
				{
					NSDictionary* videoOutputSettings = @{(NSString*)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA),
														  (NSString*)kCVPixelBufferIOSurfacePropertiesKey : @{},
														  //											  (NSString*)kCVPixelBufferIOSurfaceOpenGLFBOCompatibilityKey :@(YES),
														  //											  (NSString*)kCVPixelBufferIOSurfaceOpenGLTextureCompatibilityKey :@(YES),
														  };
			
					AVPlayerItemVideoOutput* videoOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:videoOutputSettings];
					videoOutput.suppressesPlayerRendering = YES;
					[item addOutput:videoOutput];
					
					AVAssetTrack		*vidTrack = [[n.asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
					self.playerView.resolution = (vidTrack==nil) ? NSMakeSize(16.,9.) : NSSizeFromCGSize([vidTrack naturalSize]);
				}
				else
				{
					AVAssetTrack* hapAssetTrack = [[n.asset hapVideoTracks] firstObject];
					AVPlayerItemHapDXTOutput* hapOutput = [[AVPlayerItemHapDXTOutput alloc] initWithHapAssetTrack:hapAssetTrack];
					hapOutput.suppressesPlayerRendering = YES;
					hapOutput.outputAsRGB = NO;
			
					[item addOutput:hapOutput];
					
					self.playerView.resolution = (hapAssetTrack==nil) ? NSMakeSize(16.,9.) : NSSizeFromCGSize([hapAssetTrack naturalSize]);
				}
				[self.playerView updateLayer];
		
				if(item)
				{
		//			  dispatch_async(dispatch_get_main_queue(), ^{
						if(item.outputs.count)
						{
							AVPlayerItemMetadataOutput* metadataOutput = (AVPlayerItemMetadataOutput*)[item.outputs firstObject];
							[metadataOutput setDelegate:self queue:self.metadataQueue];
						}
				
						if(containsHap)
						{
							[self.playerView.playerLayer replacePlayerItemWithHAPItem:item];
						}
						else
						{
							[self.playerView.playerLayer replacePlayerItemWithItem:item];
						}
				
						[self.playerView seekToTime:kCMTimeZero];
				
		//			  });
				}
   
			}
		});
	}];
}
- (SynopsisMetadataItem *) metadataItem	{
	return myMetadataItem;
}
/*
- (NSDictionary*) globalMetadata
{
	return globalMetadata;
}

- (void) setGlobalMetadata:(NSDictionary *)dictionary
{
}
*/

- (void) refresh	{
	
	NSUInteger metadataVersion = myMetadataItem.metadataVersion;
    
    NSString* globalKey = SynopsisKeyForMetadataTypeVersion(SynopsisMetadataTypeGlobal, metadataVersion);
    
    NSDictionary* global = [self.globalMetadata valueForKey:globalKey];
    
    NSArray* domColors = [global valueForKey: SynopsisKeyForMetadataIdentifierVersion(SynopsisMetadataIdentifierVisualDominantColors, metadataVersion)  ];
    NSArray* descriptions = [global valueForKey: SynopsisKeyForMetadataIdentifierVersion(SynopsisMetadataIdentifierGlobalVisualDescription, metadataVersion) ];
	SynopsisDenseFeature* probability = [global valueForKey:SynopsisKeyForMetadataIdentifierVersion(SynopsisMetadataIdentifierVisualProbabilities, metadataVersion)];
	SynopsisDenseFeature* feature = [global valueForKey:SynopsisKeyForMetadataIdentifierVersion(SynopsisMetadataIdentifierVisualEmbedding, metadataVersion)];
	SynopsisDenseFeature* histogram = [global valueForKey:SynopsisKeyForMetadataIdentifierVersion(SynopsisMetadataIdentifierVisualHistogram, metadataVersion)];

    SynopsisDenseFeature* dtwFeature = [global valueForKey:SynopsisKeyForMetadataIdentifierVersion(SynopsisMetadataIdentifierTimeSeriesVisualEmbedding, metadataVersion)];
    SynopsisDenseFeature* dtwProbability = [global valueForKey:SynopsisKeyForMetadataIdentifierVersion(SynopsisMetadataIdentifierTimeSeriesVisualProbabilities, metadataVersion)];

	NSMutableString* description = [NSMutableString new];
	
	for(NSString* desc in descriptions)
	{
		// Hack to make the description 'key' not have a comma
		if([desc hasSuffix:@":"])
		{
			[description appendString:[desc stringByAppendingString:@" "]];
		}
		else
		{
			[description appendString:[desc stringByAppendingString:@", "]];
		}
	}

	self.globalDominantColorView.dominantColorsArray = domColors;
	self.globalHistogramView.histogram = histogram;
	self.globalFeatureVectorView.feature = feature;
	self.globalProbabilityView.feature = probability;

    self.globalDTWFeatureVectorView.feature = dtwFeature;
    self.globalDTWProbabilityView.feature = dtwProbability;

	dispatch_async(dispatch_get_main_queue(), ^{
		
		if(description)
			self.globalDescriptors.stringValue = description;
		
		self.metadataVersionNumber.stringValue = [NSString stringWithFormat:@"Metadata Version: %lu", (unsigned long)metadataVersion];
		
		[self.globalDominantColorView updateLayer];
		[self.globalHistogramView updateLayer];
		[self.globalFeatureVectorView updateLayer];
		[self.globalProbabilityView updateLayer];
        [self.globalDTWFeatureVectorView updateLayer];
        [self.globalDTWProbabilityView updateLayer];
	});
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
            
            if ([key isEqualToString:kSynopsisMetadataIdentifier])
            {
                id metadata = [myMetadataItem.decoder decodeSynopsisMetadata:metadataItem];
                if(metadata)
                {
                    // Force the key to be kSynopsisMetadataIdentifier since version info handles variants
                    [metadataDictionary setObject:metadata forKey:kSynopsisMetadataIdentifier];
                }
            }
            else
            {
                id value = metadataItem.value;
                [metadataDictionary setObject:value forKey:key];
            }
        }
    }
    
    
    
    if(self && metadataDictionary)
    {
        [self setFrameMetadata:metadataDictionary];
    }
}


@end
