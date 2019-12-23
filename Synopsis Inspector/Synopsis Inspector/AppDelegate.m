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


#import "PlayerView.h"
#import "DataController.h"
#import "FileController.h"
#import "VVLogger.h"




@interface AppDelegate () <AVPlayerItemMetadataOutputPushDelegate>

@property (weak) IBOutlet NSWindow *window;

@property (weak) IBOutlet NSCollectionView* collectionView;

//@property (weak) IBOutlet NSSearchField* searchField;

@property (weak) IBOutlet NSArrayController * resultsArrayController;

@property (readwrite, strong) IBOutlet PlayerView* playerView;

//@property (strong) id escapeKeyMonitor;

//@property (strong) NSMutableArray* resultsArray;

//	data + file controllers
@property (weak) IBOutlet DataController * dataController;
@property (weak) IBOutlet FileController * fileController;

@end




@implementation AppDelegate

+ (void) initialize	{
#if !DEBUG
	[[VVLogger alloc] initWithFolderName:nil maxNumLogs:20];
	[[VVLogger globalLogger] redirectLogs];
#endif
}
- (void) awakeFromNib
{
    MTRegisterProfessionalVideoWorkflowFormatReaders();
    VTRegisterProfessionalVideoWorkflowVideoDecoders();
    VTRegisterProfessionalVideoWorkflowVideoEncoders();
    
    self.sortStatus = @"No Sort";
    self.filterStatus = @"No Filter";
    self.correlationStatus = @"";
    
    //self.zoomSlider.enabled = NO;

    [self.dataController updateStatusLabel];
    
    NSLayoutConstraint		*constr = nil;
    
    //[[NSUserDefaults standardUserDefaults] setObject:@YES forKey:@"NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints"];
    
    //	set the positioning of the various UI items in the inspector
    [clipView setTranslatesAutoresizingMaskIntoConstraints:NO];
	[containerView setTranslatesAutoresizingMaskIntoConstraints:NO];
	//[previewBox setTranslatesAutoresizingMaskIntoConstraints:NO];
	[self.playerView setTranslatesAutoresizingMaskIntoConstraints:NO];
	[attribsTabView setTranslatesAutoresizingMaskIntoConstraints:NO];
	
	[containerView.leadingAnchor constraintEqualToAnchor:clipView.leadingAnchor constant:0].active = true;
	[containerView.trailingAnchor constraintEqualToAnchor:clipView.trailingAnchor constant:0].active = true;
	[containerView.topAnchor constraintEqualToAnchor:clipView.topAnchor constant:0].active = true;
	constr = [containerView.bottomAnchor constraintEqualToAnchor:clipView.bottomAnchor constant:0];
	constr.priority = NSLayoutPriorityDefaultLow;
	constr.active = true;
	constr = [containerView.heightAnchor constraintGreaterThanOrEqualToConstant:600];
	constr.priority = NSLayoutPriorityDefaultHigh;
	constr.active = true;
	
	[clipView.leadingAnchor constraintEqualToAnchor:clipView.superview.leadingAnchor constant:0].active = true;
	[clipView.topAnchor constraintEqualToAnchor:clipView.superview.topAnchor constant:0].active = true;
	[clipView.trailingAnchor constraintEqualToAnchor:clipView.superview.trailingAnchor constant:0].active = true;
	[clipView.bottomAnchor constraintEqualToAnchor:clipView.superview.bottomAnchor constant:0].active = true;

	//[previewBox.leadingAnchor constraintEqualToAnchor:previewBox.superview.leadingAnchor constant:8].active = true;
	//[previewBox.trailingAnchor constraintEqualToAnchor:previewBox.superview.trailingAnchor constant:-8].active = true;
	//[previewBox.topAnchor constraintEqualToAnchor:previewBox.superview.topAnchor constant:8].active = true;
	//[previewBox.heightAnchor constraintGreaterThanOrEqualToConstant:50].active = true;
	
	[attribsTabView.leadingAnchor constraintEqualToAnchor:attribsTabView.superview.leadingAnchor constant:8].active = true;
	[attribsTabView.trailingAnchor constraintEqualToAnchor:attribsTabView.superview.trailingAnchor constant:-8].active = true;
	//[attribsTabView.topAnchor constraintEqualToAnchor:previewBox.bottomAnchor constant:8].active = true;
	[attribsTabView.topAnchor constraintEqualToAnchor:attribsTabView.superview.topAnchor constant:42].active = true;
    constr = [attribsTabView.heightAnchor constraintGreaterThanOrEqualToConstant:600];
    constr.priority = NSLayoutPriorityDefaultHigh;
    constr.active = true;
    constr = [attribsTabView.bottomAnchor constraintEqualToAnchor:attribsTabView.superview.bottomAnchor constant:-8];
    constr.priority = NSLayoutPriorityDefaultLow;
    constr.active = true;
	
	//[previewBox.bottomAnchor constraintEqualToAnchor:self.playerView.bottomAnchor constant:20].active = true;
	[self.playerView.leadingAnchor constraintEqualToAnchor:self.playerView.superview.leadingAnchor constant:8].active = true;
	[self.playerView.trailingAnchor constraintEqualToAnchor:self.playerView.superview.trailingAnchor constant:-8].active = true;
	[self.playerView.topAnchor constraintEqualToAnchor:self.playerView.superview.topAnchor constant:8].active = true;
	[self.playerView.bottomAnchor constraintEqualToAnchor:self.playerView.superview.bottomAnchor constant:-8].active = true;
	//[self.playerView.heightAnchor constraintEqualToAnchor:self.playerView.widthAnchor constant:0].active = true;
	//[self.playerView.heightAnchor constraintGreaterThanOrEqualToConstant:50].active = true;
	
	
	[self.playerView.widthAnchor constraintLessThanOrEqualToAnchor:self.window.contentView.widthAnchor multiplier:0.5 constant:0].active = true;
	[self.playerView.heightAnchor constraintLessThanOrEqualToAnchor:self.window.contentView.heightAnchor multiplier:0.5 constant:0].active = true;
	[self.playerView.heightAnchor constraintGreaterThanOrEqualToAnchor:self.window.contentView.heightAnchor multiplier:0.15 constant:0].active = true;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{    
    


    
    
    
    
    
    // Notifcations to help optimize scrolling
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willScroll:) name:NSScrollViewWillStartLiveScrollNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didScroll:) name:NSScrollViewDidEndLiveScrollNotification object:nil];
//
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willScroll:) name:NSScrollViewWillStartLiveMagnifyNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didScroll:) name:NSScrollViewDidEndLiveMagnifyNotification object:nil];
    
    
    
    
    
    
}



- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}



#pragma mark - Sorting

- (void) setupSortForSynopsisMetadatIdentifier:(SynopsisMetadataIdentifier)identifier
{
    SynopsisMetadataItem* item = [self.dataController firstSelectedItem];
    
    NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortViaSynopsisGlobalMetadataUsingIdentifier:(identifier) relativeTo:item];
    
    [self.dataController setupSortUsingSortDescriptor:sortDescriptor selectedItem:item];
}

- (IBAction)bestMatchSortUsingSelectedCell:(id)sender
{
    SynopsisMetadataItem* item = [self.dataController firstSelectedItem];
    
    NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortViaSynopsisGlobalMetadataRelativeTo:item];

    [self.dataController setupSortUsingSortDescriptor:sortDescriptor selectedItem:item];

    self.sortStatus = @"Relative Best Match Sort";
}

- (IBAction)featureVectorSortUsingSelectedCell:(id)sender
{
    [self setupSortForSynopsisMetadatIdentifier:SynopsisMetadataIdentifierVisualEmbedding];
    self.sortStatus = @"Relative Feature Vector Sort";
}

- (IBAction)probabilitySortUsingSelectedCell:(id)sender
{
    [self setupSortForSynopsisMetadatIdentifier:SynopsisMetadataIdentifierVisualProbabilities];
    self.sortStatus = @"Relative Prediction Probability Sort";
}

