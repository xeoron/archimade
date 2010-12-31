//
//  ArchimadeAgentApplicationController.m
//  ArchimadeAgent
//
//  Created by mmw on 2/2/09.
//  Copyright 2009 Cucurbita. All rights reserved.
//

// open -b com.googlepages.openspecies.ArchimadeAgent "/Users/mmw/Desktop/Home"
// Todo: Timeout deamon, prefpanes, sync, code clean up, contextual menu; automator; app; examples

#import "ArchimadeAgentApplicationController.h"
#import "ArchimadeFileManagerAddition.h"
#import "ArchimadeProgressWindowController.h"

#import "ArchimadeAgentPlugin.h"

#define kArchimadeMaxConcurrentArchiveOperationCount 3

extern NSString *const kArchimadeTerminateProgressOperationNotificationName;
extern NSString *const kArchimadeDidReceiveWrongPriviledgesAlertNotificationName;

NSString *const kArchimadeUserDefaultsArchiveTypeKey = @"NSUserDefaults Value ArchimadeArchiveType";
NSString *const kArchimadeUserDefaultsArchiveOverwriteKey = @"NSUserDefaults Value ArchimadeArchiveOverwrite";
NSString *const kArchimadeUserDefaultsArchiveAbbreviateKey = @"NSUserDefaults Value ArchimadeArchiveAbbreviate";
NSString *const kArchimadeUserDefaultsSpeakableAlertKey = @"NSUserDefaults Value ArchimadeSpeakableAlert";
NSString *const kArchimadeUserDefaultsArchivekeepContentsKey = @"NSUserDefaults Value ArchimadeArchivekeepContents";
NSString *const kArchimadeUserDefaultsArchiveAlwaysOnDesktopKey = @"NSUserDefaults Value ArchimadeArchiveAlwaysOnDesktop";
NSString *const kArchimadeUserDefaultsArchiveRevealInFinderKey = @"NSUserDefaults Value ArchimadeArchiveRevealInFinder";
NSString *const kArchimadeUserDefaultsActivateApplicationAnywayKey = @"NSUserDefaults Value ActivateApplicationAnyway";


extern int NXArgc;
extern char** NXArgv;

@implementation ArchimadeAgentApplicationController

@synthesize archiveType;
@synthesize soundCollection;
@synthesize controllerCollection;
@synthesize archiveFileQueue;

- (void)dealloc
{
	self.archiveType = nil;
	self.soundCollection = nil;
	self.controllerCollection = nil;
	self.archiveFileQueue = nil;
	[super dealloc];
}

- (void)awakeFromMain
{	
	[self initUserDefaults];
	
	self.soundCollection = [NSArray arrayWithObjects:
		[NSSound soundNamed:@"Pop"],
		[NSSound soundNamed:@"Basso"],
		[NSSound soundNamed:@"WrongDroppedFile"],
		[NSSound soundNamed:@"WrongPriviledges"],
		nil
	];
	
	self.controllerCollection = [NSMutableArray arrayWithCapacity:5];
	self.archiveFileQueue = [NSMutableArray arrayWithCapacity:5];

	NSDistributedNotificationCenter *distributedCenter = [NSDistributedNotificationCenter defaultCenter];
	
	// [distributedCenter setSuspended:NO];
	
	[distributedCenter addObserver:self
		selector:@selector(onEventExternalPluginRequestOperation:)
		name:kArchimadeAgentPluginNotificationName
		object:kArchimadeAgentPluginIdentifierObject
	];
	
	[NSTimer scheduledTimerWithTimeInterval:60.0
		target: self selector:@selector(applicationShouldTerminateTimer:) userInfo:nil repeats:YES];
}

