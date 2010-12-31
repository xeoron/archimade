//
//  ArchimadeAgentPlugin.h
//  ArchimadeAgentPlugin
//
//  Created by mmw on 2/2/09.
//  Copyright 2009 Cucurbita. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreServices/CoreServices.h>
#import <AppKit/AppKit.h>

#define kArchimadeAgentPluginIdentifierName			@"com.googlecode.archimade.ArchimadeAgentPlugin"

#define kArchimadeAgentBundleIdentifierName			CFSTR("com.googlecode.archimade.ArchimadeAgent")
#define kArchimadeAgentPluginNotificationName		@"com.googlecode.archimade.ArchimadeAgent.Notification"
#define kArchimadeAgentPluginIdentifierObject		@"com.googlecode.archimade.ArchimadeAgent.Plugin"

#define kArchimadeAgentPluginUserInfoFilePathKey	@"FilePath"
#define kArchimadeAgentPluginUserInfoAchiveTypeKey	@"AchiveType"

enum {
	kArchimadeAgentPluginArchiveTypeTarGZip = 0,
	kArchimadeAgentPluginArchiveTypeTarBZip = 1,
	kArchimadeAgentPluginArchiveTypeTarZiv = 2,
	kArchimadeAgentPluginArchiveTypeTarOnly = 3,
	kArchimadeAgentPluginArchiveTypeZipOnly = 4,
	kArchimadeAgentPluginArchiveTypeDefault = 90
};

enum {
	kArchimadeAgentPluginOptionDisableAllSounds = 10,
	kArchimadeAgentPluginOptionAbreviateExtension = 20,
	kArchimadeAgentPluginOptionArchiveOnDesktop = 30,
	kArchimadeAgentPluginOptionRevealInFinder = 40,
	kArchimadeAgentPluginOptionKeepExtraContent = 50,
	kArchimadeAgentPluginOptionOverwriteArchive = 60,
	kArchimadeAgentPluginOptionApplyDefault = 200
};

@interface ArchimadeAgentPlugin : NSObject {

@private
	NSDistributedNotificationCenter *AAP_distributedCenter;
	
}

- (BOOL)startArchiveOperation:(NSString *)filename;
- (BOOL)startArchiveOperation:(NSString *)filename options:(NSInteger)options;
- (BOOL)startArchiveOperation:(NSString *)filename options:(NSInteger)options safe:(BOOL)safe;
- (BOOL)startArchiveOperation:(NSString *)filename options:(NSInteger)options delay:(NSTimeInterval)delay;

@end

/* EOF */