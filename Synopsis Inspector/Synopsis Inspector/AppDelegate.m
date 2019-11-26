//
//  AppDelegate.m
//  Synopslight
//
//  Created by vade on 7/26/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import <Synopsis/Synopsis.h>
#import <VideoToolbox/VTProfessionalVideoWorkflow.h>
#import <MediaToolbox/MediaToolbox.h>

#import "AppDelegate.h"

#import <HapInAVFoundation/HapInAVFoundation.h>

#import "SynopsisCollectionViewItem.h"

#import "AAPLWrappedLayout.h"
#import "TSNELayout.h"
#import "DBScanLayout.h"
#import "MetadataInspectorViewController.h"
#import "PlayerView.h"
#import "SynopsisCacheWithHap.h"




@interface AppDelegate () <AVPlayerItemMetadataOutputPushDelegate>

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSWindow *chooseSearchModeSheet;
@property (weak) IBOutlet NSCollectionView* collectionView;

// Sorting that requires selection of an item to sort relative to:
@property (weak) IBOutlet NSToolbarItem* bestFitSort;
@property (weak) IBOutlet NSToolbarItem* hashSort;
@property (weak) IBOutlet NSToolbarItem* histogramSort;
@property (weak) IBOutlet NSToolbarItem* featureVectorSort;

@property (weak) IBOutlet NSSearchField* searchField;

@property (weak) IBOutlet NSSlider* zoomSlider;

@property (weak) IBOutlet NSMenuItem* hybridTSNEMenu;
@property (weak) IBOutlet NSMenuItem* featureTSNEMenu;
@property (weak) IBOutlet NSMenuItem* histogramTSNEMenu;

@property (readwrite, strong) IBOutlet MetadataInspectorViewController* metadataInspector;
@property (readwrite, strong) IBOutlet PlayerView* playerView;
@property (strong,readwrite) NSLayoutConstraint * previewViewHeightConstraint;
@property (readwrite) SynopsisMetadataDecoder* metadataDecoder;
@property (readwrite, strong) dispatch_queue_t metadataQueue;

@property (weak) IBOutlet NSTextField* statusField;
@property (strong) NSString* sortStatus;
@property (strong) NSString* filterStatus;
@property (strong) NSString* correlationStatus;

@property (strong) id escapeKeyMonitor;

// Tokens
@property (strong) NSDictionary* tokenDictionary;
@property (weak) IBOutlet NSTokenField* tokenField;

//@property (strong) NSMutableArray* resultsArray;
@property (strong) NSArrayController* resultsArrayControler;
@property (strong) NSMetadataQuery* continuousMetadataSearch;

// Layout
@property (atomic, readwrite, strong) AAPLWrappedLayout* wrappedLayout;
@property (atomic, readwrite, strong) TSNELayout* tsneHybridLayout;
@property (atomic, readwrite, strong) TSNELayout* tsneFeatureLayout;
@property (atomic, readwrite, strong) TSNELayout* tsneHistogramLayout;
//@property (atomic, readwrite, strong) DBScanLayout* dbscanHybridLayout;
//@property (atomic, readwrite, strong) DBScanLayout* dbscanFeatureLayout;
//@property (atomic, readwrite, strong) DBScanLayout* dbscanHistogramLayout;
@end




@implementation AppDelegate

