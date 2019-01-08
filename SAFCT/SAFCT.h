/*!
 *	Copyright 2015 Apple Inc. All rights reserved.
 *
 *	APPLE NEED TO KNOW CONFIDENTIAL
 *
 *  SAFCT.h
 *  SAFCT
 *
 */

 #import <CoreTestFoundation/CoreTestFoundation.h>

@interface SAFCT : CTPluginBaseFactory <CTPluginFactory>

- (void)registerBundlePlugins;

@end