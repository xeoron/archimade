//
//  ArchimadeProgressWindowController.h
//  Archimade
//
//  Created by mmw on 11/5/08.
//  Copyright Cucurbita. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ArchimadeArchiveTaskOperation.h"

@interface ArchimadeProgressWindowController : NSWindowController <ArchimadeArchiveTaskOperationController> {

@private
	unsigned long long APWC_countItem;
	unsigned long long APWC_totalSize;
	NSTimer *APWC_timerRepeat;
	struct APWC__Flags {
		BOOL _multiItems:YES;
		BOOL _lockCancel:YES;
		BOOL _isCancelled:YES;
		BOOL _isRunning:YES;
		BOOL _archiveOnDesktop:YES;
		BOOL _keepExtraContents:YES;
		BOOL _updateInfoTextFieldNumberOfItems:YES;
	} APWC_Flags;
	NSString *APWC_archivePath;
	NSArray *APWC_taskArguments;
	NSOperationQueue *APWC_operationQueue;
	ArchimadeArchiveTaskOperation *APWC_archiveTaskOperation;
	id APWC_rootController;

@public
	NSProgressIndicator *progressIndicator;
	NSTextField *messageTextField;
	NSTextField *infoTextField;
	NSImageView *iconView;
	NSArray *fileNames;
	NSNumber *archiveType;
	NSString *archivePath;
}

@property (assign) IBOutlet NSProgressIndicator *progressIndicator;
@property (assign) IBOutlet NSTextField *messageTextField;
@property (assign) IBOutlet NSTextField *infoTextField;
@property (assign) IBOutlet NSImageView *iconView;
@property (nonatomic, retain) NSArray *fileNames;
@property (nonatomic, retain) NSNumber *archiveType;

- (id)initWithRootControllerAndOptions:(id)controller options:(NSArray *)options;
- (void)startOperation;
- (void)stopOperation;
- (BOOL)isCancelled;
- (IBAction)cancelOperation:(id)sender;

@end

/* EOF */