foreach(dir "Fonts" "Forts" "Graphics" "Locale" "Maps" "Music" "Sounds" "Themes")
  add_subdirectory(${dir})
endforeach(dir)