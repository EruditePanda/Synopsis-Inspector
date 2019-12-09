//
//  TokenObject.m
//  PredicateSandbox
//
//  Created by testAdmin on 12/8/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import "TokenObject.h"








//	we create one "ParseObject" per character in a "search string".
//	this characterizes the nature of each letter in the search string.
typedef NS_ENUM(NSUInteger, ParseType)	{
	PT_BeginGroup,		//	(
	PT_EndGroup,		//	)
	PT_Quote,			//	"
	PT_Space,			//	any whitespace char
	PT_Char,			//	anything not already defined
};

@interface ParseObject : NSObject
+ (instancetype) createWithType:(ParseType)n index:(NSUInteger)i;
- (instancetype) initWithType:(ParseType)n index:(NSUInteger)i;
@property (assign,readwrite) ParseType type;
@property (assign,readwrite) NSUInteger index;
@property (weak,readwrite) ParseObject *prevToken;
@property (weak,readwrite) ParseObject *nextToken;
- (NSUInteger) indexOfLastChar;
- (NSUInteger) indexOfNextChar;
@end


@implementation ParseObject
+ (instancetype) createWithType:(ParseType)n index:(NSUInteger)i	{
	return [[ParseObject alloc] initWithType:n index:i];
}
- (instancetype) initWithType:(ParseType)n index:(NSUInteger)i	{
	self = [super init];
	if (self != nil)	{
		self.type = n;
		self.index = i;
	}
	return self;
}
- (NSUInteger) indexOfLastChar	{
	if (self.type == PT_Char)
		return self.index;
	
	NSUInteger		returnMe = NSNotFound;
	ParseObject		*targetObject = self;
	while (targetObject != nil)	{
		targetObject = targetObject.prevToken;
		if (targetObject != nil && targetObject.type == PT_Char)	{
			returnMe = targetObject.index;
			break;
		}
	}
	return returnMe;
}
- (NSUInteger) indexOfNextChar	{
	if (self.type == PT_Char)
		return self.index;
	
	NSUInteger		returnMe = NSNotFound;
	ParseObject		*targetObject = self;
	while (targetObject != nil)	{
		targetObject = targetObject.nextToken;
		if (targetObject != nil && targetObject.type == PT_Char)	{
			returnMe = targetObject.index;
			break;
		}
	}
	return returnMe;
}
@end








//	we create a flat array of "InstructionObject" instances based on the type, order, and context of "ParseObject" instances
typedef NS_ENUM(NSUInteger, InstructionType)	{
	IT_BeginGroup,
	IT_EndGroup,
	IT_BeginString,
	IT_EndString
};

@interface InstructionObject : NSObject
+ (instancetype) createWithType:(InstructionType)n index:(NSUInteger)i;
- (instancetype) initWithType:(InstructionType)n index:(NSUInteger)i;
@property (assign,readwrite) InstructionType type;
@property (assign,readwrite) NSUInteger index;
@end


@implementation InstructionObject : NSObject
+ (instancetype) createWithType:(InstructionType)n index:(NSUInteger)i	{
	return [[InstructionObject alloc] initWithType:n index:i];
}
- (instancetype) initWithType:(InstructionType)n index:(NSUInteger)i	{
	self = [super init];
	if (self != nil)	{
		self.type = n;
		self.index = i;
	}
	return self;
}
- (NSString *) description	{
	switch (self.type)	{
	case IT_BeginGroup:
		return @"BG";
	case IT_EndGroup:
		return @"EG";
	case IT_BeginString:
		return [NSString stringWithFormat:@"BS-%ld",self.index];
	case IT_EndString:
		return [NSString stringWithFormat:@"ES-%ld",self.index];
	}
}
@end








//	we create a hierarchy of "TokenObject" instances from the flat array of "InstructionObject" instances
//	TokenObjects are groups, words, or logical operators
@interface TokenObject ()
+ (instancetype) createGroupInTokenGroup:(TokenObject *)t;
+ (void) createTokenFromString:(NSString *)n inTokenGroup:(TokenObject *)t;
- (instancetype) init;
- (void) validate;
@end


