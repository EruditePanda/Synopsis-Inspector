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

#import "MetadataInspectorViewController.h"

#import <Synopsis/Synopsis.h>

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSCollectionView* collectionView;

// Sorting that requires selection of an item to sort relative to:
@property (weak) IBOutlet NSToolbarItem* bestFitSort;
@property (weak) IBOutlet NSToolbarItem* hashSort;
@property (weak) IBOutlet NSToolbarItem* histogramSort;

@property (weak) IBOutlet NSSearchField* searchField;

@property (weak) IBOutlet NSTextField* statusField;

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
    NSArray* searchScopes;
    searchScopes = @[NSMetadataQueryLocalComputerScope];
    
    [self.continuousMetadataSearch setSearchScopes:searchScopes];
    
    // Configure the sorting of the results so it will order the results by the
    // display name
    NSSortDescriptor* sortKeys = [[NSSortDescriptor alloc] initWithKey:(id)kMDItemDisplayName
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
    
    [self registerForCollectionViewDragAndDrop];
}

- (void)registerForCollectionViewDragAndDrop {
    // Register for the dropped object types we can accept.
    [self.collectionView registerForDraggedTypes:[NSArray arrayWithObject:NSURLPboardType]];
    
    // Enable dragging items from our CollectionView to other applications.
    [self.collectionView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:NO];
    
    // Enable dragging items within and into our CollectionView.
//    [self.collectionView setDraggingSourceOperationMask:NSDragOperationLink forLocal:YES];
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
// OR IF WE REPLACE THE PREDICATE
- (void)initalGatherComplete:(NSNotification*)notification;
{
    [self.continuousMetadataSearch disableUpdates];

    // Temporary fix to get spotlight search working
    [self.resultsArray removeAllObjects];

    
    // Ideally, we want to run an initial populate pass
    // And then animate things coming and going
    // However we have problems comparing objects in sets
    // since I dont know why.
    
//    if(self.resultsArray.count == 0)
    {
        NSLog(@"initial gather complete");
        
        self.resultsArray = [self.continuousMetadataSearch.results mutableCopy];

        [self.collectionView reloadData];
    }
    
    // This is fucking broken:
    
    // Otherwise we've run an initial search, but likely replaced our predicate
    // In that case were going to run a batch update
//    else
//    {
////        NSMutableOrderedSet* currentSet = [NSMutableOrderedSet orderedSetWithArray:self.resultsArray];
////        NSMutableOrderedSet* newSet = [NSMutableOrderedSet orderedSetWithArray:self.continuousMetadataSearch.results];
////        
//        NSLog(@"Current Set: %lu", (unsigned long)self.resultsArray.count);
//        NSLog(@"New Set: %lu", (unsigned long)self.continuousMetadataSearch.results.count);
//        
//        // See if our new results have more items than our old
//        // If thats the case, we add items
//        // Cache our current items in a set
//        NSMutableArray* currentArray = [self.resultsArray mutableCopy];
//        NSMutableArray* differenceArray = [self.resultsArray mutableCopy];
//        NSMutableArray* newResults = [self.continuousMetadataSearch.results mutableCopy];
//        
//        // update our backing
//        self.resultsArray = [self.continuousMetadataSearch.results mutableCopy];
//
//        if(self.resultsArray.count < self.continuousMetadataSearch.results.count)
//        {
//            NSLog(@"More New Items than Old Items - inserting");
//            differenceArray =  newResults;
//            
//            NSMutableSet* addedIndexPaths = [[NSMutableSet alloc] init];
//            NSUInteger indexOfLastItem = currentArray.count;
//            
//            for(NSUInteger index = 0; index < differenceArray.count; index++)
//            {
//                [addedIndexPaths addObject:[NSIndexPath indexPathForItem:(index + indexOfLastItem) inSection:0]];
//            }
//
//            // Now Animate our Collection View with our changes
//            [self.collectionView.animator performBatchUpdates:^{
//                [[self.collectionView animator] insertItemsAtIndexPaths:addedIndexPaths];
//                
//            } completionHandler:^(BOOL finished) {
//                
//            }];
//        }
//        else
//        {
//            NSLog(@"More Old Items than New Items - deleting");
//            // Everything we want to REMOVE from our current array would be
//            [differenceArray removeObjectsInArray:newResults];
//            
//            NSMutableSet* removedIndexPaths = [[NSMutableSet alloc] init];
//            for(SynopsisMetadataItem* item in differenceArray)
//            {
//                NSIndexPath* removedItemPath = [NSIndexPath indexPathForItem:[currentArray indexOfObject:item] inSection:0];
//                [removedIndexPaths addObject:removedItemPath];
//            }
//
//            
//            // Now Animate our Collection View with our changes
//            [self.collectionView.animator performBatchUpdates:^{
//                [[self.collectionView animator] deleteItemsAtIndexPaths:removedIndexPaths];
//                
//            } completionHandler:^(BOOL finished) {
//                
//            }];
//        }
//    
//        self.resultsArray = [self.continuousMetadataSearch.results mutableCopy];
//    }

    // Continue the query
    [self.continuousMetadataSearch enableUpdates];
}

- (void)queryDidUpdate:(NSNotification*)notification;
{
    NSLog(@"A data batch has been received");
    
    [self.continuousMetadataSearch disableUpdates];

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
    
    // Add items to our array - We dont sort them yet - so we just append them at the end until the next sort.
    NSUInteger indexOfLastItem = self.resultsArray.count;
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
    
    [self.continuousMetadataSearch enableUpdates];
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
    
//    THIS WONT WORK BECAUSE I ALLOW MULTIPLE SELECTION...
//    
//    SynopsisCollectionViewItem* item = (SynopsisCollectionViewItem*)collectionView;
//    item.metadataDelegate = self.metadataInspectorVC;

}

- (void)collectionView:(NSCollectionView *)collectionView didDeselectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths
{
    
    [self.bestFitSort setTarget:nil];
    [self.bestFitSort setAction:nil];
    
    [self.hashSort setTarget:nil];
    [self.hashSort setAction:nil];

    [self.histogramSort setTarget:nil];
    [self.histogramSort setAction:nil];
    
//    SynopsisCollectionViewItem* item = (SynopsisCollectionViewItem*)collectionView;
//    item.metadataDelegate = nil;

}

- (void)collectionView:(NSCollectionView *)collectionView willDisplayItem:(NSCollectionViewItem *)item forRepresentedObjectAtIndexPath:(NSIndexPath *)indexPath
{
    SynopsisCollectionViewItem* synopsisItem = (SynopsisCollectionViewItem*)item;
    if(!self.currentlyScrolling)
    {
        [synopsisItem endOptimizeForScrolling];
    }
}

#pragma mark - Collection View Dragging Source

- (BOOL)collectionView:(NSCollectionView *)collectionView canDragItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths withEvent:(NSEvent *)event
{
    return YES;
}

- (id <NSPasteboardWriting>)collectionView:(NSCollectionView *)collectionView pasteboardWriterForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SynopsisMetadataItem* representedObject = [self.resultsArray objectAtIndex:indexPath.item];

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

//    [draggingInfo enumerateDraggingItemsWithOptions:NSDraggingItemEnumerationConcurrent
//                                            forView:draggingInfo.draggingSource
//                                            classes:@[ [SynopsisMetadataItem class]]
//                                      searchOptions:nil
//                                         usingBlock:^(NSDraggingItem * _Nonnull draggingItem, NSInteger idx, BOOL * _Nonnull stop) {
//        
////        draggingItem.
//        
//    }];
    
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
//    [draggingInfo setDra]
    
    return NSDragOperationCopy;
}

