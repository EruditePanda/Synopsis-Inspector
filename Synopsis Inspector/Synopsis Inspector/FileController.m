//
//  FileController.m
//  Synopsis Inspector
//
//  Created by testAdmin on 11/27/19.
//  Copyright © 2019 v002. All rights reserved.
//

#import "FileController.h"

#import "AppDelegate.h"
#import "DataController.h"
#import <Synopsis/Synopsis.h>




@interface FileController ()

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSWindow *chooseSearchModeSheet;
@property (weak) IBOutlet NSCollectionView* collectionView;
@property (weak) IBOutlet NSArrayController * resultsArrayController;
@property (weak) IBOutlet DataController * dataController;

// Tokens
@property (strong) NSDictionary* tokenDictionary;
@property (weak) IBOutlet NSTokenField* tokenField;

@property (strong) NSMetadataQuery* continuousMetadataSearch;

@end




@implementation FileController


- (void) awakeFromNib	{
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
            [self.resultsArrayController removeObjects:self.resultsArrayController.content];

            for(NSURL* url in openPanel.URLs)
            {
                SynopsisMetadataItem* item = [[SynopsisMetadataItem alloc] initWithURL:url];
                if(item)
                    [self.resultsArrayController addObject:item];
            }
        
            NSLog(@"initial gather complete");
            
            [self.dataController reloadData];

            self.window.title = [@"Synopsis Inspector - " stringByAppendingString:openPanel.URL.lastPathComponent];
        }
        
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
    [self.resultsArrayController removeObjects:self.resultsArrayController.content];
    
    // Ideally, we want to run an initial populate pass
    // And then animate things coming and going
    // However we have problems comparing objects in sets
    // since I dont know why.
    
//    if(self.resultsArray.count == 0)
    {
        NSLog(@"initial gather complete");
        
        [self.resultsArrayController addObjects:[self.continuousMetadataSearch.results mutableCopy] ];
        
        [self.dataController reloadData];
    
        if([self.resultsArrayController.content count])
        {
//            [self lazyCreateLayoutsWithContent:self.resultsArrayController.content];
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
        //[self lazyCreateLayoutsWithContent:self.resultsArrayController.content];
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
        NSIndexPath* updatedItemPath = [NSIndexPath indexPathForItem:[self.resultsArrayController.content indexOfObject:item] inSection:0];
        [updatedIndexPaths addObject:updatedItemPath];
        [updatedIndexSet addIndex:[updatedItemPath item]];
    }
    // Actually update our backing
    [self.resultsArrayController.content replaceObjectsAtIndexes:updatedIndexSet withObjects:updatedItems];

    // Cache removed objects indices
    NSMutableSet* removedIndexPaths = [[NSMutableSet alloc] init];
    for(SynopsisMetadataItem* item in removedItems)
    {
        NSIndexPath* removedItemPath = [NSIndexPath indexPathForItem:[self.resultsArrayController.content indexOfObject:item] inSection:0];
        [removedIndexPaths addObject:removedItemPath];
    }
    
    // Actually remove object from our backing
    [self.resultsArrayController removeObjects:removedItems];
    
    // Add items to our array - We dont sort them yet - so we just append them at the end until the next sort.
    NSUInteger indexOfLastItem = [self.resultsArrayController.content count];
    [self.resultsArrayController addObjects:addedItems];

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


@end
