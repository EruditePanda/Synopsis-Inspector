//
//  DataController.h
//  Synopsis Inspector
//
//  Created by testAdmin on 11/27/19.
//  Copyright © 2019 v002. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Synopsis/Synopsis.h>

@class AppDelegate;
@class PlayerView;




NS_ASSUME_NONNULL_BEGIN

@interface DataController : NSObject <NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout>	{
	IBOutlet AppDelegate		*appDelegate;
	IBOutlet NSTextField		*filenameTextField;
}

+ (instancetype) global;

- (SynopsisMetadataItem*) firstSelectedItem;

- (void) reloadData;
- (void) updateStatusLabel;
- (void) setupSortUsingSortDescriptor:(nullable NSSortDescriptor*) sortDescriptor selectedItem:(nullable SynopsisMetadataItem*)item;
- (void) setupFilterUsingPredicate:(nullable NSPredicate*)predicate selectedItem:(nullable SynopsisMetadataItem*)item;

@property (readonly) PlayerView * scrubView;

- (IBAction) zoomSliderUsed:(id)sender;

@end

NS_ASSUME_NONNULL_END
