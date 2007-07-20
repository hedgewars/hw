file(GLOB BaseMusic *.ogg) 

list(LENGTH BaseMusic PlayListLength)

set(PlayListINCFile ${hedgewars_SOURCE_DIR}/hedgewars/playlist.inc)

file(WRITE ${PlayListINCFile} "const cPlayListLength = " ${PlayListLength} ";")
file(APPEND ${PlayListINCFile} "playlist = array[0..Pred(cPlayListLength)] of string = (")

set(i ${PlayListLength})
foreach(musicfile ${BaseMusic})
	math(EXPR i "${i} - 1")
	
	get_filename_component(relfilename ${musicfile} NAME)
	
	file(APPEND ${PlayListINCFile} '${relfilename}')
	
	if(i GREATER 0)
		file(APPEND ${PlayListINCFile} ",")
	endif(i GREATER 0)
endforeach(musicfile)

file(APPEND ${PlayListINCFile} ");")

file(APPEND ${PlayListINCFile} "var playlistchain = array[0..Pred(cPlayListLength)] of LongWord;")


install(FILES
	${BaseMusic}
	DESTINATION ${SHAREPATH}Data/Music)