- (void) awakeFromNib
{

    MTRegisterProfessionalVideoWorkflowFormatReaders();
    VTRegisterProfessionalVideoWorkflowVideoDecoders();
    VTRegisterProfessionalVideoWorkflowVideoEncoders();

    
    self.collectionView.backgroundColors = @[[NSColor clearColor]];
    
    self.sortStatus = @"No Sort";
    self.filterStatus = @"No Filter";
    self.correlationStatus = @"";
    
    self.zoomSlider.enabled = NO;

    // For Token Filtering logic:
    self.tokenField.tokenStyle = NSTokenStyleSquared;
    
    NSArray *colors = @[ @"White",
                          @"Black",
                          @"Gray",
                          @"Red",
                          @"Green",
                          @"Blue",
                          @"Cyan",
                          @"Magenta",
                          @"Yellow",
                          @"Orange",
                          @"Purple",
                          ];
    
    NSArray* hues = @[@"Light", @"Neutral", @"Dark", @"Warm", @"Cool"];
    NSArray* speeds = @[@"Fast", @"Medium", @"Slow"];
    NSArray* directions = @[@"Up", @"Down", @"Left", @"Right", @"Diagonal"];
    NSArray* shotCategories = @[@"Close Up", @"Extreme Close Up", @"Extreme Long", @"Long", @"Medium"];
//    NSArray* operators = @[@"AND", @"OR", @"NOT"];
    
    self.tokenDictionary = @{ @"Color:" : colors,
                              @"Hue:" : hues,
                              @"Speed:" : speeds,
                              @"Direction:" : directions,
                              @"Shot Type:" : shotCategories,
//                              @"LOGIC" : operators,
//                              @"AND" : [NSNull null],
//                              @"OR" : [NSNull null],
//                              @"NOT" : [NSNull null],
                              };

    
    [self updateStatusLabel];
    
    [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:@"NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints"];
    
    [clipView setTranslatesAutoresizingMaskIntoConstraints:NO];
	[containerView setTranslatesAutoresizingMaskIntoConstraints:NO];
	[previewBox setTranslatesAutoresizingMaskIntoConstraints:NO];
	[self.playerView setTranslatesAutoresizingMaskIntoConstraints:NO];
	[attribsTabView setTranslatesAutoresizingMaskIntoConstraints:NO];
	
	[containerView.leadingAnchor constraintEqualToAnchor:clipView.leadingAnchor constant:0].active = true;
	[containerView.trailingAnchor constraintEqualToAnchor:clipView.trailingAnchor constant:0].active = true;
	[containerView.topAnchor constraintEqualToAnchor:clipView.topAnchor constant:0].active = true;
	[containerView.bottomAnchor constraintEqualToAnchor:attribsTabView.bottomAnchor constant:20].active = true;
	
	[clipView.leadingAnchor constraintEqualToAnchor:clipView.superview.leadingAnchor constant:0].active = true;
	[clipView.topAnchor constraintEqualToAnchor:clipView.superview.topAnchor constant:0].active = true;
	[clipView.trailingAnchor constraintEqualToAnchor:clipView.superview.trailingAnchor constant:-15].active = true;
	
	[previewBox.leadingAnchor constraintEqualToAnchor:previewBox.superview.leadingAnchor constant:8].active = true;
	[previewBox.trailingAnchor constraintEqualToAnchor:previewBox.superview.trailingAnchor constant:-8].active = true;
	[previewBox.topAnchor constraintEqualToAnchor:previewBox.superview.topAnchor constant:8].active = true;
	[previewBox.heightAnchor constraintGreaterThanOrEqualToConstant:50].active = true;
	
	[attribsTabView.leadingAnchor constraintEqualToAnchor:attribsTabView.superview.leadingAnchor constant:8].active = true;
	[attribsTabView.trailingAnchor constraintEqualToAnchor:attribsTabView.superview.trailingAnchor constant:-8].active = true;
	[attribsTabView.topAnchor constraintEqualToAnchor:previewBox.bottomAnchor constant:8].active = true;
	
	
	[previewBox.bottomAnchor constraintEqualToAnchor:self.playerView.bottomAnchor constant:20].active = true;
	[self.playerView.leadingAnchor constraintEqualToAnchor:self.playerView.superview.leadingAnchor constant:20].active = true;
	[self.playerView.trailingAnchor constraintEqualToAnchor:self.playerView.superview.trailingAnchor constant:-20].active = true;
	[self.playerView.topAnchor constraintEqualToAnchor:self.playerView.superview.topAnchor constant:20].active = true;
	//[self.playerView.heightAnchor constraintEqualToAnchor:self.playerView.widthAnchor constant:0].active = true;
	//[self.playerView.heightAnchor constraintGreaterThanOrEqualToConstant:50].active = true;
	self.previewViewHeightConstraint = [self.playerView.heightAnchor constraintEqualToAnchor:self.playerView.widthAnchor multiplier:0.25 constant:0];
	self.previewViewHeightConstraint.active = true;
	
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{    
    self.metadataDecoder = [[SynopsisMetadataDecoder alloc] initWithVersion:kSynopsisMetadataVersionValue];
    self.metadataQueue = dispatch_queue_create("metadataqueue", DISPATCH_QUEUE_SERIAL);

//    self.resultsArray = [NSMutableArray new];
    self.resultsArrayControler = [[NSArrayController alloc] initWithContent:[NSMutableArray new]];
    self.resultsArrayControler.automaticallyRearrangesObjects = YES;
    
    NSNib* synopsisResultNib = [[NSNib alloc] initWithNibNamed:@"SynopsisCollectionViewItem" bundle:[NSBundle mainBundle]];
    
    [self.collectionView registerNib:synopsisResultNib forItemWithIdentifier:@"SynopsisCollectionViewItem"];
    
    NSAnimationContext.currentContext.duration = 0.5;
    self.wrappedLayout = [[AAPLWrappedLayout alloc] init];
    self.collectionView.animator.collectionViewLayout = self.wrappedLayout;
    
    // Notifcations to help optimize scrolling
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willScroll:) name:NSScrollViewWillStartLiveScrollNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didScroll:) name:NSScrollViewDidEndLiveScrollNotification object:nil];
//
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willScroll:) name:NSScrollViewWillStartLiveMagnifyNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didScroll:) name:NSScrollViewDidEndLiveMagnifyNotification object:nil];
    
    // Register for the dropped object types we can accept.
    [self.collectionView registerForDraggedTypes:[NSArray arrayWithObject:NSURLPboardType]];
    
    // Enable dragging items from our CollectionView to other applications.
    [self.collectionView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:NO];    
    
    // Configure the search predicate
    // Run and MDQuery to find every file that has tagged XAttr / Spotlight metadata hints for v002 metadata
    self.continuousMetadataSearch = [[NSMetadataQuery alloc] init];
    
    // Register the notifications for batch and completion updates
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(queryDidUpdate:)
                                                 name:NSMetadataQueryDidUpdateNotification
                                               object:self.continuousMetadataSearch];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(initalGatherComplete:)
                                                 name:NSMetadataQueryDidFinishGatheringNotification
                                               object:self.continuousMetadataSearch];
    
    self.continuousMetadataSearch.delegate = self;
    
    [self switchToLocalComputerSearchScope:nil];

