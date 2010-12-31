//
//  pluginLoader.h
//  ArchimadeAgentPlugin Example
//
//  Created by mmw on 2/2/09.
//  Copyright 2009 Cucurbita. All rights reserved.
//

#import "ArchimadeAgentPlugin.h"

@interface ArchimadeAgentPluginLoader : NSObject {

	id AAPL_instance;
	NSBundle *AAPL_bundle;

}

- (BOOL)loadBundle;
- (BOOL)loadBundleWithPath:(NSString *)fullPath;
- (ArchimadeAgentPlugin *)instance;
- (NSBundle *)bundle;

@end

/* EOF */