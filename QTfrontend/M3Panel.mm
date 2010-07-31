/*
 *  M3Panel.cpp
 *
 *
 *  Created by Vittorio on 28/09/09.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */

#include "M3Panel.h"
#include "M3InstallController.h"

#include <Cocoa/Cocoa.h>

class M3Panel::Private
{
public:
        M3InstallController *install;
};

M3Panel::M3Panel(void)
{
	c = new Private;

	c->install = [[M3InstallController alloc] init];
	[c->install retain];

}

M3Panel::~M3Panel()
{
	[c->install release];
	delete c;
}

void M3Panel::showInstallController()
{
        [c->install displayInstaller];
}
