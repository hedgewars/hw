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
