//
//  ArchimadeDirectoryLookupOperation.m
//  Archimade
//
//  Created by mmw on 11/10/08.
//  Copyright Cucurbita. All rights reserved.
//

#import "ArchimadeDirectoryLookupOperation.h"
#import "AUPathUtilitiesAddition.h"

NSString *const kArchimadeDirectoryLookupOperationCurrentSizeKey = @"size";
NSString *const kArchimadeDirectoryLookupOperationCurrentCountKey = @"count";

NSString *const kArchimadeResultDirectoryLookupOperationWithErrorNotificationName = @"ArchimadeResultDirectoryLookupOperationWithError";
NSString *const kArchimadeResultDirectoryLookupOperationNotificationName = @"ArchimadeResultDirectoryLookupOperation";
NSString *const kArchimadeTerminateDirectoryLookupOperationNotificationName = @"ArchimadeTerminateDirectoryLookupOperation";

@implementation ArchimadeDirectoryLookupOperation

@synthesize fileNames;

- (void)dealloc
{
	if (fileNames) {
		[fileNames release];
	}
	[super dealloc];
}

- (id)initWithFileNames:(NSArray *)filenames
{
	NSParameterAssert(nil != filenames);
	//NSParameterAssert(0 != [filenames count]);
	if ((self = [super init])) {
		NSLog(@"-- %@ %p", filenames, filenames);
		NSLog(@" %i",[filenames count]);
		ADLO_several = [filenames count] > 1 ? YES : NO;
		self.fileNames = filenames;
	}
	return self;
}

#if (MAC_OS_X_VERSION_MAX_ALLOWED >= 1060)
#define __64_deprecated__
#endif

#include <sys/types.h>
#include <sys/stat.h>

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <unistd.h>
#include <limits.h>

static bool file_isdir(const char *path) {
#if defined(__ppc64__) || defined(__x86_64__) && !defined(__64_deprecated__)
	struct stat64 sb;
#else
	struct stat sb;
#endif
	
#if defined(__ppc64__) || defined(__x86_64__) && !defined(__64_deprecated__)
	if (stat64(path, &sb) == -1)
#else
	if (stat(path, &sb) == -1)
#endif
		return false;
	return(sb.st_mode & S_IFDIR);
}

static bool file_islink(const char *path) {
#if defined(__ppc64__) || defined(__x86_64__) && !defined(__64_deprecated__)
	struct stat64 sb;
#else
	struct stat sb;
#endif
	
#if defined(__ppc64__) || defined(__x86_64__) && !defined(__64_deprecated__)
	if (lstat64(path, &sb) == -1)
#else
	if (lstat(path, &sb) == -1)
#endif
		return false;
	return(S_ISLNK(sb.st_mode));
}

static off_t file_size(const char *path) {
#if defined(__ppc64__) || defined(__x86_64__) && !defined(__64_deprecated__)
	struct stat64 st;
#else
	struct stat st;
#endif
	off_t st_size = 0;

#if defined(__ppc64__) || defined(__x86_64__) && !defined(__64_deprecated__)
	if (stat64(path, &st) != -1)
		st_size = st.st_size;
#else
	if (stat(path, &st) != -1)
		st_size = st.st_size;
#endif
	return st_size;
}

static bool file_isreadable(const char *path) {
	return access(path, R_OK) == 0  ? true : false;
}

static bool file_isexecutable(const char *path) {
	return access(path, X_OK) == 0  ? true : false;
}

- (void)main
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	NSDictionary* info;
	NSString *cmd;
	char line[LINE_MAX];
  	FILE *fp;
  	unsigned long long totalsize = 0, totalcount = 0;
  	size_t len;
  	off_t filesize;
  	const char *filepath;
  	bool stop = false;
 	if (ADLO_several) {
 		cmd = [[NSString alloc] initWithFormat:
			@"/usr/bin/find -f %@ -type d -or -type f 2>/dev/null", AUFileNamesToQuotedPaths(self.fileNames)];
 	} else {
 		cmd = [[NSString alloc] initWithFormat:
			@"/usr/bin/find \"%@\" -type d -or -type f 2>/dev/null", [self.fileNames objectAtIndex:0]];
 	}
	if((fp = popen([cmd UTF8String], "r"))) {
		while (NULL != fgets(line, LINE_MAX, fp)) {
			if ([self isCancelled] || stop) {
				break;
			}			
			len = strlen(line);
			if(line[len -1] == '\n') {
				line[len -1] = 0;
			}
			filepath = line;
			filesize = file_size(filepath);
			if (!file_isreadable(filepath) && !file_islink(filepath)) {
				stop = true;
			}
			if (file_isdir(filepath) && !file_isexecutable(filepath)) {
				stop = true;
			}
			if (stop) {
				[self cancel];
				[[NSNotificationCenter defaultCenter] 
					postNotificationName:kArchimadeResultDirectoryLookupOperationWithErrorNotificationName 
					object:self userInfo:nil
				];
				break;
			} else {
				totalsize += filesize;
				totalcount++;				
				info = [[NSDictionary alloc] initWithObjectsAndKeys:
					[NSNumber numberWithUnsignedLongLong:totalsize], kArchimadeDirectoryLookupOperationCurrentSizeKey,
					[NSNumber numberWithUnsignedLongLong:totalcount], kArchimadeDirectoryLookupOperationCurrentCountKey,
				nil];
				
				[[NSNotificationCenter defaultCenter] 
					postNotificationName:kArchimadeResultDirectoryLookupOperationNotificationName 
					object:self userInfo:info
				];
				
				[info release];
			}
		}		
		pclose(fp);
	}
	[cmd release];
	
	if (![self isCancelled]) {
		[[NSNotificationCenter defaultCenter] 
			postNotificationName:kArchimadeTerminateDirectoryLookupOperationNotificationName 
			object:self
		];
	}
	
	[pool drain];
}

@end

/* EOF */