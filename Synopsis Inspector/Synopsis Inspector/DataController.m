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
#import "TokenObject.h"
#import "AppDelegate.h"
#import "SynopsisCollectionViewItemView.h"

#import "Constants.h"
#define RELOAD_DATA 0




static DataController			*_globalDataController = nil;




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

@property (strong,nullable) SynopsisMetadataItem * selectedItem;

@property (strong, readwrite) PlayerView * scrubView;

@property (weak) IBOutlet NSTextField* statusField;

- (void) pushZoomSliderValToLayout;

@end




@implementation DataController


+ (instancetype) global	{
	return _globalDataController;
}
- (id) init	{
	self = [super init];
	if (self != nil)	{
		if (_globalDataController == nil)	{
			static dispatch_once_t		onceToken;
			dispatch_once(&onceToken, ^{
				_globalDataController = self;
			});
		}
		self.scrubView = [[PlayerView alloc] initWithFrame:NSMakeRect(0,0,320,240)];
		self.scrubView.layer.borderWidth = 0.0;
		self.scrubView.layer.cornerRadius = 0.0;
		self.scrubView.layer.backgroundColor = [NSColor clearColor].CGColor;
		
		self.scrubView.alphaValue = 0.0;
	}
	return self;
}
- (void) awakeFromNib	{
	
	self.collectionView.backgroundColors = @[[NSColor clearColor]];
	
	//	  self.resultsArray = [NSMutableArray new];
	//self.resultsArrayController = [[NSArrayController alloc] initWithContent:[NSMutableArray new]];
	self.resultsArrayController.automaticallyRearrangesObjects = NO;
	
	NSNib* synopsisResultNib = [[NSNib alloc] initWithNibNamed:@"SynopsisCollectionViewItem" bundle:[NSBundle mainBundle]];
	
	[self.collectionView registerNib:synopsisResultNib forItemWithIdentifier:@"SynopsisCollectionViewItem"];
	
	NSAnimationContext.currentContext.duration = 0.5;
	self.wrappedLayout = [[AAPLWrappedLayout alloc] init];
	self.collectionView.animator.collectionViewLayout = self.wrappedLayout;
	
	// Register for the dropped object types we can accept.
	[self.collectionView registerForDraggedTypes:[NSArray arrayWithObject:NSURLPboardType]];
	
	// Enable dragging items from our CollectionView to other applications.
	[self.collectionView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:NO];
	
	//	bang the zoom slider so our layout is consistent
	[self pushZoomSliderValToLayout];
	
	//	register to receive KVO notifications of the scroll view's frame
	[self.collectionView
		addObserver:self
		forKeyPath:@"superview.frame"
		options:NSKeyValueObservingOptionNew
		context:NULL];
    
        // Notifcations to help optimize scrolling
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willScroll:) name:NSScrollViewWillStartLiveScrollNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didScroll:) name:NSScrollViewDidEndLiveScrollNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willScroll:) name:NSScrollViewWillStartLiveMagnifyNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didScroll:) name:NSScrollViewDidEndLiveMagnifyNotification object:nil];
}

- (void) reloadData {
	//NSLog(@"%s",__func__);
	[self.collectionView reloadData];
}

#pragma mark - KVO

- (void) observeValueForKeyPath:(NSString *)p ofObject:(id)o change:(NSDictionary *)ch context:(void*)cx	{
	//NSLog(@"%s",__func__);
	if (o == self.collectionView)	{
		//NSLog(@"\tcollectionView frame change");
		[self pushZoomSliderValToLayout];
	}
}


#pragma mark - Sorting


- (SynopsisMetadataItem*) firstSelectedItem
{
	return self.selectedItem;
	/*
	NSIndexSet *path = [self.collectionView selectionIndexes];
	if(path.firstIndex != NSNotFound)
	{
		SynopsisMetadataItem* item = [[self.resultsArrayController arrangedObjects] objectAtIndex:[path firstIndex]];
		return item;
	}
	return nil;
	*/
}

