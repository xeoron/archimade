//
//  ArchimadeProgressWindowController.m
//  Archimade
//
//  Created by mmw on 11/5/08.
//  Copyright Cucurbita. All rights reserved.
//

#import "ArchimadeProgressWindowController.h"
#import "ArchimadeDirectoryLookupOperation.h"
#import "AUFileManagerAddition.h"

extern NSString *const kArchimadeDirectoryLookupOperationCurrentSizeKey;
extern NSString *const kArchimadeDirectoryLookupOperationCurrentCountKey;

extern NSString *const kArchimadeResultDirectoryLookupOperationWithErrorNotificationName;
extern NSString *const kArchimadeResultDirectoryLookupOperationNotificationName;
extern NSString *const kArchimadeTerminateDirectoryLookupOperationNotificationName;

extern NSString *const kArchimadeTerminateTaskOperationWithErrorNotificationName;
extern NSString *const kArchimadeTerminateTaskOperationNotificationName;

extern NSString *const kArchimadeUserDefaultsArchiveTypeKey;
extern NSString *const kArchimadeUserDefaultsArchiveOverwriteKey;
extern NSString *const kArchimadeUserDefaultsArchiveAbbreviateKey;
extern NSString *const kArchimadeUserDefaultsArchivekeepContentsKey;
extern NSString *const kArchimadeUserDefaultsArchiveAlwaysOnDesktopKey;
extern NSString *const kArchimadeUserDefaultsArchiveRevealInFinderKey;

NSString *const kArchimadeTerminateProgressOperationNotificationName = @"ArchimadeTerminateProgressOperation";
NSString *const kArchimadeDidReceiveWrongPriviledgesAlertNotificationName = @"ArchimadeDidReceiveWrongPriviledgesAlert";

@implementation ArchimadeProgressWindowController

@synthesize progressIndicator;
@synthesize messageTextField;
@synthesize infoTextField;
@synthesize iconView;
@synthesize fileNames;
@synthesize archiveType;

#include <stdlib.h>
#include <unistd.h>

#define __APWC_SLEEP_FOR_ANIMATION__

NS_INLINE void APWC_sleepForAnimation(useconds_t microseconds)
{
#ifdef __APWC_SLEEP_FOR_ANIMATION__
	usleep(microseconds); // blocking
#endif
}

- (void)dealloc
{
	[fileNames release];
	[archiveType release];
	
	if (APWC_operationQueue) {
		[APWC_operationQueue release];
	}
	
	if (APWC_archiveTaskOperation) {
		[APWC_archiveTaskOperation release];
	}
	
	if (APWC_taskArguments) {
		[APWC_taskArguments release];
		APWC_taskArguments = nil;
	}

	[super dealloc];
}

