//
//	DataController.m
//	Synopsis Inspector
//
//	Created by testAdmin on 11/27/19.
//	Copyright © 2019 v002. All rights reserved.
//

#import "DataController.h"

#import "AppDelegate.h"

#import "AAPLWrappedLayout.h"
#import "PlayerView.h"
#import "TSNELayout.h"
#import "DBScanLayout.h"
#import "MetadataInspectorViewController.h"
#import "SynopsisCacheWithHap.h"
#import "SynopsisCollectionViewItem.h"



@interface DataController ()

@property (weak) IBOutlet NSCollectionView* collectionView;

@property (weak) IBOutlet NSSlider* zoomSlider;

//@property (strong) NSArrayController* resultsArrayController;
@property (weak) IBOutlet NSArrayController * resultsArrayController;

// Layout
@property (atomic, readwrite, strong) AAPLWrappedLayout* wrappedLayout;
@property (atomic, readwrite, strong) TSNELayout* tsneHybridLayout;
@property (atomic, readwrite, strong) TSNELayout* tsneFeatureLayout;
@property (atomic, readwrite, strong) TSNELayout* tsneHistogramLayout;
//@property (atomic, readwrite, strong) DBScanLayout* dbscanHybridLayout;
//@property (atomic, readwrite, strong) DBScanLayout* dbscanFeatureLayout;
//@property (atomic, readwrite, strong) DBScanLayout* dbscanHistogramLayout;

@property (weak) IBOutlet NSMenuItem* hybridTSNEMenu;
@property (weak) IBOutlet NSMenuItem* featureTSNEMenu;
@property (weak) IBOutlet NSMenuItem* histogramTSNEMenu;

// Sorting that requires selection of an item to sort relative to:
@property (weak) IBOutlet NSToolbarItem* bestFitSort;
@property (weak) IBOutlet NSToolbarItem* hashSort;
@property (weak) IBOutlet NSToolbarItem* histogramSort;
@property (weak) IBOutlet NSToolbarItem* featureVectorSort;

@property (weak) IBOutlet NSToolbarItem* satSort;
@property (weak) IBOutlet NSToolbarItem* hueSort;
@property (weak) IBOutlet NSToolbarItem* brightSort;

@property (readwrite, strong) IBOutlet MetadataInspectorViewController* metadataInspector;

@property (readwrite, strong) IBOutlet PlayerView* playerView;
@property (strong,readwrite) NSLayoutConstraint * previewViewHeightConstraint;

@property (readwrite) SynopsisMetadataDecoder* metadataDecoder;
@property (readwrite, strong) dispatch_queue_t metadataQueue;


@property (weak) IBOutlet NSTextField* statusField;

- (void) pushZoomSliderValToLayout;

@end




@implementation DataController


- (void) awakeFromNib	{
	self.metadataDecoder = [[SynopsisMetadataDecoder alloc] initWithVersion:kSynopsisMetadataVersionValue];
	self.metadataQueue = dispatch_queue_create("metadataqueue", DISPATCH_QUEUE_SERIAL);
	
	self.collectionView.backgroundColors = @[[NSColor clearColor]];
	
	//	  self.resultsArray = [NSMutableArray new];
	//self.resultsArrayController = [[NSArrayController alloc] initWithContent:[NSMutableArray new]];
	self.resultsArrayController.automaticallyRearrangesObjects = YES;
	
	NSNib* synopsisResultNib = [[NSNib alloc] initWithNibNamed:@"SynopsisCollectionViewItem" bundle:[NSBundle mainBundle]];
	
	[self.collectionView registerNib:synopsisResultNib forItemWithIdentifier:@"SynopsisCollectionViewItem"];
	
	NSAnimationContext.currentContext.duration = 0.5;
	self.wrappedLayout = [[AAPLWrappedLayout alloc] init];
	self.collectionView.animator.collectionViewLayout = self.wrappedLayout;
	
	// Register for the dropped object types we can accept.
	[self.collectionView registerForDraggedTypes:[NSArray arrayWithObject:NSURLPboardType]];
	
	// Enable dragging items from our CollectionView to other applications.
	[self.collectionView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:NO];
	
	[self pushZoomSliderValToLayout];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidFinishLaunching:) name:NSApplicationDidFinishLaunchingNotification object:nil];
}
- (void) applicationDidFinishLaunching:(NSNotification *)note	{
	self.previewViewHeightConstraint = [self.playerView.heightAnchor constraintEqualToAnchor:self.playerView.widthAnchor multiplier:0.25 constant:0];
	self.previewViewHeightConstraint.active = true;
}