//    [self.window beginSheet:self.chooseSearchModeSheet completionHandler:^(NSModalResponse returnCode) {
//       
//        switch (returnCode) {
//            case NSModalResponseOK:
//                [self setGlobalMetadataSearch];
//                break;
//                
//            case NSModalResponseOK + 1:
//                [self switchToLocalComputerPathSearchScope:nil];
//                break;
//        }
//    }];
    
    
}

- (IBAction)chooseInitialSearchMode:(id)sender
{
    switch([sender tag])
    {
        case 0:
            [self.window endSheet:self.chooseSearchModeSheet returnCode:NSModalResponseOK];
            break;
            
        case 1:
            [self.window endSheet:self.chooseSearchModeSheet returnCode:NSModalResponseOK + 1];
            break;
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

#pragma mark - Metadata Search

- (IBAction)switchToLocalComputerSearchScope:(id)sender
{
    NSPredicate *searchPredicate;
    searchPredicate = [NSPredicate predicateWithFormat:@"info_synopsis_version >= 0 || info_synopsis_descriptors like '*'"];
    
    [self.continuousMetadataSearch setPredicate:searchPredicate];
    
    NSArray* searchScopes;
    searchScopes = @[NSMetadataQueryIndexedLocalComputerScope];
    
    [self.continuousMetadataSearch setSearchScopes:searchScopes];

    [self.continuousMetadataSearch startQuery];
    
    self.window.title = @"Synopsis Inspector - All Local Media";
}

- (IBAction)switchToLocalComputerPathSearchScope:(id)sender
{
    [self.continuousMetadataSearch stopQuery];

    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    openPanel.allowedFileTypes = nil;
    openPanel.canChooseDirectories = TRUE;
    
    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
       if(result == NSFileHandlingPanelOKButton)
       {
           NSPredicate *searchPredicate;
           searchPredicate = [NSPredicate predicateWithFormat:@"info_synopsis_version >= 0 || info_synopsis_descriptors like '*'"];
           
           [self.continuousMetadataSearch setPredicate:searchPredicate];
           
           // Set the search scope. In this case it will search the User's home directory
           // and the iCloud documents area
           
           // Configure the sorting of the results so it will order the results by the
           // display name
//           NSSortDescriptor* sortKeys = [[NSSortDescriptor alloc] initWithKey:(id)kMDItemDisplayName
//                                                                    ascending:YES];
//           
//           [self.continuousMetadataSearch setSortDescriptors:[NSArray arrayWithObject:sortKeys]];
           
           NSArray* searchScopes;
           searchScopes = @[openPanel.URL];
           
           [self.continuousMetadataSearch setSearchScopes:searchScopes];
           
           [self.continuousMetadataSearch startQuery];
           
           self.window.title = [@"Synopsis Inspector - " stringByAppendingString:openPanel.URL.lastPathComponent];
       }
    }];
    
}

#pragma mark - Force Specific Files

- (IBAction)switchForcedFiles:(id)sender
{
    [self.continuousMetadataSearch stopQuery];
    
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    openPanel.allowedFileTypes = [AVURLAsset audiovisualTypes];
    openPanel.canChooseDirectories = false;
    openPanel.allowsMultipleSelection = true;
    
    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if(result == NSFileHandlingPanelOKButton)
        {
            [self.resultsArrayControler removeObjects:self.resultsArrayControler.content];

            for(NSURL* url in openPanel.URLs)
            {
                SynopsisMetadataItem* item = [[SynopsisMetadataItem alloc] initWithURL:url];
                if(item)
                    [self.resultsArrayControler addObject:item];
            }
        
            NSLog(@"initial gather complete");
            
            [self.collectionView reloadData];

            self.window.title = [@"Synopsis Inspector - " stringByAppendingString:openPanel.URL.lastPathComponent];
        }
        
    }];
}

#pragma mark - Sorting

- (SynopsisMetadataItem*) firstSelectedItem
{
    NSIndexSet *path = [self.collectionView selectionIndexes];
    if(path.firstIndex != NSNotFound)
    {
        SynopsisMetadataItem* item = [[self.resultsArrayControler arrangedObjects] objectAtIndex:[path firstIndex]];
        return item;
    }
    return nil;
}

- (IBAction)bestMatchSortUsingSelectedCell:(id)sender
{
    SynopsisMetadataItem* item = [self firstSelectedItem];
    
    NSSortDescriptor* bestMatchSortDescriptor = [NSSortDescriptor synopsisBestMatchSortDescriptorRelativeTo:[item valueForKey:kSynopsisStandardMetadataDictKey]];
    
    self.sortStatus = @"Relative Best Match Sort";
    
    [self setupSortUsingSortDescriptor:bestMatchSortDescriptor selectedItem:item];
}

