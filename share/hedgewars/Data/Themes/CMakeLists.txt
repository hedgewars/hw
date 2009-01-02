foreach(dir
	Bamboo
	Bath
	Blox
	Cake
	City
	CrazyMission
	EarthRise
	Eyes
	Freeway
	hell
	Island
	nature
	Planes
	Sheep
	Snow
	cheese
	Underwater
	)
	add_subdirectory(${dir})
endforeach(dir)

install(FILES themes.cfg DESTINATION ${SHAREPATH}Data/Themes)