- (IBAction)histogramSortUsingSelectingCell:(id)sender
{
    [self setupSortForSynopsisMetadatIdentifier:SynopsisMetadataIdentifierVisualHistogram];
    self.sortStatus = @"Relative Histogram Sort";
}

- (IBAction)dtwFeatureSortUsingSelectingCell:(id)sender
{
    [self setupSortForSynopsisMetadatIdentifier:SynopsisMetadataIdentifierTimeSeriesVisualEmbedding];
    self.sortStatus = @"Relative DTW Feature Sort";
}

- (IBAction)dtwProbabilitySortUsingSelectingCell:(id)sender
{
    [self setupSortForSynopsisMetadatIdentifier:SynopsisMetadataIdentifierTimeSeriesVisualProbabilities];
    self.sortStatus = @"Relative DTW Feature Sort";
}

- (IBAction)sortUsingCinemaNetGroupUsingSelectedCell:(id)sender
{
    SynopsisMetadataItem* item = [self.dataController firstSelectedItem];
    
    CinemaNetClassGroup classGroup = (CinemaNetClassGroup)[sender tag];
    
    NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortViaSynopsisGlobalMetadataUsingCinemaNetClassGroup:classGroup relativeTo:item];

    [self.dataController setupSortUsingSortDescriptor:sortDescriptor selectedItem:item];

    self.sortStatus = @"CinemaNet Class Group Match Sort";
}

- (IBAction)sortUsingCinemaNetConceptGroupUsingSelectedCell:(id)sender
{
    SynopsisMetadataItem* item = [self.dataController firstSelectedItem];
    
    CinemaNetConceptGroup conceptGroup = (CinemaNetConceptGroup)[sender tag];
    
    NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortViaSynopsisGlobalMetadataUsingCinemaNetConceptGroup:conceptGroup relativeTo:item];

    [self.dataController setupSortUsingSortDescriptor:sortDescriptor selectedItem:item];

    self.sortStatus = @"CinemaNet Concept Match Sort";
}

/*
- (IBAction)motionVectorSortUsingSelectingCell:(id)sender
{
    SynopsisMetadataItem* item = [self.dataController firstSelectedItem];
    
    NSSortDescriptor* motionVectorSort = [NSSortDescriptor synopsisMotionVectorSortDescriptorRelativeTo:[item valueForKey:kSynopsisStandardMetadataMotionVectorDictKey]];
    
    self.sortStatus = @"Relative Motion Vector Sort";
    
    [self.dataController setupSortUsingSortDescriptor:motionVectorSort selectedItem:item];
}


- (IBAction)motionSortUsingSelectingCell:(id)sender
{
    SynopsisMetadataItem* item = [self.dataController firstSelectedItem];
    
    NSSortDescriptor* motionVectorSort = [NSSortDescriptor synopsisMotionSortDescriptorRelativeTo:[item valueForKey:kSynopsisStandardMetadataMotionDictKey]];
    
    self.sortStatus = @"Relative Motion Sort";
    
    [self.dataController setupSortUsingSortDescriptor:motionVectorSort selectedItem:item];
}
*/