- (IBAction)featureVectorSortUsingSelectedCell:(id)sender
{
    SynopsisMetadataItem* item = [self firstSelectedItem];
    
    NSSortDescriptor* perceptualHashSort = [NSSortDescriptor synopsisFeatureSortDescriptorRelativeTo:[item valueForKey:kSynopsisStandardMetadataFeatureVectorDictKey]];
    
    self.sortStatus = @"Feature Vector Sort";
    
    [self setupSortUsingSortDescriptor:perceptualHashSort selectedItem:item];
}


- (IBAction)histogramSortUsingSelectingCell:(id)sender
{
    SynopsisMetadataItem* item = [self firstSelectedItem];
    
    NSSortDescriptor* histogtamSort = [NSSortDescriptor synopsisHistogramSortDescriptorRelativeTo:[item valueForKey:kSynopsisStandardMetadataHistogramDictKey]];
    
    self.sortStatus = @"Relative Histogram Sort";

    [self setupSortUsingSortDescriptor:histogtamSort selectedItem:item];
}

- (IBAction)motionVectorSortUsingSelectingCell:(id)sender
{
    SynopsisMetadataItem* item = [self firstSelectedItem];
    
    NSSortDescriptor* motionVectorSort = [NSSortDescriptor synopsisMotionVectorSortDescriptorRelativeTo:[item valueForKey:kSynopsisStandardMetadataMotionVectorDictKey]];
    
    self.sortStatus = @"Relative Motion Vector Sort";
    
    [self setupSortUsingSortDescriptor:motionVectorSort selectedItem:item];
}


- (IBAction)motionSortUsingSelectingCell:(id)sender
{
    SynopsisMetadataItem* item = [self firstSelectedItem];
    
    NSSortDescriptor* motionVectorSort = [NSSortDescriptor synopsisMotionSortDescriptorRelativeTo:[item valueForKey:kSynopsisStandardMetadataMotionDictKey]];
    
    self.sortStatus = @"Relative Motion Sort";
    
    [self setupSortUsingSortDescriptor:motionVectorSort selectedItem:item];
}



- (IBAction)sortDominantColorsRGBUsingSelectingCell:(id)sender
{
    SynopsisMetadataItem* item = [self firstSelectedItem];
    
    NSSortDescriptor* motionVectorSort = [NSSortDescriptor synopsisDominantRGBDescriptorRelativeTo:[item valueForKey:kSynopsisStandardMetadataDominantColorValuesDictKey]];
    
    self.sortStatus = @"Dominant Color RGB Sort";
    
    [self setupSortUsingSortDescriptor:motionVectorSort selectedItem:item];
}

- (IBAction)sortDominantColorsHSBUsingSelectingCell:(id)sender
{
    SynopsisMetadataItem* item = [self firstSelectedItem];
    
    NSSortDescriptor* motionVectorSort = [NSSortDescriptor synopsisDominantHSBDescriptorRelativeTo:[item valueForKey:kSynopsisStandardMetadataDominantColorValuesDictKey]];
    
    self.sortStatus = @"Dominant Color HSB Sort";
    
    [self setupSortUsingSortDescriptor:motionVectorSort selectedItem:item];
}

- (IBAction)saturationSortUsingSelectedCell:(id)sender
{
    self.sortStatus = @"Saturation Sort";
    [self setupSortUsingSortDescriptor:[NSSortDescriptor synopsisColorSaturationSortDescriptor] selectedItem:[self firstSelectedItem]];
}

- (IBAction)hueSortUsingSelectedCell:(id)sender
{
    self.sortStatus = @"Hue Sort";
    [self setupSortUsingSortDescriptor:[NSSortDescriptor synopsisColorHueSortDescriptor] selectedItem:[self firstSelectedItem]];
}

- (IBAction)brightnessSortUsingSelectedCell:(id)sender
{
    self.sortStatus = @"Brightness Sort";
    [self setupSortUsingSortDescriptor:[NSSortDescriptor synopsisColorBrightnessSortDescriptor] selectedItem:[self firstSelectedItem]];
}

- (void) setupSortUsingSortDescriptor:(NSSortDescriptor*) sortDescriptor selectedItem:(SynopsisMetadataItem*)item
{
    NSArray* before = [self.resultsArrayControler.arrangedObjects copy];
    
    self.resultsArrayControler.sortDescriptors = @[sortDescriptor];
    
    NSArray* after = [self.resultsArrayControler.arrangedObjects copy];
    
    [self.collectionView.animator performBatchUpdates:^{
        
        [before enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
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
            NSUInteger index = [self.resultsArrayControler.arrangedObjects indexOfObject:item];
            if(index != NSNotFound)
            {
                NSIndexPath* newItem = [NSIndexPath indexPathForItem:index inSection:0];
                
                NSSet* newItemSet = [NSSet setWithCollectionViewIndexPath:newItem];
                
                [self.resultsArrayControler setSelectionIndex:index];
                
                [self.collectionView.animator scrollToItemsAtIndexPaths:newItemSet scrollPosition:NSCollectionViewScrollPositionCenteredVertically];
            }
        }

        
    } completionHandler:^(BOOL finished) {
        
        [self updateStatusLabel];

    }];
}

