foreach(dir avematan bubbles ethereal norsk steel tibet wood xtheme)
  add_subdirectory(${dir})
endforeach(dir)

install(FILES themes.cfg DESTINATION Data/Themes)
