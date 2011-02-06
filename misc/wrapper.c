/*
 This is an experimental main to use with hwLibary
 - create the library with `cmake . -DBUILD_ENGINE_LIBRARY=1' and `make hwengine'
 - compile this file with `gcc libhwLibrary.dylib libSDLmain.a wrapper.c -o wrapper -framework Cocoa -framework SDL'
   (in Mac OS X, but this command line shouldn't be much different in other OSes; make sure to set the correct files/paths)
 - this executable expect a save file "Save.hws" and the data folder "Data" to be in the same launching directory
 */

#import <stdlib.h>

extern void Game (const char **);

int SDL_main (int argc, const char **argv)
{
    // Note: if you get a segfault or other unexpected crashes on startup
    // make sure that these arguments are up-to-date with the ones actual needed

    const char **gameArgs = (const char**) malloc(sizeof(char *) * 11);

    gameArgs[ 0] = "0";          //ipcPort
    gameArgs[ 1] = "1024";       //cScreenWidth
    gameArgs[ 2] = "768";        //cScreenHeight
    gameArgs[ 3] = "0";          //cReducedQuality
    gameArgs[ 4] = "en.txt";     //cLocaleFName
    gameArgs[ 5] = "wrapper";    //UserNick
    gameArgs[ 6] = "1";          //isSoundEnabled
    gameArgs[ 7] = "1";          //isMusicEnabled
    gameArgs[ 8] = "1";          //cAltDamage
    gameArgs[ 9] = "0.0";        //rotationQt
    gameArgs[10] = "Save.hws";   //recordFileName

    Game(gameArgs);
    free(gameArgs);

    return 0;
}
