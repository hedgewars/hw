foreach(dir "cheese" "mushrooms" "Volcano")
  add_subdirectory(${dir})
endforeach(dir)