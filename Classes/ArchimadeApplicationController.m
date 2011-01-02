//
//  ArchimadeApplicationController.m
//  Archimade
//
//  Created by mmw on 11/2/08.
//  Copyright Cucurbita. All rights reserved.
//

#import "ArchimadeApplicationController.h"
#import "AUFileManagerAddition.h"
#import "ArchimadeProgressWindowController.h"
#import "AUPreferencesMultiItems.h"
#import "ArchimadePreferenceGeneralViewController.h"
#import "ArchimadePreferenceAccessibilityViewController.h"
#import "ArchimadePreferenceAdvancedViewController.h"
#import <QuartzCore/CoreAnimation.h>

#define kArchimadeMaxConcurrentArchiveOperationCount 6

extern NSString *const kArchimadeConcludeDragOperationNotificationName;
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

@interface NSOpenPanel(ArchimadeOpenPanelPrivate)

- (void)setShowsHiddenFiles:(BOOL)show;

@end

@implementation ArchimadeApplicationController

@synthesize window;
@synthesize dropView;
@synthesize archiveTypeList;
@synthesize soundCollection;
@synthesize controllerCollection;
@synthesize archiveFileQueue;

- (void)dealloc
{
	[self.soundCollection release];
	[self.controllerCollection release];
	[self.archiveFileQueue release];
	[super dealloc];
}

- (void)awakeFromNib
{
	[self initUserDefaults];
	[[[self archiveTypeList] cell] setImage:[NSImage imageNamed:@"ArchimadePopup"]];
	
	self.soundCollection = [[NSArray alloc] initWithObjects:
		[NSSound soundNamed:@"Pop"],
		[NSSound soundNamed:@"Basso"],
		[NSSound soundNamed:@"WrongDroppedFile"],
		[NSSound soundNamed:@"WrongPriviledges"],
		nil
	];
	
	self.controllerCollection = [[NSMutableArray alloc]  initWithCapacity:6];
	self.archiveFileQueue = [[NSMutableArray alloc] initWithCapacity:6];
	
	ArchimadePreferenceGeneralViewController *preferenceGeneralViewController = [
		[ArchimadePreferenceGeneralViewController alloc] 
			initWithLabelAndIcon:NSLocalizedString(@"General", @"General")
			icon:[NSImage imageNamed:@"NSPreferencesGeneral"] 
			identifier:@"Archimade Preference General Item"
	];
	
	
	[[AUPreferencesMultiItems defaultController] addItem:preferenceGeneralViewController];
	[preferenceGeneralViewController release];
	
	ArchimadePreferenceAccessibilityViewController *preferenceAccessibilityViewController = [
		[ArchimadePreferenceAccessibilityViewController alloc] 
			initWithLabelAndIcon:NSLocalizedString(@"Accessibility", @"Accessibility") 
			icon:[NSImage imageNamed:@"UniversalAccessPref"] 
			identifier:@"Archimade Preference Accessibility Item"
	];
	
	
	[[AUPreferencesMultiItems defaultController] addItem:preferenceAccessibilityViewController];
	[preferenceAccessibilityViewController release];
	
	ArchimadePreferenceAdvancedViewController *preferenceAdvancedViewController = [
		[ArchimadePreferenceAdvancedViewController alloc] 
			initWithLabelAndIcon:NSLocalizedString(@"Advanced", @"Advanced") 
			icon:[NSImage imageNamed:@"NSAdvanced"] 
			identifier:@"Archimade Preference Advanced Item"
	];
	
	
	[[AUPreferencesMultiItems defaultController] addItem:preferenceAdvancedViewController];
	[preferenceAdvancedViewController release];
	
	[self.archiveTypeList selectItemAtIndex:[[[NSUserDefaults standardUserDefaults] 
		objectForKey:kArchimadeUserDefaultsArchiveTypeKey] integerValue]];
}

