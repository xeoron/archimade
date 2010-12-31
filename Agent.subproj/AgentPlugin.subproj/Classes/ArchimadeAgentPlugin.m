//
//  ArchimadeAgentPlugin.m
//  ArchimadeAgentPlugin
//
//  Created by mmw on 2/2/09.
//  Copyright 2009 Cucurbita. All rights reserved.
//

#import "ArchimadeAgentPlugin.h"
#import "ArchimadeAgentPluginWorkspaceAddition.h"

@implementation ArchimadeAgentPlugin

#include <unistd.h>
#define AAP_kSyncDefaultTimeDelay 600000
#define AAP_syncDelay usleep
#define AAP_syncBlock AAP_syncDelay(AAP_kSyncDefaultTimeDelay)
#define AAP_toMicroseconds(aTime) (useconds_t)(1000000.0 * (aTime))

//#define _MULTI_THREADED
//#include <pthread.h>
//pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;

static OSStatus AAP_ArchimadeAgentOpen(useconds_t microseconds) {
	OSStatus status = noErr;
	FSRef outAppRef;
	BOOL block = NO;
	
	if(noErr == (status = LSFindApplicationForInfo(
			kLSUnknownCreator, kArchimadeAgentBundleIdentifierName, NULL, &outAppRef, NULL))) {
		LSApplicationParameters params = {0, kLSLaunchDefaults, &outAppRef, NULL, NULL, NULL};

		[[NSWorkspace sharedWorkspace] findApplications];
		if (![[NSWorkspace sharedWorkspace] isApplicationLaunchedUsingIdentifier:
				(NSString *)kArchimadeAgentBundleIdentifierName checkInBackground:YES]) {
			block = YES;
		}

		if (noErr == (status = LSOpenApplication(&params, NULL))) {
			if (block) {
				AAP_syncBlock;
				return AAP_ArchimadeAgentOpen(AAP_toMicroseconds(0.1));
			}
			
			if (microseconds) {
				AAP_syncDelay(microseconds);
			}
		}
	}
	
	return status;
}

- (void)dealloc
{
	[super dealloc];
}

- (id)init
{
	if ((self = [super init])) {
		AAP_distributedCenter = [NSDistributedNotificationCenter defaultCenter];
	}
	
	return self;
}

- (BOOL)startArchiveOperation:(NSString *)filename
{
	return [self startArchiveOperation:filename options:kArchimadeAgentPluginArchiveTypeDefault];
}

- (BOOL)startArchiveOperation:(NSString *)filename options:(NSInteger)options
{
	return [self startArchiveOperation:filename options:options safe:YES];
}

- (BOOL)startArchiveOperation:(NSString *)filename options:(NSInteger)options safe:(BOOL)safe
{
	return [self startArchiveOperation:filename options:options delay:(safe ? 0 : AAP_toMicroseconds(0.1))];
}

- (BOOL)startArchiveOperation:(NSString *)filename options:(NSInteger)options delay:(NSTimeInterval)delay
{
	if (noErr == AAP_ArchimadeAgentOpen(AAP_toMicroseconds(delay))) {
		[AAP_distributedCenter postNotificationName:kArchimadeAgentPluginNotificationName
			object:kArchimadeAgentPluginIdentifierObject
			userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
				filename, kArchimadeAgentPluginUserInfoFilePathKey,
				[NSNumber numberWithInt:options], kArchimadeAgentPluginUserInfoAchiveTypeKey,		
			nil]
			deliverImmediately:YES
		];
		
		return YES;
	}
	
	return NO;
}

@end

/* EOF */