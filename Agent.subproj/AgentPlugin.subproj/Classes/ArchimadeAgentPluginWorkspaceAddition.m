//
//  ArchimadeAgentPluginWorkspaceAddition.m
//  ArchimadeAgentPlugin
//
//  Created by mmw on 2/2/09.
//  Copyright 2009 Cucurbita. All rights reserved.
//

#import "ArchimadeAgentPluginWorkspaceAddition.h"

NSString *const AAPWA_kArchimadeAgentPluginWorkspaceAdditionNSApplicationPathKey = @"NSApplicationPath";
NSString *const AAPWA_kArchimadeAgentPluginWorkspaceAdditionNSApplicationNameKey = @"NSApplicationName";
NSString *const AAPWA_kArchimadeAgentPluginWorkspaceAdditionNSApplicationBundleIdentifierKey = @"NSApplicationBundleIdentifier";
NSString *const AAPWA_kArchimadeAgentPluginWorkspaceAdditionNSApplicationProcessIdentifierKey = @"NSApplicationProcessIdentifier";
NSString *const AAPWA_kArchimadeAgentPluginWorkspaceAdditionNSApplicationProcessSerialNumberHighKey = @"NSApplicationProcessSerialNumberHigh";
NSString *const AAPWA_kArchimadeAgentPluginWorkspaceAdditionNSApplicationProcessSerialNumberLowKey = @"NSApplicationProcessSerialNumberLow";

#define AAPWA_kArchimadeAgentPluginWorkspaceAdditionCFBundleExecutableKey (NSString *const)kCFBundleExecutableKey
#define AAPWA_kArchimadeAgentPluginWorkspaceAdditionCFBundlePathKey @"BundlePath"
#define AAPWA_kArchimadeAgentPluginWorkspaceAdditionCFBundleNameKey (NSString *const)kCFBundleNameKey
#define AAPWA_kArchimadeAgentPluginWorkspaceAdditionCFBundleIdentifierKey (NSString *const)kCFBundleIdentifierKey
#define AAPWA_kArchimadeAgentPluginWorkspaceAdditionCFBundleProcessIdentifierKey @"pid"
#define AAPWA_kArchimadeAgentPluginWorkspaceAdditionCFBundleLSBackgroundOnlyKey @"LSBackgroundOnly"
#define AAPWA_kArchimadeAgentPluginWorkspaceAdditionCFBundleLSUIElementKey @"LSUIElement"

@interface NSWorkspace (ArchimadeAgentPluginWorkspaceAdditionPrivateMethods)

- (BOOL)AAPWA_isApplicationRunningInBackground:(NSInteger)processIdentifier;

@end

@implementation NSWorkspace (ArchimadeAgentPluginWorkspaceAddition)

- (BOOL)AAPWA_isApplicationRunningInBackground:(NSInteger)processIdentifier
{
	ProcessSerialNumber psn;
	OSStatus status;
	
	NSDictionary *info;
	NSNumber *bundleLSBackgroundOnly;
	NSNumber *bundleLSUIElement;
	
	BOOL backgroundOnly = NO;
	BOOL noUIElement = NO;
	
	status = GetProcessForPID((pid_t)processIdentifier, &psn);
	if ((info = (NSDictionary *)ProcessInformationCopyDictionary(&psn, kProcessDictionaryIncludeAllInformationMask))) {
		if ((bundleLSBackgroundOnly = [info objectForKey:AAPWA_kArchimadeAgentPluginWorkspaceAdditionCFBundleLSBackgroundOnlyKey])) {
			backgroundOnly = [bundleLSBackgroundOnly boolValue];
		}
		
		if ((bundleLSUIElement = [info objectForKey:AAPWA_kArchimadeAgentPluginWorkspaceAdditionCFBundleLSUIElementKey])) {
			noUIElement = [bundleLSUIElement boolValue];
		}
		
		[info release];
		info = nil;
	}
	
	return (backgroundOnly || noUIElement);
}

- (BOOL)isApplicationLaunchedUsingIdentifier:(NSString *)identifier
{
	return [self isApplicationLaunchedUsingIdentifier:identifier checkInBackground:NO isBackgroundProcess:nil];
}

- (BOOL)isApplicationLaunchedUsingIdentifier:(NSString *)identifier checkInBackground:(BOOL)checkInBackground
{
	return [self isApplicationLaunchedUsingIdentifier:identifier checkInBackground:checkInBackground isBackgroundProcess:nil];
}

