foreach(dir "Fonts" "Forts" "Graphics" "Locale" "Maps" "Music" "Sounds" "Themes" "Missions" "Names" "misc" "Scripts")
    add_subdirectory(${dir})
endforeach(dir)

if(${GL2})
    add_subdirectory(Shaders)
endif(${GL2})
