foreach(dir "Fonts" "Forts" "Graphics" "Locale" "Maps" "Sounds" "Themes")
  add_subdirectory(${dir})
endforeach(dir)