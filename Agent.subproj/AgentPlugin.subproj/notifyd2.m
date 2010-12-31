#import "pluginLoader.h"

// gcc notifyd2.m pluginLoader.m -framework CoreServices -framework Foundation -framework AppKit -o mynotifyd -I Classes

#define forever for(;;)

int main (int argc, const char * argv[]) {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	ArchimadeAgentPluginLoader *loader = [ArchimadeAgentPluginLoader new];
	
	NSString *fullpath = [[NSString alloc] initWithFormat:@"%s/build/Debug/ArchimadeAgentPlugin.bundle", getenv("PWD")];
	
	[loader loadBundleWithPath:fullpath];
	
	forever {
		[[loader instance] startArchiveOperation:@"/Users/mmw/Desktop/Home"];
		sleep(15);
	}
	
	[pool drain];
	return 0;
}

/* EOF */