- (void)initUserDefaults
{
	if (nil == [[NSUserDefaults standardUserDefaults] objectForKey:kArchimadeUserDefaultsArchiveTypeKey]) {
		[[NSUserDefaults standardUserDefaults] setObject:
			[NSNumber numberWithInteger:0] forKey:kArchimadeUserDefaultsArchiveTypeKey];
	}
	
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

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{	
	[[NSNotificationCenter defaultCenter] addObserver:self 
		selector:@selector(onEventConcludeDragOperation:) 
		name:kArchimadeConcludeDragOperationNotificationName object:self.dropView];
		
	[[NSNotificationCenter defaultCenter] addObserver:self 
		selector:@selector(onEventDidReceiveWrongPriviledgesAlert:) 
		name:kArchimadeDidReceiveWrongPriviledgesAlertNotificationName object:nil];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	NSInteger i = 0;
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
		name:kArchimadeConcludeDragOperationNotificationName object:self.dropView];
		
	[[NSNotificationCenter defaultCenter] removeObserver:self 
		name:kArchimadeDidReceiveWrongPriviledgesAlertNotificationName object:nil];
	
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	return NSTerminateNow;
}

- (IBAction)openPreferences:(id)sender
{
	[[AUPreferencesMultiItems defaultController] showWindow:self];
}

- (IBAction)openDocument:(id)sender
{
	NSOpenPanel *panel = [[NSOpenPanel openPanel] retain];
	[panel setCanChooseDirectories:YES];
	[panel setResolvesAliases:NO];
	if (1 == [sender tag]) {
		if ([[panel class] instancesRespondToSelector:@selector(setShowsHiddenFiles:)]) {
			[panel setShowsHiddenFiles:YES];
		}	
	}
	[panel setAllowsMultipleSelection:NO];
	[panel setCanChooseFiles:NO];
	[panel beginSheetForDirectory:nil 
		file:nil 
		types:nil 
		modalForWindow:nil 
		modalDelegate:self
		didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
		contextInfo:nil
	];
}

- (NSArray *)filenamesForOperation:(NSArray *)filenames
{
	NSArray *newfilenames = nil;
	NSMutableArray *buffer;
	NSString *root;
	BOOL flag = NO;
	buffer = [[NSMutableArray alloc] initWithCapacity:[filenames count]];
	root = [[NSFileManager defaultManager] directoryNameAtPath:[[filenames objectAtIndex:0] stringByResolvingSymlinksInPath]];
	for (id item in filenames) {
		id path = [item stringByResolvingSymlinksInPath];
		if (![root isEqualToString:[[NSFileManager defaultManager] directoryNameAtPath:path]]) {
			flag = NO; break;
		}
		if ([[NSFileManager defaultManager] isVolumeFileAtPath:path]) {
			flag = NO; break;
		}
		if (![[NSFileManager defaultManager] isDirectoryFileAtPath:path]) {
			flag = NO; break;
		}
		[buffer addObject:path];
		flag = YES;
	}
	if (flag) {
		newfilenames = [NSArray arrayWithArray:(NSArray *)buffer];
	}
	[buffer release];
	return newfilenames;
}

- (BOOL)startOperationForFilenames:(NSArray *)filenames
{
	BOOL flag = NO;
	NSArray *options;
	NSArray *newfilenames;
	ArchimadeProgressWindowController *progressWindowController;
	if ([filenames count]) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];		
		if (nil != (newfilenames = [self filenamesForOperation:filenames])) {
			if (nil != (options = [[NSArray alloc] initWithObjects:newfilenames, [self.archiveTypeList objectValue], nil])) {
				if (nil != (progressWindowController = [[ArchimadeProgressWindowController alloc] initWithRootControllerAndOptions:self options:options])) {
					if(![[self.soundCollection objectAtIndex:0] isPlaying]) {
						[[self.soundCollection objectAtIndex:0] play];
					}
					[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onEventTerminateProgressOperation:) 
						name:kArchimadeTerminateProgressOperationNotificationName object:progressWindowController
					];
					[self pushWindowController:progressWindowController];			
					[progressWindowController release];
					flag = YES;
				}
				[options release];
			}
		}
		[pool release];
	}
	return flag;
}

- (void)startingOperationFailed
{
	[self shakeWindow:self.window];
	if ([[[NSUserDefaults standardUserDefaults]  objectForKey:kArchimadeUserDefaultsSpeakableAlertKey] boolValue]) {
		if (![[self.soundCollection objectAtIndex:2] isPlaying] && ![[self.soundCollection objectAtIndex:3] isPlaying]) {
			[[self.soundCollection objectAtIndex:2] play];
		}
	} else {
		if(![[self.soundCollection objectAtIndex:1] isPlaying]) {
			[[self.soundCollection objectAtIndex:1] play];
		}
	}
}

