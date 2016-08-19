//
//  AppDelegate.m
//  Synopslight
//
//  Created by vade on 7/26/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import "AppDelegate.h"
#import "SynopsisCollectionViewItem.h"
#import "SynopsisMetadataItem.h"
#import "AAPLWrappedLayout.h"

#import <Synopsis/Synopsis.h>

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSCollectionView* collectionView;

// Sorting that requires selection of an item to sort relative to:
@property (weak) IBOutlet NSToolbarItem* bestFitSort;
@property (weak) IBOutlet NSToolbarItem* hashSort;
@property (weak) IBOutlet NSToolbarItem* histogramSort;

@property (strong) NSMutableArray* resultsArray;

@property (strong) NSMetadataQuery* continuousMetadataSearch;

@property (readwrite) BOOL currentlyScrolling;
@end

@implementation AppDelegate

- (void) awakeFromNib
{
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    self.resultsArray = [NSMutableArray new];
    
    // Run and MDQuery to find every file that has tagged XAttr / Spotlight metadata hints for v002 metadata
    self.continuousMetadataSearch = [[NSMetadataQuery alloc] init];
    
    self.continuousMetadataSearch.delegate = self;
    
    // Register the notifications for batch and completion updates
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(queryDidUpdate:)
                                                 name:NSMetadataQueryDidUpdateNotification
                                               object:self.continuousMetadataSearch];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(initalGatherComplete:)
                                                 name:NSMetadataQueryDidFinishGatheringNotification
                                               object:self.continuousMetadataSearch];
    
    // Configure the search predicate
    NSPredicate *searchPredicate;
    searchPredicate = [NSPredicate predicateWithFormat:@"info_v002_synopsis_descriptors like '*'"];
    
    [self.continuousMetadataSearch setPredicate:searchPredicate];
    
    // Set the search scope. In this case it will search the User's home directory
    // and the iCloud documents area
    NSArray *searchScopes;
    searchScopes = @[NSMetadataQueryLocalComputerScope];
    
    [self.continuousMetadataSearch setSearchScopes:searchScopes];
    
    // Configure the sorting of the results so it will order the results by the
    // display name
    NSSortDescriptor *sortKeys=[[NSSortDescriptor alloc] initWithKey:(id)kMDItemDisplayName
                                                            ascending:YES];
    
    [self.continuousMetadataSearch setSortDescriptors:[NSArray arrayWithObject:sortKeys]];

    [self.continuousMetadataSearch startQuery];
    
    NSNib* synopsisResultNib = [[NSNib alloc] initWithNibNamed:@"SynopsisCollectionViewItem" bundle:[NSBundle mainBundle]];
    
    [self.collectionView registerNib:synopsisResultNib forItemWithIdentifier:@"SynopsisCollectionViewItem"];
    
//    self.collectionView.collectionViewLayout = [[AAPLWrappedLayout alloc] init];
    NSAnimationContext.currentContext.duration = 0.5;
    self.collectionView.animator.collectionViewLayout = [[AAPLWrappedLayout alloc] init];
    
    // Notifcations to help optimize scrolling
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willScroll:) name:NSScrollViewWillStartLiveScrollNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didScroll:) name:NSScrollViewDidEndLiveScrollNotification object:nil];

    self.currentlyScrolling = NO;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

#pragma mark - Sorting

- (IBAction)bestMatchSortUsingSelectedCell:(id)sender
{
    NSIndexSet *path = [self.collectionView selectionIndexes];
    SynopsisMetadataItem* item = [self.resultsArray objectAtIndex:[path firstIndex]];
    
    NSSortDescriptor* bestMatchSortDescriptor = [NSSortDescriptor synopsisBestMatchSortDescriptorRelativeTo:[item valueForKey:kSynopsisGlobalMetadataSortKey]];
    
    NSArray* previous = [self.resultsArray copy];
    [self.resultsArray sortUsingDescriptors:@[bestMatchSortDescriptor]];
    [self animateSort:previous selectedItem:item];

//    [self.collectionView reloadData];
}

