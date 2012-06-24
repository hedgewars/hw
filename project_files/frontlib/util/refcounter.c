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