#pragma mark - Filtering

- (IBAction)filterClear:(id)sender
{
    SynopsisMetadataItem* item = [self firstSelectedItem];
    self.filterStatus = @"No Filter";
    [self setupFilterUsingPredicate:nil selectedItem:item];
    [self updateStatusLabel];
}

- (IBAction)filterWarmColors:(id)sender
{
    SynopsisMetadataItem* item = [self firstSelectedItem];
    self.filterStatus = @"Warm Color Filter";
    [self setupFilterUsingPredicate:[NSPredicate synopsisWarmColorPredicate] selectedItem:item];
}

- (IBAction)filterCoolColors:(id)sender
{
    SynopsisMetadataItem* item = [self firstSelectedItem];
    self.filterStatus = @"Cool Color Filter";
    [self setupFilterUsingPredicate:[NSPredicate synopsisCoolColorPredicate] selectedItem:item];
}

- (IBAction)filterLightColors:(id)sender
{
    SynopsisMetadataItem* item = [self firstSelectedItem];
    self.filterStatus = @"Light Color Filter";
    [self setupFilterUsingPredicate:[NSPredicate synopsisLightColorPredicate] selectedItem:item];
}

- (IBAction)filterDarkColors:(id)sender
{
    SynopsisMetadataItem* item = [self firstSelectedItem];
    self.filterStatus = @"Dark Color Filter";
    [self setupFilterUsingPredicate:[NSPredicate synopsisDarkColorPredicate] selectedItem:item];
}

- (IBAction)filterNeutralColors:(id)sender
{
    SynopsisMetadataItem* item = [self firstSelectedItem];
    self.filterStatus = @"Neutral Color Filter";
    [self setupFilterUsingPredicate:[NSPredicate synopsisNeutralColorPredicate] selectedItem:item];
}

- (void) setupFilterUsingPredicate:(NSPredicate*)predicate selectedItem:(SynopsisMetadataItem*)item
{
//    NSArray* before = [self.resultsArrayControler.arrangedObjects copy];
//    NSMutableSet* beforeSet = [NSMutableSet setWithArray:before];
//
    self.resultsArrayControler.filterPredicate = predicate;
//
//    
//    NSArray* after = [self.resultsArrayControler.arrangedObjects copy];
//    NSMutableSet* afterSet = [NSMutableSet setWithArray:after];

    [self.collectionView.animator performBatchUpdates:^{
        
        [self.collectionView.animator reloadItemsAtIndexPaths:self.collectionView.indexPathsForVisibleItems];
        
        if(item != nil)
        {
            NSUInteger index = [self.resultsArrayControler.arrangedObjects indexOfObject:item];
            if(index != NSNotFound)
            {
                NSIndexPath* newItem = [NSIndexPath indexPathForItem:index inSection:0];
                
                NSSet* newItemSet = [NSSet setWithCollectionViewIndexPath:newItem];
                
                [self.resultsArrayControler setSelectionIndex:index];
                
                [self.collectionView.animator scrollToItemsAtIndexPaths:newItemSet scrollPosition:NSCollectionViewScrollPositionCenteredVertically];
            }
        }
        
    } completionHandler:^(BOOL finished) {
        
        [self updateStatusLabel];

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

    dispatch_async(dispatch_get_main_queue(), ^{
        [self handleInitialGatherComplete];
        
        // Continue the query
        [self.continuousMetadataSearch enableUpdates];
    });
}

- (void) handleInitialGatherComplete
{
    // Temporary fix to get spotlight search working
    [self.resultsArrayControler removeObjects:self.resultsArrayControler.content];
    
    // Ideally, we want to run an initial populate pass
    // And then animate things coming and going
    // However we have problems comparing objects in sets
    // since I dont know why.
    
//    if(self.resultsArray.count == 0)
    {
        NSLog(@"initial gather complete");
        
        [self.resultsArrayControler addObjects:[self.continuousMetadataSearch.results mutableCopy] ];
        
        [self.collectionView reloadData];
    
        if([self.resultsArrayControler.content count])
        {
//            [self lazyCreateLayoutsWithContent:self.resultsArrayControler.content];
        }
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
}

- (void)queryDidUpdate:(NSNotification*)notification;
{
    [self.continuousMetadataSearch disableUpdates];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self handleQueuryDidUpdate:notification.userInfo];

        [self.continuousMetadataSearch enableUpdates];
        
        // Once we are finished, we
        //[self lazyCreateLayoutsWithContent:self.resultsArrayControler.content];
    });
}