- (void) reloadData {
	[self.collectionView reloadData];
}


#pragma mark - Sorting


- (SynopsisMetadataItem*) firstSelectedItem
{
	NSIndexSet *path = [self.collectionView selectionIndexes];
	if(path.firstIndex != NSNotFound)
	{
		SynopsisMetadataItem* item = [[self.resultsArrayController arrangedObjects] objectAtIndex:[path firstIndex]];
		return item;
	}
	return nil;
}

- (void) setupSortUsingSortDescriptor:(NSSortDescriptor*) sortDescriptor selectedItem:(SynopsisMetadataItem*)item
{
	NSArray* before = [self.resultsArrayController.arrangedObjects copy];
	
	self.resultsArrayController.sortDescriptors = @[sortDescriptor];
	
	NSArray* after = [self.resultsArrayController.arrangedObjects copy];
	
	[self.collectionView.animator performBatchUpdates:^{
		
		[before enumerateObjectsUsingBlock:^(id	 _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			
			NSIndexPath* beforePath = [NSIndexPath indexPathForItem:idx inSection:0];
			
			NSUInteger afterIdx = [after indexOfObject:obj];
			NSIndexPath* afterPath = [NSIndexPath indexPathForItem:afterIdx inSection:0];
			
			if(idx != NSNotFound && afterIdx != NSNotFound)
			{
				[self.collectionView.animator moveItemAtIndexPath:beforePath toIndexPath:afterPath];
			}
		}];
		
		if(item != nil)
		{
			NSUInteger index = [self.resultsArrayController.arrangedObjects indexOfObject:item];
			if(index != NSNotFound)
			{
				NSIndexPath* newItem = [NSIndexPath indexPathForItem:index inSection:0];
				
				NSSet* newItemSet = [NSSet setWithCollectionViewIndexPath:newItem];
				
				[self.resultsArrayController setSelectionIndex:index];
				
				[self.collectionView.animator scrollToItemsAtIndexPaths:newItemSet scrollPosition:NSCollectionViewScrollPositionCenteredVertically];
			}
		}

		
	} completionHandler:^(BOOL finished) {
		
		[self updateStatusLabel];

	}];
}

- (void) setupFilterUsingPredicate:(NSPredicate*)predicate selectedItem:(SynopsisMetadataItem*)item
{
//	  NSArray* before = [self.resultsArrayController.arrangedObjects copy];
//	  NSMutableSet* beforeSet = [NSMutableSet setWithArray:before];
//
	self.resultsArrayController.filterPredicate = predicate;
//
//	  
//	  NSArray* after = [self.resultsArrayController.arrangedObjects copy];
//	  NSMutableSet* afterSet = [NSMutableSet setWithArray:after];

	[self.collectionView.animator performBatchUpdates:^{
		
		[self.collectionView.animator reloadItemsAtIndexPaths:self.collectionView.indexPathsForVisibleItems];
		
		if(item != nil)
		{
			NSUInteger index = [self.resultsArrayController.arrangedObjects indexOfObject:item];
			if(index != NSNotFound)
			{
				NSIndexPath* newItem = [NSIndexPath indexPathForItem:index inSection:0];
				
				NSSet* newItemSet = [NSSet setWithCollectionViewIndexPath:newItem];
				
				[self.resultsArrayController setSelectionIndex:index];
				
				[self.collectionView.animator scrollToItemsAtIndexPaths:newItemSet scrollPosition:NSCollectionViewScrollPositionCenteredVertically];
			}
		}
		
	} completionHandler:^(BOOL finished) {
		
		[self updateStatusLabel];

	}];
	
}


