//
//  Constants.h
//  Synopsis Inspector
//
//  Created by testAdmin on 1/14/20.
//  Copyright © 2020 v002. All rights reserved.
//

#ifndef Constants_h
#define Constants_h


#pragma mark - Preferences -


//	this enum describes the various options for which thumbnail frame to use from an asset
typedef NS_ENUM(NSUInteger, ThumbnailFrame)	{
	ThumbnailFrame_First = 0,
	ThumbnailFrame_Ten,
	ThumbnailFrame_Fifty
};


//	this is the name of the NSNotification fired when the user changes the thumbnail frame time
#define kSynopsisInspectorThumnailImageChangeName @"ThumbnailFrameChangeName"


//	this is the NSUserDefaults key used to store the path of the default folder to display on launch (or nil, in which case all local media is discovered via metadata query)
#define kSynopsisInspectorDefaultFolderPathKey @"DefaultFolder" //	NSString
//	this is the NSUserDefaults key used to store an int/ThumbnailFrame enum describing which frame to display as the thumbnail image
#define kSynopsisInspectorThumbnailImageKey @"ThumbnailFrame"	//	NSString


#endif /* Constants_h */
