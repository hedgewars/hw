foreach(dir
    Fonts
    Forts
    Graphics
    Locale
    Maps
    Missions
    Music
    Names
    Scripts
    Sounds
    Themes
    Tiles
    misc
    )
    add_subdirectory(${dir})
endforeach(dir)

if(${GL2})
    add_subdirectory(Shaders)
endif(${GL2})

install(FILES
    map_templates.yaml
    maze_templates.yaml
    wfc_templates.toml
    DESTINATION ${SHAREPATH}Data)
