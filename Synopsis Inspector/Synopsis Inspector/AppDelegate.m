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
@end

@implementation AppDelegate

- (void) awakeFromNib
{
//    [self registerTableView];
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
    
    self.collectionView.collectionViewLayout = [[AAPLWrappedLayout alloc] init];
    self.collectionView.animator.collectionViewLayout = [[AAPLWrappedLayout alloc] init];
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
    
    [self.resultsArray sortUsingDescriptors:@[bestMatchSortDescriptor]];
    
    [self.collectionView reloadData];
}

- (IBAction)perceptualHashSortUsingSelectedCell:(id)sender
{
    NSIndexSet *path = [self.collectionView selectionIndexes];
    SynopsisMetadataItem* item = [self.resultsArray objectAtIndex:[path firstIndex]];
    
    NSSortDescriptor* perceptualHashSort = [NSSortDescriptor synopsisHashSortDescriptorRelativeTo:[item valueForKey:kSynopsisPerceptualHashSortKey]];
    [self.resultsArray sortUsingDescriptors:@[perceptualHashSort]];
    
    [self.collectionView reloadData];
}

- (IBAction)histogramSortUsingSelectingCell:(id)sender
{
    NSIndexSet *path = [self.collectionView selectionIndexes];
    SynopsisMetadataItem* item = [self.resultsArray objectAtIndex:[path firstIndex]];
    
    NSSortDescriptor* histogtamSort = [NSSortDescriptor synopsisHistogramSortDescriptorRelativeTo:[item valueForKey:kSynopsisHistogramSortKey]];
    [self.resultsArray sortUsingDescriptors:@[histogtamSort]];
    
    [self.collectionView reloadData];
}


- (IBAction)saturationSortUsingSelectedCell:(id)sender
{
    NSArray* previous = self.resultsArray;
    [self.resultsArray sortUsingDescriptors:@[[NSSortDescriptor synopsisColorSaturationSortDescriptor]]];
    
    [self animateSort:previous];
}

- (IBAction)hueSortUsingSelectedCell:(id)sender
{
    NSArray* previous = self.resultsArray;
    [self.resultsArray sortUsingDescriptors:@[[NSSortDescriptor synopsisColorHueSortDescriptor]]];
    [self animateSort:previous];
}


- (IBAction)brightnessSortUsingSelectedCell:(id)sender
{
    NSArray* previous = self.resultsArray;
    [self.resultsArray sortUsingDescriptors:@[[NSSortDescriptor synopsisColorBrightnessSortDescriptor]]];
    [self animateSort:previous];
}

- (void) animateSort:(NSArray*)previous
{
    NSAnimationContext.currentContext.allowsImplicitAnimation = YES;
    NSAnimationContext.currentContext.duration = 0.5;
    
    [self.collectionView.animator performBatchUpdates:^{
        
        for (NSInteger i = 0; i < previous.count; i++)
        {
            NSIndexPath* fromIndexPath = [NSIndexPath indexPathForItem:i inSection:0];
            
            NSInteger j = [self.resultsArray indexOfObject:previous[i]];
            
            NSIndexPath* toIndexPath = [NSIndexPath indexPathForItem:j inSection:0];
            
            [self.collectionView.animator moveItemAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
        }
        
    } completionHandler:^(BOOL finished) {
        [self.collectionView reloadData];
    }];
    
}


#pragma mark -  Metadata Query Delegate

- (id)metadataQuery:(NSMetadataQuery *)query replacementObjectForResultObject:(NSMetadataItem *)result
{
    // Swap our metadata item for a SynopsisMetadataItem which has some Key Value updates
    SynopsisMetadataItem* item = [[SynopsisMetadataItem alloc] initWithURL:[NSURL fileURLWithPath:[result valueForAttribute:(NSString*)kMDItemPath]]];
    
    return item;
}

#pragma mark - Metadata

- (void)queryDidUpdate:sender;
{
    NSLog(@"A data batch has been received");
    [self updateResults];
}


// Method invoked when the initial query gathering is completed
- (void)initalGatherComplete:sender;
{
    NSLog(@"A Initial Gather has been received");
    [self updateResults];
}

- (void) updateResults
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


#pragma mark - Collection View Bullshit

- (NSInteger)collectionView:(NSCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.resultsArray.count;
}

- (NSCollectionViewItem *)collectionView:(NSCollectionView *)collectionView itemForRepresentedObjectAtIndexPath:(NSIndexPath *)indexPath
{
    SynopsisCollectionViewItem* item = (SynopsisCollectionViewItem*)[collectionView makeItemWithIdentifier:@"SynopsisCollectionViewItem" forIndexPath:indexPath];
    
    SynopsisMetadataItem* representedObject = [self.resultsArray objectAtIndex:indexPath.item];
    
    item.graphicsContext = [self.window graphicsContext];
    
    item.representedObject = representedObject;
    
    return item;
}

- (void)collectionView:(NSCollectionView *)collectionView didSelectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths NS_AVAILABLE_MAC(10_11);
{
    [self.bestFitSort setTarget:self];
    [self.bestFitSort setAction:@selector(bestMatchSortUsingSelectedCell:)];

    [self.hashSort setTarget:self];
    [self.hashSort setAction:@selector(perceptualHashSortUsingSelectedCell:)];

    [self.histogramSort setTarget:self];
    [self.histogramSort setAction:@selector(histogramSortUsingSelectingCell:)];
}

- (void)collectionView:(NSCollectionView *)collectionView didDeselectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths NS_AVAILABLE_MAC(10_11);
{
    [self.bestFitSort setTarget:nil];
    [self.bestFitSort setAction:nil];
    
    [self.hashSort setTarget:nil];
    [self.hashSort setAction:nil];

    [self.histogramSort setTarget:nil];
    [self.histogramSort setAction:nil];
}



@end
