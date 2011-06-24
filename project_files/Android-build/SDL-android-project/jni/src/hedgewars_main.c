
#include "android/log.h"
#include "SDL.h"
#include "dlfcn.h"
#include "GLES/gl.h"

#define TAG "HWEngine Loader"

typedef  (*HWEngine_Game)(char**);

main(int argc, char *argv[]){
	void *handle;
	char *error;
	HWEngine_Game Game;
	

        __android_log_print(ANDROID_LOG_INFO, TAG, "HWEngine being loaded");
	handle = dlopen("/data/data/org.hedgewars/lib/libhwengine.so", RTLD_NOW|RTLD_GLOBAL);
	if(!handle){
		__android_log_print(ANDROID_LOG_INFO, "foo", dlerror());
		__android_log_print(ANDROID_LOG_INFO, "foo", "error dlopen");
		exit(EXIT_FAILURE);
	}
	dlerror();

        __android_log_print(ANDROID_LOG_INFO, TAG, "HWEngine successfully loaded..");


	Game = (HWEngine_Game) dlsym(handle,"Game");
	if((error = dlerror()) != NULL){
		__android_log_print(ANDROID_LOG_INFO, "foo", error);
		__android_log_print(ANDROID_LOG_INFO, "foo", "error dlsym");
		exit(EXIT_FAILURE);
	}
	__android_log_print(ANDROID_LOG_INFO, "foo", "dlsym succeeded");
	Game(argv);
	__android_log_print(ANDROID_LOG_INFO, "foo", "Game() succeeded");

	dlclose(handle);
}
