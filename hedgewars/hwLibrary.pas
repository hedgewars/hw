(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2011 Andrey Korotaev <unC0Rr@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
 *)

Library hwLibrary;

// Add all your Pascal units to the "uses" clause below to add them to the program.
// Mark all Pascal procedures/functions that you wish to call from C/C++/Objective-C code using
// "cdecl; export;" (see the fpclogo.pas unit for an example), and then add C-declarations for
// these procedures/functions to the PascalImports.h file (also in the "Pascal Sources" group)
// to make these functions available in the C/C++/Objective-C source files
// (add "#include PascalImports.h" near the top of these files if it's not there yet)
uses PascalExports, hwengine;
exports Game;
begin

end.

