foreach(dir "Fonts" "Forts" "Graphics" "Locale" "Maps" "Music" "Sounds" "Themes" "Missions" "Names")
  add_subdirectory(${dir})
endforeach(dir)
