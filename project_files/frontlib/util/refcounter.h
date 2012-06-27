/*
 * Hedgewars, a free turn based strategy game
 * Copyright (C) 2012 Simeon Maxein <smaxein@googlemail.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

/**
 * Helper functions for reference counted structs.
 *
 * We don't have enough of them to justify going crazy with macros, but I still prefer
 * to have the logic in one place.
 *
 * In particular, these functions handle counter overflow in a sensible way
 * (log and leak).
 */

#ifndef REFCOUNTER_H_
#define REFCOUNTER_H_

#include <stdbool.h>

/**
 * Pass a pointer to the counter variable to be incremented, and the name of the
 * object for logging purposes. On overflow an error will be logged and the
 * counter will get "stuck" so neither retain nor release will modify it anymore.
 */
void flib_retain(int *referenceCountPtr, const char *objName);

/**
 * Pass a pointer to the counter variable to be decremented and the name
 * of the object for logging purposes.
 * Returns true if the object should be freed.
 */
bool flib_release(int *referenceCountPtr, const char *objName);

#endif /* REFCOUNTER_H_ */
