/*
 This is an experimental main to use with hwLibary
 - create the library with `cmake . -DBUILD_ENGINE_LIBRARY=1' and `make hwengine'
 - compile this file with `gcc libhwLibrary.dylib libSDLmain.a wrapper.c -o wrapper -framework Cocoa -framework SDL'
   (in Mac OS X, but this command line shouldn't be much different in other OSes; make sure to set the correct files/paths)
 - this executable expect a save file "Save.hws" and the data folder "Data" to be in the same launching directory
 */

#import <stdio.h>
#import <stdlib.h>

extern void Game (const char **);

int SDL_main (int argc, const char **argv) {
    
    const char **gameArgs = (const char**) malloc(sizeof(char *) * 9);
    
    gameArgs[0] = "wrapper";    //UserNick
	gameArgs[1] = "0";          //ipcPort
	gameArgs[2] = "0";          //isSoundEnabled
	gameArgs[3] = "0";          //isMusicEnabled
	gameArgs[4] = "en.txt";     //cLocaleFName
	gameArgs[5] = "0";          //cAltDamage
	gameArgs[6] = "768";        //cScreenHeight
    gameArgs[7] = "1024";       //cScreenHeight
    gameArgs[8] = "Save.hws";   //recordFileName
    
    Game(gameArgs);
    free(gameArgs);
    
    return 0;
}
