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

// see original example here https://el-tramo.be/blog/mixing-cocoa-and-qt

#include "CocoaInitializer.h"

#include <AppKit/AppKit.h>
#include <Cocoa/Cocoa.h>
#include <QtDebug>

class CocoaInitializer::Private
{
    public:
        NSAutoreleasePool* pool;
};

CocoaInitializer::CocoaInitializer()
{
    c = new CocoaInitializer::Private();
    c->pool = [[NSAutoreleasePool alloc] init];
    NSApplicationLoad();
}

CocoaInitializer::~CocoaInitializer()
{
    [c->pool release];
    delete c;
}
