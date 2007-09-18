foreach(dir "Fonts" "Forts" "Graphics" "Locale" "Maps" "Music" "Sounds" "Themes" "Trainings")
  add_subdirectory(${dir})
endforeach(dir)