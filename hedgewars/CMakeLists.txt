add_subdirectory(Data)

set(dcc32_tryexe dcc32.exe)
set(ppc386_tryexe ppc386)
set(hwengine_project "hwengine.dpr")

find_program(dcc32_executable ${dcc32_tryexe})
find_program(ppc386_executable ${ppc386_tryexe})

if (dcc32_executable)
	 exec_program(${dcc32_executable} ARGS "--version" OUTPUT_VARIABLE dcc32_output)
endif (dcc32_executable)

if (ppc386_executable)
	 exec_program(${ppc386_executable} ARGS "-v" OUTPUT_VARIABLE ppc386_output)
endif (ppc386_executable)

string(REGEX MATCH "[0-9]+\\.[0-9]+" dcc32version "${dcc32_output}")
if (dcc32version)
	set(pascal_compiler ${dcc32_executable})
	set(pascal_compiler_flags "-B -W"${hwengine_project})
else (dcc32version)
	string(REGEX MATCH "[0-9]+\\.[0-9]+\\.[0-9]+" ppc386_version "${ppc386_output}")
	if (ppc386_version)
		string(REGEX REPLACE "([0-9]+)\\.[0-9]+\\.[0-9]+" "\\1" ppc386_vers_major "${ppc386_version}")
		string(REGEX REPLACE "[0-9]+\\.([0-9])+\\.[0-9]+" "\\1" ppc386_vers_minor "${ppc386_version}")
		string(REGEX REPLACE "[0-9]+\\.[0-9]+\\.([0-9]+)" "\\1" ppc386_vers_patch "${ppc386_version}")
		math(EXPR ppc386_ver "${ppc386_vers_major}*10000 + ${ppc386_vers_minor}*100 + ${ppc386_vers_patch}")
		if (ppc386_ver LESS "010902")
			message("Minimum required version of FreePascal is 1.9.2")
		else (ppc386_ver LESS "010902")
			set(pascal_compiler ${ppc386_executable})
			set(pascal_compiler_flags "-B -Sd -Xs -OG -O3 -Cs2000000"${hwengine_project})
		endif (ppc386_ver LESS "010902")
	endif (ppc386_version)
endif (dcc32version)

if (NOT pascal_compiler)
	message(FATAL_ERROR "No Pascal compiler found!")
endif (NOT pascal_compiler)

add_custom_command(COMMAND ${pascal_compiler} TARGET hwengine OUTPUTS hwengine ARGS ${pascal_compiler_flags})

install(PROGRAMS "hwengine${CMAKE_EXECUTABLE_SUFFIX}" DESTINATION bin)
