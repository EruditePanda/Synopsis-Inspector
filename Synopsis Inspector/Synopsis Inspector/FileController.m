//
//	FileController.m
//	Synopsis Inspector
//
//	Created by testAdmin on 11/27/19.
//	Copyright © 2019 v002. All rights reserved.
//

#import "FileController.h"
#import "AppDelegate.h"
#import "DataController.h"
#import <Synopsis/Synopsis.h>
#import "DataController.h"

#define RELOAD_DATA 1

@interface FileController ()

@property (strong) IBOutlet NSWindow *window;
@property (strong) IBOutlet NSWindow *fileLoadingWindow;
@property (strong) IBOutlet NSProgressIndicator *fileLoadingProgress;
@property (strong) NSArray* fileLoadingTopLevelObjects;
@property (strong) IBOutlet NSWindow *chooseSearchModeSheet;
@property (strong) IBOutlet NSCollectionView* collectionView;
@property (strong) IBOutlet NSArrayController * resultsArrayController;
@property (strong) IBOutlet DataController * dataController;
@property (strong) NSOperationQueue* fileLoadingOperationQueue;

// Tokens
@property (strong) NSDictionary* tokenDictionary;
@property (weak) IBOutlet NSTokenField* tokenField;
@property (strong) NSMetadataQuery* continuousMetadataSearch;

@end

@implementation FileController

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        NSArray* topLevel = nil;
        NSNib* fileLoadingProgressNIB = [[NSNib alloc] initWithNibNamed:@"FileLoadingProgress" bundle:[NSBundle bundleForClass:[self class]]];
        
        BOOL loaded = [fileLoadingProgressNIB instantiateWithOwner:self topLevelObjects:&topLevel];
        if ( loaded )
        {
            self.fileLoadingTopLevelObjects = topLevel;
        }
        else
        {
            NSLog(@"Unable to load FileLoadingProgress nib");
            return nil;
        }
        
    }
    return self;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    self.fileLoadingOperationQueue = [[NSOperationQueue alloc] init];
    self.fileLoadingOperationQueue.maxConcurrentOperationCount = [[NSProcessInfo processInfo] processorCount];
    self.fileLoadingOperationQueue.qualityOfService = NSQualityOfServiceUserInitiated;
    
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
//	  NSArray* operators = @[@"AND", @"OR", @"NOT"];
	
	self.tokenDictionary = @{ @"Color:" : colors,
							  @"Hue:" : hues,
							  @"Speed:" : speeds,
							  @"Direction:" : directions,
							  @"Shot Type:" : shotCategories,
//								@"LOGIC" : operators,
//								@"AND" : [NSNull null],
//								@"OR" : [NSNull null],
//								@"NOT" : [NSNull null],
							  };
	
	
	// Configure the search predicate
	// Run and MDQuery to find every file that has tagged XAttr / Spotlight metadata hints for v002 metadata
	self.continuousMetadataSearch = [[NSMetadataQuery alloc] init];
	
	// Register the notifications for batch and completion updates
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(queryDidUpdate:)
		name:NSMetadataQueryDidUpdateNotification
		object:self.continuousMetadataSearch];
	
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(initalGatherComplete:)
		name:NSMetadataQueryDidFinishGatheringNotification
		object:self.continuousMetadataSearch];
	
//	self.continuousMetadataSearch.delegate = self;
	
	//[self switchToLocalComputerSearchScope:nil];

//	  [self.window beginSheet:self.chooseSearchModeSheet completionHandler:^(NSModalResponse returnCode) {
//		 
//		  switch (returnCode) {
//			  case NSModalResponseOK:
//				  [self setGlobalMetadataSearch];
//				  break;
//				  
//			  case NSModalResponseOK + 1:
//				  [self switchToLocalComputerPathSearchScope:nil];
//				  break;
//		  }
//	  }];
	
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


#pragma mark - Metadata Search

