#include "list.h"

#include <string.h>
#include "util.h"
#include "logging.h"

void *flib_list_insert(void *list, int *listSizePtr, size_t elementSize, void *elementPtr, int pos) {
	void *result = NULL;
	if(!listSizePtr || !elementPtr || pos < 0 || pos > *listSizePtr) {
		flib_log_e("Invalid parameter in flib_list_insert");
	} else {
		unsigned char *newList = flib_realloc(list, ((*listSizePtr)+1)*elementSize);
		if(newList) {
			memmove(newList + (pos+1)*elementSize, newList + pos*elementSize, ((*listSizePtr)-pos)*elementSize);
			memmove(newList + pos*elementSize, elementPtr, elementSize);
			(*listSizePtr)++;
			result = newList;
		}
	}
	return result;
}

void *flib_list_delete(void *list, int *listSizePtr, size_t elementSize, int pos) {
	void *result = NULL;
	if(!listSizePtr || pos < 0 || pos >= *listSizePtr) {
		flib_log_e("Invalid parameter in flib_list_delete");
	} else {
		unsigned char *charList = list;
		memmove(charList + (pos*elementSize), charList + (pos+1)*elementSize, (*listSizePtr-(pos+1))*elementSize);
		(*listSizePtr)--;

		// If the realloc fails, just keep using the old buffer...
		size_t newCharSize = (*listSizePtr)*elementSize;
		void *newList = flib_realloc(list, newCharSize);
		if(newList || newCharSize==0) {
			result = newList;
		} else {
			result = list;
		}
	}
	return result;
}