- (void)initUserDefaults
{
	if (nil == [[NSUserDefaults standardUserDefaults] objectForKey:kArchimadeUserDefaultsArchiveTypeKey]) {
		[[NSUserDefaults standardUserDefaults] setObject:
		 [NSNumber numberWithInt:0] forKey:kArchimadeUserDefaultsArchiveTypeKey];
	}
	
	self.archiveType = [[NSUserDefaults standardUserDefaults] objectForKey:kArchimadeUserDefaultsArchiveTypeKey];
	
	if (nil == [[NSUserDefaults standardUserDefaults] objectForKey:kArchimadeUserDefaultsSpeakableAlertKey]) {
		[[NSUserDefaults standardUserDefaults] setObject:
		 [NSNumber numberWithBool:NO] forKey:kArchimadeUserDefaultsSpeakableAlertKey];
	}
	
	if (nil == [[NSUserDefaults standardUserDefaults] objectForKey:kArchimadeUserDefaultsArchiveOverwriteKey]) {
		[[NSUserDefaults standardUserDefaults] setObject:
		 [NSNumber numberWithBool:NO] forKey:kArchimadeUserDefaultsArchiveOverwriteKey];
	}
	
	if (nil == [[NSUserDefaults standardUserDefaults] objectForKey:kArchimadeUserDefaultsArchiveAbbreviateKey]) {
		[[NSUserDefaults standardUserDefaults] setObject:
		 [NSNumber numberWithBool:NO] forKey:kArchimadeUserDefaultsArchiveAbbreviateKey];
	}
	
	if (nil == [[NSUserDefaults standardUserDefaults] objectForKey:kArchimadeUserDefaultsArchivekeepContentsKey]) {
		[[NSUserDefaults standardUserDefaults] setObject:
		 [NSNumber numberWithBool:YES] forKey:kArchimadeUserDefaultsArchivekeepContentsKey];
	}
	
	if (nil == [[NSUserDefaults standardUserDefaults] objectForKey:kArchimadeUserDefaultsArchiveAlwaysOnDesktopKey]) {
		[[NSUserDefaults standardUserDefaults] setObject:
		 [NSNumber numberWithBool:NO] forKey:kArchimadeUserDefaultsArchiveAlwaysOnDesktopKey];
	}
	
	if (nil == [[NSUserDefaults standardUserDefaults] objectForKey:kArchimadeUserDefaultsArchiveRevealInFinderKey]) {
		[[NSUserDefaults standardUserDefaults] setObject:
		 [NSNumber numberWithBool:YES] forKey:kArchimadeUserDefaultsArchiveRevealInFinderKey];
	}
	
	if (nil == [[NSUserDefaults standardUserDefaults] objectForKey:kArchimadeUserDefaultsActivateApplicationAnywayKey]) {
		[[NSUserDefaults standardUserDefaults] setObject:
		 [NSNumber numberWithBool:NO] forKey:kArchimadeUserDefaultsActivateApplicationAnywayKey];
	}
}

- (void)applicationShouldTerminateTimer:(NSTimer *)timer
{
	if (![self.controllerCollection count]) {
		[timer invalidate];
		[[NSApplication sharedApplication] terminate:self];
	}
}