- (void) handleQueuryDidUpdate:(NSDictionary*)userInfo
{
    NSLog(@"A data batch has been received");

    NSArray* addedItems = [userInfo objectForKey:NSMetadataQueryUpdateAddedItemsKey];
    NSArray* updatedItems = [userInfo objectForKey:NSMetadataQueryUpdateChangedItemsKey];
    NSArray* removedItems = [userInfo objectForKey:NSMetadataQueryUpdateRemovedItemsKey];
    
    // Cache updaed objects indices
    NSMutableSet* updatedIndexPaths = [[NSMutableSet alloc] init];
    NSMutableIndexSet* updatedIndexSet = [[NSMutableIndexSet alloc] init];
    for(SynopsisMetadataItem* item in updatedItems)
    {
        NSIndexPath* updatedItemPath = [NSIndexPath indexPathForItem:[self.resultsArrayControler.content indexOfObject:item] inSection:0];
        [updatedIndexPaths addObject:updatedItemPath];
        [updatedIndexSet addIndex:[updatedItemPath item]];
    }
    // Actually update our backing
    [self.resultsArrayControler.content replaceObjectsAtIndexes:updatedIndexSet withObjects:updatedItems];

    // Cache removed objects indices
    NSMutableSet* removedIndexPaths = [[NSMutableSet alloc] init];
    for(SynopsisMetadataItem* item in removedItems)
    {
        NSIndexPath* removedItemPath = [NSIndexPath indexPathForItem:[self.resultsArrayControler.content indexOfObject:item] inSection:0];
        [removedIndexPaths addObject:removedItemPath];
    }
    
    // Actually remove object from our backing
    [self.resultsArrayControler removeObjects:removedItems];
    
    // Add items to our array - We dont sort them yet - so we just append them at the end until the next sort.
    NSUInteger indexOfLastItem = [self.resultsArrayControler.content count];
    [self.resultsArrayControler addObjects:addedItems];

    // Build an indexSet
    NSMutableSet* addedIndexPaths = [[NSMutableSet alloc] init];
    for(NSUInteger index = 0; index < addedItems.count; index++)
    {
        [addedIndexPaths addObject:[NSIndexPath indexPathForItem:(index + indexOfLastItem) inSection:0]];
    }

    // Now Animate our Collection View with our changes
    [self.collectionView.animator performBatchUpdates:^{
        
        // Handle Updated objects
        [[self.collectionView animator] reloadItemsAtIndexPaths:updatedIndexPaths];

        // Handle RemovedItems
        [[self.collectionView animator] deleteItemsAtIndexPaths:removedIndexPaths];
        
        // Handle Added items
        [[self.collectionView animator] insertItemsAtIndexPaths:addedIndexPaths];
        
    } completionHandler:^(BOOL finished) {
        
    }];
}

#pragma mark - Collection View Datasource (Now using Bindings)

- (NSInteger)collectionView:(NSCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.resultsArrayControler.arrangedObjects count];
}

- (NSCollectionViewItem *)collectionView:(NSCollectionView *)collectionView itemForRepresentedObjectAtIndexPath:(NSIndexPath *)indexPath
{
    SynopsisCollectionViewItem* item = (SynopsisCollectionViewItem*)[collectionView makeItemWithIdentifier:@"SynopsisCollectionViewItem" forIndexPath:indexPath];
    
    SynopsisMetadataItem* representedObject = [self.resultsArrayControler.arrangedObjects objectAtIndex:indexPath.item];
    
    item.representedObject = representedObject;
    
    return item;
}

#pragma mark - Collection View Delegate

