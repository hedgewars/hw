/*
 * Public header file for the hedgewars frontent networking library.
 *
 * This is the only header you should need to include from frontend code.
 */

#ifndef FRONTLIB_H_
#define FRONTLIB_H_

#define FRONTLIB_SDL_ALREADY_INITIALIZED 1

/**
 * Call this function before anything else in this library.
 *
 * If the calling program uses SDL, it needs to call SDL_Init before initializing
 * this library and then pass FRONTLIB_SDL_ALREADY_INITIALIZED as flag to this function.
 *
 * Otherwise, pass 0 to let this library handle SDL_Init an SDL_Quit itself.
 *
 * Returns 0 on success, -1 on error.
 */
int flib_init(int flags);

/**
 * Free resources associated with the library. Call this function once
 * the library is no longer needed. You can re-initialize the library by calling
 * flib_init again.
 */
void flib_quit();

#endif /* FRONTLIB_H_ */
