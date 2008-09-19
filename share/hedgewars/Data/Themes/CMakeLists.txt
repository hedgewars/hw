foreach(dir
	"Bamboo"
	"Bath"
	"City"
	"EarthRise"
	"Freeway"
	"hell"
	"Island"
	"nature"
	"Planes"
	"Sheep"
	"Snow"
	"cheese"
	"Underwater")
	add_subdirectory(${dir})
endforeach(dir)

install(FILES themes.cfg DESTINATION ${SHAREPATH}Data/Themes)
