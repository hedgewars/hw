/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2015 Andrey Korotaev <unC0Rr@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
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
    m = new M3Panel::Private();

    m->install = [[M3InstallController alloc] init];
    [m->install retain];
}

M3Panel::~M3Panel()
{
    [m->install release];
    delete m;
}

void M3Panel::showInstallController()
{
    [m->install displayInstaller];
}