@implementation TokenObject : NSObject
+ (instancetype) createTokenGroupFromString:(NSString *)rawSearchString	{
	//NSLog(@"%s ... %@",__func__,rawSearchString);
	
	//	do a quick count, looking for basic errors:
	//	- if the search term doesn't have equal numbers of ( and ) then the syntax is broken
	//	- if the search term doesn't have even numbers of " then the syntax is broken
	//	- if there's an open or close paren between quotes, the syntax is broken
	
	int			openParenCount = 0;
	int			closeParenCount = 0;
	int			quoteCount = 0;
	BOOL		syntaxErr = NO;
	for (int i=0; i<rawSearchString.length; ++ i)	{
		unichar		tmpChar = [rawSearchString characterAtIndex:i];
		switch (tmpChar)	{
		case '(':
			++openParenCount;
			if (quoteCount % 2 != 0)
				syntaxErr = YES;
			break;
		case ')':
			++closeParenCount;
			if (quoteCount % 2 != 0)
				syntaxErr = YES;
			break;
		case '\"':
			++quoteCount;
			break;
		}
	}
	if (syntaxErr || openParenCount != closeParenCount || quoteCount % 2 != 0)	{
		NSLog(@"ERR: syntax bad (%@)",rawSearchString);
		return nil;
	}
	
	NSString			*searchString = [rawSearchString stringByAppendingString:@" "];
	
	//	run through the search term, making a doubly-linked list of tokens for the chars in the search string
	NSMutableArray		*parseObjects = [[NSMutableArray alloc] init];
	ParseObject			*currentToken = nil;
	for (int i=0; i<searchString.length; ++ i)	{
		ParseObject			*newToken = nil;
		unichar				tmpChar = [searchString characterAtIndex:i];
		switch (tmpChar)	{
		case '(':
			newToken = [ParseObject createWithType:PT_BeginGroup index:i];
			break;
		case ')':
			newToken = [ParseObject createWithType:PT_EndGroup index:i];
			break;
		case '\"':
			newToken = [ParseObject createWithType:PT_Quote index:i];
			break;
		case ' ':
		case '\t':
		case '\n':
		case '\r':
			newToken = [ParseObject createWithType:PT_Space index:i];
			break;
		default:
			newToken = [ParseObject createWithType:PT_Char index:i];
			break;
		}
		
		newToken.prevToken = currentToken;
		if (currentToken != nil)
			currentToken.nextToken = newToken;
		
		[parseObjects addObject:newToken];
		
		currentToken = newToken;
	}
	
	//	run through the parse token array, looking for patterns that indicate bad syntax in the search terms
	for (ParseObject *parseObject in parseObjects)	{
		//	char-quote-char is bad syntax
		if (parseObject.type == PT_Char)	{
			ParseObject		*prevObject = parseObject.prevToken;
			ParseObject		*prevPrevObject = (prevObject==nil) ? nil : prevObject.prevToken;
			if (prevObject != nil && prevPrevObject != nil && prevPrevObject.type == PT_Char && prevObject.type == PT_Quote)	{
				NSLog(@"ERR: syntax bad (%@)",rawSearchString);
				return nil;
			}
		}
	}
	
	//	now make an instruction object array by running through the parse token array and making new tokens where necessary
	NSMutableArray		*instructionObjects = [[NSMutableArray alloc] init];
	BOOL				hasOpenQuote = NO;
	BOOL				hasOpenString = NO;
	int					openGroupCount = 0;
	for (ParseObject *parseObject in parseObjects)	{
		if (parseObject.type == PT_BeginGroup)	{
			if (hasOpenString)	{
				hasOpenString = NO;
				NSUInteger		lastCharIndex = [parseObject indexOfLastChar];
				[instructionObjects addObject:[InstructionObject createWithType:IT_EndString index:lastCharIndex]];
			}
			++openGroupCount;
			[instructionObjects addObject:[InstructionObject createWithType:IT_BeginGroup index:parseObject.index]];
		}
		else if (parseObject.type == PT_EndGroup)	{
			if (hasOpenString)	{
				hasOpenString = NO;
				NSUInteger		lastCharIndex = [parseObject indexOfLastChar];
				[instructionObjects addObject:[InstructionObject createWithType:IT_EndString index:lastCharIndex]];
			}
			--openGroupCount;
			[instructionObjects addObject:[InstructionObject createWithType:IT_EndGroup index:parseObject.index]];
		}
		else if (parseObject.type == PT_Quote)	{
			if (hasOpenString && hasOpenQuote)	{
				hasOpenString = NO;
				hasOpenQuote = NO;
				NSUInteger		lastCharIndex = [parseObject indexOfLastChar];
				[instructionObjects addObject:[InstructionObject createWithType:IT_EndString index:lastCharIndex]];
			}
			else if (!hasOpenString)	{
				hasOpenString = YES;
				hasOpenQuote = YES;
				NSUInteger		nextCharIndex = [parseObject indexOfNextChar];
				[instructionObjects addObject:[InstructionObject createWithType:IT_BeginString index:nextCharIndex]];
			}
		}
		else if (parseObject.type == PT_Char)	{
			if (!hasOpenString)	{
				hasOpenString = YES;
				[instructionObjects addObject:[InstructionObject createWithType:IT_BeginString index:parseObject.index]];
			}
		}
		else if (parseObject.type == PT_Space)	{
			if (hasOpenString && !hasOpenQuote)	{
				hasOpenString = NO;
				NSUInteger		lastCharIndex = [parseObject indexOfLastChar];
				[instructionObjects addObject:[InstructionObject createWithType:IT_EndString index:lastCharIndex]];
			}
		}
	}
	//NSLog(@"\tinstructionObjects are %@",instructionObjects);
	
	//	now run through the instruction object array, creating tokens for the actual terms
	TokenObject			*topGroup = [[TokenObject alloc] init];
	topGroup.type = Group;
	TokenObject			*targetGroup = topGroup;
	NSUInteger			stringStartIndex = NSNotFound;
	for (InstructionObject * instructionObject in instructionObjects)	{
		if (instructionObject.type == IT_BeginGroup)	{
			stringStartIndex = NSNotFound;
			
			TokenObject		*newGroup = [TokenObject createGroupInTokenGroup:targetGroup];
			targetGroup = newGroup;
		}
		else if (instructionObject.type == IT_EndGroup)	{
			stringStartIndex = NSNotFound;
			
			targetGroup = targetGroup.parentGroup;
			if (targetGroup == nil)
				targetGroup = topGroup;
		}
		else if (instructionObject.type == IT_BeginString)	{
			stringStartIndex = instructionObject.index;
		}
		else if (instructionObject.type == IT_EndString)	{
			if (stringStartIndex != NSNotFound)	{
				NSRange			tmpRange = NSMakeRange(stringStartIndex, instructionObject.index + 1 - stringStartIndex);
				if (tmpRange.length > 0)	{
					NSString		*tmpStr = [searchString substringWithRange:tmpRange];
					[TokenObject createTokenFromString:tmpStr inTokenGroup:targetGroup];
				}
			}
		}
	}
	//	validate the top group
	[topGroup validate];
	
	
	//	if the top-level group is empty, return nil;
	if (topGroup.contents.count < 1)	{
		topGroup = nil;
	}
	//	else if the top-level group only has one item, and that item is a term or another group, just return that
	else if (topGroup.contents.count == 1
	&& (topGroup.contents[0].type == Term || topGroup.contents[0].type == Group))	{
		topGroup = topGroup.contents[0];
		topGroup.parentGroup = nil;
	}
	
	//NSLog(@"returning %@",topGroup);
	
	return topGroup;
}
+ (instancetype) createGroupInTokenGroup:(TokenObject *)tg	{
	if (tg == nil || tg.type != Group)
		return nil;
	TokenObject		*newGroup = [[TokenObject alloc] init];
	newGroup.type = Group;
	newGroup.parentGroup = tg;
	
	if (tg.contents.count > 0)	{
		tg.contents.lastObject.nextToken = newGroup;
		newGroup.prevToken = tg.contents.lastObject;
	}
	
	[tg.contents addObject:newGroup];
	
	return newGroup;
}
+ (void) createTokenFromString:(NSString *)n inTokenGroup:(TokenObject *)tg	{
	if (tg == nil || tg.type != Group || n == nil)
		return;
	if ([n characterAtIndex:0] == '!')	{
		TokenObject		*notObject = [[TokenObject alloc] init];
		notObject.type = NOT;
		[tg.contents addObject:notObject];
		
		NSRange		remainingRange = NSMakeRange(1,n.length-1);
		if (remainingRange.length > 0)	{
			NSString		*remainingString = [n substringWithRange:remainingRange];
			[TokenObject createTokenFromString:remainingString inTokenGroup:tg];
		}
	}
	else if ([n caseInsensitiveCompare:@"and"] == NSOrderedSame || [n caseInsensitiveCompare:@"&&"] == NSOrderedSame)	{
		TokenObject		*andObject = [[TokenObject alloc] init];
		andObject.type = AND;
		[tg.contents addObject:andObject];
	}
	else if ([n caseInsensitiveCompare:@"or"] == NSOrderedSame || [n caseInsensitiveCompare:@"||"] == NSOrderedSame)	{
		TokenObject		*orObject = [[TokenObject alloc] init];
		orObject.type = OR;
		[tg.contents addObject:orObject];
	}
	else if ([n caseInsensitiveCompare:@"not"] == NSOrderedSame)	{
		TokenObject		*notObject = [[TokenObject alloc] init];
		notObject.type = NOT;
		[tg.contents addObject:notObject];
	}
	else	{
		TokenObject		*strToken = [[TokenObject alloc] init];
		strToken.type = Term;
		strToken.term = n;
		[tg.contents addObject:strToken];
	}
	
	//	run through all the tokens in my group, fixing the next/prev/parent token ptrs
	[tg _fixNextPrevParentTokenPtrs];
}
- (instancetype) init	{
	self = [super init];
	if (self != nil)	{
		self.type = Group;
		self.contents = [[NSMutableArray alloc] init];
		self.term = nil;
		self.parentGroup = nil;
	}
	return self;
}
- (NSString *) description	{
	return [self _tabIndentedDescription:0];
}
- (NSString *) _tabIndentedDescription:(int)idnt	{
	NSMutableString		*returnMe = [[NSMutableString alloc] init];
	switch (self.type)	{
	case Group:
		{
			for (int i=0; i<idnt; ++i)
				[returnMe appendString:@"\t"];
			[returnMe appendString:@"{\r"];
			
			for (TokenObject *subObj in self.contents)
				[returnMe appendString:[subObj _tabIndentedDescription:idnt+1]];
			
			for (int i=0; i<idnt; ++i)
				[returnMe appendString:@"\t"];
			[returnMe appendString:@"}\r"];
		}
		break;
	case Term:
		{
			for (int i=0; i<idnt; ++i)
				[returnMe appendString:@"\t"];
			[returnMe appendFormat:@"\"%@\"\r",self.term];
		}
		break;
	case AND:
		{
			for (int i=0; i<idnt; ++i)
				[returnMe appendString:@"\t"];
			[returnMe appendString:@"AND\r"];
		}
		break;
	case OR:
		{
			for (int i=0; i<idnt; ++i)
				[returnMe appendString:@"\t"];
			[returnMe appendString:@"OR\r"];
		}
		break;
	case NOT:
		{
			for (int i=0; i<idnt; ++i)
				[returnMe appendString:@"\t"];
			[returnMe appendString:@"NOT\r"];
		}
		break;
	}
	return [returnMe copy];
}
- (void) validate	{
	//	run through myself and all my sub-tokens, make sure that everything's valid
	//	at this time, this just means "insert AND tokens where it looks like operators are missing"
	
	/*		this means:
		- if the last token in the group is an && or || or ! operator, delete it
		- if the first token in the group is an && or || operator, delete it
		- if there are any groups that only contain an operator, delete them
		- if there are any groups that only contain a single term, get rid of the group wrapper and move the term "up" in the hierarchy
		- insert an && operator if there are any term/term or group/term or group/group pairs that don't have an operator between them
	*/
	
	if (self.type == Group)	{
		//NSLog(@"%s ... %d, %@",__func__,self.type,self);
		
		//	first run through and take care of the recursive stuff
		//NSLog(@"\tfirst validating contents recursively...");
		for (TokenObject * token in self.contents)	{
			[token validate];
		}
		
		BOOL			foundInvalidToken = NO;
		
		
		//	if the last token in my group is an operator, delete it
		do	{
			foundInvalidToken = NO;
			
			if (self.type == Group
			&& self.contents.count > 0
			&& (self.contents.lastObject.type == AND || self.contents.lastObject.type == OR || self.contents.lastObject.type == NOT))	{
				//	flag this so we know to repeat the do/while loop again...
				foundInvalidToken = YES;
				
				[self.contents removeObjectAtIndex:self.contents.count-1];
				
				//	run through all the tokens in my group, fixing the next/prev/parent token ptrs
				[self _fixNextPrevParentTokenPtrs];
			}
		} while (foundInvalidToken);
		
		
		
		
		//	check my contents for groups that start with an operator (delete them)
		do	{
			foundInvalidToken = NO;
			
			if (self.contents.count > 0 && (self.contents[0].type == AND || self.contents[0].type == OR))	{
				//	flag this so we know to repeat the do/while loop again...
				foundInvalidToken = YES;
				
				[self.contents removeObjectAtIndex:0];
				
				//	run through all the tokens in my group, fixing the next/prev/parent token ptrs
				[self _fixNextPrevParentTokenPtrs];
			}
		} while (foundInvalidToken);
		
		
		
		
		//	check my contents for groups that only contain operators (delete them) or groups that only contain a single term or single group (get rid of the group, move the term up a level in the hierarchy)
		do	{
			//NSLog(@"\tchecking for groups that can be trimmed or shifted, contents have %d items",self.contents.count);
			foundInvalidToken = NO;
			NSUInteger			tokenIndex = 0;
			for (TokenObject * token in self.contents)	{
				//	if this token is a group...
				if (token.type == Group)	{
					//NSLog(@"\t\tchecking token at index %d, has %d items",tokenIndex, token.contents.count);
					//	if the subgroup is empty, or the subgroup's only item is an operator, delete it
					if (token.contents.count == 0
					|| (token.contents.count == 1 && (token.contents[0].type == AND || token.contents[0].type == OR || token.contents[0].type == NOT)))	{
						//	flag this so we know to repeat the do/while loop again...
						foundInvalidToken = YES;
						
						[self.contents removeObjectAtIndex:tokenIndex];
						
						//	run through all the tokens in my group, fixing the next/prev/parent token ptrs
						[self _fixNextPrevParentTokenPtrs];
						//	break the for loop, let the do/while loop again
						break;
					}
					//	else if the only item in the subgroup is a term or group, move it up and replace the subgroup with the subgroup's only item
					else if (token.contents.count == 1 && (token.contents[0].type == Term || token.contents[0].type == Group))	{
						//	flag this so we know to repeat the do/while loop again...
						foundInvalidToken = YES;
						
						[self.contents insertObject:token.contents[0] atIndex:tokenIndex+1];
						[self.contents removeObjectAtIndex:tokenIndex];
						
						//	run through all the tokens in my group, fixing the next/prev/parent token ptrs
						[self _fixNextPrevParentTokenPtrs];
						//	break the for loop, let the do/while loop again
						break;
					}
				}
				//else
					//NSLog(@"\t\ttoken at index %d is not a group",tokenIndex);
				
				++tokenIndex;
			}
		} while (foundInvalidToken);
		
		
		
		
		//	check the tokens in my contents for missing operators...
		do	{
			foundInvalidToken = NO;
			NSUInteger		insertionIndex = 0;
			for (TokenObject * token in self.contents)	{
				//	if this is a term and the previous token was either a group or another term....we need to insert an operator
				if ((token.type == Term || token.type == Group)
				&& (token.prevToken != nil && (token.prevToken.type == Group || token.prevToken.type == Term)))	{
					//	flag this so we know to repeat the do/while loop again...
					foundInvalidToken = YES;
					
					//	make a new 'AND' token, insert it at the appropriate index
					TokenObject		*newToken = [[TokenObject alloc] init];
					newToken.type = AND;
					newToken.parentGroup = self;
					[self.contents insertObject:newToken atIndex:insertionIndex];
				
					//	run through all the tokens in my group, fixing the next/prev/parent token ptrs
					[self _fixNextPrevParentTokenPtrs];
					//	break the for loop, let the do/while loop again
					break;
				}
				
				++insertionIndex;
			}
		} while (foundInvalidToken);
		
		//NSLog(@"\t\tdone validating...");
	}
}
- (void) _fixNextPrevParentTokenPtrs	{
	//NSLog(@"%s",__func__);
	if (self.type != Group)	{
		return;
	}
	TokenObject		*lastToken = nil;
	for (TokenObject * tmpToken in self.contents)	{
		if (lastToken != nil)
			lastToken.nextToken = tmpToken;
		tmpToken.prevToken = lastToken;
		
		tmpToken.parentGroup = self;
		
		lastToken = tmpToken;
	}
	lastToken.nextToken = nil;
	
	/*
	NSUInteger		tmpIndex = 0;
	for (TokenObject * tmpToken in self.contents)	{
		NSLog(@"\ttoken idx %d has prev (%@) and next (%@)", tmpIndex, tmpToken.prevToken, tmpToken.nextToken);
		++tmpIndex;
	}
	*/
}
- (NSPredicate *) createPredicateWithFormat:(NSString *)n	{
	//NSLog(@"%s ... %@",__func__,n);
	if (n == nil)
		return nil;
	
	NSPredicate			*lastPredicate = nil;
	@try	{
		NSArray				*fakeContents = nil;
		if (self.type == Group)
			fakeContents = self.contents.copy;
		else if (self.type == Term)
			fakeContents = @[ self ];
		
		for (TokenObject * token in fakeContents)	{
			if (token.type == AND || token.type == OR || token.type == NOT)	{
				//	do nothing, we "back up" and process op tokens while we're processing terms/groups...
			}
			else	{
				//	make a predicate for this token, which is either a group or a term
				NSPredicate			*thisPredicate = nil;
				if (token.type == Group)
					thisPredicate = [token createPredicateWithFormat:n];
				else
					thisPredicate = [NSPredicate predicateWithFormat:n, token.term];
			
				TokenObject			*prevToken = token.prevToken;
				//	if the prev token was a NOT token, make a compound predicate and move the prev token back another slot
				if (prevToken != nil && prevToken.type == NOT)	{
					thisPredicate = [NSCompoundPredicate notPredicateWithSubpredicate:thisPredicate];
					prevToken = prevToken.prevToken;
				}
			
				if (lastPredicate != nil && thisPredicate != nil && prevToken != nil)	{
					if (prevToken.type == AND)	{
						NSCompoundPredicate		*compPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[ lastPredicate, thisPredicate ]];
						lastPredicate = compPredicate;
					}
					else if (prevToken.type == OR)	{
						NSCompoundPredicate		*compPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[ lastPredicate, thisPredicate ]];
						lastPredicate = compPredicate;
					}
					else	{
						lastPredicate = thisPredicate;
					}
				}
				else	{
					lastPredicate = thisPredicate;
				}
			}
		}
	}
	@catch (NSException *err)	{
		NSLog(@"ERR: caught exception %@ in %s",err,__func__);
	}
	
	return lastPredicate;
}
@end


















