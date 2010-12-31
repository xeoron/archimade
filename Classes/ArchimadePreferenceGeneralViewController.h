//
//  ArchimadePreferenceGeneralViewController.h
//  Archimade
//
//  Created by mmw on 11/16/08.
//  Copyright Cucurbita. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AUPreferencesMultiItems.h"

@interface ArchimadePreferenceGeneralViewController : NSViewController <AUPreferencesItemController> {

@private
	BOOL APGVC_sync;

@public
	NSArray *options;
	NSButton *overwriteArchive;
	NSButton *abbreviateExtension;
	
}

@property (assign) NSArray *options;
@property (assign) IBOutlet NSButton *overwriteArchive;
@property (assign) IBOutlet NSButton *abbreviateExtension;

- (id)initWithLabelAndIcon:(NSString *)label icon:(NSImage *)icon identifier:(NSString *)identifier;
- (IBAction)update:(id)sender;

- (NSImage *)icon;
- (NSString *)label;
- (NSString *)identifier;
- (NSView *)contentView;

@end

/* EOF */