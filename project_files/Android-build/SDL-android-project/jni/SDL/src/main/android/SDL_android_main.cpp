
/* Include the SDL main definition header */
#include "SDL_main.h"

/*******************************************************************************
                 Functions called by JNI
*******************************************************************************/
#include <jni.h>

// Called before SDL_main() to initialize JNI bindings in SDL library
extern "C" void SDL_Android_Init(JNIEnv* env, jclass cls);

// Library init
extern "C" jint JNI_OnLoad(JavaVM* vm, void* reserved)
{
    return JNI_VERSION_1_4;
}

// Start up the SDL app
extern "C" void Java_org_hedgewars_hedgeroid_SDLActivity_nativeInit(JNIEnv* env, jclass cls, jobjectArray strArray)
{
    /* This interface could expand with ABI negotiation, calbacks, etc. */
    SDL_Android_Init(env, cls);

    //Get the String array from java
    int argc = env->GetArrayLength(strArray);
    char *argv[argc];
    jstring jstringArgv[argc];
    for(int i = 0; i < argc; i++){
        jstringArgv[i] = (jstring)env->GetObjectArrayElement(strArray, i);  //get the element
        argv[i] = (char*)malloc(env->GetStringUTFLength(jstringArgv[i]) + 1);
        const char *str = env->GetStringUTFChars(jstringArgv[i], NULL);
        strcpy(argv[i], str); //copy it to a mutable location
        env->ReleaseStringUTFChars(jstringArgv[i], str);
    }

    /* Run the application code! */
    int status = SDL_main(argc, argv);

    //Clean up argv
    for(int i = 0; i < argc; i++){
        free(argv[i]);
    }
}

/* vi: set ts=4 sw=4 expandtab: */
