//
//  AUFileManagerAddition.m
//  Application Utility
//
//  Copyright Cucurbita. All rights reserved.
//

#import "AUFileManagerAddition.h"

@implementation NSFileManager (AUFileManagerAddition)

#include <sys/types.h>
#include <sys/param.h>
#include <sys/ucred.h>
#include <sys/mount.h>
#include <sys/stat.h>

#include <stdio.h>
#include <stdlib.h>

#if (MAC_OS_X_VERSION_MAX_ALLOWED >= 1060)
#define __64_deprecated__
#endif

- (BOOL)isSymbolicLinkFileAtPath:(NSString *)filePath
{
#if 0
	NSDictionary *fileAttributes = [self fileAttributesAtPath:filePath traverseLink:NO];
	NSString *fileTypeDescription;
	
	if ((fileTypeDescription = [fileAttributes objectForKey:NSFileType])) {
		return [fileTypeDescription isEqualToString:NSFileTypeSymbolicLink];
	}
	
	return NO;
#endif
	
	BOOL islink = NO;
	const char *path;
	
#if defined(__ppc64__) || defined(__x86_64__) && !defined(__64_deprecated__)
	struct stat64 sb;
#else
	struct stat sb;
#endif
	
	if (NULL != (path = [self fileSystemRepresentationWithPath:filePath])) {
#if defined(__ppc64__) || defined(__x86_64__) && !defined(__64_deprecated__)
		if (lstat64(path, &sb) == -1)
#else
		if (lstat(path, &sb) == -1)
#endif
			islink = NO;
		else
			islink = S_ISLNK(sb.st_mode) ? YES : NO;
	}
	
	return islink;
}

- (NSNumber *)fileSizeAtPath:(NSString *)filePath
{
#if 0
	NSDictionary *fileAttributes = [self fileAttributesAtPath:filePath traverseLink:NO];
	
	return [fileAttributes objectForKey:NSFileSize];
#endif

	off_t st_size = 0;
	const char *path;
	
#if defined(__ppc64__) || defined(__x86_64__) && !defined(__64_deprecated__)
	struct stat64 st;
#else
	struct stat st;
#endif
	
	if (NULL != (path = [self fileSystemRepresentationWithPath:filePath])) {
#if defined(__ppc64__) || defined(__x86_64__) && !defined(__64_deprecated__)
		if (stat64(path, &st) != -1) {
			st_size = st.st_size;
		}
#else
		if (stat(path, &st) != -1) {
			st_size = st.st_size;
		}
#endif
	}
	
	return [NSNumber numberWithUnsignedLongLong:st_size];

}

- (BOOL)isDirectoryFileAtPath:(NSString *)filePath
{
	BOOL isdir = NO;

	if(![self fileExistsAtPath:filePath isDirectory:&isdir]) {
		return NO;
	}
	
	return isdir;
}

- (BOOL)isVolumeFileAtPath:(NSString *)filePath
{
	NSInteger i = 0;
	NSArray *vols;
	
	if ([filePath isEqualToString:@"/Volumes"] ||
			[filePath isEqualToString:@"/Network"]) { // ditto automountd
		return YES;
	}
	
	if (nil != (vols = [self volumes])) {
		do {
			if ([filePath isEqualToString:[[vols objectAtIndex:i] 
					objectForKey:kAUFileManagerAdditionVolumeInfoDirectorykey]]) {
				return YES;
			}
		} while (++i < [vols count]);
	}
	
	return NO;
}

- (NSString *)directoryNameAtPath:(NSString *)filePath
{
	return [filePath stringByDeletingLastPathComponent];
}

- (NSString *)baseNameAtPath:(NSString *)filePath
{
	return [filePath lastPathComponent];
}

- (NSArray *)volumes
{
	NSInteger i = 0, items = 0;
	struct statfs *mntbufp;
	NSMutableArray *list;
	NSArray *objects;
	NSArray *keys;
	
	if ((items = getmntinfo(&mntbufp, MNT_NOWAIT))) {
		keys = [NSArray arrayWithObjects:
			kAUFileManagerAdditionVolumeInfoTypekey, 
			kAUFileManagerAdditionVolumeInfoDirectorykey, 
			kAUFileManagerAdditionVolumeInfoFileSystemkey, 
		nil];
		
		if (nil != (list = [NSMutableArray arrayWithCapacity:items])) {
			do {
				objects = [NSArray arrayWithObjects:
					[NSString stringWithCString:mntbufp[i].f_fstypename encoding:NSUTF8StringEncoding], 
					[NSString stringWithCString:mntbufp[i].f_mntonname encoding:NSUTF8StringEncoding], 
					[NSString stringWithCString:mntbufp[i].f_mntfromname encoding:NSUTF8StringEncoding], 
				nil];
				
				if ([objects count] == [keys count]) {
					[list addObject:[NSDictionary dictionaryWithObjects:objects forKeys:keys]];
				}
			} while (++i < items);
			
			return list;
		}
	}
	
	return nil;
}

@end

/* EOF */