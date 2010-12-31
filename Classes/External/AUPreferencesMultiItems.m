//
//  AUPreferencesMultiItems.m
//  Application Utility
//
//  Copyright Cucurbita. All rights reserved.
//

#import "AUPreferencesMultiItems.h"
#import "AUSingletonizeClass.h"

#define _kAUPreferencesToolbarIdentifierKey @"NSUserDefaults Value AUPreferencesToolbarIdentifier"
#define _kAUPreferencesToolbarSelectedIdentifierKey @"NSToolbar Configuration NSUserDefaults Value AUPreferencesToolbarSelectedIdentifier"

@implementation AUPreferencesMultiItems

@synthesize selectedItemIdentifier;

#pragma mark singleton

AU_SINGLETONIZE_CLASS_USING_INSTANCE (
	AUPreferencesMultiItems, 
	defaultController
)

- (void)dealloc
{
	[_items release];
	[selectedItemIdentifier release];
	[super dealloc];
}

- (id)init
{
	if ((self = [super init])) {
		NSWindow *aWindow = [
			[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 480, 270) 
			styleMask:(NSTitledWindowMask|NSClosableWindowMask) 
			backing:NSBackingStoreBuffered defer:YES
		];
		
		[aWindow setShowsToolbarButton:NO];
		self.window = aWindow;
		[[self window] setDelegate:self];
		[aWindow release];

		NSToolbar *aToolbar = [[NSToolbar alloc] initWithIdentifier:_kAUPreferencesToolbarIdentifierKey];
		[aToolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
		[aToolbar setAllowsUserCustomization:NO];
		[aToolbar setDelegate:self];
		[aToolbar setAutosavesConfiguration:YES];
		
		[[self window] setToolbar:aToolbar];
		[aToolbar release];
		_items = [[NSMutableArray alloc] initWithCapacity:5];
	}
	
	return self;
}

#pragma mark custom

#if 0

- (CGFloat)toolbarFrameSizeHeight:(NSWindow *)aWindow
{
	NSRect windowFrame;
	
	if([aWindow toolbar] && [[aWindow toolbar] isVisible]) {
		windowFrame = [NSWindow contentRectForFrameRect:[aWindow frame] styleMask:[aWindow styleMask]];
		return NSHeight(windowFrame) - NSHeight([[aWindow contentView] frame]);
	}
	
	return 0.0;
}

#endif

- (void)setItemView:(id<AUPreferencesItemController>)sender firstPaint:(BOOL)firstPaint;
{
	NSRect windowFrame;
	NSRect viewFrame;
	NSView *windowContentView = [[self window] contentView];
	NSView *senderContentView = [sender contentView];
	
	if (NSViewNotSizable != [senderContentView autoresizingMask]) {
		[senderContentView setAutoresizingMask:NSViewNotSizable];
	}
	
	if (!firstPaint && [[self window] isVisible]) {
		if ([[sender class] instancesRespondToSelector:@selector(contentViewWillAppear)]) {
			[sender performSelector:@selector(contentViewWillAppear)];
		}
	}
	
	if (!firstPaint) {
		if ([[windowContentView subviews] count])
			[[[windowContentView subviews] objectAtIndex:0] removeFromSuperview];
	}
	
	viewFrame = [senderContentView frame];
	viewFrame.origin.y = 0;
	[senderContentView setFrame:viewFrame];
	
	windowFrame = [[self window] frameRectForContentRect:viewFrame];
	windowFrame.origin = [[self window] frame].origin;
	windowFrame.origin.y -= windowFrame.size.height - [[self window] frame].size.height;

	if (!NSEqualRects(windowFrame,[[self window] frame]))
		[[self window] setFrame:windowFrame display:YES animate:YES];
	else
		[[self window] displayIfNeeded];
	
	[windowContentView addSubview:senderContentView];
	[[self window] setTitle:[sender label]];
	
	if (!firstPaint && [[self window] isVisible]) {
		if ([[sender class] instancesRespondToSelector:@selector(contentViewDidAppear)]) {
			[sender performSelector:@selector(contentViewDidAppear)];
		}
	}
}

- (NSUInteger)itemCount
{
	return [_items count];
}

- (void)insertItem:(id<AUPreferencesItemController>)item atIndex:(NSUInteger)index
{	
 	if ([[self window] toolbar]) {	
 		if (index <= [self itemCount]) {
 			[_items insertObject:item atIndex:index];
 			[[[self window] toolbar] insertItemWithItemIdentifier:[item identifier] atIndex:index];
 			
 			if (nil == [[NSUserDefaults standardUserDefaults] objectForKey:_kAUPreferencesToolbarSelectedIdentifierKey]) {
				[[NSUserDefaults standardUserDefaults] setObject:[item identifier] 
					forKey:_kAUPreferencesToolbarSelectedIdentifierKey];
				self.selectedItemIdentifier = [item identifier];
			}
 			
 			if (nil == [[[self window] toolbar] selectedItemIdentifier]) {
				[[[self window] toolbar] setSelectedItemIdentifier:[[NSUserDefaults standardUserDefaults] 
					objectForKey:_kAUPreferencesToolbarSelectedIdentifierKey]];
			}
			
			if ([[[[self window] toolbar] selectedItemIdentifier] isEqualToString:[item identifier]]) {
				[[[self window] toolbar] setSelectedItemIdentifier:[item identifier]];
				[self setItemView:item firstPaint:YES];
				self.selectedItemIdentifier = [item identifier];
			}
 		}
 	}
}

- (void)addItem:(id<AUPreferencesItemController>)item
{
	if ([[self window] toolbar]) {
		[self insertItem:item atIndex:[self itemCount]];
	}
}

- (void)removeItem:(NSUInteger)index
{
	
}

- (id<AUPreferencesItemController>)itemAtIndex:(NSUInteger)index
{
 	if (index < [self itemCount]) {
		return [_items objectAtIndex:index];
	}
	
	return nil;
}

- (id<AUPreferencesItemController>)itemForIdentifier:(NSString *)identifier
{
	id<AUPreferencesItemController> toolbarItem;
	NSUInteger index = 0;
	
	do {
		if (nil != (toolbarItem = [self itemAtIndex:index])) {
			if ([[toolbarItem identifier] isEqualToString:identifier]) {
				return toolbarItem;
			}
		}
	} while (++index < [self itemCount]);
	
	return nil;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
	NSMutableArray *identifiers = [NSMutableArray arrayWithCapacity:5];
	id<AUPreferencesItemController> toolbarItem;
	NSUInteger index = 0;
	
	do {
		if (nil != (toolbarItem = [self itemAtIndex:index])) {
			[identifiers addObject:[toolbarItem identifier]];
		}
	} while (++index < [self itemCount]);
	
	return identifiers;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
	return nil;
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{	
	return [self toolbarAllowedItemIdentifiers:toolbar];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)aToolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{	
	NSToolbarItem *tbItem;
	id<AUPreferencesItemController> toolbarItem;
	
	tbItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
	if (nil != (toolbarItem = [self itemForIdentifier:itemIdentifier])) {
		[tbItem setLabel:[toolbarItem label]];
		[tbItem setImage:[toolbarItem icon]];
		[tbItem setTarget:self];
		[tbItem setAction:@selector(toolbarItemSelector:)];
	}

	return tbItem;
}

- (void)toolbarItemSelector:(id)sender
{
	if (![selectedItemIdentifier isEqualToString:[sender itemIdentifier]]) {
		id selected = [self itemForIdentifier:selectedItemIdentifier];
		if ([[selected class] instancesRespondToSelector:@selector(contentViewWillDisappear)]) {
			[selected performSelector:@selector(contentViewWillDisappear)];
		}
	
		[self setItemView:[self itemForIdentifier:[sender itemIdentifier]] firstPaint:NO];
		self.selectedItemIdentifier = [sender itemIdentifier];
		[[NSUserDefaults standardUserDefaults] setObject:[sender itemIdentifier] forKey:_kAUPreferencesToolbarSelectedIdentifierKey];
		
		if ([[selected class] instancesRespondToSelector:@selector(contentViewDidDisappear)]) {
			[selected performSelector:@selector(contentViewDidDisappear)];
		}
	}
}

#pragma mark window delegate

- (void)windowWillClose:(NSNotification *)aNotification
{
	id selected;
	if (!(selected = [self itemForIdentifier:selectedItemIdentifier])) {
		return;
	}
	
	if ([[selected class] instancesRespondToSelector:@selector(contentViewWillDisappear)]) {
		[selected performSelector:@selector(contentViewWillDisappear)];
	}
	
	if ([[selected class] instancesRespondToSelector:@selector(contentViewDidDisappear)]) {
		[selected performSelector:@selector(contentViewDidDisappear)];
	}
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
	id selected;
	if (!(selected = [self itemForIdentifier:selectedItemIdentifier])) {
		return;
	}
	
	if ([[selected class] instancesRespondToSelector:@selector(contentViewWillAppear)]) {
		[selected performSelector:@selector(contentViewWillAppear)];
	}
}

- (void)windowDidBecomeMain:(NSNotification *)aNotification
{
	id selected;
	if (!(selected = [self itemForIdentifier:selectedItemIdentifier])) {
		return;
	}
	
	if ([[selected class] instancesRespondToSelector:@selector(contentViewDidAppear)]) {
		[selected performSelector:@selector(contentViewDidAppear)];
	}
}

#pragma mark inherit

- (void)showWindow:(id)sender
{
	if (![[self window] isVisible]) {
		[[self window] center];
	}
	
	[super showWindow:sender];
}

#pragma mark bind command-w to the window

- (void)keyDown:(NSEvent *)theEvent
{
	if ([[self window] isVisible]) {
		if (NSCommandKeyMask & [theEvent modifierFlags]) {
			if ([theEvent keyCode] == 13) {
				[[NSNotificationCenter defaultCenter] 
					postNotificationName:NSWindowWillCloseNotification 
					object:[self window] userInfo:nil
				];
				[[self window] orderOut:nil];
				return;
			}
		}
		
		NSBeep();
	}
}

@end

/* EOF */