- (id)initWithRootControllerAndOptions:(id)controller options:(NSArray *)options
{
	NSNumber *abbreviate, *onDesktop, *overwrite;
	NSString *prog, *root, *ar, *src, *opt, *ext, *file;
	BOOL renameFlag = YES;
	NSInteger i = 1;
	
	if ((self = [super initWithWindowNibName:@"ProgressWindow"])) {
		[self setShouldCloseDocument:YES];
		
		self.fileNames = [options objectAtIndex:0];
		self.archiveType = [options objectAtIndex:1];
		
		APWC_Flags._multiItems = [self.fileNames count] > 1 ? YES : NO;
		APWC_rootController = controller;
		APWC_operationQueue = nil;
		APWC_archiveTaskOperation = nil;
		
		[[self window] setTitle:NSLocalizedString(@"Copy", @"Copy")];
		
		APWC_Flags._keepExtraContents  = [[[NSUserDefaults standardUserDefaults] objectForKey:kArchimadeUserDefaultsArchivekeepContentsKey] boolValue];		
		APWC_Flags._archiveOnDesktop = NO;
		
		prog = @"";
		opt = @"";
		ext = @"";
		
		switch ([self.archiveType integerValue]) {
			case 0: // tar gzip
				abbreviate = [[NSUserDefaults standardUserDefaults] 
					objectForKey:kArchimadeUserDefaultsArchiveAbbreviateKey];
				prog = @"/usr/bin/tar";
				opt = @"--gzip";
				ext = [abbreviate boolValue] ? @".tgz" : @".tar.gz";
			break;
			case 1: // tar bzip
				abbreviate = [[NSUserDefaults standardUserDefaults] 
					objectForKey:kArchimadeUserDefaultsArchiveAbbreviateKey];
				prog = @"/usr/bin/tar";
				opt = @"--bzip";
				ext = [abbreviate boolValue] ? @".tbz" : @".tar.bz2";
			break;
			case 2: // tar ziv
				abbreviate = [[NSUserDefaults standardUserDefaults] 
					objectForKey:kArchimadeUserDefaultsArchiveAbbreviateKey];
				prog = @"/usr/bin/tar";
				opt = @"--compress";
				ext = [abbreviate boolValue] ? @".taz" : @".tar.Z";
			break;
			case 3: // tar
				prog = @"/usr/bin/tar";
				opt = @"";
				ext = @".tar";
			break;
			case 4: // zip
				prog = @"/usr/bin/ditto";
				opt = @"";
				ext = @".zip";
			break;
		}
		
		file = [self.fileNames objectAtIndex:0];
		root = [[NSFileManager defaultManager] directoryNameAtPath:file];
		src = [[NSFileManager defaultManager] baseNameAtPath:file];
	
		//NSLog(@" %@ %@", src);
		
		onDesktop = [[NSUserDefaults standardUserDefaults] 
			objectForKey:kArchimadeUserDefaultsArchiveAlwaysOnDesktopKey];
		
		if (APWC_Flags._multiItems) {
			ar = [[root stringByAppendingString:@"/Archive"] stringByAppendingString:ext];
			if (![[NSFileManager defaultManager] isWritableFileAtPath:root] || [onDesktop boolValue]) {
				NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES);
				ar = [[[paths objectAtIndex:0] stringByAppendingString:@"/Archive"] stringByAppendingString:ext];
				APWC_Flags._archiveOnDesktop = YES;
			}
		} else {
			if (![[NSFileManager defaultManager] isWritableFileAtPath:root] || [onDesktop boolValue]) {
				NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES);
				file = [[paths objectAtIndex:0] stringByAppendingPathComponent:src];
				APWC_Flags._archiveOnDesktop = YES;
			}
			if ([[file pathExtension] isEqualToString:@"app"]) {
				ar = [[file stringByDeletingPathExtension] stringByAppendingString:ext];
			} else {
				ar = [file stringByAppendingString:ext];
			}
		}
		
		//NSLog(@" %@ %@", ar, [file stringByAppendingString:ext]);
		
		overwrite = [[NSUserDefaults standardUserDefaults] 
			objectForKey:kArchimadeUserDefaultsArchiveOverwriteKey];
		
		if ([[NSFileManager defaultManager] isWritableFileAtPath:ar] && [overwrite boolValue]) {
			renameFlag = [[APWC_rootController performSelector:@selector(archiveFileQueueExists:) withObject:ar] boolValue];
		}
		
		if(renameFlag && APWC_Flags._multiItems) {
			if ([[NSFileManager defaultManager] fileExistsAtPath:ar] ||
				[[APWC_rootController performSelector:@selector(archiveFileQueueExists:) withObject:ar] boolValue]) {
				while (true) {
					if ([[file pathExtension] isEqualToString:@"app"]) {
						ar = [[file stringByDeletingPathExtension] stringByAppendingFormat:@" %lu%@", ++i, ext];
					} else {
						ar = [file stringByAppendingFormat:@" %lu%@", ++i, ext];
					}
					
					if ([overwrite boolValue]) {
						if ([[NSFileManager defaultManager] fileExistsAtPath:ar] &&
							[[NSFileManager defaultManager] isWritableFileAtPath:ar] &&
							![[APWC_rootController performSelector:@selector(archiveFileQueueExists:) withObject:ar] boolValue]
							) {
							break;
						}
					}
					
					if (![[NSFileManager defaultManager] fileExistsAtPath:ar] &&
						![[APWC_rootController performSelector:@selector(archiveFileQueueExists:) withObject:ar] boolValue]) {
						break;
					} else {
						ar = nil;
					}
				}
			}
		}
		
		[APWC_rootController performSelector:@selector(archiveFileQueueAdd:) withObject:ar];
			
		if (4 != [self.archiveType integerValue]) { // !zip
			APWC_taskArguments = [[NSArray alloc] initWithObjects:
				prog, ar, opt, @"-C", root, @"-cvf", ar, src, 
			nil];
		} else {
			if (APWC_Flags._keepExtraContents) {
				APWC_taskArguments = [[NSArray alloc] initWithObjects:
					prog, ar, @"-V", @"-c", @"-k", @"--keepParent", @"--rsrc", @"--sequesterRsrc", 
					[root stringByAppendingPathComponent:src], ar, 
				nil];
			} else {
				APWC_taskArguments = [[NSArray alloc] initWithObjects:
					prog, ar, @"-V", @"-c", @"-k", @"--keepParent", @"--norsrc", @"--noextattr", 
					[root stringByAppendingPathComponent:src], ar, 
				nil];			
			}
		}
		
		//NSLog(@" %@", APWC_taskArguments);
		
		APWC_archivePath = ar;
		APWC_timerRepeat = nil;
		APWC_Flags._lockCancel = NO;
		
		APWC_countItem = 0;
		APWC_totalSize = 0;
		APWC_Flags._isRunning = NO;
		APWC_Flags._isCancelled = NO;
		
		[[self window] setBackgroundColor:[NSColor whiteColor]];
		
		if (APWC_Flags._multiItems) {
			[self.iconView setImage:[[NSWorkspace sharedWorkspace] iconForFile:@"/private"]];
		} else {
			[self.iconView setImage:[[NSWorkspace sharedWorkspace] iconForFile:[self.fileNames objectAtIndex:0]]];
		}

		NSString *messageText = NSLocalizedString(
				@"Preparing data for archiving", 
				@"Preparing data for archiving"
			);
		[self.messageTextField setStringValue:messageText];
		[self.infoTextField setStringValue:@""];
	}
	
	return self;
}