- (void) setupSynopsisMetadataSearchWithScopes:(NSArray*)scopes
{
    NSLog(@"%s",__func__);
    NSPredicate *searchPredicate;
    NSString        *predStr = [NSString stringWithFormat:@"%@ >= 0 || %@ like '*'",kSynopsisMetadataHFSAttributeVersionKey,kSynopsisMetadataHFSAttributeDescriptorKey];
    searchPredicate = [NSPredicate predicateWithFormat:predStr];
    //searchPredicate = [NSPredicate predicateWithFormat:@"info_synopsis_version >= 0 || info_synopsis_descriptors like '*'"];
    
    
    [self.continuousMetadataSearch setPredicate:searchPredicate];
    
    NSArray* searchScopes;
    searchScopes = @[NSMetadataQueryIndexedLocalComputerScope];
    
    [self.continuousMetadataSearch setSearchScopes:scopes];

    [self.continuousMetadataSearch startQuery];
}

- (IBAction) switchToLocalComputerSearchScope:(id)sender
{
    [self setupSynopsisMetadataSearchWithScopes:@[NSMetadataQueryLocalComputerScope]];
	
	self.window.title = @"Synopsis Inspector - All Local Media";
}

- (IBAction) switchToLocalComputerPathSearchScope:(id)sender
{
    NSLog(@"%s",__func__);
    
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    openPanel.allowedFileTypes = nil;
    openPanel.canChooseDirectories = TRUE;
    openPanel.canChooseFiles = NO;
    openPanel.allowsMultipleSelection = NO;
    
    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if(result == NSModalResponseOK)    {
//            [self loadFilesInDirectory:openPanel.URL];
            
            [self setupSynopsisMetadataSearchWithScopes:@[openPanel.URL]];

            self.window.title = [@"Synopsis Inspector - " stringByAppendingString:openPanel.URL.lastPathComponent];
        }
    }];
}

#pragma mark - Force Specific Files

- (IBAction) switchForcedDirectoryPath:(id)sender
{
	NSLog(@"%s",__func__);
	
	NSOpenPanel* openPanel = [NSOpenPanel openPanel];
	openPanel.allowedFileTypes = nil;
	openPanel.canChooseDirectories = TRUE;
	openPanel.canChooseFiles = NO;
	openPanel.allowsMultipleSelection = NO;
	
	[openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
		if(result == NSModalResponseOK)	{
			[self loadFilesInDirectory:openPanel.URL];
		}
	}];
}

- (IBAction)switchForcedFiles:(id)sender
{
	NSLog(@"%s",__func__);
	
	NSOpenPanel* openPanel = [NSOpenPanel openPanel];
	openPanel.allowedFileTypes = [AVURLAsset audiovisualTypes];
	openPanel.canChooseDirectories = false;
	openPanel.canChooseFiles = true;
	openPanel.allowsMultipleSelection = true;
	
	[openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
		if(result == NSModalResponseOK)	{
			//	halt the MD query, we're not going to uses it while running files manually
	   		[self.continuousMetadataSearch stopQuery];
	   			   		
	   		NSArray			*urls = openPanel.URLs;
	   		if (urls.count > 0)	{
	   			NSURL			*firstURL = urls[0];
	   			self.window.title = [@"Synopsis Inspector - " stringByAppendingString:firstURL.lastPathComponent];
	   		}
	   		
            [self loadFilesFromURLs:urls];
        }
	}];
}

- (void) loadFilesInDirectory:(NSURL *)n	{
	//	halt the MD query, we're not going to uses it while running files manually
	[self.continuousMetadataSearch stopQuery];
		
	self.window.title = [@"Synopsis Inspector - " stringByAppendingString:n.lastPathComponent];
	
	//	now we want to run through the contents of the directory recursively...
	NSFileManager			*fm = [NSFileManager defaultManager];
	NSDirectoryEnumerationOptions		iterOpts = NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsHiddenFiles;
	NSDirectoryEnumerator				*dirIt = [fm
		enumeratorAtURL:n
		includingPropertiesForKeys:@[ NSURLIsDirectoryKey ]
		options:iterOpts
		errorHandler:nil];
	
    NSMutableArray* urls = [NSMutableArray new];
    
	for (NSURL *fileURL in dirIt)	{
		NSError			*nsErr = nil;
		NSNumber		*isDir = nil;
		if (![fileURL getResourceValue:&isDir forKey:NSURLIsDirectoryKey error:&nsErr])	{
		}
		else if (![isDir boolValue]) {
		
            [urls addObject:fileURL];
		}
	}
    
    [self loadFilesFromURLs:urls];
}


