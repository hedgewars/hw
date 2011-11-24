
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
	argv[i] = (char*)malloc(sizeof(char) * env->GetStringLength(jstringArgv[i]));
	strcpy(argv[i], env->GetStringUTFChars(jstringArgv[i], JNI_FALSE)); //copy it to a mutable location
	//Don't release memory the JAVA GC will take care of it
        //env->ReleaseStringChars(jstringArgv[i], (jchar*)argv[i]);           
    }
    
    /* Run the application code! */
    int status;
    status = SDL_main(argc, argv);

    //Clean up argv
    for(int i = 0; i < argc; i++){
    }

    /* We exit here for consistency with other platforms. */
    //exit(status); Xeli: Or lets not crash the entire app.....
}

/* vi: set ts=4 sw=4 expandtab: */