- (void)windowDidLoad
{
	[progressIndicator setUsesThreadedAnimation:YES];
	[progressIndicator startAnimation:self];
}

#pragma mark lookup operation

- (void)lookupOperationBegin:(NSTimer *)timer
{
	[timer invalidate];
	APWC_Flags._lockCancel = YES;

	APWC_operationQueue = [[NSOperationQueue alloc] init];
	[APWC_operationQueue setMaxConcurrentOperationCount:1];
	
	ArchimadeDirectoryLookupOperation *lookupOperation = [
		[ArchimadeDirectoryLookupOperation alloc] initWithFileNames:self.fileNames
	];
	
	[APWC_operationQueue addOperation:lookupOperation];
	[lookupOperation release];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
		selector:@selector(lookupOperationObserver:) 
		name:kArchimadeResultDirectoryLookupOperationWithErrorNotificationName 
		object:[[APWC_operationQueue operations] objectAtIndex:0]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
		selector:@selector(lookupOperationObserver:) 
		name:kArchimadeResultDirectoryLookupOperationNotificationName 
		object:[[APWC_operationQueue operations] objectAtIndex:0]];
		
	[[NSNotificationCenter defaultCenter] addObserver:self 
		selector:@selector(lookupOperationObserver:) 
		name:kArchimadeTerminateDirectoryLookupOperationNotificationName 
		object:[[APWC_operationQueue operations] objectAtIndex:0]];

	NSString *messageText = NSLocalizedString(
			@"Reading data", 
			@"Reading data"
		);
	[self.messageTextField setStringValue:messageText];
	
	APWC_Flags._updateInfoTextFieldNumberOfItems = YES;
	APWC_timerRepeat = [NSTimer scheduledTimerWithTimeInterval:0.45
		target:self selector:@selector(lookupUpdateNumberOfItems:) userInfo:nil repeats:YES];
	
	APWC_Flags._isRunning = YES;
	APWC_Flags._lockCancel = NO;
}

- (void)lookupUpdateNumberOfItems:(NSTimer *)timer
{	
	NSString *key = nil, *format = nil;
	if (APWC_Flags._updateInfoTextFieldNumberOfItems) {
		key = APWC_countItem > 1 ? @"Preparing to archive %llu items." : @"Preparing to archive %llu item.";
		format = NSLocalizedString(key, key);
		NSString *informationText = [[NSString alloc] initWithFormat:format, APWC_countItem];
		[self.infoTextField setStringValue:informationText];	
		[informationText release];
	}
}

