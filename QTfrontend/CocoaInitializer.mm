/*
 * Copyright (C) 2008 Remko Troncon
 */

#include "CocoaInitializer.h"

#include <AppKit/AppKit.h>
#include <Cocoa/Cocoa.h>
#include <QtDebug>

class CocoaInitializer::Private
{
	public:
		NSAutoreleasePool* autoReleasePool_;
};

CocoaInitializer::CocoaInitializer()
{
	d = new CocoaInitializer::Private();
        c = new CocoaInitializer::Private();
	NSApplicationLoad();
        c->autoReleasePool_ = [[NSAutoreleasePool alloc] init];
	d->autoReleasePool_ = [[NSAutoreleasePool alloc] init];
}

CocoaInitializer::~CocoaInitializer()
{
	[d->autoReleasePool_ release];
        [c->autoReleasePool_ release];
	delete c;
	delete d;
}