#pragma mark - Collection View Datasource (Now using Bindings)

- (NSInteger)collectionView:(NSCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return [self.resultsArrayController.arrangedObjects count];
}

- (NSCollectionViewItem *)collectionView:(NSCollectionView *)collectionView itemForRepresentedObjectAtIndexPath:(NSIndexPath *)indexPath
{
	SynopsisCollectionViewItem* item = (SynopsisCollectionViewItem*)[collectionView makeItemWithIdentifier:@"SynopsisCollectionViewItem" forIndexPath:indexPath];
	
	SynopsisMetadataItem* representedObject = [self.resultsArrayController.arrangedObjects objectAtIndex:indexPath.item];
	
	item.representedObject = representedObject;
	
	return item;
}

#pragma mark - Collection View Delegate

- (void)collectionView:(NSCollectionView *)collectionView didSelectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths
{
//	  NSCollectionViewItem* item = [self.collectionView itemAtIndex]
	
	[self.bestFitSort setTarget:appDelegate];
	[self.bestFitSort setAction:@selector(bestMatchSortUsingSelectedCell:)];
	[self.bestFitSort validate];

	[self.histogramSort setTarget:appDelegate];
	[self.histogramSort setAction:@selector(histogramSortUsingSelectingCell:)];

	[self.featureVectorSort setTarget:appDelegate];
	[self.featureVectorSort setAction:@selector(featureVectorSortUsingSelectedCell:)];

	[self.satSort setTarget:appDelegate];
	[self.satSort setAction:@selector(saturationSortUsingSelectedCell:)];

	[self.hueSort setTarget:appDelegate];
	[self.hueSort setAction:@selector(hueSortUsingSelectedCell:)];

	[self.brightSort setTarget:appDelegate];
	[self.brightSort setAction:@selector(brightnessSortUsingSelectedCell:)];
	
	[self updateStatusLabel];

	//	  THIS WONT WORK BECAUSE I ALLOW MULTIPLE SELECTION...
//	  
//	  SynopsisCollectionViewItem* item = (SynopsisCollectionViewItem*)collectionView;
//	  item.metadataDelegate = self.metadataInspectorVC;
	
	NSIndexPath* zerothSelection = [indexPaths anyObject];
	
	SynopsisCollectionViewItem* colletionViewItem = (SynopsisCollectionViewItem*)[self.collectionView itemAtIndex:zerothSelection.item];
	SynopsisMetadataItem* metadataItem = (SynopsisMetadataItem*)colletionViewItem.representedObject;
	
	[[SynopsisCacheWithHap sharedCache] cachedGlobalMetadataForItem:metadataItem completionHandler:^(id	 _Nullable cachedValue, NSError * _Nullable error) {
		
		NSDictionary* globalMetadata = (NSDictionary*)cachedValue;
		dispatch_async(dispatch_get_main_queue(), ^{
			self.metadataInspector.globalMetadata = globalMetadata;
		});
	}];
	
	// Set up our video player to the currently selected item
	
	//	DO NOT use this 'loadAsset' method- if you do, the UI won't update to display the metadata
	//[self.playerView loadAsset:metadataItem.asset];
	
	NSArray				*vidTracks = [metadataItem.asset tracksWithMediaType:AVMediaTypeVideo];
	AVAssetTrack		*vidTrack = (vidTracks==nil || vidTracks.count<1) ? nil : [vidTracks objectAtIndex:0];
	CGSize				tmpSize = (vidTrack==nil) ? CGSizeMake(1,1) : [vidTrack naturalSize];
	if (self.previewViewHeightConstraint != nil)	{
		[self.playerView removeConstraint:self.previewViewHeightConstraint];
		self.previewViewHeightConstraint = nil;
		self.previewViewHeightConstraint = [self.playerView.heightAnchor constraintEqualToAnchor:self.playerView.widthAnchor multiplier:tmpSize.height/tmpSize.width constant:0];
		self.previewViewHeightConstraint.active = true;
	}
	
	
	
	if(self.playerView.playerLayer.player.currentItem.asset != metadataItem.asset)
	{
		BOOL containsHap = [metadataItem.asset containsHapVideoTrack];
		
		AVPlayerItem* item = [AVPlayerItem playerItemWithAsset:metadataItem.asset];
		
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
		}
		else
		{
			AVAssetTrack* hapAssetTrack = [[metadataItem.asset hapVideoTracks] firstObject];
			AVPlayerItemHapDXTOutput* hapOutput = [[AVPlayerItemHapDXTOutput alloc] initWithHapAssetTrack:hapAssetTrack];
			hapOutput.suppressesPlayerRendering = YES;
			hapOutput.outputAsRGB = NO;
			
			[item addOutput:hapOutput];
		}
		
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

	
}

