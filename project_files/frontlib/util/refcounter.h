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

#include "logging.h"
#include <stdbool.h>

static inline void flib_retain(int *referenceCountPtr, const char *objName) {
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
static inline bool flib_release(int *referenceCountPtr, const char *objName) {
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

#endif /* REFCOUNTER_H_ */