- (void)collectionView:(NSCollectionView *)collectionView didSelectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths
{
//    NSCollectionViewItem* item = [self.collectionView itemAtIndex]
    
    [self.bestFitSort setTarget:self];
    [self.bestFitSort setAction:@selector(bestMatchSortUsingSelectedCell:)];

    [self.histogramSort setTarget:self];
    [self.histogramSort setAction:@selector(histogramSortUsingSelectingCell:)];

    [self.featureVectorSort setTarget:self];
    [self.featureVectorSort setAction:@selector(featureVectorSortUsingSelectedCell:)];
    
    [self updateStatusLabel];

    //    THIS WONT WORK BECAUSE I ALLOW MULTIPLE SELECTION...
//    
//    SynopsisCollectionViewItem* item = (SynopsisCollectionViewItem*)collectionView;
//    item.metadataDelegate = self.metadataInspectorVC;
    
    NSIndexPath* zerothSelection = [indexPaths anyObject];
    
    SynopsisCollectionViewItem* colletionViewItem = (SynopsisCollectionViewItem*)[self.collectionView itemAtIndex:zerothSelection.item];
    SynopsisMetadataItem* metadataItem = (SynopsisMetadataItem*)colletionViewItem.representedObject;
    
    [[SynopsisCacheWithHap sharedCache] cachedGlobalMetadataForItem:metadataItem completionHandler:^(id  _Nullable cachedValue, NSError * _Nullable error) {
        
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
                                                  //                                              (NSString*)kCVPixelBufferIOSurfaceOpenGLFBOCompatibilityKey :@(YES),
                                                  //                                              (NSString*)kCVPixelBufferIOSurfaceOpenGLTextureCompatibilityKey :@(YES),
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
//            dispatch_async(dispatch_get_main_queue(), ^{
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
                
//            });
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
    SynopsisMetadataItem* representedObject = [self.resultsArrayControler.arrangedObjects objectAtIndex:indexPath.item];

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

//- (IBAction)zoom:(id)sender
//{
//    self.collectionView.enclosingScrollView.magnification = [sender floatValue];
//}

static BOOL toggleAspect = false;
- (IBAction)toggleAspectRatio:(id)sender
{
    for(SynopsisCollectionViewItem* item in self.collectionView.visibleItems)
    {
        toggleAspect = !toggleAspect;
        [item setAspectRatio: (toggleAspect) ? AVLayerVideoGravityResizeAspect : AVLayerVideoGravityResizeAspectFill];
    }
}

- (IBAction)switchLayout:(id)sender
{
    self.zoomSlider.enabled = YES;

    NSCollectionViewLayout* layout;
    
    self.resultsArrayControler.sortDescriptors = @[];
    self.resultsArrayControler.filterPredicate = nil;
    [self.resultsArrayControler rearrangeObjects];

//    float zoomAmount = self.zoomSlider.floatValue;
    
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

//    self.collectionView.animator.enclosingScrollView.magnification = zoomAmount;
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
//    zoomAmount = 1.0;
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
        
//        DBScanLayout* dbScanLayout = [[DBScanLayout alloc] initWithData:allMetadataFeatures];
//        dbScanLayout.itemSize = NSMakeSize(400, 200);

        self.tsneFeatureLayout = tsneLayout;
//        self.dbscanFeatureLayout = dbScanLayout;
        
        dispatch_group_leave(tsneGroup);
        
    });
    
    dispatch_group_enter(tsneGroup);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        TSNELayout* tsneLayout = [[TSNELayout alloc] initWithFeatures:allHistograms initialSize:collectionViewInitialSize];
        tsneLayout.itemSize = NSMakeSize(300, 300);
        
//        DBScanLayout* dbScanLayout = [[DBScanLayout alloc] initWithData:allHistogramFeatures];
//        dbScanLayout.itemSize = NSMakeSize(400, 200);

        self.tsneHistogramLayout = tsneLayout;
//        self.dbscanHistogramLayout = dbScanLayout;

        dispatch_group_leave(tsneGroup);
    });

    dispatch_group_enter(tsneGroup);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        TSNELayout* tsneLayout = [[TSNELayout alloc] initWithFeatures:allHybridFeatures initialSize:collectionViewInitialSize];
        tsneLayout.itemSize = NSMakeSize(300, 300);
        
//        DBScanLayout* dbScanLayout = [[DBScanLayout alloc] initWithData:allHybridFeatures];
//        dbScanLayout.itemSize = NSMakeSize(400, 200);

        self.tsneHybridLayout = tsneLayout;
//        self.dbscanHybridLayout = dbScanLayout;

        dispatch_group_leave(tsneGroup);
        
    });

    dispatch_group_notify(tsneGroup, dispatch_get_main_queue(), ^{
        self.hybridTSNEMenu.enabled = YES;
        self.featureTSNEMenu.enabled = YES;
        self.histogramTSNEMenu.enabled = YES;
    });
}


//MAKE A SYNOPSIS MEDIA ITEM CACHE THAT HANDLES GLOBAL METADATA DECODING / CACHING
////
//WE CAN THEN USE THAT TO BACK OUR ARRAY FOR QUICK SEARCHES AND SHIT
//
//MAKE A SUBCLASS OF THAT WHICH CAN HANDLE 

#pragma mark - Search