- (void)collectionView:(NSCollectionView *)collectionView didDeselectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths
{
	[self.bestFitSort setTarget:nil];
	[self.bestFitSort setAction:nil];
	
	[self.hashSort setTarget:nil];
	[self.hashSort setAction:nil];

	[self.histogramSort setTarget:nil];
	[self.histogramSort setAction:nil];
	
	[self.featureVectorSort setTarget:nil];
	[self.featureVectorSort setAction:nil];

	[self updateStatusLabel];
}


#pragma mark - Collection View Dragging Source

- (BOOL)collectionView:(NSCollectionView *)collectionView canDragItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths withEvent:(NSEvent *)event
{
	return YES;
}

- (id <NSPasteboardWriting>)collectionView:(NSCollectionView *)collectionView pasteboardWriterForItemAtIndexPath:(NSIndexPath *)indexPath
{
	SynopsisMetadataItem* representedObject = [self.resultsArrayController.arrangedObjects objectAtIndex:indexPath.item];

	// An NSURL can be a pasteboard writer, but must be returned as an absolute URL.
	return representedObject.url.absoluteURL;
}

- (void)collectionView:(NSCollectionView *)collectionView draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint forItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths
{
	[session setDraggingFormation:NSDraggingFormationStack];
	NSLog(@"begin");
}

- (void)collectionView:(NSCollectionView *)collectionView updateDraggingItemsForDrag:(id <NSDraggingInfo>)draggingInfo
{

//	  [draggingInfo enumerateDraggingItemsWithOptions:NSDraggingItemEnumerationConcurrent
//											  forView:draggingInfo.draggingSource
//											  classes:@[ [SynopsisMetadataItem class]]
//										searchOptions:nil
//										   usingBlock:^(NSDraggingItem * _Nonnull draggingItem, NSInteger idx, BOOL * _Nonnull stop) {
//		  
////		draggingItem.
//		  
//	  }];
	
	NSLog(@"update");
}

- (void)collectionView:(NSCollectionView *)collectionView draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint dragOperation:(NSDragOperation)operation
{
	NSLog(@"end");
}

- (NSDragOperation)collectionView:(NSCollectionView *)collectionView validateDrop:(id <NSDraggingInfo>)draggingInfo proposedIndex:(NSInteger *)proposedDropIndex dropOperation:(NSCollectionViewDropOperation *)proposedDropOperation 
{
	NSLog(@"validate");
	
	[draggingInfo setDraggingFormation:NSDraggingFormationStack];
//	  [draggingInfo setDra]
	
	return NSDragOperationCopy;
}


#pragma mark -

//- (IBAction)zoom:(id)sender
//{
//	  self.collectionView.enclosingScrollView.magnification = [sender floatValue];
//}

/*
static BOOL toggleAspect = false;
- (IBAction)toggleAspectRatio:(id)sender
{
	for(SynopsisCollectionViewItem* item in self.collectionView.visibleItems)
	{
		toggleAspect = !toggleAspect;
		[item setAspectRatio: (toggleAspect) ? AVLayerVideoGravityResizeAspect : AVLayerVideoGravityResizeAspectFill];
	}
}
*/

