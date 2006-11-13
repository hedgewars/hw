foreach(dir "avematan" "bubbles" "cheese" "ethereal" "norsk" "steel" "tibet" "wood" "xtheme")
  add_subdirectory(${dir})
endforeach(dir)

install(FILES themes.cfg DESTINATION ${SHAREPATH}Data/Themes)