- (void)applicationWillBecomeActive:(NSNotification *)aNotification
{
	NSLog(@"applicationWillBecomeActive: %@", aNotification);
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{	
	[[NSNotificationCenter defaultCenter] addObserver:self 
		selector:@selector(onEventDidReceiveWrongPriviledgesAlert:) 
		name:kArchimadeDidReceiveWrongPriviledgesAlertNotificationName object:nil];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	int i = 0;
	id controller;
	
	if ([self.controllerCollection count]) {
		do {
			if (nil != (controller = [self.controllerCollection objectAtIndex:i])) {
				if ([[controller class] instancesRespondToSelector:@selector(stopOperation)]) {
					[controller performSelector:@selector(stopOperation)];
				}
			}
		} while(++i < [self.controllerCollection count]);
	}
	
	[[NSNotificationCenter defaultCenter] removeObserver:self 
		name:kArchimadeDidReceiveWrongPriviledgesAlertNotificationName object:nil];
	
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	return NSTerminateNow;
}

- (BOOL)startOperationForFilenames:(NSArray *)filenames
{
	NSString *filename;
	NSArray *options;
	ArchimadeProgressWindowController *progressWindowController;
	BOOL success = NO;
	
	if ([filenames count] == 1) {
		filename = [[filenames objectAtIndex:0] stringByResolvingSymlinksInPath];
		if (![[NSFileManager defaultManager] isSymbolicLinkFileAtPath:filename]
			&& [[NSFileManager defaultManager] isDirectoryFileAtPath:filename] 
			&& ![[NSFileManager defaultManager] isVolumeFileAtPath:filename]) {
			if (nil != (options = [[NSArray alloc] initWithObjects:filename, self.archiveType, nil])) {
				if (nil != (progressWindowController = [[ArchimadeProgressWindowController alloc] 
						initWithRootControllerAndOptions:self options:options])) {
														
					if(![[self.soundCollection objectAtIndex:0] isPlaying])
						[[self.soundCollection objectAtIndex:0] play];
					
					[[NSNotificationCenter defaultCenter] addObserver:self 
						selector:@selector(onEventTerminateProgressOperation:) 
						name:kArchimadeTerminateProgressOperationNotificationName object:progressWindowController];
					
					[self pushWindowController:progressWindowController];			
					[progressWindowController release];
					
					success = YES;
				}
				[options release];
			}
		}
	}
	
	return success;
}

- (void)startingOperationFailed
{
	if ([[[NSUserDefaults standardUserDefaults]  objectForKey:kArchimadeUserDefaultsSpeakableAlertKey] boolValue]) {
		if (![[self.soundCollection objectAtIndex:2] isPlaying] &&
			![[self.soundCollection objectAtIndex:3] isPlaying]
			) {
			[[self.soundCollection objectAtIndex:2] play];
		}
	} else {
		if(![[self.soundCollection objectAtIndex:1] isPlaying])
			[[self.soundCollection objectAtIndex:1] play];
	}
}

- (void)onEventExternalPluginRequestOperation:(NSNotification *)aNotification
{
	NSArray *filenames;
	NSNumber *aType;
	if ([[aNotification name] isEqualToString:kArchimadeAgentPluginNotificationName]) {
		if ([[aNotification object] isEqualToString:kArchimadeAgentPluginIdentifierObject]) {
			if (nil != (aType = [[aNotification userInfo] objectForKey:kArchimadeAgentPluginUserInfoAchiveTypeKey])) {
				if (kArchimadeAgentPluginArchiveTypeDefault != [aType intValue] && [aType intValue] < 5) {
					self.archiveType = aType;
				}
			}
			
			filenames = [NSArray arrayWithObjects:[[aNotification userInfo] objectForKey:kArchimadeAgentPluginUserInfoFilePathKey], nil];
			if (![self startOperationForFilenames:filenames]) {
				[self startingOperationFailed];
			}
		}
	}
}

/*- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames
{
	BOOL onTask = NO;
	
	if (!(onTask = [self startOperationForFilenames:filenames])) {
		[self startingOperationFailed];
	}
}*/

- (void)onEventTerminateProgressOperation:(NSNotification *)aNotification
{
	if ([[aNotification name] isEqualToString:kArchimadeTerminateProgressOperationNotificationName]) {
		[[NSNotificationCenter defaultCenter] removeObserver:self 
			name:kArchimadeTerminateProgressOperationNotificationName object:[aNotification object]];
		[self popWindowController:[aNotification object]];
	}
}

- (void)onEventDidReceiveWrongPriviledgesAlert:(NSNotification *)aNotification
{
	if ([[aNotification name] isEqualToString:kArchimadeDidReceiveWrongPriviledgesAlertNotificationName]) {
		if ([[[NSUserDefaults standardUserDefaults]  objectForKey:kArchimadeUserDefaultsSpeakableAlertKey] boolValue]) {
			if (![[self.soundCollection objectAtIndex:2] isPlaying] &&
				![[self.soundCollection objectAtIndex:3] isPlaying]
				) {
				[[self.soundCollection objectAtIndex:3] play];
			}
		}
	}
}

- (void)pushWindowController:(id)controller
{
	[controller showWindow:self];
	if ([self.controllerCollection count] < kArchimadeMaxConcurrentArchiveOperationCount) {
		[controller startOperation];
	}
	
	[self.controllerCollection addObject:controller];
}

- (void)popWindowController:(id)controller
{
	if ([self.controllerCollection count] > kArchimadeMaxConcurrentArchiveOperationCount) {
		id aController = [self.controllerCollection objectAtIndex:kArchimadeMaxConcurrentArchiveOperationCount];
		if (![aController isCancelled])
			[aController startOperation];
	}
	
	[self.controllerCollection removeObject:controller];
	controller = nil;
}

- (void)archiveFileQueueAdd:(NSString *)archiveFilePath
{
	[self.archiveFileQueue addObject:archiveFilePath];
}

- (void)archiveFileQueueRemove:(NSString *)archiveFilePath
{
	[self.archiveFileQueue removeObject:archiveFilePath];
}

- (NSNumber *)archiveFileQueueExists:(NSString *)archiveFilePath
{
	BOOL ret = NSNotFound == [self.archiveFileQueue indexOfObject:archiveFilePath] ? NO : YES;
	
	return [NSNumber numberWithBool:ret];
}

@end

/* EOF */