- (void) setupSortUsingSortDescriptor:(NSSortDescriptor*) sortDescriptor selectedItem:(SynopsisMetadataItem*)item
{
	NSLog(@"%s ... %@",__func__,item);
	
    NSTimeInterval start = [[NSDate date] timeIntervalSince1970];
    
	NSArray			*before = [self.resultsArrayController.arrangedObjects copy];
	
	self.resultsArrayController.sortDescriptors = @[ sortDescriptor ];
	[self.resultsArrayController rearrangeObjects];
    
    NSTimeInterval end = [[NSDate date] timeIntervalSince1970];

    NSTimeInterval delta = end - start;
    
    NSLog(@"Sorting took %f", delta);

    
	//NSLog(@"\tfirst 12 arranged objects are:");
	//for (int i=0; i<12; ++i)	{
	//	if ([self.resultsArrayController.arrangedObjects count] <= i)
	//		break;
	//	NSLog(@"\t\t%d - %@",i,[self.resultsArrayController.arrangedObjects objectAtIndex:i]);
	//}
	
	NSArray			*after = [self.resultsArrayController.arrangedObjects copy];
	
#if RELOAD_DATA
	[self.collectionView reloadData];
	[self updateStatusLabel];
#else
    
    int afterIdx = 0;
    
    NSMutableArray* beforeIndexPaths = [NSMutableArray new];
    NSMutableArray* afterIndexPaths = [NSMutableArray new];
    for (SynopsisMetadataItem *item in after)
    {
        NSIndexPath *afterPath = [NSIndexPath indexPathForItem:afterIdx inSection:0];
        
        [afterIndexPaths addObject:afterPath];
        
        NSUInteger beforeIdx = [before indexOfObjectIdenticalTo:item];
        if (beforeIdx == NSNotFound)
        {
            beforeIdx = [before indexOfObject:item];
        }
        if (beforeIdx != NSNotFound && beforeIdx != afterIdx)
        {
            //if (afterIdx < 10)
            //    NSLog(@"\tmoving %@ from %ld to %ld",item,beforeIdx,afterIdx);
            
            NSIndexPath *beforePath = [NSIndexPath indexPathForItem:beforeIdx inSection:0];
           
            [beforeIndexPaths addObject:beforePath];
        }
    
        ++afterIdx;
    }
    
	[self.collectionView.animator performBatchUpdates:^{
		
        NSLog(@"Perform Batch Updates");
        
        [beforeIndexPaths enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            NSIndexPath* beforePath = (NSIndexPath*) obj;
            NSIndexPath* afterPath = afterIndexPaths[idx];
            
            [self.collectionView.animator moveItemAtIndexPath:beforePath toIndexPath:afterPath];
            //[self.collectionView.animator reloadItemsAtIndexPaths:[NSSet setWithCollectionViewIndexPath:afterPath]];
        }];

		if (self.selectedItem != nil)	{
			NSUInteger		tmpIdx = [self.resultsArrayController.arrangedObjects indexOfObjectIdenticalTo:self.selectedItem];
			if (tmpIdx != NSNotFound)	{
				//NSLog(@"\tselected item is at index %ld in the UI",tmpIdx);
				NSIndexPath		*tmpPath = [NSIndexPath indexPathForItem:tmpIdx inSection:0];
				NSSet			*tmpSet = [NSSet setWithCollectionViewIndexPath:tmpPath];
				
				[self.resultsArrayController setSelectionIndex:tmpIdx];
				[self.collectionView.animator scrollToItemsAtIndexPaths:tmpSet scrollPosition:NSCollectionViewScrollPositionCenteredVertically];
			}
		}
		
		
	} completionHandler:^(BOOL finished) {
		[self updateStatusLabel];

        NSTimeInterval animationEnd = [[NSDate date] timeIntervalSince1970];

        NSTimeInterval delta = animationEnd - start;
        
        NSLog(@"Animating and sorting took %f", delta);
	}];
#endif
	
}

- (void) setupFilterUsingPredicate:(NSPredicate*)predicate selectedItem:(SynopsisMetadataItem*)item
{
	//NSLog(@"%s",__func__);
//	  NSArray* before = [self.resultsArrayController.arrangedObjects copy];
//	  NSMutableSet* beforeSet = [NSMutableSet setWithArray:before];
//
    NSTimeInterval start = [[NSDate date] timeIntervalSince1970];

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

        NSTimeInterval end = [[NSDate date] timeIntervalSince1970];

        NSTimeInterval delta = end - start;
        
        NSLog(@"Sorting took %f", delta);
	}];
	
}


