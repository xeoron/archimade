//
//  ArchimadePreferenceAccessibilityViewController.h
//  Archimade
//
//  Created by mmw on 11/16/08.
//  Copyright Cucurbita. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AUPreferencesMultiItems.h"

@interface ArchimadePreferenceAccessibilityViewController : NSViewController <AUPreferencesItemController> {

@private
	BOOL APACVC_sync;

@public
	NSArray *options;
	NSButton *activateVoiceOver;
	
}

@property (assign) NSArray *options;
@property (assign) IBOutlet NSButton *activateVoiceOver;

- (id)initWithLabelAndIcon:(NSString *)label icon:(NSImage *)icon identifier:(NSString *)identifier;
- (IBAction)update:(id)sender;

- (NSImage *)icon;
- (NSString *)label;
- (NSString *)identifier;
- (NSView *)contentView;

@end

/* EOF */