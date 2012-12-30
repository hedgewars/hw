foreach(dir "Fonts" "Forts" "Graphics" "Locale" "Maps" "Music" "Shaders" "Sounds" "Themes" "Missions" "Names" "misc" "Scripts")
  add_subdirectory(${dir})
endforeach(dir)
