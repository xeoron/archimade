//
//  ArchimadePreferenceGeneralViewController.m
//  Archimade
//
//  Created by mmw on 11/16/08.
//  Copyright Curcubita. All rights reserved.
//

#import "ArchimadePreferenceGeneralViewController.h"

extern NSString *const kArchimadeUserDefaultsArchiveOverwriteKey;
extern NSString *const kArchimadeUserDefaultsArchiveAbbreviateKey;

@implementation ArchimadePreferenceGeneralViewController

@synthesize options;
@synthesize overwriteArchive;
@synthesize abbreviateExtension;

- (void)dealloc
{
	[self.options release];
	[super dealloc];
}

- (id)initWithLabelAndIcon:(NSString *)label icon:(NSImage *)icon identifier:(NSString *)identifier
{
	if ((self = [super initWithNibName:@"PreferenceGeneralView" bundle:[NSBundle mainBundle]])) {
		self.options = [[NSArray alloc] initWithObjects:label, icon, identifier, nil];	
	}
	
	return self;
}

- (void)loadView
{
	[super loadView];
	
	NSNumber *storedValue;
	id key;
	
	key = kArchimadeUserDefaultsArchiveOverwriteKey;
	if (nil != (storedValue = [[NSUserDefaults standardUserDefaults] objectForKey:key])) {
		[overwriteArchive setState:[storedValue boolValue] ? NSOnState : NSOffState];
	}
	storedValue = nil;
	
	key = kArchimadeUserDefaultsArchiveAbbreviateKey;
	if (nil != (storedValue = [[NSUserDefaults standardUserDefaults] objectForKey:key])) {
		[abbreviateExtension setState:[storedValue boolValue] ? NSOnState : NSOffState];
	}
	storedValue = nil;
}

- (IBAction)update:(id)sender
{
	APGVC_sync = YES;
	id senderItemKey;
	BOOL canUpdate =  YES;
	
	switch ([sender tag]) {
		case 0:
			senderItemKey = kArchimadeUserDefaultsArchiveOverwriteKey;
			break;
		case 1:
			senderItemKey = kArchimadeUserDefaultsArchiveAbbreviateKey;
			break;
		default:
			canUpdate =  NO;
			break;
	}
	
	if (canUpdate) {
		[[NSUserDefaults standardUserDefaults] setObject:
			[NSNumber numberWithBool:[sender state] ? YES : NO] 
			forKey:senderItemKey
		];
	}
}

#pragma mark protocol methods

- (NSImage *)icon
{
	return [[self options] objectAtIndex:1];
}

- (NSString *)label
{
	return [[self options] objectAtIndex:0];
}

- (NSString *)identifier
{
	return [[self options] objectAtIndex:2];
}

- (NSView *)contentView
{
	return [self view];
}

#pragma mark protocol delegates

- (void)contentViewWillAppear
{
	APGVC_sync = NO;
}

- (void)contentViewDidAppear
{
	//
}

- (void)contentViewWillDisappear
{
	//
}

- (void)contentViewDidDisappear
{
	if (APGVC_sync) {
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
}

@end

/* EOF */