- (void) loadFilesFromURLs:(NSArray<NSURL*>*)urls
{
    
    NSMutableArray *toBeAdded = [[NSMutableArray alloc] init];
    NSArray *toBeRemoved = [self.resultsArrayController.content copy];

    // Cancel any inflight loads that have yet to finish
    [self.fileLoadingOperationQueue cancelAllOperations];
    
    self.fileLoadingProgress.doubleValue = 0.0;
    self.fileLoadingProgress.minValue = 0.0;
    self.fileLoadingProgress.maxValue = (double) urls.count;
    
    id activityToken = [[NSProcessInfo processInfo] beginActivityWithOptions:(NSActivityUserInitiated) reason:@"File Loading"];
    
    // Our completion block
    NSBlockOperation* everythingCompleted = [NSBlockOperation  blockOperationWithBlock:^{

        dispatch_async(dispatch_get_main_queue(), ^{

            NSLog(@"Finished Loading");
            
            [self.window endSheet:self.fileLoadingWindow];
            
            [self somethingUpdatedItems:@[] addedItems:toBeAdded removedItems:toBeRemoved];

            [[NSProcessInfo processInfo] endActivity:activityToken];
        });
    }];
    
    for ( NSURL* url in urls ) {

        NSBlockOperation* fileLoad = [NSBlockOperation blockOperationWithBlock:^{
        
            SynopsisMetadataItem *item = [[SynopsisMetadataItem alloc] initWithURL:url];
                                                 
            @synchronized(self) {
                if (item != nil)
                    [toBeAdded addObject:item];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.fileLoadingProgress incrementBy:1.0];
            });
            
        }];
        
        [everythingCompleted addDependency:fileLoad];
        
        [self.fileLoadingOperationQueue addOperation:fileLoad];
    }
    
    [self.fileLoadingOperationQueue addOperation:everythingCompleted];

    
    [self.window beginSheet:self.fileLoadingWindow completionHandler:^(NSModalResponse returnCode) {
        
    }];

    
//    [self.fileLoadingOperationQueue waitUntilAllOperationsAreFinished];
    

}

- (IBAction)cancelFileLoading:(id)sender
{
    [self.window endSheet:self.fileLoadingWindow];
    
    [self.fileLoadingOperationQueue cancelAllOperations];
}


#pragma mark - Metadata Results

// Method invoked when the initial query gathering is completed
// OR IF WE REPLACE THE PREDICATE
- (void)initalGatherComplete:(NSNotification*)notification	{
	//NSLog(@"%s",__func__);
	[self.continuousMetadataSearch disableUpdates];

	dispatch_async(dispatch_get_main_queue(), ^{
		[self handleInitialGatherComplete];
		
		// Continue the query
		[self.continuousMetadataSearch enableUpdates];
	});
}

- (void) handleInitialGatherComplete	{
	NSLog(@"%s",__func__);
	
	[self.resultsArrayController.content removeAllObjects];
	
	NSArray				*rawArray = [self.continuousMetadataSearch.results copy];
	NSMutableArray		*tmpArray = [[NSMutableArray alloc] init];
	for (id item in rawArray)	{
		if ([item isKindOfClass:[NSMetadataItem class]]) {
            
            NSURL* urlOfItem = [NSURL fileURLWithPath: [item valueForAttribute:NSMetadataItemPathKey] ];
            
			[tmpArray addObject:urlOfItem];
		}
	}
    
    [self loadFilesFromURLs:tmpArray];
    
	NSLog(@"\tfound %ld items",tmpArray.count);
	
//	[self.resultsArrayController addObjects:tmpArray];
//	[self.resultsArrayController rearrangeObjects];
	
	[[DataController global] reloadData];
	
}

