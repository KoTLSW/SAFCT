/*!
 *	Copyright 2015 Apple Inc. All rights reserved.
 *
 *	APPLE NEED TO KNOW CONFIDENTIAL
 *
 *  SAFCT.h
 *  SAFCT
 *
 */

#import "SAFCT.h"
#import "Communication.h"

@implementation SAFCT

- (void)registerBundlePlugins
{
	[self registerPluginName:@"Communication" withPluginCreator:^id<CTPluginProtocol>(){
		return [[Communication alloc] init];
	}];
}

@end
