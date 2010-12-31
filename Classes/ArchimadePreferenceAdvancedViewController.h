//
//  ArchimadePreferenceAdvancedViewController.h
//  Archimade
//
//  Created by mmw on 11/16/08.
//  Copyright Cucurbita. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AUPreferencesMultiItems.h"

@interface ArchimadePreferenceAdvancedViewController : NSViewController <AUPreferencesItemController> {

@private
	BOOL APADVC_sync;

@public
	NSArray *options;
	NSButton *keepMacOSContents;
	NSButton *archiveOnDesktop;
	NSButton *revealInFinder;
	NSButton *activateApplication;
}

@property (assign) NSArray *options;
@property (assign) IBOutlet NSButton *keepMacOSContents;
@property (assign) IBOutlet NSButton *archiveOnDesktop;
@property (assign) IBOutlet NSButton *revealInFinder;
@property (assign) IBOutlet NSButton *activateApplication;

- (id)initWithLabelAndIcon:(NSString *)label icon:(NSImage *)icon identifier:(NSString *)identifier;
- (IBAction)update:(id)sender;

- (NSImage *)icon;
- (NSString *)label;
- (NSString *)identifier;
- (NSView *)contentView;

@end

/* EOF */