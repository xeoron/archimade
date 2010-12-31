//
//  AUPreferencesMultiItems.h
//  Application Utility
//
//  Copyright Cucurbita. All rights reserved.
//

#import "AUCommonGround.h"

@protocol AUPreferencesItemController <NSObject>

- (NSImage *)icon;
- (NSString *)label;
- (NSString *)identifier;
- (NSView *)contentView;

@optional
- (void)contentViewWillAppear;
- (void)contentViewDidAppear;
- (void)contentViewWillDisappear;
- (void)contentViewDidDisappear;

@end

@interface AUPreferencesMultiItems : NSWindowController
#if (MAC_OS_X_VERSION_MAX_ALLOWED >= 1060)
<NSWindowDelegate, NSToolbarDelegate>
#endif
{
	
@private
	NSMutableArray *_items;
	
@public
	NSString *selectedItemIdentifier;
	
}

@property (nonatomic, retain) NSString *selectedItemIdentifier;

+ (AUPreferencesMultiItems *)defaultController;
- (void)addItem:(id<AUPreferencesItemController>)item;

@end

/* EOF */