//
//  ArchimadePreferenceAccessibilityViewController.m
//  Archimade
//
//  Created by mmw on 11/16/08.
//  Copyright Curcubita. All rights reserved.
//

#import "ArchimadePreferenceAccessibilityViewController.h"

extern NSString *const kArchimadeUserDefaultsSpeakableAlertKey;

@implementation ArchimadePreferenceAccessibilityViewController

@synthesize options;
@synthesize activateVoiceOver;

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
	
	if ((self = [super initWithNibName:@"PreferenceAccessibilityView" bundle:[NSBundle mainBundle]])) {
		self.options = [[NSArray alloc] initWithObjects:label, icon, identifier, nil];
	}
	
	return self;
}

- (void)loadView
{
	[super loadView];
	
	NSNumber *storedValue;
	id key;
	
	key = kArchimadeUserDefaultsSpeakableAlertKey;
	if (nil != (storedValue = [[NSUserDefaults standardUserDefaults] objectForKey:key])) {
		[activateVoiceOver setState:[storedValue boolValue] ? NSOnState : NSOffState];
	}
	storedValue = nil;
}

- (IBAction)update:(id)sender
{
	APACVC_sync = YES;
	
	[[NSUserDefaults standardUserDefaults] setObject:
		[NSNumber numberWithBool:[sender state] ? YES : NO] 
		forKey:kArchimadeUserDefaultsSpeakableAlertKey
	];
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
	APACVC_sync = NO;
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
	if (APACVC_sync) {
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
}

@end

/* EOF */