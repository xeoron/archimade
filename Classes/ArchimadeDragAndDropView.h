//
//  ArchimadeDragAndDropView.h
//  Archimade
//
//  Created by mmw on 11/3/08.
//  Copyright Cucurbita. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ArchimadeDragAndDropView : NSImageView {

	NSPasteboard *draggingPasteboard;
	
}

@property (nonatomic, retain) NSPasteboard *draggingPasteboard;

@end

/* EOF */