- (IBAction)perceptualHashSortUsingSelectedCell:(id)sender
{
    NSIndexSet *path = [self.collectionView selectionIndexes];
    SynopsisMetadataItem* item = [self.resultsArray objectAtIndex:[path firstIndex]];
    
    NSSortDescriptor* perceptualHashSort = [NSSortDescriptor synopsisHashSortDescriptorRelativeTo:[item valueForKey:kSynopsisPerceptualHashSortKey]];

    NSArray* previous = [self.resultsArray copy];
    [self.resultsArray sortUsingDescriptors:@[perceptualHashSort]];
    [self animateSort:previous selectedItem:item];

//    [self.collectionView reloadData];
}

- (IBAction)histogramSortUsingSelectingCell:(id)sender
{
    NSIndexSet *path = [self.collectionView selectionIndexes];
    SynopsisMetadataItem* item = [self.resultsArray objectAtIndex:[path firstIndex]];
    
    NSSortDescriptor* histogtamSort = [NSSortDescriptor synopsisHistogramSortDescriptorRelativeTo:[item valueForKey:kSynopsisHistogramSortKey]];
    
    NSArray* previous = [self.resultsArray copy];
    [self.resultsArray sortUsingDescriptors:@[histogtamSort]];
    [self animateSort:previous selectedItem:item];

//    [self.collectionView reloadData];
}


- (IBAction)saturationSortUsingSelectedCell:(id)sender
{
    NSIndexSet *path = [self.collectionView selectionIndexes];
    SynopsisMetadataItem* item = [self.resultsArray objectAtIndex:[path firstIndex]];

    NSArray* previous = [self.resultsArray copy];
    [self.resultsArray sortUsingDescriptors:@[[NSSortDescriptor synopsisColorSaturationSortDescriptor]]];
    
    [self animateSort:previous selectedItem:item];
}

- (IBAction)hueSortUsingSelectedCell:(id)sender
{
    NSIndexSet *path = [self.collectionView selectionIndexes];
    SynopsisMetadataItem* item = [self.resultsArray objectAtIndex:[path firstIndex]];

    NSArray* previous = [self.resultsArray copy];
    [self.resultsArray sortUsingDescriptors:@[[NSSortDescriptor synopsisColorHueSortDescriptor]]];
    [self animateSort:previous selectedItem:item];
}


- (IBAction)brightnessSortUsingSelectedCell:(id)sender
{
    NSIndexSet *path = [self.collectionView selectionIndexes];
    SynopsisMetadataItem* item = [self.resultsArray objectAtIndex:[path firstIndex]];

    NSArray* previous = [self.resultsArray copy];
    [self.resultsArray sortUsingDescriptors:@[[NSSortDescriptor synopsisColorBrightnessSortDescriptor]]];
    [self animateSort:previous selectedItem:item];
}

