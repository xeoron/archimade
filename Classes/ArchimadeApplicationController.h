//
//  ArchimadeApplicationController.h
//  Archimade
//
//  Created by mmw on 11/2/08.
//  Copyright Cucurbita. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ArchimadeApplicationController : NSObject {

	NSWindow *window;
	NSImageView *dropView;
	NSPopUpButton *archiveTypeList;
	NSArray *soundCollection;
	NSMutableArray *controllerCollection;
	NSMutableArray *archiveFileQueue;
	
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSImageView *dropView;
@property (assign) IBOutlet NSPopUpButton *archiveTypeList;
@property (assign) NSArray *soundCollection;
@property (assign) NSMutableArray *controllerCollection;
@property (assign) NSMutableArray *archiveFileQueue;

- (void)initUserDefaults;
- (void)pushWindowController:(id)controller;
- (void)popWindowController:(id)controller;
- (void)archiveFileQueueAdd:(NSString *)archiveFilePath;
- (void)archiveFileQueueRemove:(NSString *)archiveFilePath;
- (NSNumber *)archiveFileQueueExists:(NSString *)archiveFilePath;
- (IBAction)openPreferences:(id)sender;
- (IBAction)archiveTypeSelector:(id)sender;
- (void)shakeWindow:(NSWindow *)aWindow;

@end

/* EOF */