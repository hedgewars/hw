foreach(dir "Fonts" "Forts" "Graphics" "Locale" "Maps" "Music" "Sounds" "Themes" "Trainings" "Names")
  add_subdirectory(${dir})
endforeach(dir)