#pragma mark - Search


- (IBAction)search:(id)sender
{
	//NSLog(@"%s",__func__);
	NSString		*rawSearchString = [sender stringValue];
	//NSLog(@"\tsearch term is %@",rawSearchString);
	
	TokenObject		*obj = [TokenObject createTokenGroupFromString:rawSearchString];
	if (obj == nil)	{
		if (rawSearchString == nil || rawSearchString.length < 1)
			[sender setTextColor:[NSColor textColor]];
		else
			[sender setTextColor:[NSColor redColor]];
		self.resultsArrayController.filterPredicate = nil;
		[self.resultsArrayController rearrangeObjects];
		[self.collectionView reloadData];
		return;
	}
	else	{
		[sender setTextColor:[NSColor textColor]];
		
		NSPredicate		*descriptorPred = [obj createPredicateWithFormat:@"ANY SELF.GM.VD CONTAINS[c] %@"];
		NSPredicate		*filenamePred = [obj createPredicateWithFormat:@"SELF.url.path CONTAINS[c] %@"];
		NSPredicate		*pred = nil;
		
		if (descriptorPred == nil && filenamePred != nil)
			pred = filenamePred;
		else if (descriptorPred != nil && filenamePred == nil)
			pred = descriptorPred;
		else if (descriptorPred != nil && filenamePred != nil)
			pred = [NSCompoundPredicate orPredicateWithSubpredicates:@[ descriptorPred, filenamePred ]];
		
		//NSLog(@"\tpred is %@",pred);
		self.resultsArrayController.filterPredicate = pred;
		[self.resultsArrayController rearrangeObjects];
		[self.collectionView reloadData];
		return;
	}
	
}


#pragma mark - Collection View Datasource (Now using Bindings)


- (NSInteger)collectionView:(NSCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return [self.resultsArrayController.arrangedObjects count];
}

- (NSCollectionViewItem *)collectionView:(NSCollectionView *)collectionView itemForRepresentedObjectAtIndexPath:(NSIndexPath *)indexPath
{
	//NSLog(@"%s ... %@",__func__,indexPath);
	if (indexPath == nil)
		return nil;
	SynopsisCollectionViewItem* item = (SynopsisCollectionViewItem*)[collectionView makeItemWithIdentifier:@"SynopsisCollectionViewItem" forIndexPath:indexPath];
	
	SynopsisMetadataItem* representedObject = [self.resultsArrayController.arrangedObjects objectAtIndex:indexPath.item];
	item.representedObject = representedObject;
	//NSLog(@"\tmade item %@",item);
	
	return item;
}

#pragma mark - Collection View Delegate

