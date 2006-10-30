if(WIN32 AND NOT UNIX)
	install(FILES
		libpng13.dll
		SDL.dll
		SDL_image.dll
		SDL_mixer.dll
		SDL_net.dll
		SDL_ttf.dll
		zlib1.dll
		DESTINATION bin)
endif(WIN32 AND NOT UNIX)
