//
//  pluginLoader.m
//  ArchimadeAgentPlugin Example
//  gcc -c pluginLoader.m -o pluginLoader.o -I Classes
//
//  Created by mmw on 2/2/09.
//  Copyright 2009 Cucurbita. All rights reserved.
//

#import "pluginLoader.h"

@implementation ArchimadeAgentPluginLoader

- (void)dealloc {
	if (AAPL_instance) {
		[AAPL_instance release];
	}
	
	[super dealloc];
}

- (BOOL)loadBundle {
	if (!AAPL_bundle) {
		Class ArchimadeAgentPlugin;
		if (AAPL_bundle = [NSBundle bundleWithIdentifier:kArchimadeAgentPluginIdentifierName]) {
			if (ArchimadeAgentPlugin = [AAPL_bundle principalClass]) {
				if (AAPL_instance = [[ArchimadeAgentPlugin alloc] init]) {
					return YES;
				}
			}
		}
	}
	
	return NO;
}

- (BOOL)loadBundleWithPath:(NSString *)fullPath {
	if (!AAPL_bundle && fullPath) {
		Class ArchimadeAgentPlugin;
		if (AAPL_bundle = [NSBundle bundleWithPath:fullPath]) {
			if (ArchimadeAgentPlugin = [AAPL_bundle principalClass]) {
				if (AAPL_instance = [[ArchimadeAgentPlugin alloc] init]) {
					return YES;
				}
			}
		}
	}
	
	return NO;
}

- (ArchimadeAgentPlugin *)instance
{
	return AAPL_instance;
}

- (NSBundle *)bundle
{
	return AAPL_bundle;
}

@end

/* EOF */