- (void)lookupOperationObserver:(NSNotification *)aNotification
{
	if ([[aNotification name] isEqualToString:kArchimadeResultDirectoryLookupOperationWithErrorNotificationName]) {
		[self performSelectorOnMainThread:@selector(lookupOperationError:) 
			withObject:aNotification waitUntilDone:NO];
	}

	if ([[aNotification name] isEqualToString:kArchimadeResultDirectoryLookupOperationNotificationName]) {
		APWC_totalSize = [[[aNotification userInfo] objectForKey:
			kArchimadeDirectoryLookupOperationCurrentSizeKey] unsignedLongLongValue];
		APWC_countItem = [[[aNotification userInfo] objectForKey:
			kArchimadeDirectoryLookupOperationCurrentCountKey] unsignedLongLongValue];
	}
	
	if ([[aNotification name] isEqualToString:kArchimadeTerminateDirectoryLookupOperationNotificationName]) {
		[self performSelectorOnMainThread:@selector(lookupOperationTerminate:) 
			withObject:aNotification waitUntilDone:NO];
	}
}

- (void)lookupOperationError:(NSNotification *)aNotification
{	
	APWC_Flags._lockCancel = YES;
	APWC_Flags._updateInfoTextFieldNumberOfItems = NO;
	if (nil != APWC_timerRepeat) {
		[APWC_timerRepeat invalidate];
		APWC_timerRepeat = nil;
	}	
	[APWC_operationQueue cancelAllOperations];
	[progressIndicator stopAnimation:self];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self 
			name:kArchimadeResultDirectoryLookupOperationWithErrorNotificationName 
			object:[aNotification object]];
		
	[[NSNotificationCenter defaultCenter] removeObserver:self 
		name:kArchimadeResultDirectoryLookupOperationNotificationName 
		object:[aNotification object]];
		
	[[NSNotificationCenter defaultCenter] removeObserver:self 
		name:kArchimadeTerminateDirectoryLookupOperationNotificationName 
		object:[aNotification object]];
	
	[APWC_operationQueue release];
	APWC_operationQueue = nil;	
	
	[[NSNotificationCenter defaultCenter] 
		postNotificationName:kArchimadeDidReceiveWrongPriviledgesAlertNotificationName 
		object:self];
	
	NSAlert* alert = [[NSAlert alloc] init]; // released into @selector
	[alert setAlertStyle:NSCriticalAlertStyle];
	[alert setMessageText:[[self.fileNames objectAtIndex:0] lastPathComponent]];

	[alert setInformativeText:
		NSLocalizedString(
			@"The Operation cannot be completed because you do not have sufficient privileges.", 
			@"The Operation cannot be completed because you do not have sufficient privileges."
		)
	];
	
	[alert beginSheetModalForWindow:
		[self window]
		modalDelegate:self  
		didEndSelector:@selector(lookupOperationErrorAlertDidEnd:returnCode:contextInfo:) 
		contextInfo:nil
	];
	
	[self.messageTextField setStringValue:NSLocalizedString(@"Cancelling", @"Cancelling")];
	[self.infoTextField setStringValue:@""];
}

- (void)lookupOperationErrorAlertDidEnd:(NSAlert *)alert returnCode:
		(NSUInteger)returnCode contextInfo:(void *)contextInfo;
{	
	[[NSNotificationCenter defaultCenter] 
		postNotificationName:kArchimadeTerminateProgressOperationNotificationName object:self];
		
	[alert release];
}

- (void)lookupOperationTerminate:(NSNotification *)aNotification
{	
	APWC_Flags._lockCancel = YES;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self 
		name:kArchimadeResultDirectoryLookupOperationWithErrorNotificationName 
		object:[aNotification object]];
		
	[[NSNotificationCenter defaultCenter] removeObserver:self 
		name:kArchimadeResultDirectoryLookupOperationNotificationName 
		object:[aNotification object]];
		
	[[NSNotificationCenter defaultCenter] removeObserver:self 
		name:kArchimadeTerminateDirectoryLookupOperationNotificationName 
		object:[aNotification object]];
	
	[APWC_operationQueue cancelAllOperations];
	[APWC_operationQueue release];
	APWC_operationQueue = nil;
	
	[NSTimer scheduledTimerWithTimeInterval:0.50
		target: self selector:@selector(archiveTaskOperationBegin:) userInfo:nil repeats:NO];
}

#pragma mark archive operation

