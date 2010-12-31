//
//  AUFileManagerAddition.h
//  Application Utility
//
//  Copyright Cucurbita. All rights reserved.
//

#import "AUCommonGround.h"

#define kAUFileManagerAdditionVolumeInfoTypekey @"type"
#define kAUFileManagerAdditionVolumeInfoDirectorykey @"directory"
#define kAUFileManagerAdditionVolumeInfoFileSystemkey @"filesystem"

@interface NSFileManager (AUFileManagerAddition)

- (BOOL)isSymbolicLinkFileAtPath:(NSString *)filePath;
- (NSNumber *)fileSizeAtPath:(NSString *)filePath;
- (BOOL)isDirectoryFileAtPath:(NSString *)filePath;
- (BOOL)isVolumeFileAtPath:(NSString *)filePath;
- (NSString *)directoryNameAtPath:(NSString *)filePath;
- (NSString *)baseNameAtPath:(NSString *)filePath;
- (NSArray *)volumes;

@end

/* EOF */