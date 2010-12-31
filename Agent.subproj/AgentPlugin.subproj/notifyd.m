#import "ArchimadeAgentPlugin.h"

// gcc notifyd.m Classes/*.m -I./Classes -framework CoreServices -framework Foundation -framework AppKit -o notifyd

#define forever for(;;)

int main (int argc, const char * argv[]) {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	ArchimadeAgentPlugin *plugin = [ArchimadeAgentPlugin new];
	
	forever {
		[plugin startArchiveOperation:@"/usr"];
		sleep(15);
	}
	
	[pool drain];
	return 0;
}

/* EOF */