- (void) animateSort:(NSArray*)previous selectedItem:(SynopsisMetadataItem*)item
{
    NSAnimationContext.currentContext.allowsImplicitAnimation = YES;
    NSAnimationContext.currentContext.duration = 0.5;
    
    NSUInteger index = [self.resultsArray indexOfObject:item];
    NSIndexPath* newItem = [NSIndexPath indexPathForItem:index inSection:0];
    
    NSSet* newItemSet = [NSSet setWithCollectionViewIndexPath:newItem];
    
    [self.collectionView.animator scrollToItemsAtIndexPaths:newItemSet scrollPosition:NSCollectionViewScrollPositionCenteredVertically];

    [self.collectionView.animator performBatchUpdates:^{
//
        for (NSInteger i = 0; i < previous.count; i++)
        {
            NSIndexPath* fromIndexPath = [NSIndexPath indexPathForItem:i inSection:0];
            
            NSInteger j = [self.resultsArray indexOfObject:previous[i]];
            
            NSIndexPath* toIndexPath = [NSIndexPath indexPathForItem:j inSection:0];
            
            [[self.collectionView animator] moveItemAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
        }
        
    } completionHandler:^(BOOL finished) {
        
    }];
}


#pragma mark -  Metadata Query Delegate

- (id)metadataQuery:(NSMetadataQuery *)query replacementObjectForResultObject:(NSMetadataItem *)result
{
    // Swap our metadata item for a SynopsisMetadataItem which has some Key Value updates
    SynopsisMetadataItem* item = [[SynopsisMetadataItem alloc] initWithURL:[NSURL fileURLWithPath:[result valueForAttribute:(NSString*)kMDItemPath]]];
    
    return item;
}

#pragma mark - Metadata Results

// Method invoked when the initial query gathering is completed
- (void)initalGatherComplete:(NSNotification*)notification;
{
    // Pause the query
    [self.continuousMetadataSearch disableUpdates];
    
    for(NSMetadataItem* item in self.continuousMetadataSearch.results)
    {
        [self.resultsArray addObject:item];
    }
    
    
    // Continue the query
    [self.continuousMetadataSearch enableUpdates];

//    [self.collectionView setItemPrototype:[SynopsisResultItem new]];
//    [self.collectionView setContent:self.resultsArray];

    [self.collectionView reloadData];
}

- (void)queryDidUpdate:(NSNotification*)notification;
{
    NSLog(@"A data batch has been received");
    
    NSArray* addedItems = [[notification userInfo] objectForKey:NSMetadataQueryUpdateAddedItemsKey];
    NSArray* updatedItems = [[notification userInfo] objectForKey:NSMetadataQueryUpdateChangedItemsKey];
    NSArray* removedItems = [[notification userInfo] objectForKey:NSMetadataQueryUpdateRemovedItemsKey];

    // Cache removed objects indices
    NSMutableSet* removedIndexPaths = [[NSMutableSet alloc] init];
    for(SynopsisMetadataItem* item in removedItems)
    {
        NSIndexPath* removedItemPath = [NSIndexPath indexPathForItem:[self.resultsArray indexOfObject:item] inSection:0];
        [removedIndexPaths addObject:removedItemPath];
    }

    // Actually remove object from our backing
    [self.resultsArray removeObjectsInArray:removedItems];

    
    // Cache updaed objects indices
    NSMutableSet* updatedIndexPaths = [[NSMutableSet alloc] init];
    NSMutableIndexSet* updatedIndexSet = [[NSMutableIndexSet alloc] init];
    for(SynopsisMetadataItem* item in updatedItems)
    {
        NSIndexPath* updatedItemPath = [NSIndexPath indexPathForItem:[self.resultsArray indexOfObject:item] inSection:0];
        [updatedIndexPaths addObject:updatedItemPath];
        [updatedIndexSet addIndex:[updatedItemPath item]];
    }
    
    // Actually remove object from our backing
    [self.resultsArray replaceObjectsAtIndexes:updatedIndexSet withObjects:updatedItems];

    
    // Update Objects
//    // Find objects which match the same URL
//    NSMutableSet* updatedIndexPaths = [[NSMutableSet alloc] init];
//    NSIndexSet* updatedIndexSet = [self.resultsArray indexesOfObjectsWithOptions:NSEnumerationConcurrent passingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//        
//        SynopsisMetadataItem* testItem = (SynopsisMetadataItem*)obj;
//        NSURL* testItemURL = [NSURL fileURLWithPath:[testItem valueForAttribute:(NSString*)kMDItemPath]];
//                              
//        for(SynopsisMetadataItem* addedItem in updatedItems)
//        {
//            NSURL* addedItemURL = [NSURL fileURLWithPath:[addedItem valueForAttribute:(NSString*)kMDItemPath]];
//            
//            if([addedItemURL isEqualTo:testItemURL])
//                return YES;
//        }
//        
//        return NO;
//    }];
//
//    // Convert our Index Set to an NSSet of IndexPaths. Oh Apple.
//    [updatedIndexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
//        [updatedIndexPaths addObject:[NSIndexPath indexPathForItem:idx inSection:0]];
//    }];
//    
//    // Update our backing to actually represent our updated data
//    [self.resultsArray replaceObjectsAtIndexes:updatedIndexSet withObjects:updatedItems];
    
    
    // Add items to our array - We dont sort them yet - so we just append them at the end until the next sort.
    NSUInteger indexOfLastItem = self.resultsArray.count - 1;
    [self.resultsArray addObjectsFromArray:addedItems];

    // Build an indexSet
    NSMutableSet* addedIndexPaths = [[NSMutableSet alloc] init];
    for(NSUInteger index = 0; index < addedItems.count; index++)
    {
        [addedIndexPaths addObject:[NSIndexPath indexPathForItem:(index + indexOfLastItem) inSection:0]];
    }
    
    // Now Animate our Collection View with our changes
    [self.collectionView.animator performBatchUpdates:^{
        
        // Handle RemovedItems
        [[self.collectionView animator] deleteItemsAtIndexPaths:removedIndexPaths];

        // Handle Updated objects
        [[self.collectionView animator] reloadItemsAtIndexPaths:updatedIndexPaths];
        
        // Handle Added items
        [[self.collectionView animator] insertItemsAtIndexPaths:addedIndexPaths];
        
    } completionHandler:^(BOOL finished) {
        
    }];
}




#pragma mark - Collection View Bullshit

- (NSInteger)collectionView:(NSCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.resultsArray.count;
}

- (NSCollectionViewItem *)collectionView:(NSCollectionView *)collectionView itemForRepresentedObjectAtIndexPath:(NSIndexPath *)indexPath
{
    SynopsisCollectionViewItem* item = (SynopsisCollectionViewItem*)[collectionView makeItemWithIdentifier:@"SynopsisCollectionViewItem" forIndexPath:indexPath];
    
    SynopsisMetadataItem* representedObject = [self.resultsArray objectAtIndex:indexPath.item];
    
    item.representedObject = representedObject;
    
    return item;
}

- (void)collectionView:(NSCollectionView *)collectionView didSelectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths
{
    [self.bestFitSort setTarget:self];
    [self.bestFitSort setAction:@selector(bestMatchSortUsingSelectedCell:)];

    [self.hashSort setTarget:self];
    [self.hashSort setAction:@selector(perceptualHashSortUsingSelectedCell:)];

    [self.histogramSort setTarget:self];
    [self.histogramSort setAction:@selector(histogramSortUsingSelectingCell:)];
}

- (void)collectionView:(NSCollectionView *)collectionView didDeselectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths
{
    [self.bestFitSort setTarget:nil];
    [self.bestFitSort setAction:nil];
    
    [self.hashSort setTarget:nil];
    [self.hashSort setAction:nil];

    [self.histogramSort setTarget:nil];
    [self.histogramSort setAction:nil];
}

- (void)collectionView:(NSCollectionView *)collectionView willDisplayItem:(NSCollectionViewItem *)item forRepresentedObjectAtIndexPath:(NSIndexPath *)indexPath
{
    SynopsisCollectionViewItem* synopsisItem = (SynopsisCollectionViewItem*)item;
    if(!self.currentlyScrolling)
    {
        [synopsisItem endOptimizeForScrolling];
    }
}

- (IBAction)zoom:(id)sender
{
    AAPLWrappedLayout* layout = (AAPLWrappedLayout*) self.collectionView.collectionViewLayout;
    
    float factor = [sender floatValue];
    NSSize size = NSMakeSize(200.0 * factor, 100.0 * factor);
    [layout setItemSize:size];
}


#pragma mark - Scroll View

- (void) willScroll:(NSNotification*)notifcation
{
    self.currentlyScrolling = YES;
    
    // hide ALL AVPlayerLayers
    NSArray* visibleResults = [self.collectionView visibleItems];

    [visibleResults makeObjectsPerformSelector:@selector(beginOptimizeForScolling)];
}

- (void) didScroll:(NSNotification*)notification
{
    self.currentlyScrolling = NO;
    
    NSArray* visibleResults = [self.collectionView visibleItems];
    
    [visibleResults makeObjectsPerformSelector:@selector(endOptimizeForScrolling)];

}

#pragma mark - Search

- (IBAction)search:(id)sender
{
    NSLog(@"Searching for :%@", [sender stringValue]);
    
    
//    [self.resultsArray indexesOfObjectsPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//        
//        
//        
//    }];
    
}



@end
