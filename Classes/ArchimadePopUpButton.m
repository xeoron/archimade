//
//  ArchimadePopUpButton.m
//  Archimade
//
//  Created by mmw on 1/1/11.
//  Copyright 2011 Cucurbita. All rights reserved.
//

#import "ArchimadePopUpButton.h"


@implementation ArchimadePopUpButton

- (void)dealloc
{
	if (APUB_bgimage != nil) {
		[APUB_bgimage release];
	}
	if (APUB_fontattr != nil) {
		[APUB_fontattr release];
	}
	[super dealloc];
}

- (id)initWithCoder:(NSCoder *)decoder
{
	if ((self = [super initWithCoder:decoder])) {
		APUB_bgimage = [[NSImage imageNamed:@"ArchimadePopup"] retain];
		APUB_fontattr = [[NSMutableDictionary alloc] init];
		[APUB_fontattr setValue:[NSFont systemFontOfSize:11.0] forKey:NSFontAttributeName];
		NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
		[shadow setShadowOffset:NSMakeSize(0, -1)];
		[shadow setShadowBlurRadius:0.1];
		[shadow setShadowColor:[[NSColor whiteColor] colorWithAlphaComponent:0.6]];
		[APUB_fontattr setValue:shadow forKey:NSShadowAttributeName];
		[APUB_fontattr setValue:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
#if (MAC_OS_X_VERSION_MAX_ALLOWED < 1060)
		[APUB_bgimage setFlipped:YES];
#endif
	}
	return self;
}

- (void)drawRect:(NSRect)rect
{
	if (APUB_bgimage != nil) {
#if (MAC_OS_X_VERSION_MAX_ALLOWED >= 1060)
	 	[APUB_bgimage drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0f respectFlipped:YES hints:nil];
#else
	 	[APUB_bgimage drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0f];
#endif
	}
	if (APUB_fontattr != nil) {
		NSString *item = [self titleOfSelectedItem];
		NSSize itemsize = [item sizeWithAttributes:APUB_fontattr];
		NSSize imgsize = [APUB_bgimage size];
		CGFloat x = (imgsize.width - itemsize.width) / 2.0f;
		CGFloat y = (imgsize.height - itemsize.height) / 2.0f;
		[item drawAtPoint:NSMakePoint(x, y) withAttributes:APUB_fontattr];
	}
}

@end

/* EOF */