- (IBAction)switchLayout:(id)sender
{
	self.zoomSlider.enabled = YES;
	self.zoomSlider.minValue = 3;
	self.zoomSlider.maxValue = 20;
	self.zoomSlider.allowsTickMarkValuesOnly = YES;
	self.zoomSlider.numberOfTickMarks = self.zoomSlider.maxValue - self.zoomSlider.minValue + 1;

	NSCollectionViewLayout* layout;
	
	self.resultsArrayController.sortDescriptors = @[];
	self.resultsArrayController.filterPredicate = nil;
	[self.resultsArrayController rearrangeObjects];

//	  float zoomAmount = self.zoomSlider.floatValue;
	
	switch([sender tag])
	{
		case 0:
		{
			layout = self.wrappedLayout;
			break;
		}
		case 1:
		{
			layout = self.tsneHybridLayout;
			[self configureScrollViewForTSNE];
			break;
		}
		case 2:
		{
			layout = self.tsneFeatureLayout;
			[self configureScrollViewForTSNE];
			break;
		}
		case 3:
		{
			layout = self.tsneHistogramLayout;
			[self configureScrollViewForTSNE];
			break;
		}
	}
	
	NSAnimationContext.currentContext.allowsImplicitAnimation = YES;
	NSAnimationContext.currentContext.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	NSAnimationContext.currentContext.duration = 0.5;
	[NSAnimationContext beginGrouping];

//	  self.collectionView.animator.enclosingScrollView.magnification = zoomAmount;
	self.collectionView.animator.collectionViewLayout = layout;
	self.collectionView.animator.selectionIndexPaths = [NSSet set];
	
	[NSAnimationContext endGrouping];
}


- (void) configureScrollViewForFLow
{
	self.zoomSlider.enabled = NO;
	
	
	self.collectionView.enclosingScrollView.autohidesScrollers = NO;
	self.collectionView.enclosingScrollView.hasVerticalScroller = YES;
	self.collectionView.enclosingScrollView.hasHorizontalScroller = YES;
	self.collectionView.enclosingScrollView.horizontalScroller.hidden = NO;
	self.collectionView.enclosingScrollView.verticalScroller.hidden = NO;
	self.collectionView.enclosingScrollView.allowsMagnification = YES;
	
	self.zoomSlider.enabled = NO;
//	  zoomAmount = 1.0;
}

- (void) configureScrollViewForTSNE
{
	self.zoomSlider.enabled = YES;
	
	self.collectionView.enclosingScrollView.autohidesScrollers = NO;
	self.collectionView.enclosingScrollView.hasVerticalScroller = YES;
	self.collectionView.enclosingScrollView.hasHorizontalScroller = YES;
	self.collectionView.enclosingScrollView.horizontalScroller.hidden = NO;
	self.collectionView.enclosingScrollView.verticalScroller.hidden = NO;
	self.collectionView.enclosingScrollView.allowsMagnification = YES;
}

- (void) lazyCreateLayoutsWithContent:(NSArray*)content
{
	self.hybridTSNEMenu.enabled = NO;
	self.featureTSNEMenu.enabled = NO;
	self.histogramTSNEMenu.enabled = NO;

	NSSize collectionViewInitialSize = [self.collectionView frame].size;
	
	NSMutableArray<SynopsisDenseFeature*>* allFeatures = [NSMutableArray new];
	NSMutableArray<SynopsisDenseFeature*>* allHistograms = [NSMutableArray new];
	NSMutableArray<SynopsisDenseFeature*>* allHybridFeatures = [NSMutableArray new];

	for(SynopsisMetadataItem* metadataItem in content)
	{
		SynopsisDenseFeature* feature = [metadataItem valueForKey:kSynopsisStandardMetadataFeatureVectorDictKey];
		SynopsisDenseFeature* histogram = [metadataItem valueForKey:kSynopsisStandardMetadataHistogramDictKey];

		// Add our Feature
		[allFeatures addObject:feature];

		[allHistograms addObject:histogram];
		
		[allHybridFeatures addObject:[SynopsisDenseFeature denseFeatureByAppendingFeature:feature withFeature:histogram]];
	}

	
	dispatch_group_t tsneGroup = dispatch_group_create();
	
	dispatch_group_enter(tsneGroup);
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		
		TSNELayout* tsneLayout = [[TSNELayout alloc] initWithFeatures:allFeatures initialSize:collectionViewInitialSize];
		tsneLayout.itemSize = NSMakeSize(300, 300);
		
//		  DBScanLayout* dbScanLayout = [[DBScanLayout alloc] initWithData:allMetadataFeatures];
//		  dbScanLayout.itemSize = NSMakeSize(400, 200);

		self.tsneFeatureLayout = tsneLayout;
//		  self.dbscanFeatureLayout = dbScanLayout;
		
		dispatch_group_leave(tsneGroup);
		
	});
	
	dispatch_group_enter(tsneGroup);
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		
		TSNELayout* tsneLayout = [[TSNELayout alloc] initWithFeatures:allHistograms initialSize:collectionViewInitialSize];
		tsneLayout.itemSize = NSMakeSize(300, 300);
		
