//
//  ArchimadeArchiveTaskOperation.h
//  Archimade
//
//  Created by mmw on 11/7/08.
//  Copyright Cucurbita. All rights reserved.
//

#import <Cocoa/Cocoa.h>

enum {
	ArchimadeArchiveTaskOperationNoSelector,
	ArchimadeArchiveTaskOperationDataSelector,
	ArchimadeArchiveTaskOperationSizeSelector
};

@protocol ArchimadeArchiveTaskOperationController <NSObject>

@optional
- (void)receivedSize:(NSNumber *)size;
- (void)receivedData:(NSData *)data;
	
@end

@interface ArchimadeArchiveTaskOperation : NSObject {

@private
    NSMutableArray *AATOC_arguments;
    NSTask *AATOC_internalTask;
    id<ArchimadeArchiveTaskOperationController> AATOC_rootController;
    NSInteger AATOC_typeOfSelector;
    BOOL AATOC_running;
    
@public
    NSString *launchPath;
    NSString *targetPath;
    
}

@property (nonatomic, retain) NSString *launchPath;
@property (nonatomic, retain) NSString *targetPath;

- (id)initWithRootControllerAndArguments:(id)controller arguments:(NSArray *)args typeOfSelector:(NSInteger)type;
- (void)setEnvironmentVariable:(id)value forKey:(NSString *)name;
- (void)setEnvironmentVariables:(NSDictionary *)environment;
- (NSDictionary *)environment;
- (void)start;
- (void)stop:(BOOL)shouldContinueUntilDataLen;
- (void)kill;
- (BOOL)isRunning;

@end

/* EOF */