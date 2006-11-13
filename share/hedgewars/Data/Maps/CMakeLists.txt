foreach(dir "cheese" "mushrooms")
  add_subdirectory(${dir})
endforeach(dir)