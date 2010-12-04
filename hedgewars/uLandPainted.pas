(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2010 Andrey Korotaev <unC0Rr@gmail.com>
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

{$INCLUDE "options.inc"}

unit uLandPainted;

interface

procedure LoadFromFile(fileName: shortstring);

implementation

type PointRec = packed record
    x, y: ShortInt;
    flags: byte;
    end;

procedure LoadFromFile(fileName: shortstring);
var
    f: file of PointRec;
    rec: PointRec;
begin
    fileMode = foReadOnly;

    assignFile(f, fileName);
    reset(f);

    while not eof(f) do
        begin
        read(f, rec);
        end;

    closeFile(f);
end;

end.
