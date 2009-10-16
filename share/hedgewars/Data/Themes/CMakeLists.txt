foreach(dir
	Bamboo
	Bath
	Blox
	Cake
	Castle
	cheese
	City
	CrazyMission
	EarthRise
	Eyes
	Freeway
	Halloween
	hell
	Island
	nature
	Planes
	Sheep
	Snow
	Underwater
    Compost
	)
	add_subdirectory(${dir})
endforeach(dir)

install(FILES themes.cfg DESTINATION ${SHAREPATH}Data/Themes)
