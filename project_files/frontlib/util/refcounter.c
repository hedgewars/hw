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

#include "refcounter.h"

#include "logging.h"

void flib_retain(int *referenceCountPtr, const char *objName) {
	if(!referenceCountPtr || !objName) {
		flib_log_e("null parameter to flib_retain");
	} else {
		if((*referenceCountPtr)  >= 0) {
			(*referenceCountPtr)++;
			flib_log_d("retaining %s, now %i references", objName, (*referenceCountPtr));
		}
		if((*referenceCountPtr) < 0) {
			flib_log_e("Memory leak: Reference count overflow in %s object!", objName);
		}
	}
}

/**
 * Returns true if the struct should be freed.
 */
bool flib_release(int *referenceCountPtr, const char *objName) {
	bool result = false;
	if(!referenceCountPtr) {
		flib_log_e("null parameter to flib_release");
	} else if((*referenceCountPtr) > 0) {
		if(--(*referenceCountPtr) == 0) {
			flib_log_d("releasing and destroying %s", objName);
			result = true;
		} else {
			flib_log_d("releasing %s, now %i references", objName, (*referenceCountPtr));
		}
	} else if((*referenceCountPtr) == 0) {
		flib_log_e("Attempt to release a %s with zero references!", objName);
	}
	return result;
}
