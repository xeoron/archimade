//
//  ArchimadePreferenceAdvancedViewController.m
//  Archimade
//
//  Created by mmw on 11/16/08.
//  Copyright Curcubita. All rights reserved.
//

#import "ArchimadePreferenceAdvancedViewController.h"

extern NSString *const kArchimadeUserDefaultsArchivekeepContentsKey;
extern NSString *const kArchimadeUserDefaultsArchiveAlwaysOnDesktopKey;
extern NSString *const kArchimadeUserDefaultsArchiveRevealInFinderKey;
extern NSString *const kArchimadeUserDefaultsActivateApplicationAnywayKey;

@implementation ArchimadePreferenceAdvancedViewController

@synthesize options;
@synthesize keepMacOSContents;
@synthesize archiveOnDesktop;
@synthesize revealInFinder;
@synthesize activateApplication;

- (void)dealloc
{
	[self.options release];
	[super dealloc];
}

- (id)initWithLabelAndIcon:(NSString *)label icon:(NSImage *)icon identifier:(NSString *)identifier
{
	NSParameterAssert(nil != label);
	NSParameterAssert(nil != icon);
	NSParameterAssert(nil != identifier);
	
	if ((self = [super initWithNibName:@"PreferenceAdvancedView" bundle:[NSBundle mainBundle]])) {
		self.options = [[NSArray alloc] initWithObjects:label, icon, identifier, nil];
	}
	
	return self;
}

- (void)loadView
{
	[super loadView];
	
	NSNumber *storedValue;
	id key;
	
	key = kArchimadeUserDefaultsArchivekeepContentsKey;
	if (nil != (storedValue = [[NSUserDefaults standardUserDefaults] objectForKey:key])) {
		[keepMacOSContents setState:[storedValue boolValue] ? NSOnState : NSOffState];
	}
	storedValue = nil;
	
	key = kArchimadeUserDefaultsArchiveAlwaysOnDesktopKey;
	if (nil != (storedValue = [[NSUserDefaults standardUserDefaults] objectForKey:key])) {
		[archiveOnDesktop setState:[storedValue boolValue] ? NSOnState : NSOffState];
	}
	storedValue = nil;
	
	key = kArchimadeUserDefaultsArchiveRevealInFinderKey;
	if (nil != (storedValue = [[NSUserDefaults standardUserDefaults] objectForKey:key])) {
		[revealInFinder setState:[storedValue boolValue] ? NSOnState : NSOffState];
	}
	storedValue = nil;
	
	key = kArchimadeUserDefaultsActivateApplicationAnywayKey;
	if (nil != (storedValue = [[NSUserDefaults standardUserDefaults] objectForKey:key])) {
		[activateApplication setState:[storedValue boolValue] ? NSOnState : NSOffState];
	}
	storedValue = nil;
	
	if ([archiveOnDesktop state]) {
		[revealInFinder setEnabled:NO];
	}
}

- (IBAction)update:(id)sender
{
	APADVC_sync = YES;
	id senderItemKey;
	BOOL canUpdate =  YES;
	
	switch ([sender tag]) {
		case 0:
			senderItemKey = kArchimadeUserDefaultsArchivekeepContentsKey;
			break;
		case 1:
			senderItemKey = kArchimadeUserDefaultsArchiveAlwaysOnDesktopKey;
			[revealInFinder setEnabled:[sender state] ? NO : YES];
			break;
		case 2:
			senderItemKey = kArchimadeUserDefaultsArchiveRevealInFinderKey;
			break;
		case 3:
			senderItemKey = kArchimadeUserDefaultsActivateApplicationAnywayKey;
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
	APADVC_sync = NO;
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
	if (APADVC_sync) {
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
}

@end

/* EOF */