- (void)collectionView:(NSCollectionView *)cv didSelectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths
{
	NSLog(@"%s ... %@",__func__,indexPaths);
//	  NSCollectionViewItem* item = [self.collectionView itemAtIndex]
	
	[self.bestFitSort setTarget:appDelegate];
	[self.bestFitSort setAction:@selector(bestMatchSortUsingSelectedCell:)];
	[self.bestFitSort validate];
	
	[self.hashSort setTarget:appDelegate];
	[self.hashSort setAction:@selector(probabilitySortUsingSelectedCell:)];
	[self.hashSort validate];

	[self.histogramSort setTarget:appDelegate];
	[self.histogramSort setAction:@selector(histogramSortUsingSelectingCell:)];

	[self.featureVectorSort setTarget:appDelegate];
	[self.featureVectorSort setAction:@selector(featureVectorSortUsingSelectedCell:)];

//	[self.satSort setTarget:appDelegate];
//	[self.satSort setAction:@selector(saturationSortUsingSelectedCell:)];
//
//	[self.hueSort setTarget:appDelegate];
//	[self.hueSort setAction:@selector(hueSortUsingSelectedCell:)];
//
//	[self.brightSort setTarget:appDelegate];
//	[self.brightSort setAction:@selector(brightnessSortUsingSelectedCell:)];
	
	[self updateStatusLabel];

	//	  THIS WONT WORK BECAUSE I ALLOW MULTIPLE SELECTION...
//	  
//	  SynopsisCollectionViewItem* item = (SynopsisCollectionViewItem*)collectionView;
//	  item.metadataDelegate = self.metadataInspectorVC;
	
	NSIndexPath* zerothSelection = [indexPaths anyObject];
	//NSLog(@"\tnumber of items in section (%d) is %d", zerothSelection.section, [cv numberOfItemsInSection:zerothSelection.section]);
	//NSLog(@"\tzerothSelection is %@, index is %d", zerothSelection,zerothSelection.item);
	//SynopsisCollectionViewItem* collectionViewItem = (SynopsisCollectionViewItem*)[cv itemAtIndex:zerothSelection.item];
	SynopsisCollectionViewItem* collectionViewItem = (SynopsisCollectionViewItem*)[cv itemAtIndexPath:zerothSelection];
	//NSLog(@"\tcollectionViewItem is %@",collectionViewItem);
	SynopsisMetadataItem* metadataItem = (SynopsisMetadataItem*)collectionViewItem.representedObject;
	//NSLog(@"\tmetdataItem is %@",metadataItem);
	self.selectedItem = metadataItem;
	NSLog(@"\tselecing %@",self.selectedItem);
	
	self.metadataInspector.metadataItem = metadataItem;
	
	//	update the filename text field
	SynopsisMetadataItem		*selItem = [self firstSelectedItem];
	[filenameTextField setStringValue:(selItem==nil) ? @"" : [[selItem url] lastPathComponent]];
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

- (IBAction)calculateLayouts:(id)sender
{
    [self lazyCreateLayoutsWithContent:self.resultsArrayController.content];
}

- (IBAction)switchLayout:(id)sender
{
	self.zoomSlider.enabled = YES;
	self.zoomSlider.minValue = 3;
	self.zoomSlider.maxValue = 10;
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
//	self.hybridTSNEMenu.enabled = NO;
//	self.featureTSNEMenu.enabled = NO;
//	self.histogramTSNEMenu.enabled = NO;
//
//	NSSize collectionViewInitialSize = [self.collectionView frame].size;
//
//	NSMutableArray<SynopsisDenseFeature*>* allFeatures = [NSMutableArray new];
//	NSMutableArray<SynopsisDenseFeature*>* allHistograms = [NSMutableArray new];
//	NSMutableArray<SynopsisDenseFeature*>* allHybridFeatures = [NSMutableArray new];
//
//	for(SynopsisMetadataItem* metadataItem in content)
//	{
//		SynopsisDenseFeature* feature = [metadataItem valueForKey:kSynopsisStandardMetadataFeatureVectorDictKey];
//		SynopsisDenseFeature* histogram = [metadataItem valueForKey:kSynopsisStandardMetadataHistogramDictKey];
//
//		// Add our Feature
//		[allFeatures addObject:feature];
//
//		[allHistograms addObject:histogram];
//
//		[allHybridFeatures addObject:[SynopsisDenseFeature denseFeatureByAppendingFeature:feature withFeature:histogram]];
//	}
//
//
//	dispatch_group_t tsneGroup = dispatch_group_create();
//
//	dispatch_group_enter(tsneGroup);
//	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
//
//		TSNELayout* tsneLayout = [[TSNELayout alloc] initWithFeatures:allFeatures initialSize:collectionViewInitialSize];
//		tsneLayout.itemSize = NSMakeSize(300, 300);
//
////		  DBScanLayout* dbScanLayout = [[DBScanLayout alloc] initWithData:allMetadataFeatures];
////		  dbScanLayout.itemSize = NSMakeSize(400, 200);
//
//		self.tsneFeatureLayout = tsneLayout;
////		  self.dbscanFeatureLayout = dbScanLayout;
//
//		dispatch_group_leave(tsneGroup);
//
//	});
//
//	dispatch_group_enter(tsneGroup);
//	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
//
//		TSNELayout* tsneLayout = [[TSNELayout alloc] initWithFeatures:allHistograms initialSize:collectionViewInitialSize];
//		tsneLayout.itemSize = NSMakeSize(300, 300);
//
////		  DBScanLayout* dbScanLayout = [[DBScanLayout alloc] initWithData:allHistogramFeatures];
////		  dbScanLayout.itemSize = NSMakeSize(400, 200);
//
//		self.tsneHistogramLayout = tsneLayout;
////		  self.dbscanHistogramLayout = dbScanLayout;
//
//		dispatch_group_leave(tsneGroup);
//	});
//
//	dispatch_group_enter(tsneGroup);
//	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
//
//		TSNELayout* tsneLayout = [[TSNELayout alloc] initWithFeatures:allHybridFeatures initialSize:collectionViewInitialSize];
//		tsneLayout.itemSize = NSMakeSize(300, 300);
//
////		  DBScanLayout* dbScanLayout = [[DBScanLayout alloc] initWithData:allHybridFeatures];
////		  dbScanLayout.itemSize = NSMakeSize(400, 200);
//
//		self.tsneHybridLayout = tsneLayout;
////		  self.dbscanHybridLayout = dbScanLayout;
//
//		dispatch_group_leave(tsneGroup);
//
//	});
//
//	dispatch_group_notify(tsneGroup, dispatch_get_main_queue(), ^{
//		self.hybridTSNEMenu.enabled = YES;
//		self.featureTSNEMenu.enabled = YES;
//		self.histogramTSNEMenu.enabled = YES;
//	});
}


- (void) updateStatusLabel
{
	/*
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
	*/
	if(self.collectionView.selectionIndexPaths.count == 2)
	{
		NSIndexPath* path1 = self.collectionView.selectionIndexPaths.allObjects[0];
		NSIndexPath* path2 = self.collectionView.selectionIndexPaths.allObjects[1];

		SynopsisMetadataItem* item1 = [self.resultsArrayController.arrangedObjects objectAtIndex:path1.item];
		SynopsisMetadataItem* item2 = [self.resultsArrayController.arrangedObjects objectAtIndex:path2.item];

		// Feature
        NSString* embeddingKey = SynopsisKeyForMetadataIdentifierVersion(SynopsisMetadataIdentifierVisualEmbedding, kSynopsisMetadataVersionCurrent);
        float embeddingSimilarity = compareFeaturesCosineSimilarity([item1 valueForKey:embeddingKey],[item2 valueForKey:embeddingKey]);
		NSString* embeddingString = [NSString stringWithFormat:@" Embedding : %f", embeddingSimilarity];

        NSString* probabilityKey = SynopsisKeyForMetadataIdentifierVersion(SynopsisMetadataIdentifierVisualProbabilities, kSynopsisMetadataVersionCurrent);
		float probabiltySimilarity = compareFeaturesCosineSimilarity([item1 valueForKey:probabilityKey],[item2 valueForKey:probabilityKey]);
        NSString* probabilityString = [NSString stringWithFormat:@" Probailities : %f", probabiltySimilarity];

		// Histogram
        NSString* histogramKey = SynopsisKeyForMetadataIdentifierVersion(SynopsisMetadataIdentifierVisualHistogram, kSynopsisMetadataVersionCurrent);
		float histWeight = compareHistogtams([item1 valueForKey:histogramKey],[item2 valueForKey:histogramKey]);
		NSString* histString = [NSString stringWithFormat:@" Histogram : %f", histWeight];

		NSMutableString* value = [NSMutableString new];
		[value appendString:@"Metrics:"];

		[value appendString:embeddingString];
		[value appendString:probabilityString];
		[value appendString:histString];
		
		self.statusField.stringValue = value;
	}
	else
	{
		self.statusField.stringValue = [NSString stringWithFormat:@"%@ : %@ : %@", appDelegate.sortStatus, appDelegate.filterStatus, appDelegate.correlationStatus];
	}
}

#pragma mark - Scrolling Optimization

- (void) willScroll:(NSNotification*)notification
{
    [[SynopsisCacheWithHap sharedCache]  returnOnlyCachedResults];
}

- (void) didScroll:(NSNotification*)notification
{
    [[SynopsisCacheWithHap sharedCache]  returnCachedAndUncachedResults];
    // fire off a notification to trigger re-loading of thumbnails
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kSynopsisInspectorThumnailImageChangeName
                                                        object:nil
                                                      userInfo:nil];
}

#pragma mark - UI item actions

- (IBAction) zoomSliderUsed:(id)sender	{
	[self pushZoomSliderValToLayout];
}

#pragma mark - backend

- (void) pushZoomSliderValToLayout	{
	//NSLog(@"%s",__func__);
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
