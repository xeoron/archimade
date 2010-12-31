//
//  ArchimadeAgentPluginWorkspaceAddition.h
//  ArchimadeAgentPlugin
//
//  Created by mmw on 2/2/09.
//  Copyright 2009 Cucurbita. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreServices/CoreServices.h>
#import <AppKit/AppKit.h>

@interface NSWorkspace (ArchimadeWorkspaceAddition)

- (BOOL)isApplicationLaunchedUsingIdentifier:(NSString *)identifier;
- (BOOL)isApplicationLaunchedUsingIdentifier:(NSString *)identifier checkInBackground:(BOOL)checkInBackground;
- (BOOL)isApplicationLaunchedUsingIdentifier:(NSString *)identifier checkInBackground:(BOOL)checkInBackground isBackgroundProcess:(BOOL *)isBackgroundProcess;
- (NSArray *)launchedApplications:(BOOL)showBackgroundProcess;

@end

/* EOF */