- (void)archiveTaskOperationBegin:(NSTimer *)timer
{
	double threshold = 0.0;
	NSString *key = nil, *format = nil;
	NSInteger typeOfSelector = ArchimadeArchiveTaskOperationDataSelector;
	
	[timer invalidate];
	
	APWC_Flags._updateInfoTextFieldNumberOfItems = NO;
	if (nil != APWC_timerRepeat) {
		[APWC_timerRepeat invalidate];
		APWC_timerRepeat = nil;
	}
	
	NSString *messageText = [[NSString alloc] initWithFormat:
		NSLocalizedString(
			@"Processing \"%@\"", 
			@"Processing \"%@\""),
		[APWC_archivePath lastPathComponent]
	];
	
	[self.messageTextField setStringValue:messageText];	
	[messageText release];
	
	key = APWC_countItem > 1 ? @"Archiving %llu items" : @"Archiving %llu item.";
	format = NSLocalizedString(key, key);
	NSString *informationText = [[NSString alloc] initWithFormat:format, APWC_countItem];	
		
	[self.infoTextField setStringValue:informationText];
	[informationText release];

	[progressIndicator setIndeterminate:NO];
	
	if (APWC_countItem && APWC_totalSize) {
		threshold = (APWC_totalSize / 10000 / APWC_countItem);
		if (threshold > 180.0 || APWC_totalSize > 1<<30L) {
			typeOfSelector = ArchimadeArchiveTaskOperationSizeSelector;
			[progressIndicator setDoubleValue:(double)(10.0 / APWC_countItem) + 4.0];
		}
	}
	
	APWC_archiveTaskOperation = [[ArchimadeArchiveTaskOperation alloc] 
		initWithRootControllerAndArguments:self arguments:APWC_taskArguments typeOfSelector:typeOfSelector];
	
	[APWC_taskArguments release];
	APWC_taskArguments = nil;
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
		selector:@selector(archiveTaskOperationError:) 
		name:kArchimadeTerminateTaskOperationWithErrorNotificationName 
		object:APWC_archiveTaskOperation];
		
	[[NSNotificationCenter defaultCenter] addObserver:self 
		selector:@selector(archiveTaskOperationTerminate:) 
		name:kArchimadeTerminateTaskOperationNotificationName 
		object:APWC_archiveTaskOperation];

	if (4 != [self.archiveType integerValue]) { // !zip
		if (!APWC_Flags._keepExtraContents) {
			[APWC_archiveTaskOperation setEnvironmentVariable:
				@"true" 
				forKey:@"COPY_EXTENDED_ATTRIBUTES_DISABLE"
			];
			setenv("COPY_EXTENDED_ATTRIBUTES_DISABLE", "true", 1);
		} else {
			[APWC_archiveTaskOperation setEnvironmentVariable:
				@"false" 
				forKey:@"COPY_EXTENDED_ATTRIBUTES_DISABLE"
			];
			unsetenv("COPY_EXTENDED_ATTRIBUTES_DISABLE");
		}
	}
	
	[APWC_archiveTaskOperation start];
	APWC_Flags._lockCancel = NO;
}

- (void)setFinalizingTaskOperationStatus
{
	NSString *messageText = [[NSString alloc] initWithFormat:
		NSLocalizedString(@"Finalizing \"%@\"", @"Finalizing \"%@\""), 
		[APWC_archivePath lastPathComponent]
	];
	
	[self.messageTextField setStringValue:messageText];
	[messageText release];
	
	[progressIndicator setUsesThreadedAnimation:YES];
	[progressIndicator setIndeterminate:YES];
	[progressIndicator startAnimation:self];
}

- (void)receivedSize:(NSNumber *)size
{
	double newValue;
	double currentValue;
	unsigned long long archiveFileSize;
	if ([self isCancelled]) {
		return;
	}	
	if ([progressIndicator doubleValue] < 100.0) {
		if ((archiveFileSize = [size unsignedLongLongValue])) {
			if ((newValue = (archiveFileSize * ([self.archiveType integerValue] >= 3 ? 100.0 : 120.0) / APWC_totalSize))) {
				currentValue = [progressIndicator doubleValue];
				if (newValue > currentValue) {
					[progressIndicator incrementBy:(newValue - currentValue)];				
					if ([progressIndicator doubleValue] >= 99.0) {
						[self setFinalizingTaskOperationStatus];
					}
				}
			}
		}
	} else {
		if (![progressIndicator isIndeterminate]) {
			if ([progressIndicator doubleValue] < 90.0) {
				[progressIndicator setDoubleValue:100.0];
				APWC_sleepForAnimation(400000);
			}
		}
	}
}