- (void)openPanelDidEnd:(NSOpenPanel *)panel returnCode:(NSInteger)returnCode  contextInfo:(void  *)contextInfo
{
	if(returnCode == NSOKButton) {
		if (![self startOperationForFilenames:[panel filenames]]) {
			[self startingOperationFailed];
		}
	}
	
	[panel release];
}

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames
{
	if (![self startOperationForFilenames:filenames]) {
		[self startingOperationFailed];
	}
}

- (void)onEventConcludeDragOperation:(NSNotification *)aNotification
{
	BOOL onTask = NO;
	NSArray *filenames;
	NSPasteboard *pasteboard;
	if ([[[NSUserDefaults standardUserDefaults]  objectForKey:kArchimadeUserDefaultsActivateApplicationAnywayKey] boolValue]) {
		if(![[NSApplication sharedApplication] isActive]) {
			[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
			[[self window] orderFront:nil];
		}
	}	
	if ([[aNotification name] isEqualToString:kArchimadeConcludeDragOperationNotificationName]) {
		if ([[self.dropView class] instancesRespondToSelector:@selector(draggingPasteboard)]) {
			if (nil != (pasteboard = [self.dropView performSelector:@selector(draggingPasteboard)])) {
				if (nil != (filenames = [pasteboard propertyListForType:[pasteboard availableTypeFromArray:
						[NSArray arrayWithObjects:NSFilenamesPboardType, nil]]])) {
					onTask = [self startOperationForFilenames:filenames];
				}
			}
		}
		
		if (!onTask) {
			[self startingOperationFailed];
		}
	}
}

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
	[controller showWindow:[self window]];
	if ([self.controllerCollection count] < kArchimadeMaxConcurrentArchiveOperationCount) {
		[controller startOperation];
	}	
	[self.controllerCollection addObject:controller];
}

- (void)popWindowController:(id)controller
{
	if ([self.controllerCollection count] > kArchimadeMaxConcurrentArchiveOperationCount) {
		id aController = [self.controllerCollection objectAtIndex:kArchimadeMaxConcurrentArchiveOperationCount];
		if (![aController isCancelled]) {
			[aController startOperation];
		}
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
	if ([self.archiveFileQueue count] > 0) {
		[self.archiveFileQueue removeObject:archiveFilePath];
	}
}

- (NSNumber *)archiveFileQueueExists:(NSString *)archiveFilePath
{
	BOOL ret = NO;
	if ([self.archiveFileQueue count] > 0) {
		ret = (NSNotFound == [self.archiveFileQueue indexOfObject:archiveFilePath]) ? NO : YES;
	}
	return [NSNumber numberWithBool:ret];
}

- (IBAction)archiveTypeSelector:(id)sender
{
	[[NSUserDefaults standardUserDefaults] setObject:[sender objectValue] 
		forKey:kArchimadeUserDefaultsArchiveTypeKey];
}

- (CAKeyframeAnimation *)shakeAnimation:(NSRect)frame
{	// Marcus S. Zarra (Cocoa Is My Girlfriend)
	NSInteger index;
	CGMutablePathRef path;
	CAKeyframeAnimation *anim;	
	path = CGPathCreateMutable();
	CGPathMoveToPoint(path, NULL, NSMinX(frame), NSMinY(frame));
	anim = [CAKeyframeAnimation animation];
	for (index = 0; index < 5; ++index) {
		CGPathAddLineToPoint(path, NULL, 
			NSMinX(frame) - frame.size.width * 0.03f, NSMinY(frame));
		CGPathAddLineToPoint(path, NULL, 
			NSMinX(frame) + frame.size.width * 0.03f, NSMinY(frame));
	}	
	CGPathCloseSubpath(path);
	anim.path = path;
	anim.duration = 0.30f;
	return anim;
}

- (void)shakeWindow:(NSWindow *)aWindow
{
	[aWindow setAnimations:[NSDictionary dictionaryWithObject:[self shakeAnimation:[aWindow frame]] forKey:@"frameOrigin"]];
	[[aWindow animator] setFrameOrigin:[aWindow frame].origin];
}

@end

/* EOF */