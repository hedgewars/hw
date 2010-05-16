//  fptest
//
//  Created by Vittorio on 08/01/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.

Library hwLibrary;

// Add all your Pascal units to the "uses" clause below to add them to the program.

// Mark all Pascal procedures/functions that you wish to call from C/C++/Objective-C code using
// "cdecl; export;" (see the fpclogo.pas unit for an example), and then add C-declarations for
// these procedures/functions to the PascalImports.h file (also in the "Pascal Sources" group)
// to make these functions available in the C/C++/Objective-C source files
// (add "#include PascalImports.h" near the top of these files if it's not there yet)
uses cmem, hwengine, PascalExports;

end.