- (void)queryDidUpdate:(NSNotification*)notification	{
	//NSLog(@"%s",__func__);
	[self.continuousMetadataSearch disableUpdates];
	
	dispatch_async(dispatch_get_main_queue(), ^{
		//[self handleQueuryDidUpdate:notification.userInfo];
		NSArray *addedMDItems = [notification.userInfo objectForKey:NSMetadataQueryUpdateAddedItemsKey];
		NSArray *updatedMDItems = [notification.userInfo objectForKey:NSMetadataQueryUpdateChangedItemsKey];
		NSArray *removedMDItems = [notification.userInfo objectForKey:NSMetadataQueryUpdateRemovedItemsKey];
		
        // make an array of urls for added, updated and removed
        NSMutableArray *addedItems = [[NSMutableArray alloc] init];
        NSMutableArray *updatedItems = [[NSMutableArray alloc] init];
        NSMutableArray *removedItems = [[NSMutableArray alloc] init];

        self.fileLoadingProgress.doubleValue = 0.0;
        self.fileLoadingProgress.minValue = 0.0;
        self.fileLoadingProgress.maxValue = (double) (addedMDItems.count + updatedMDItems.count + removedItems.count);
        
        id activityToken = [[NSProcessInfo processInfo] beginActivityWithOptions:(NSActivityUserInitiated) reason:@"File Loading"];
        
        // Our completion block
        NSBlockOperation* everythingCompleted = [NSBlockOperation  blockOperationWithBlock:^{

            dispatch_async(dispatch_get_main_queue(), ^{

                NSLog(@"Finished Loading");
                
                [self.window endSheet:self.fileLoadingWindow];
                
                [self somethingUpdatedItems:updatedItems addedItems:addedItems removedItems:removedItems];
                
                [self.continuousMetadataSearch enableUpdates];
                
                [[NSProcessInfo processInfo] endActivity:activityToken];

            });
        }];

        
        for (id item in addedMDItems)
        {
            if ([item isKindOfClass:[NSMetadataItem class]]) {
                
                NSBlockOperation* fileLoad = [NSBlockOperation blockOperationWithBlock:^{
                           
                    NSURL* urlOfItem = [NSURL fileURLWithPath: [item valueForAttribute:NSMetadataItemPathKey] ];
                    
                    SynopsisMetadataItem *item = [[SynopsisMetadataItem alloc] initWithURL:urlOfItem];
                    
                    @synchronized(self) {
                        if (item != nil)
                            [addedItems addObject:item];
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.fileLoadingProgress incrementBy:1.0];
                    });
                    
                }];
                
                [everythingCompleted addDependency:fileLoad];

                [self.fileLoadingOperationQueue addOperation:fileLoad];
            }
        }
        
        for (id item in updatedMDItems)
        {
            if ([item isKindOfClass:[NSMetadataItem class]]) {
                
                NSBlockOperation* fileLoad = [NSBlockOperation blockOperationWithBlock:^{
                    
                    NSURL* urlOfItem = [NSURL fileURLWithPath: [item valueForAttribute:NSMetadataItemPathKey] ];
                    
                    SynopsisMetadataItem *item = [[SynopsisMetadataItem alloc] initWithURL:urlOfItem];
                    
                    @synchronized(self) {
                        if (item != nil)
                            [updatedItems addObject:item];
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.fileLoadingProgress incrementBy:1.0];
                    });

                }];
                
                [everythingCompleted addDependency:fileLoad];
                [self.fileLoadingOperationQueue addOperation:fileLoad];
            }
        }
        
        for (id item in removedMDItems)
        {
            if ([item isKindOfClass:[NSMetadataItem class]]) {
                
                NSBlockOperation* fileLoad = [NSBlockOperation blockOperationWithBlock:^{
                    
                    NSURL* urlOfItem = [NSURL fileURLWithPath: [item valueForAttribute:NSMetadataItemPathKey] ];
                    
                    SynopsisMetadataItem *item = [[SynopsisMetadataItem alloc] initWithURL:urlOfItem];
                    
                    @synchronized(self) {
                        if (item != nil)
                            [removedItems addObject:item];
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.fileLoadingProgress incrementBy:1.0];
                    });

                }];
                
                [everythingCompleted addDependency:fileLoad];
                [self.fileLoadingOperationQueue addOperation:fileLoad];
            }
        }
        
        [self.fileLoadingOperationQueue addOperation:everythingCompleted];

