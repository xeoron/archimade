//
//  ArchimadeArchiveTaskOperation.m
//  Archimade
//
//  Created by mmw on 11/7/08.
//  Copyright Cucurbita. All rights reserved.
//

#import "ArchimadeArchiveTaskOperation.h"
#import "AUFileManagerAddition.h"

NSString *const kArchimadeTerminateTaskOperationWithErrorNotificationName = @"ArchimadeTerminateTaskOperationWithError";
NSString *const kArchimadeTerminateTaskOperationNotificationName = @"ArchimadeTerminateTaskOperation";

@implementation ArchimadeArchiveTaskOperation

@synthesize launchPath;
@synthesize targetPath;

- (void)dealloc
{
	if (AATOC_internalTask) {
		[AATOC_internalTask release];
	}
	
	if (AATOC_arguments) {
		[AATOC_arguments release];
	}
	
	[launchPath release];
	[targetPath release];
	
	[super dealloc];
}

- (id)initWithRootControllerAndArguments:(id)controller arguments:(NSArray *)args typeOfSelector:(NSInteger)type
{
	NSParameterAssert(nil != controller);
	NSParameterAssert(nil != args);

	if ((self = [super init])) {
		AATOC_rootController = controller;
		AATOC_typeOfSelector = type;
		AATOC_arguments = [[NSMutableArray alloc] initWithArray:args];
		
		self.launchPath = [AATOC_arguments objectAtIndex:0];
		[AATOC_arguments removeObjectAtIndex:0];
		
		self.targetPath = [AATOC_arguments objectAtIndex:0];
		[AATOC_arguments removeObjectAtIndex:0];
		
		AATOC_running = NO;
		AATOC_internalTask = [[NSTask alloc] init];
		
	}
	
    return self;
}

- (void)setEnvironmentVariable:(id)value forKey:(NSString *)name
{	
	[AATOC_internalTask setEnvironment:[NSDictionary dictionaryWithObject:value forKey:name]];
}

- (void)setEnvironmentVariables:(NSDictionary *)environment
{	
	[AATOC_internalTask setEnvironment:environment];
}

- (NSDictionary *)environment
{
	return [AATOC_internalTask environment];
}
	
- (void)start
{
	if ([self isRunning]) {
		return;
	}
	
	[AATOC_internalTask setStandardOutput:[NSPipe pipe]];
	[AATOC_internalTask setStandardError:[AATOC_internalTask standardOutput]];
	[AATOC_internalTask setLaunchPath:self.launchPath];
	[AATOC_internalTask setArguments:AATOC_arguments];
	
	NSLog(@" %@" , AATOC_arguments);
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
		selector:@selector(onEventData:) 
		name:NSFileHandleReadCompletionNotification 
		object:[[AATOC_internalTask standardOutput] fileHandleForReading]];
	
	[[[AATOC_internalTask standardOutput] fileHandleForReading] readInBackgroundAndNotify];
	
	@try {
		[AATOC_internalTask launch];
	} @catch (NSException *exc) {
		[[NSNotificationCenter defaultCenter] removeObserver:self 
			name:NSFileHandleReadCompletionNotification 
			object:[[AATOC_internalTask standardOutput] fileHandleForReading]];
		
		[AATOC_internalTask release];
		[AATOC_arguments release];
		AATOC_arguments = nil;
		AATOC_internalTask = nil;
		AATOC_running = NO;
		
		[[NSNotificationCenter defaultCenter] 
			postNotificationName:kArchimadeTerminateTaskOperationWithErrorNotificationName object:self];
			
		return;
	}
	
	if (![AATOC_internalTask isRunning]) {
		[[NSNotificationCenter defaultCenter] removeObserver:self 
			name:NSFileHandleReadCompletionNotification 
			object:[[AATOC_internalTask standardOutput] fileHandleForReading]];
			
		[AATOC_internalTask release];
		[AATOC_arguments release];
		AATOC_arguments = nil;
		AATOC_internalTask = nil;
		AATOC_running = NO;
		
		[[NSNotificationCenter defaultCenter] 
			postNotificationName:kArchimadeTerminateTaskOperationWithErrorNotificationName object:self];
		
	} else {
		AATOC_running = YES;
	}
	
	if ([self isRunning] && AATOC_typeOfSelector == ArchimadeArchiveTaskOperationSizeSelector) {
		NSTimer *aTimer;
		aTimer = [NSTimer scheduledTimerWithTimeInterval:6.65
			target:self selector:@selector(onEventSize:) userInfo:nil repeats:YES];
	}
}

- (void)stop:(BOOL)shouldContinueUntilDataLen
{	
	NSData *data;
	
	if (![self isRunning]) {
		return;
	}
	
	[[NSNotificationCenter defaultCenter] removeObserver:self 
		name:NSFileHandleReadCompletionNotification 
		object:[[AATOC_internalTask standardOutput] fileHandleForReading]];
	
	[AATOC_internalTask terminate];
	
	if ([self isRunning] && shouldContinueUntilDataLen && AATOC_typeOfSelector == ArchimadeArchiveTaskOperationDataSelector) {
		while ((data = [[[AATOC_internalTask standardOutput] fileHandleForReading] availableData]) && [data length]) {
			if (!AATOC_rootController) {
				break;
			}
			
			if ([AATOC_rootController respondsToSelector:@selector(receivedData:)]) {
				[AATOC_rootController performSelector:@selector(receivedData:) withObject:data];
			}
		}
	}
	
	[AATOC_internalTask interrupt];
	[AATOC_internalTask release];
	[AATOC_arguments release];
	AATOC_arguments = nil;
	AATOC_internalTask = nil;
	AATOC_running = NO;
	
	[[NSNotificationCenter defaultCenter] 
		postNotificationName:kArchimadeTerminateTaskOperationNotificationName object:self];
}

- (void)kill {
	if (![self isRunning]) {
		return;
	}

	[[NSNotificationCenter defaultCenter] removeObserver:self 
		name:NSFileHandleReadCompletionNotification 
		object:[[AATOC_internalTask standardOutput] fileHandleForReading]];
	
	[AATOC_internalTask terminate];
	[AATOC_internalTask interrupt];
	[AATOC_internalTask release];
	[AATOC_arguments release];
	AATOC_arguments = nil;
	AATOC_internalTask = nil;
	AATOC_running = NO;
}

- (BOOL)isRunning
{
	return AATOC_running;
}

- (void)onEventSize:(NSTimer *)timer
{
	NSNumber *size;
	if (![self isRunning]) {
		[timer invalidate];
		return;
	}	
	if (nil != (size = [[NSFileManager defaultManager] fileSizeAtPath:self.targetPath])) {
		if (!AATOC_rootController) {
			return;
		}
		
		if ([AATOC_rootController respondsToSelector:@selector(receivedSize:)]) {
			[AATOC_rootController performSelector:@selector(receivedSize:) withObject:size];
		}
	}
}

- (void)onEventData:(NSNotification *)aNotification
{
	NSData *data;
	BOOL onData = NO;	
	if ([self isRunning]) {
		if (nil != (data = [[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem])) {
			if ([data length]) {
				if (AATOC_typeOfSelector == ArchimadeArchiveTaskOperationDataSelector) {
					if (!AATOC_rootController) {
						return;
					}
					if ([AATOC_rootController respondsToSelector:@selector(receivedData:)]) {
						[AATOC_rootController performSelector:@selector(receivedData:) withObject:data];
					}
				}
				onData = YES;
			}
		}		
		if (!onData) {
			[self stop:YES];
		}
		[[aNotification object] readInBackgroundAndNotify];
	}
}

@end

/* EOF */