- (void)receivedData:(NSData *)data
{
	double count = 0.0;
	double increment = 0.0;
	NSString *buf;
	NSArray *rows;	
	if ([self isCancelled]) {
		return;
	}
	if ([progressIndicator doubleValue] < 100.0) {
		buf = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		rows = [buf componentsSeparatedByString:@"\n"];
		if ((count = (double)([rows count] -1))) {
			if ((increment = (double)((([self.archiveType integerValue] >= 3 ? 90.0 : 60.0) / APWC_countItem) * count))) {
				[progressIndicator incrementBy:increment];
			}
		}
		
		if ([progressIndicator doubleValue] >= 99.0) {
			if (![progressIndicator isIndeterminate]) {
				[progressIndicator setDoubleValue:100.0];
				[self setFinalizingTaskOperationStatus];
			}
		}

		[buf release];
	} else {
		if (![progressIndicator isIndeterminate]) {
			if ([progressIndicator doubleValue] < 90.0) {
				[progressIndicator setDoubleValue:100.0];
				APWC_sleepForAnimation(400000);
			}
			[self setFinalizingTaskOperationStatus];
		}
	}
}

- (void)archiveTaskOperationError:(NSNotification *)aNotification
{
	if ([[aNotification name] isEqualToString:kArchimadeTerminateTaskOperationWithErrorNotificationName]) {
		APWC_Flags._lockCancel = YES;
		if (nil != APWC_timerRepeat) {
			[APWC_timerRepeat invalidate];
			APWC_timerRepeat = nil;
		}
		
		[[NSNotificationCenter defaultCenter] removeObserver:self 
			name:kArchimadeTerminateTaskOperationWithErrorNotificationName 
			object:[aNotification object]];
		
		[[NSNotificationCenter defaultCenter] removeObserver:self 
			name:kArchimadeTerminateTaskOperationNotificationName 
			object:[aNotification object]];

#if (MAC_OS_X_VERSION_MAX_ALLOWED >= 1060)
		[[NSFileManager defaultManager] removeItemAtPath:APWC_archivePath error:nil];
#else
		[[NSFileManager defaultManager] removeFileAtPath:APWC_archivePath handler:nil];
#endif
		
		if ([APWC_rootController respondsToSelector:@selector(archiveFileQueueRemove:)]) {
			[APWC_rootController performSelector:@selector(archiveFileQueueRemove:) withObject:APWC_archivePath];
		}
		
		[APWC_archiveTaskOperation release];
		APWC_archiveTaskOperation = nil;
		
		/* TODO: unexpected error */
		[self close];
	
		[[NSNotificationCenter defaultCenter] 
			postNotificationName:kArchimadeTerminateProgressOperationNotificationName object:self];	
	}
}

- (oneway void)archiveTaskOperationTerminate:(NSNotification *)aNotification
{
	if ([[aNotification name] isEqualToString:kArchimadeTerminateTaskOperationNotificationName]) {
		
		APWC_Flags._lockCancel = YES;
		if (nil != APWC_timerRepeat) {
			[APWC_timerRepeat invalidate];
			APWC_timerRepeat = nil;
		}
		
		[[NSNotificationCenter defaultCenter] removeObserver:self 
			name:kArchimadeTerminateTaskOperationWithErrorNotificationName 
			object:[aNotification object]];
	
		[[NSNotificationCenter defaultCenter] removeObserver:self 
			name:kArchimadeTerminateTaskOperationNotificationName 
			object:[aNotification object]];

		if (![progressIndicator isIndeterminate]) {
			if ([progressIndicator doubleValue] < 90.0) {
				[progressIndicator setDoubleValue:100.0];
				APWC_sleepForAnimation(400000);
			}
			[progressIndicator setUsesThreadedAnimation:YES];
			[progressIndicator setIndeterminate:YES];
			[progressIndicator startAnimation:self];
		}
		
		[APWC_archiveTaskOperation release];
		APWC_archiveTaskOperation = nil;
		
		if (!APWC_Flags._archiveOnDesktop) {
			if ([[[NSUserDefaults standardUserDefaults] 
					objectForKey:kArchimadeUserDefaultsArchiveRevealInFinderKey] boolValue]) {
				[[NSWorkspace sharedWorkspace] selectFile:APWC_archivePath inFileViewerRootedAtPath:nil];
			}
		}
		
		if ([APWC_rootController respondsToSelector:@selector(archiveFileQueueRemove:)]) {
			[APWC_rootController performSelector:@selector(archiveFileQueueRemove:) withObject:APWC_archivePath];
		}
		
		[NSTimer scheduledTimerWithTimeInterval:0.30
			target: self selector:@selector(archiveTaskOperationDidTerminate:) userInfo:nil repeats:NO];
	}
}

