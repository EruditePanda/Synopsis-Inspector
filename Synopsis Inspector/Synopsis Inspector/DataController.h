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




NS_ASSUME_NONNULL_BEGIN

@interface DataController : NSObject <NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout>	{
	IBOutlet AppDelegate		*appDelegate;
}

+ (instancetype) global;

- (SynopsisMetadataItem*) firstSelectedItem;

- (void) reloadData;
- (void) updateStatusLabel;
- (void) setupSortUsingSortDescriptor:(NSSortDescriptor*) sortDescriptor selectedItem:(SynopsisMetadataItem*)item;
- (void) setupFilterUsingPredicate:(NSPredicate*)predicate selectedItem:(SynopsisMetadataItem*)item;

- (IBAction) zoomSliderUsed:(id)sender;

@end

NS_ASSUME_NONNULL_END
