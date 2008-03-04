foreach(dir "avematan" "bubbles" "cheese" "nature" "norsk" "steel" "tibet" "Volcano" "wood" "xtheme")
  add_subdirectory(${dir})
endforeach(dir)

install(FILES themes.cfg DESTINATION ${SHAREPATH}Data/Themes)