//- (IBAction)sortDominantColorsRGBUsingSelectingCell:(id)sender
//{
//    SynopsisMetadataItem* item = [self.dataController firstSelectedItem];
//
//    NSSortDescriptor* motionVectorSort = [NSSortDescriptor synopsisDominantRGBDescriptorRelativeTo:[item valueForKey:kSynopsisStandardMetadataDominantColorValuesDictKey]];
//
//    self.sortStatus = @"Dominant Color RGB Sort";
//
//    [self.dataController setupSortUsingSortDescriptor:motionVectorSort selectedItem:item];
//}
//
//- (IBAction)sortDominantColorsHSBUsingSelectingCell:(id)sender
//{
//    SynopsisMetadataItem* item = [self.dataController firstSelectedItem];
//
//    NSSortDescriptor* motionVectorSort = [NSSortDescriptor synopsisDominantHSBDescriptorRelativeTo:[item valueForKey:kSynopsisStandardMetadataDominantColorValuesDictKey]];
//
//    self.sortStatus = @"Dominant Color HSB Sort";
//
//    [self.dataController setupSortUsingSortDescriptor:motionVectorSort selectedItem:item];
//}
//
//- (IBAction)saturationSortUsingSelectedCell:(id)sender
//{
//    self.sortStatus = @"Saturation Sort";
//    [self.dataController setupSortUsingSortDescriptor:[NSSortDescriptor synopsisColorSaturationSortDescriptor] selectedItem:[self.dataController firstSelectedItem]];
//}
//
//- (IBAction)hueSortUsingSelectedCell:(id)sender
//{
//    self.sortStatus = @"Hue Sort";
//    [self.dataController setupSortUsingSortDescriptor:[NSSortDescriptor synopsisColorHueSortDescriptor] selectedItem:[self.dataController firstSelectedItem]];
//}
//
//- (IBAction)brightnessSortUsingSelectedCell:(id)sender
//{
//    self.sortStatus = @"Brightness Sort";
//    [self.dataController setupSortUsingSortDescriptor:[NSSortDescriptor synopsisColorBrightnessSortDescriptor] selectedItem:[self.dataController firstSelectedItem]];
//}

- (IBAction) zoomInUsed:(id)sender	{
	[zoomSlider setIntValue:[zoomSlider intValue] - 1];
	[[DataController global] zoomSliderUsed:zoomSlider];
}
- (IBAction) zoomOutUsed:(id)sender	{
	[zoomSlider setIntValue:[zoomSlider intValue] + 1];
	[[DataController global] zoomSliderUsed:zoomSlider];
}


#pragma mark - Filtering


- (IBAction)filterClear:(id)sender
{
    SynopsisMetadataItem* item = [self.dataController firstSelectedItem];
    self.filterStatus = @"No Filter";
    [self.dataController setupFilterUsingPredicate:nil selectedItem:item];
    [self.dataController updateStatusLabel];
}

- (IBAction)filterWarmColors:(id)sender
{
    SynopsisMetadataItem* item = [self.dataController firstSelectedItem];
    self.filterStatus = @"Warm Color Filter";
    [self.dataController setupFilterUsingPredicate:[NSPredicate synopsisWarmColorPredicate] selectedItem:item];
}

- (IBAction)filterCoolColors:(id)sender
{
    SynopsisMetadataItem* item = [self.dataController firstSelectedItem];
    self.filterStatus = @"Cool Color Filter";
    [self.dataController setupFilterUsingPredicate:[NSPredicate synopsisCoolColorPredicate] selectedItem:item];
}

- (IBAction)filterLightColors:(id)sender
{
    SynopsisMetadataItem* item = [self.dataController firstSelectedItem];
    self.filterStatus = @"Light Color Filter";
    [self.dataController setupFilterUsingPredicate:[NSPredicate synopsisLightColorPredicate] selectedItem:item];
}

- (IBAction)filterDarkColors:(id)sender
{
    SynopsisMetadataItem* item = [self.dataController firstSelectedItem];
    self.filterStatus = @"Dark Color Filter";
    [self.dataController setupFilterUsingPredicate:[NSPredicate synopsisDarkColorPredicate] selectedItem:item];
}

- (IBAction)filterNeutralColors:(id)sender
{
    SynopsisMetadataItem* item = [self.dataController firstSelectedItem];
    self.filterStatus = @"Neutral Color Filter";
    [self.dataController setupFilterUsingPredicate:[NSPredicate synopsisNeutralColorPredicate] selectedItem:item];
}







@end