//		  DBScanLayout* dbScanLayout = [[DBScanLayout alloc] initWithData:allHistogramFeatures];
//		  dbScanLayout.itemSize = NSMakeSize(400, 200);

		self.tsneHistogramLayout = tsneLayout;
//		  self.dbscanHistogramLayout = dbScanLayout;

		dispatch_group_leave(tsneGroup);
	});

	dispatch_group_enter(tsneGroup);
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		
		TSNELayout* tsneLayout = [[TSNELayout alloc] initWithFeatures:allHybridFeatures initialSize:collectionViewInitialSize];
		tsneLayout.itemSize = NSMakeSize(300, 300);
		
//		  DBScanLayout* dbScanLayout = [[DBScanLayout alloc] initWithData:allHybridFeatures];
//		  dbScanLayout.itemSize = NSMakeSize(400, 200);

		self.tsneHybridLayout = tsneLayout;
//		  self.dbscanHybridLayout = dbScanLayout;

		dispatch_group_leave(tsneGroup);
		
	});

	dispatch_group_notify(tsneGroup, dispatch_get_main_queue(), ^{
		self.hybridTSNEMenu.enabled = YES;
		self.featureTSNEMenu.enabled = YES;
		self.histogramTSNEMenu.enabled = YES;
	});
}


- (void) updateStatusLabel
{
	if(self.collectionView.selectionIndexPaths.count == 1)
	{
		NSIndexPath* path1 = self.collectionView.selectionIndexPaths.allObjects[0];
		SynopsisMetadataItem* item1 = [self.resultsArrayController.arrangedObjects objectAtIndex:path1.item];
		// Dom Colors
		NSArray* domColors1 = [item1 valueForKey:kSynopsisStandardMetadataDominantColorValuesDictKey];

		// Color Components
		float hueWeight = weightHueDominantColors(domColors1);
		NSString* hueString = [NSString stringWithFormat:@" Hue : %f", hueWeight];
		float satWeight = weightSaturationDominantColors(domColors1);
		NSString* satString = [NSString stringWithFormat:@" Saturation : %f", satWeight];
		float briWeight = weightBrightnessDominantColors(domColors1);
		NSString* briString = [NSString stringWithFormat:@" Brightness : %f", briWeight];
		
		NSMutableString* value = [NSMutableString new];
		[value appendString:@"Metrics:"];
		
		[value appendString:hueString];
		[value appendString:satString];
		[value appendString:briString];
		
		self.statusField.stringValue = value;

	}
	
	else if(self.collectionView.selectionIndexPaths.count == 2)
	{
		NSIndexPath* path1 = self.collectionView.selectionIndexPaths.allObjects[0];
		NSIndexPath* path2 = self.collectionView.selectionIndexPaths.allObjects[1];
		
		SynopsisMetadataItem* item1 = [self.resultsArrayController.arrangedObjects objectAtIndex:path1.item];
		SynopsisMetadataItem* item2 = [self.resultsArrayController.arrangedObjects objectAtIndex:path2.item];
		
		// Feature
		float featureWeight = compareFeatureVector([item1 valueForKey:kSynopsisStandardMetadataFeatureVectorDictKey],[item2 valueForKey:kSynopsisStandardMetadataFeatureVectorDictKey]);
		NSString* featureString = [NSString stringWithFormat:@" Features : %f", featureWeight];

		// Hash
		float hashWeight = compareGlobalHashes([item1 valueForKey:kSynopsisStandardMetadataPerceptualHashDictKey],[item2 valueForKey:kSynopsisStandardMetadataPerceptualHashDictKey]);
		NSString* hashString = [NSString stringWithFormat:@" Perceptual Hash : %f", hashWeight];
		
		// Histogram
		float histWeight = compareHistogtams([item1 valueForKey:kSynopsisStandardMetadataHistogramDictKey],[item2 valueForKey:kSynopsisStandardMetadataHistogramDictKey]);
		NSString* histString = [NSString stringWithFormat:@" Histogram : %f", histWeight];

		float motionWeight = fabsf(compareFeatureVector([item1 valueForKey:kSynopsisStandardMetadataMotionVectorDictKey],[item2 valueForKey:kSynopsisStandardMetadataMotionVectorDictKey]));
		NSString* motionString = [NSString stringWithFormat:@" MotionVector : %f", motionWeight];

		// Dom Colors
		NSArray* domColors1 = [item1 valueForKey:kSynopsisStandardMetadataDominantColorValuesDictKey];
		NSArray* domColors2 = [item2 valueForKey:kSynopsisStandardMetadataDominantColorValuesDictKey];
		
		// Color Components
		float hueWeight1 = weightHueDominantColors(domColors1);
		float hueWeight2 = weightHueDominantColors(domColors2);
		float hueWeight = 1.0 - fabsf(hueWeight1 - hueWeight2);
		NSString* hueString = [NSString stringWithFormat:@" Hue : %f", hueWeight];

		float satWeight1 = weightSaturationDominantColors(domColors1);
		float satWeight2 = weightSaturationDominantColors(domColors2);
		float satWeight = 1.0 - fabsf(satWeight1 - satWeight2);
		NSString* satString = [NSString stringWithFormat:@" Saturation : %f", satWeight];

		float briWeight1 = weightBrightnessDominantColors(domColors1);
		float briWeight2 = weightBrightnessDominantColors(domColors2);
		float briWeight = 1.0 - fabsf(briWeight1 - briWeight2);
		NSString* briString = [NSString stringWithFormat:@" Brightness : %f", briWeight];
		
		NSMutableString* value = [NSMutableString new];
		[value appendString:@"Metrics:"];
		
		[value appendString:featureString];
		[value appendString:hashString];
		[value appendString:histString];
		[value appendString:motionString];
		[value appendString:hueString];
		[value appendString:satString];
		[value appendString:briString];
		
		self.statusField.stringValue = value;
	}
	else
	{
		self.statusField.stringValue = [NSString stringWithFormat:@"%@ : %@ : %@", appDelegate.sortStatus, appDelegate.filterStatus, appDelegate.correlationStatus];
	}
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
	
	if(self.metadataInspector)
	{
		[self.metadataInspector setFrameMetadata:metadataDictionary];
	}
}


#pragma mark - UI item actions

- (IBAction) zoomSliderUsed:(id)sender	{
	NSLog(@"%s",__func__);
	[self pushZoomSliderValToLayout];
}

#pragma mark - backend

- (void) pushZoomSliderValToLayout	{
	NSLog(@"%s",__func__);
	NSSize			scrollViewSize = self.collectionView.frame.size;
	scrollViewSize.width -= 22;
	double			padding = self.wrappedLayout.minimumInteritemSpacing;
	double			numOfColumns = self.zoomSlider.intValue;
	//(numOfColumns * WIDTH) + ((numOfColumns - 1) * padding) = scrollViewSize.width
	//(numOfColumns * WIDTH) = scrollViewSize.width - ((numOfColumns - 1) * padding);
	//WIDTH = (scrollViewSize.width/numOfColumns) - ((numOfColumns - 1) * padding)/numOfColumns
	double			colWidth = (scrollViewSize.width/numOfColumns) - (((numOfColumns - 1.0) * padding)/numOfColumns);
	self.wrappedLayout.itemSize = NSMakeSize(colWidth, colWidth);
}


@end
