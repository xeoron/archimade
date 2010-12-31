//
//  ArchimadeDirectoryLookupOperation.h
//  Archimade
//
//  Created by mmw on 11/10/08.
//  Copyright Cucurbita. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ArchimadeDirectoryLookupOperation : NSOperation {
	
	BOOL ADLO_several;
	NSArray *fileNames;
	
}

@property (nonatomic, retain) NSArray *fileNames;

- (id)initWithFileNames:(NSArray *)filenames;

@end

/* EOF */