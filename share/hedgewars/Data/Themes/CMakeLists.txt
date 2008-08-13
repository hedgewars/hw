foreach(dir "Bamboo" "Bath" "City" "EarthRise" "hell" "Island" "nature" "Planes" "Sheep" "Snow" "cheese")
  add_subdirectory(${dir})
endforeach(dir)

install(FILES themes.cfg DESTINATION ${SHAREPATH}Data/Themes)