- (IBAction)search:(id)sender
{
    [self.continuousMetadataSearch stopQuery];
    
    NSLog(@"Searching for :%@", [sender stringValue]);
    
    if([sender stringValue] == nil || [[sender stringValue] isEqualToString:@""])
    {
        // reset to default search
        NSPredicate *searchPredicate;
        searchPredicate = [NSPredicate predicateWithFormat:@"info_synopsis_version >= 0 || info_synopsis_descriptors LIKE '*'"];
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
        
        NSString* predicateBase = @"info_synopsis_descriptors LIKE[cd] ";
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

- (void) updateStatusLabel
{
    if(self.collectionView.selectionIndexPaths.count == 1)
    {
        NSIndexPath* path1 = self.collectionView.selectionIndexPaths.allObjects[0];
        SynopsisMetadataItem* item1 = [self.resultsArrayControler.arrangedObjects objectAtIndex:path1.item];
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
        
        SynopsisMetadataItem* item1 = [self.resultsArrayControler.arrangedObjects objectAtIndex:path1.item];
        SynopsisMetadataItem* item2 = [self.resultsArrayControler.arrangedObjects objectAtIndex:path2.item];
        
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
        self.statusField.stringValue = [NSString stringWithFormat:@"%@ : %@ : %@", self.sortStatus, self.filterStatus, self.correlationStatus];
    }
}

#pragma mark - Token Field

- (IBAction)actionFromTokenField:(id)sender
{
    NSLog(@"actionFromTokenField: %@", sender);
}

- (IBAction)tokenDidSelectMenuItem:(id)sender
{
    NSLog(@"tokenDidSelectMenuItem: %@", sender);
    
    NSMutableArray* allTokens = [[self.tokenField objectValue] mutableCopy];
    
    NSUInteger specificTokenIndex = [allTokens indexOfObject:[sender representedObject]];
    
    if(specificTokenIndex != NSNotFound)
    {
        // replace the specific token text with the text of the sender
        NSString* newTokenText = [sender title];
        
        allTokens[specificTokenIndex] = newTokenText;
        
        // is our Token a top level token (ie, filter type, not filter value)
        if (specificTokenIndex % 2 == 0)
        {
            // if its changed, remove the next token if there is one, and suggest a value
            if(allTokens.count >= specificTokenIndex + 1)
            {
                allTokens[specificTokenIndex + 1] = @"";
            }
        }
        // update token field
        self.tokenField.objectValue = allTokens;
    }
}

#pragma mark - Token Field Delegate

- (NSArray *)tokenField:(NSTokenField *)tokenField completionsForSubstring:(NSString *)substring indexOfToken:(NSInteger)tokenIndex indexOfSelectedItem:(NSInteger *)selectedIndex
{
    
    NSLog(@"completionsForSubstring:%li", (long)tokenIndex);
    
    NSPredicate* prefixPredicate = [NSPredicate predicateWithFormat:@"SELF beginswith[cd] %@", substring];

    // Top Level Tokens
    NSArray* keyTokens = [self.tokenDictionary allKeys];

    if([tokenField.objectValue isKindOfClass:[NSArray class]])
    {
        NSArray* objects = (NSArray*)tokenField.objectValue;
        
        // If our token is an even number its 'first' in the token order
        if((objects.count - 1) % 2 == 0)
        {
            NSArray *potentialTokens = [keyTokens filteredArrayUsingPredicate:prefixPredicate];

            if(!potentialTokens.count)
                return keyTokens;

            return potentialTokens;
        }
        else
        {
            // check the content of the preceding object
            NSString* lastToken = [objects objectAtIndex:objects.count - 2];

            // if the preceding token is a top level key token:
            if([keyTokens containsObject:lastToken])
            {
                NSArray* possibleSubTokens = [self.tokenDictionary valueForKey:lastToken];
                NSArray* possibleTypedToken = [possibleSubTokens filteredArrayUsingPredicate:prefixPredicate];
                if(!possibleTypedToken.count)
                    return possibleSubTokens;
                return possibleTypedToken;
            }
            
        }
    }

    return nil;
}

- (NSArray *)tokenField:(NSTokenField *)tokenField shouldAddObjects:(NSArray *)tokens atIndex:(NSUInteger)index
{
    return tokens;
//    if(index % 2 == 0)
//    {
//        if(self.topTokens )
//    }
//    
//    else
//        return self.knownColors;
}

- (BOOL)tokenField:(NSTokenField *)tokenField hasMenuForRepresentedObject:(id)representedObject
{
    if([[self.tokenDictionary allKeys] containsObject:representedObject])
    {
        return YES;
    }
    
    for(NSArray* subTokenArray in [self.tokenDictionary allValues])
    {
        if([subTokenArray containsObject:representedObject])
        {
            return YES;
        }
    }

    return NO;
}

- (NSMenu *)tokenField:(NSTokenField *)tokenField menuForRepresentedObject:(id)representedObject
{
//    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    NSMenu *tokenMenu = [[NSMenu alloc] init];

    if([[self.tokenDictionary allKeys] containsObject:representedObject])
    {
        
        for(NSString* key in [self.tokenDictionary allKeys])
        {
            NSMenuItem *keyItem = [[NSMenuItem alloc] init];
            [keyItem setTitle:key];
            [keyItem setAction:@selector(tokenDidSelectMenuItem:)];
            [keyItem setTarget:self];
            [keyItem setRepresentedObject:representedObject];
            [tokenMenu addItem:keyItem];
        }
        
        return tokenMenu;
    }
 
    for(NSArray* subTokenArray in [self.tokenDictionary allValues])
    {
        if([subTokenArray containsObject:representedObject])
        {
            for(NSString* subToken in subTokenArray)
            {
                NSMenuItem *tokenItem = [[NSMenuItem alloc] init];
                [tokenItem setTitle:subToken];
                [tokenItem setAction:@selector(tokenDidSelectMenuItem:)];
                [tokenItem setTarget:self];
                [tokenItem setRepresentedObject:representedObject];
                [tokenMenu addItem:tokenItem];
            }
            
            return tokenMenu;
        }
    }

//    if([self.knownColors containsObject:representedObject])
//    {
//        NSMenu *tokenMenu = [[NSMenu alloc] init];
//
//        for(NSString* color in self.knownColors)
//        {
//            NSMenuItem *colorItem = [[NSMenuItem alloc] init];
//            [colorItem setTitle:color];
//            [tokenMenu addItem:colorItem];
//        }
//        
//        return tokenMenu;
//    }
    
    return nil;
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

@end
