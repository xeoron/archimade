//
//  ArchimadeAgentApplicationController.h
//  ArchimadeAgent
//
//  Created by mmw on 2/2/09.
//  Copyright 2009 Cucurbita. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ArchimadeAgentApplicationController : NSObject {

	NSNumber *archiveType;
	NSArray *soundCollection;
	NSMutableArray *controllerCollection;
	NSMutableArray *archiveFileQueue;

}

@property (nonatomic, retain) NSNumber *archiveType;
@property (nonatomic, retain) NSArray *soundCollection;
@property (nonatomic, retain) NSMutableArray *controllerCollection;
@property (nonatomic, retain) NSMutableArray *archiveFileQueue;

- (void)initUserDefaults;
- (void)awakeFromMain;
- (void)pushWindowController:(id)controller;
- (void)popWindowController:(id)controller;
- (void)archiveFileQueueAdd:(NSString *)archiveFilePath;
- (void)archiveFileQueueRemove:(NSString *)archiveFilePath;
- (NSNumber *)archiveFileQueueExists:(NSString *)archiveFilePath;
	
@end

/* EOF */
