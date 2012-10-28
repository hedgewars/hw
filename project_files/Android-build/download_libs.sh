#!/bin/sh
download_and_zip (){
    echo "Downloading: $1"
    curl -silent -o tmp.zip $1 #grab the zips from an url
    unzip -qq tmp.zip  -d SDL-android-project/jni/tmp #unzip it to a tmp file
    rm -fr SDL-android-project/jni/$2 #remove any old dirs, we will get those files back with hg revert in CMakeList
    mv SDL-android-project/jni/tmp/* SDL-android-project/jni/$2 #move the tmp dir to the jni directory
    rm tmp.zip #remove old tmp dir
}
download_and_zip http://www.xelification.com/tmp/jpeg.zip jpeg
download_and_zip http://www.xelification.com/tmp/png.zip png
download_and_zip http://www.libsdl.org/projects/SDL_image/release/SDL_image-1.2.12.zip SDL_image
download_and_zip http://www.libsdl.org/projects/SDL_mixer/release/SDL_mixer-1.2.12.zip SDL_mixer
download_and_zip http://www.xelification.com/tmp/mikmod.zip mikmod #temporary url since the libsdl.org site doesn't work at the moment
download_and_zip http://www.xelification.com/tmp/SDL_net.zip SDL_net
download_and_zip http://www.libsdl.org/projects/SDL_ttf/release/SDL_ttf-2.0.11.zip SDL_ttf
download_and_zip http://www.libsdl.org/tmp/SDL-1.3.zip SDL