//        [self.fileLoadingOperationQueue waitUntilAllOperationsAreFinished];
        [self.window beginSheet:self.fileLoadingWindow completionHandler:^(NSModalResponse returnCode) {
            
        }];
        
        
		// Once we are finished, we
		//[self lazyCreateLayoutsWithContent:self.resultsArrayController.content];
	});
}


#pragma mark - array controller manipulation


- (void) somethingUpdatedItems:(NSArray *)updatedItems addedItems:(NSArray *)addedItems removedItems:(NSArray *)removedItems	{
	NSLog(@"%s",__func__);
	
	NSLog(@"\tadded %ld items, updated %ld items, removed %ld items", (unsigned long)addedItems.count, (unsigned long)updatedItems.count, (unsigned long)removedItems.count);
	
	//	we have to do two different things with all these items- we have to insert them into the 
	//	array controller's contents, and we also have to tell the collection view to reload/update 
	//	the corresponding items (if they're visible with the current search predicates)
	
	//	first we're going to modify the array controller's contents...
	
	NSArray				*origArrangedObjects = [[self.resultsArrayController arrangedObjects] copy];
	
	NSMutableArray		*actualItemsToUpdate = [[NSMutableArray alloc] init];
	NSMutableIndexSet	*updateIndices = [[NSMutableIndexSet alloc] init];
	for (SynopsisMetadataItem * item in updatedItems)	{
		NSUInteger		tmpIdx = [self.resultsArrayController.content indexOfObject:item];
		if (tmpIdx == NSNotFound)
			continue;
		
		[actualItemsToUpdate addObject:item];
		[updateIndices addIndex:tmpIdx];
	}
	if (updateIndices.count > 0 && updateIndices.count == actualItemsToUpdate.count)
		[self.resultsArrayController.content replaceObjectsAtIndexes:updateIndices withObjects:actualItemsToUpdate];
	
	if (removedItems.count > 0)
		[self.resultsArrayController.content removeObjectsInArray:removedItems];
	
	if (addedItems.count > 0)	{
		NSMutableArray		*tmpArray = [[NSMutableArray alloc] init];
		for (id item in addedItems)	{
			if ([item isKindOfClass:[SynopsisMetadataItem class]])	{
				[tmpArray addObject:item];
			}
		}
		[self.resultsArrayController.content addObjectsFromArray:tmpArray];
	}
	
	
	//	re-apply the sort descriptor and search predicates...
	[self.resultsArrayController rearrangeObjects];
	//	print the first 12 items in the array
	//NSLog(@"\tfirst 12 arranged objects are:");
	//for (int i=0; i<12; ++i)	{
	//	if ([self.resultsArrayController.arrangedObjects count] <= i)
	//		break;
	//	NSLog(@"\t\t%d - %@",i,[self.resultsArrayController.arrangedObjects objectAtIndex:i]);
	//}
	
	
#if RELOAD_DATA
	[self.collectionView reloadData];
#else
    
    NSArray                *newArrangedObjects = [self.resultsArrayController arrangedObjects];

    precalculate loops outside of the batch?
    
	[self.collectionView performBatchUpdates:^{
		
		//NSMutableArray		*objectsThatWereMoved = [newArrangedObjects mutableCopy];
		
		NSMutableSet		*collectionUpdate = [[NSMutableSet alloc] init];
		for (SynopsisMetadataItem * item in actualItemsToUpdate)	{
			//[objectsThatWereMoved removeObject:item];
			
			NSUInteger		tmpIdx = [newArrangedObjects indexOfObject:item];
			if (tmpIdx == NSNotFound)
				continue;
			[collectionUpdate addObject:[NSIndexPath indexPathForItem:tmpIdx inSection:0]];
		}
		if (collectionUpdate.count > 0)	{
			[self.collectionView.animator reloadItemsAtIndexPaths:collectionUpdate];
		}
		//NSLog(@"\tcollectionUpdate is %@",collectionUpdate);
		
		
		NSMutableSet		*collectionRemove = [[NSMutableSet alloc] init];
		for (SynopsisMetadataItem * item in removedItems)	{
			//[objectsThatWereMoved removeObject:item];
			
			NSUInteger		tmpIdx = [origArrangedObjects indexOfObject:item];
			if (tmpIdx == NSNotFound)
				continue;
			[collectionRemove addObject:[NSIndexPath indexPathForItem:tmpIdx inSection:0]];
		}
		if (collectionRemove.count > 0)	{
			[self.collectionView.animator deleteItemsAtIndexPaths:collectionRemove];
		}
		//NSLog(@"\tcollectionRemove is %@",collectionRemove);
		
		
		NSMutableSet		*collectionInsert = [[NSMutableSet alloc] init];
		for (SynopsisMetadataItem * item in addedItems)	{
			//[objectsThatWereMoved removeObject:item];
			
			NSUInteger		tmpIdx = [newArrangedObjects indexOfObject:item];
			if (tmpIdx == NSNotFound)
				continue;
			[collectionInsert addObject:[NSIndexPath indexPathForItem:tmpIdx inSection:0]];
		}
		if (collectionInsert.count > 0)	{
			[self.collectionView.animator insertItemsAtIndexPaths:collectionInsert];
		}
		//NSLog(@"\tcollectionInsert is %@",collectionInsert);
		
		/*
		//	now we want to make animations for the objects that we neither reloaded, removed, nor inserted- the objects that were just moved around...
		//	strangely, this doesn't make a visible difference in the UI- that's why this is commented out...
		NSMutableSet		*collectionMove = [[NSMutableSet alloc] init];
		for (SynopsisMetadataItem * item in objectsThatWereMoved)	{
			NSUInteger			oldIdx = [origArrangedObjects indexOfObject:item];
			NSUInteger			newIdx = [newArrangedObjects indexOfObject:item];
			
			if (oldIdx != NSNotFound && newIdx != NSNotFound && oldIdx != newIdx)	{
				//NSLog(@"\tmoved %ld to %ld",oldIdx,newIdx);
				NSIndexPath		*oldPath = [NSIndexPath indexPathForItem:oldIdx inSection:0];
				NSIndexPath		*newPath = [NSIndexPath indexPathForItem:newIdx inSection:0];
				[self.collectionView.animator moveItemAtIndexPath:oldPath toIndexPath:newPath];
			}
		}
		*/
		
	} completionHandler:^(BOOL finished)	{
	}];
#endif
	
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
        
        // Should have this link off of some Framework predicate maybe?
		searchPredicate = [NSPredicate predicateWithFormat:@"info_synopsis_version >= 0 || info_synopsis_descriptors LIKE '*' || video_synopsis_version >= 0 || video_synopsis_descriptors LIKE '*'"];
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
		
		// if we have any operators	 we need to ensure we wrap our search between operators with parens
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
		
		NSLog(@"Built Predicate is \"%@\"", finalSearchString);
		
		// reset to default search
		NSPredicate *searchPredicate;
		searchPredicate = [NSPredicate predicateWithFormat:finalSearchString];

		self.continuousMetadataSearch.predicate = searchPredicate;
	}
	
	[self.continuousMetadataSearch startQuery];
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
//	  if(index % 2 == 0)
//	  {
//		  if(self.topTokens )
//	  }
//	  
//	  else
//		  return self.knownColors;
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
//	  NSLog(@"%@", NSStringFromSelector(_cmd));
	
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

//	  if([self.knownColors containsObject:representedObject])
//	  {
//		  NSMenu *tokenMenu = [[NSMenu alloc] init];
//
//		  for(NSString* color in self.knownColors)
//		  {
//			  NSMenuItem *colorItem = [[NSMenuItem alloc] init];
//			  [colorItem setTitle:color];
//			  [tokenMenu addItem:colorItem];
//		  }
//		  
//		  return tokenMenu;
//	  }
	
	return nil;
}


@end