#pragma mark -

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
    [self.continuousMetadataSearch stopQuery];
    
    NSLog(@"Searching for :%@", [sender stringValue]);
    
    if([sender stringValue] == nil || [[sender stringValue] isEqualToString:@""])
    {
        // reset to default search
        NSPredicate *searchPredicate;
        searchPredicate = [NSPredicate predicateWithFormat:@"info_v002_synopsis_descriptors LIKE '*'"];
        self.continuousMetadataSearch.predicate = searchPredicate;
    }
    else
    {
        // seperate our search string by @" "
        NSString* searchTerm = [sender stringValue];
        NSMutableArray* searchTerms = [[searchTerm componentsSeparatedByString:@" "] mutableCopy];
        
        // clean any random spaces
        [searchTerms removeObject:@""];
        
        NSMutableArray* trimmedTerms = [NSMutableArray arrayWithCapacity:searchTerms.count];
        
        // remove any whitespace
        for(NSString* string in searchTerms)
        {
            NSString* trimmedString = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [trimmedTerms addObject:trimmedString];
        }
        
        searchTerm = [searchTerm stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        searchTerms = trimmedTerms;
        
        NSString* predicateBase = @"info_v002_synopsis_descriptors LIKE[cd] ";
        NSArray* operators = @[ @"AND", @"&&", @"OR", @"||", @"NOT", @"!" ];
        
        // See how many operators we have
        NSUInteger operatorCount = 0;
        for(NSString* term in searchTerms)
        {
            for(NSString* op in operators)
            {
                if([term caseInsensitiveCompare:op] == NSOrderedSame)
                {
                    operatorCount++;
                }
            }
        }
    
        // if we have an operator, make sure its not the last operator
        // (because if it is, we havent finished typing our search)
        if(operatorCount)
        {
            BOOL lastTermIsOp = false;
            NSString* lastSearchTerm = [searchTerms lastObject];
            for(NSString* op in operators)
            {
                if([lastSearchTerm caseInsensitiveCompare:op] == NSOrderedSame)
                {
                    lastTermIsOp = true;
                }
            }
            // early bail
            if (lastTermIsOp)
            {
                NSLog(@"Search Early Bail");

                return;
            }
        }
        
        // if we have any operators  we need to ensure we wrap our search between operators with parens
        // ie (something contains 'thing') OR (something contains 'otherthing) to be valid syntax
        NSString* finalSearchString;
        

        if(operatorCount)
        {
            NSMutableString* searchString = [[NSMutableString alloc] init];

            NSLog(@"Should be building operator thing");
            
            for(NSString* term in searchTerms)
            {
                // Early bail
                if([term isEqualToString:@""])
                    continue;
                
                BOOL termIsOp = false;

                // if our term is an operator we simply append it
                for(NSString* op in operators)
                {
                    if([term caseInsensitiveCompare:op] == NSOrderedSame)
                    {
                        termIsOp = true;
                        break;
                    }
                }

                if(termIsOp)
                {
                    [searchString appendString:@" "];
                    [searchString appendString:term];
                    [searchString appendString:@" "];
                }
                else
                {
                    
                    
                    NSString* start = [@"(" stringByAppendingString:predicateBase];
                    start = [start stringByAppendingString:@"\"*"];
                    NSString* newTerm = [start stringByAppendingString:term];
                    [searchString appendString:[newTerm stringByAppendingString:@"*\")"]];
                }
            }
            
            finalSearchString = searchString;
        }
        // Otherwise we can just do a regular something contains 'thing' search
        else
        {
            NSString* newTerm = [@"\"*" stringByAppendingString:searchTerm];
            newTerm = [newTerm stringByAppendingString:@"*\""];
            finalSearchString = [predicateBase stringByAppendingString:newTerm];
        }
        
        NSLog(@"Built Predicate is :%@", finalSearchString);
        
        // reset to default search
        NSPredicate *searchPredicate;
        searchPredicate = [NSPredicate predicateWithFormat:finalSearchString];

        self.continuousMetadataSearch.predicate = searchPredicate;
    }
    
    [self.continuousMetadataSearch startQuery];
}



@end
