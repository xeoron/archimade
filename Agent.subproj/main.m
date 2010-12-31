//
//  ArchimadeAgent.m
//  ArchimadeAgent
//
//  Created by mmw on 2/2/09.
//  Copyright Cucurbita 2009. All rights reserved.
//

#import "ArchimadeAgentApplicationController.h"

int main(int argc, char* argv[])
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	id owner = [[ArchimadeAgentApplicationController alloc] init];
	[[NSApplication sharedApplication] setDelegate:owner];
	[[[NSApplication sharedApplication] delegate] awakeFromMain];
	[owner release];
	[[NSApplication sharedApplication] run];
	[pool release];
	
    return 0;
}

/* EOF */