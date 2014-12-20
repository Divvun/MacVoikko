//
//  VoikkoSpellChecker.m
//  MacVoikko
//

#import "VoikkoSpellChecker.h"
#import "CocoaVoikko.h"

@interface VoikkoSpellChecker ()

@property (nonatomic, strong) NSDictionary* handles;

+ (NSString*)languageName:(NSString*)code;

@end

@implementation VoikkoSpellChecker

- (instancetype)init
{
	self = [super init];
	
	if(self)
	{
		_handles = [VoikkoSpellChecker initializeHandles];
	}
	
	return self;
}

- (NSArray *)supportedLanguages
{
//	NSArray* languageCodes = [CocoaVoikko spellingLanguagesAtPath:nil];
//	NSMutableArray* languages = [NSMutableArray arrayWithCapacity:[languageCodes count]];
//	for(NSString* languageCode in languageCodes)
//	{
//		NSString* languageName = [VoikkoSpellChecker languageName:languageCode];
//		[languages addObject:languageName];
//	}
//	return languages;
	return [CocoaVoikko spellingLanguages];
}

- (NSRange)spellServer:(NSSpellServer *)sender findMisspelledWordInString:(NSString *)stringToCheck language:(NSString *)language wordCount:(NSInteger *)wordCount countOnly:(BOOL)countOnly
{
	NSString* languageName = [VoikkoSpellChecker languageName:language];
	NSLog(@"Find misspelled word in '%@' (language %@, %@)", stringToCheck, language, languageName);
	
	CocoaVoikko* handle = self.handles[languageName];
	if(handle != nil)
	{
		return [handle nextMisspelledWord:stringToCheck wordCount:wordCount];
	}
	else
	{
		NSLog(@"Unknown language: %@", language);
		return NSMakeRange(0, 0);
	}
}

+ (NSDictionary*)initializeHandles
{
	NSError* error = nil;
	NSMutableDictionary* handles = [NSMutableDictionary dictionary];
	for(NSString* languageCode in [CocoaVoikko spellingLanguages])
	{
		NSString* languageName = [VoikkoSpellChecker languageName:languageCode];
		CocoaVoikko* handle = [[CocoaVoikko alloc] initWithLangcode:languageCode error:&error];
		
		if(handle == nil)
		{
			NSLog(@"Unable to create Voikko handle for language %@: %@", languageCode, error);
		}
		else
		{
			handles[languageName] = handle;
		}
	}
	
	return handles;
}

+ (NSString*)languageName:(NSString*)code
{
	NSLocale* enLocale = [NSLocale localeWithLocaleIdentifier:@"en"];
	return [enLocale displayNameForKey:NSLocaleIdentifier value:code];
}

@end