- (void)archiveTaskOperationDidTerminate:(NSTimer *)timer
{	
	[self close];
	[timer invalidate];
	
	[[NSNotificationCenter defaultCenter] 
		postNotificationName:kArchimadeTerminateProgressOperationNotificationName object:self];	
}

#pragma mark controller

- (void)startOperation
{
	if (!APWC_Flags._isCancelled && !APWC_Flags._isRunning) {
		[NSTimer scheduledTimerWithTimeInterval:0.15
			target:self selector:@selector(lookupOperationBegin:) userInfo:nil repeats:NO];
	}
}

- (oneway void)stopOperation
{	
	if (APWC_Flags._isRunning) {
		APWC_Flags._isRunning = NO;
		APWC_Flags._updateInfoTextFieldNumberOfItems = NO;
		
		if (nil != APWC_timerRepeat) {
			[APWC_timerRepeat invalidate];
			APWC_timerRepeat = nil;
		}
		
		if (nil != APWC_operationQueue) {
			APWC_Flags._updateInfoTextFieldNumberOfItems = NO;
			
			[[NSNotificationCenter defaultCenter] removeObserver:self 
				name:kArchimadeResultDirectoryLookupOperationWithErrorNotificationName 
				object:[[APWC_operationQueue operations] objectAtIndex:0]];
	
			[[NSNotificationCenter defaultCenter] removeObserver:self 
				name:kArchimadeResultDirectoryLookupOperationNotificationName
				object:[[APWC_operationQueue operations] objectAtIndex:0]];
				
			[[NSNotificationCenter defaultCenter] removeObserver:self 
				name:kArchimadeTerminateDirectoryLookupOperationNotificationName
				object:[[APWC_operationQueue operations] objectAtIndex:0]];
			
			[APWC_operationQueue cancelAllOperations];
			[APWC_operationQueue release];
			APWC_operationQueue = nil;
		}
		
		if (nil != APWC_archiveTaskOperation) {
			
			[[NSNotificationCenter defaultCenter] removeObserver:self 
				name:kArchimadeTerminateTaskOperationWithErrorNotificationName 
				object:APWC_archiveTaskOperation];
		
			[[NSNotificationCenter defaultCenter] removeObserver:self 
				name:kArchimadeTerminateTaskOperationNotificationName 
				object:APWC_archiveTaskOperation];
			
			[APWC_archiveTaskOperation kill];
			
			[APWC_archiveTaskOperation release];
			APWC_archiveTaskOperation = nil;

#if (MAC_OS_X_VERSION_MAX_ALLOWED >= 1060)
			[[NSFileManager defaultManager] removeItemAtPath:APWC_archivePath error:nil];
#else
			[[NSFileManager defaultManager] removeFileAtPath:APWC_archivePath handler:nil];
#endif
			
			if ([APWC_rootController respondsToSelector:@selector(archiveFileQueueRemove:)]) {
				[APWC_rootController performSelector:@selector(archiveFileQueueRemove:) withObject:APWC_archivePath];
			}
		}
	}
}

- (BOOL)isCancelled
{
	return APWC_Flags._isCancelled;
}

- (void)cancelOperationDidEnd:(NSTimer *)timer
{
	[timer invalidate];
	[self close];
		
	[[NSNotificationCenter defaultCenter] 
		postNotificationName:kArchimadeTerminateProgressOperationNotificationName object:self];	
}

- (IBAction)cancelOperation:(id)sender
{
	if (!APWC_Flags._lockCancel) {
		APWC_Flags._lockCancel = YES;
		APWC_Flags._isCancelled = YES;
		
		[self stopOperation];
		[self.messageTextField setStringValue:NSLocalizedString(@"Cancelling", @"Cancelling")];
		[self.infoTextField setStringValue:@""];
		
		if (![progressIndicator isIndeterminate]) {
			[progressIndicator setUsesThreadedAnimation:YES];
			[progressIndicator setIndeterminate:YES];
			[progressIndicator startAnimation:self];
		}
		
		[NSTimer scheduledTimerWithTimeInterval:0.50
			target: self selector:@selector(cancelOperationDidEnd:) userInfo:nil repeats:NO];
	}
}

@end

/* EOF */