- (BOOL)isApplicationLaunchedUsingIdentifier:(NSString *)identifier checkInBackground:(BOOL)checkInBackground isBackgroundProcess:(BOOL *)isBackgroundProcess
{
	NSArray *launchedApps;
	NSDictionary *launchedApp;
	NSString *currentIdentifier;
	NSNumber *processIdentifier;
	BOOL flag = NO;
	
	if (nil != isBackgroundProcess) {
		*isBackgroundProcess = NO;
	}

	if ((launchedApps = [self launchedApplications:checkInBackground])) {
		for (launchedApp in launchedApps) {
			if ((currentIdentifier = [launchedApp objectForKey:AAPWA_kArchimadeAgentPluginWorkspaceAdditionNSApplicationBundleIdentifierKey])) {
				if ([currentIdentifier isEqualToString:identifier]) {
					if (nil != isBackgroundProcess) {
						if ((processIdentifier = [launchedApp objectForKey:AAPWA_kArchimadeAgentPluginWorkspaceAdditionNSApplicationProcessIdentifierKey])) {
							*isBackgroundProcess = [self AAPWA_isApplicationRunningInBackground:[processIdentifier integerValue]];
						}
					}
				
					flag = YES;
					break;
				}
			} else {
				break;
			}
		}
	}
	
	return flag;
}

- (NSArray *)launchedApplications:(BOOL)showBackgroundProcess
{
	if (NO == showBackgroundProcess) {
		return [self launchedApplications];
	}
	
	NSMutableArray *list;
	NSArray *objects;
	NSArray *keys;
	
	NSDictionary *info;
	ProcessSerialNumber psn = {0, kNoProcess};
	
	NSString *bundlePath;
	NSString *bundleName;
	NSString *bundleIdentifier;
	NSNumber *bundleProcessIdentifier;
		
	if (nil != (list = [NSMutableArray arrayWithCapacity:5])) {
		keys = [NSArray arrayWithObjects:
			AAPWA_kArchimadeAgentPluginWorkspaceAdditionNSApplicationPathKey, 
			AAPWA_kArchimadeAgentPluginWorkspaceAdditionNSApplicationNameKey, 
			AAPWA_kArchimadeAgentPluginWorkspaceAdditionNSApplicationBundleIdentifierKey,
			AAPWA_kArchimadeAgentPluginWorkspaceAdditionNSApplicationProcessIdentifierKey,
			AAPWA_kArchimadeAgentPluginWorkspaceAdditionNSApplicationProcessSerialNumberHighKey,
			AAPWA_kArchimadeAgentPluginWorkspaceAdditionNSApplicationProcessSerialNumberLowKey,
		nil];
		
		info = nil;
		for (;;) {	
			if (noErr == GetNextProcess(&psn)) {
				if ((info = (NSDictionary *)ProcessInformationCopyDictionary(&psn, kProcessDictionaryIncludeAllInformationMask))) {
					if ((bundlePath = [info objectForKey:AAPWA_kArchimadeAgentPluginWorkspaceAdditionCFBundlePathKey]) && 
						(bundleName = [info objectForKey:AAPWA_kArchimadeAgentPluginWorkspaceAdditionCFBundleNameKey]) && 
						(bundleIdentifier = [info objectForKey:AAPWA_kArchimadeAgentPluginWorkspaceAdditionCFBundleIdentifierKey]) && 
						(bundleProcessIdentifier = [info objectForKey:AAPWA_kArchimadeAgentPluginWorkspaceAdditionCFBundleProcessIdentifierKey])) {

						objects = [NSArray arrayWithObjects:
							bundlePath,
							bundleName,
							bundleIdentifier,
							bundleProcessIdentifier,
							[NSNumber numberWithUnsignedLong:psn.highLongOfPSN],
							[NSNumber numberWithUnsignedLong:psn.lowLongOfPSN],
						nil];
						
						if ([objects count] == [keys count]) {
							[list addObject:[NSDictionary dictionaryWithObjects:objects forKeys:keys]];
						}
					}
					
					[info release];
					info = nil;
				}
			} else {
				break;
			}
		}
		
		if (nil != info)
			[info release];
		
		return list;
	}
	
	return nil;
}

@end

/* EOF */