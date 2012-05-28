(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2012 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uMatrix;

interface

uses uTypes, gl;

procedure MatrixLoadIdentity(out Result: TMatrix4x4f);
procedure MatrixMultiply(out Result: TMatrix4x4f; const lhs, rhs: TMatrix4x4f);

implementation

procedure MatrixLoadIdentity(out Result: TMatrix4x4f);
begin
    Result[0,0]:= 1.0; Result[1,0]:=0.0; Result[2,0]:=0.0; Result[3,0]:=0.0;
    Result[0,1]:= 0.0; Result[1,1]:=1.0; Result[2,1]:=0.0; Result[3,1]:=0.0;
    Result[0,2]:= 0.0; Result[1,2]:=0.0; Result[2,2]:=1.0; Result[3,2]:=0.0;
    Result[0,3]:= 0.0; Result[1,3]:=0.0; Result[2,3]:=0.0; Result[3,3]:=1.0;
end;

procedure MatrixMultiply(out Result: TMatrix4x4f; const lhs, rhs: TMatrix4x4f);
var
    test: TMatrix4x4f;
    i, j: Integer;
    error: boolean;
begin
    Result[0,0]:=lhs[0,0]*rhs[0,0] + lhs[1,0]*rhs[0,1] + lhs[2,0]*rhs[0,2] + lhs[3,0]*rhs[0,3];
    Result[0,1]:=lhs[0,1]*rhs[0,0] + lhs[1,1]*rhs[0,1] + lhs[2,1]*rhs[0,2] + lhs[3,1]*rhs[0,3];
    Result[0,2]:=lhs[0,2]*rhs[0,0] + lhs[1,2]*rhs[0,1] + lhs[2,2]*rhs[0,2] + lhs[3,2]*rhs[0,3];
    Result[0,3]:=lhs[0,3]*rhs[0,0] + lhs[1,3]*rhs[0,1] + lhs[2,3]*rhs[0,2] + lhs[3,3]*rhs[0,3];

    Result[1,0]:=lhs[0,0]*rhs[1,0] + lhs[1,0]*rhs[1,1] + lhs[2,0]*rhs[1,2] + lhs[3,0]*rhs[1,3];
    Result[1,1]:=lhs[0,1]*rhs[1,0] + lhs[1,1]*rhs[1,1] + lhs[2,1]*rhs[1,2] + lhs[3,1]*rhs[1,3];
    Result[1,2]:=lhs[0,2]*rhs[1,0] + lhs[1,2]*rhs[1,1] + lhs[2,2]*rhs[1,2] + lhs[3,2]*rhs[1,3];
    Result[1,3]:=lhs[0,3]*rhs[1,0] + lhs[1,3]*rhs[1,1] + lhs[2,3]*rhs[1,2] + lhs[3,3]*rhs[1,3];

    Result[2,0]:=lhs[0,0]*rhs[2,0] + lhs[1,0]*rhs[2,1] + lhs[2,0]*rhs[2,2] + lhs[3,0]*rhs[2,3];
    Result[2,1]:=lhs[0,1]*rhs[2,0] + lhs[1,1]*rhs[2,1] + lhs[2,1]*rhs[2,2] + lhs[3,1]*rhs[2,3];
    Result[2,2]:=lhs[0,2]*rhs[2,0] + lhs[1,2]*rhs[2,1] + lhs[2,2]*rhs[2,2] + lhs[3,2]*rhs[2,3];
    Result[2,3]:=lhs[0,3]*rhs[2,0] + lhs[1,3]*rhs[2,1] + lhs[2,3]*rhs[2,2] + lhs[3,3]*rhs[2,3];

    Result[3,0]:=lhs[0,0]*rhs[3,0] + lhs[1,0]*rhs[3,1] + lhs[2,0]*rhs[3,2] + lhs[3,0]*rhs[3,3];
    Result[3,1]:=lhs[0,1]*rhs[3,0] + lhs[1,1]*rhs[3,1] + lhs[2,1]*rhs[3,2] + lhs[3,1]*rhs[3,3];
    Result[3,2]:=lhs[0,2]*rhs[3,0] + lhs[1,2]*rhs[3,1] + lhs[2,2]*rhs[3,2] + lhs[3,2]*rhs[3,3];
    Result[3,3]:=lhs[0,3]*rhs[3,0] + lhs[1,3]*rhs[3,1] + lhs[2,3]*rhs[3,2] + lhs[3,3]*rhs[3,3];

{
    Result[0,0]:=lhs[0,0]*rhs[0,0] + lhs[1,0]*rhs[0,1] + lhs[2,0]*rhs[0,2] + lhs[3,0]*rhs[0,3];
    Result[0,1]:=lhs[0,0]*rhs[1,0] + lhs[1,0]*rhs[1,1] + lhs[2,0]*rhs[1,2] + lhs[3,0]*rhs[1,3];
    Result[0,2]:=lhs[0,0]*rhs[2,0] + lhs[1,0]*rhs[2,1] + lhs[2,0]*rhs[2,2] + lhs[3,0]*rhs[2,3];
    Result[0,3]:=lhs[0,0]*rhs[3,0] + lhs[1,0]*rhs[3,1] + lhs[2,0]*rhs[3,2] + lhs[3,0]*rhs[3,3];
  
    Result[1,0]:=lhs[0,1]*rhs[0,0] + lhs[1,1]*rhs[0,1] + lhs[2,1]*rhs[0,2] + lhs[3,1]*rhs[0,3];
    Result[1,1]:=lhs[0,1]*rhs[1,0] + lhs[1,1]*rhs[1,1] + lhs[2,1]*rhs[1,2] + lhs[3,1]*rhs[1,3];
    Result[1,2]:=lhs[0,1]*rhs[2,0] + lhs[1,1]*rhs[2,1] + lhs[2,1]*rhs[2,2] + lhs[3,1]*rhs[2,3];
    Result[1,3]:=lhs[0,1]*rhs[3,0] + lhs[1,1]*rhs[3,1] + lhs[2,1]*rhs[3,2] + lhs[3,1]*rhs[3,3];

    Result[2,0]:=lhs[0,2]*rhs[0,0] + lhs[1,2]*rhs[0,1] + lhs[2,2]*rhs[0,2] + lhs[3,2]*rhs[0,3];
    Result[2,1]:=lhs[0,2]*rhs[1,0] + lhs[1,2]*rhs[1,1] + lhs[2,2]*rhs[1,2] + lhs[3,2]*rhs[1,3];
    Result[2,2]:=lhs[0,2]*rhs[2,0] + lhs[1,2]*rhs[2,1] + lhs[2,2]*rhs[2,2] + lhs[3,2]*rhs[2,3];
    Result[2,3]:=lhs[0,2]*rhs[3,0] + lhs[1,2]*rhs[3,1] + lhs[2,2]*rhs[3,2] + lhs[3,2]*rhs[3,3];

    Result[3,0]:=lhs[0,3]*rhs[0,0] + lhs[1,3]*rhs[0,1] + lhs[2,3]*rhs[0,2] + lhs[3,3]*rhs[0,3];
    Result[3,1]:=lhs[0,3]*rhs[1,0] + lhs[1,3]*rhs[1,1] + lhs[2,3]*rhs[1,2] + lhs[3,3]*rhs[1,3];
    Result[3,2]:=lhs[0,3]*rhs[2,0] + lhs[1,3]*rhs[2,1] + lhs[2,3]*rhs[2,2] + lhs[3,3]*rhs[2,3];
    Result[3,3]:=lhs[0,3]*rhs[3,0] + lhs[1,3]*rhs[3,1] + lhs[2,3]*rhs[3,2] + lhs[3,3]*rhs[3,3];
}
    glPushMatrix;
    glLoadMatrixf(@lhs[0, 0]);
    glMultMatrixf(@rhs[0, 0]);
    glGetFloatv(GL_MODELVIEW_MATRIX, @test[0, 0]);
    glPopMatrix;

    error:=false;
    for i:=0 to 3 do
      for j:=0 to 3 do
        if Abs(test[i, j] - Result[i, j]) > 0.000001 then
          error:=true;

    if error then
    begin
        writeln('shall:');
        for i:=0 to 3 do
        begin
          for j:=0 to 3 do
            write(test[i, j]);
          writeln;
        end;

        writeln('is:');
        for i:=0 to 3 do
        begin
          for j:=0 to 3 do
            write(Result[i, j]);
          writeln;
        end;
        halt(0);
    end;


end;


end.
