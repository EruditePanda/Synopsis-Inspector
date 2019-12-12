//
//  TokenObject.h
//  PredicateSandbox
//
//  Created by testAdmin on 12/8/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN




//	create a TokenObject from a search string
//	parse the hierarchy of TokenObject instances in the returned instance to construct predicates
typedef NS_ENUM(NSUInteger, TokenType)	{
	Group,	//	'contents' are valid, and consist of TokenObject instances only
	Term,	//	'term' is valid
	AND,	//	'contents' and 'term' are both nil
	OR,		//	'contents' and 'term' are both nil
	NOT		//	'contents' and 'term' are both nil
};
@interface TokenObject : NSObject
+ (instancetype) createTokenGroupFromString:(NSString *)n;
@property (assign,readwrite) TokenType type;
@property (nullable,strong,readwrite) NSMutableArray<TokenObject*> * contents;
@property (nullable,strong,readwrite) NSString * term;
@property (nullable,weak,readwrite) TokenObject * parentGroup;
@property (nullable,weak,readwrite) TokenObject * prevToken;
@property (nullable,weak,readwrite) TokenObject * nextToken;
- (NSPredicate *) createPredicateWithFormat:(NSString *)n;
@end




NS_ASSUME_NONNULL_END
