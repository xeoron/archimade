//
//  ArchimadeDragAndDropView.m
//  Archimade
//
//  Created by mmw on 11/3/08.
//  Copyright Cucurbita. All rights reserved.
//

#import "ArchimadeDragAndDropView.h"

NSString *const kArchimadeConcludeDragOperationNotificationName = @"ArchimadeConcludeDragOperation";

@implementation ArchimadeDragAndDropView

@synthesize draggingPasteboard;

- (void)dealloc
{
	if (draggingPasteboard != nil) {
		[draggingPasteboard release];
		self.draggingPasteboard = nil;
	}
	[super dealloc];
}


- (void)setImage:(NSImage *)image
{
	// our disable mode
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
	if (draggingPasteboard != nil) {
		[draggingPasteboard release];
		self.draggingPasteboard = nil;
	}
	return NSDragOperationCopy;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
	self.draggingPasteboard = [sender draggingPasteboard];	
	return YES;
}

- (void)concludeDragOperation:(id<NSDraggingInfo>)sender
{	
	[super concludeDragOperation:sender];
	[[NSNotificationCenter defaultCenter] 
		postNotificationName:kArchimadeConcludeDragOperationNotificationName object:self];
}

@end

/* EOF */