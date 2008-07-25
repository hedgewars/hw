foreach(dir "Bamboo" "Bath" "City" "EarthRise" "Island" "nature" "Planes" "Snow" "Volcano" "cheese")
  add_subdirectory(${dir})
endforeach(dir)

install(FILES themes.cfg DESTINATION ${SHAREPATH}Data/Themes)
