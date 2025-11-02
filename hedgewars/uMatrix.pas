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
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *)

{$INCLUDE "options.inc"}

unit uMatrix;

interface

uses uTypes {$IFNDEF PAS2C}, gl{$ENDIF};

const
    MATRIX_MODELVIEW:Integer = 0;
    MATRIX_PROJECTION:Integer = 1;

procedure MatrixLoadIdentity(out Result: TMatrix4x4f);
procedure MatrixMultiply(out Result: TMatrix4x4f; const lhs, rhs: TMatrix4x4f);

procedure hglMatrixMode(t: Integer);
procedure hglLoadIdentity();
procedure hglPushMatrix();
procedure hglPopMatrix();
procedure hglMVP(var res : TMatrix4x4f);
procedure hglScalef(x: GLfloat; y: GLfloat; z: GLfloat);
procedure hglTranslatef(x: GLfloat; y: GLfloat; z: GLfloat);
procedure hglRotatef(a:GLfloat; x:GLfloat; y:GLfloat; z:GLfloat);
procedure initModule();
procedure freeModule();

implementation

uses uDebug;

const
    MATRIX_STACK_SIZE = 10;

type
    TMatrixStack = record
        top:Integer;
        stack: array[0..9] of TMatrix4x4f;
        end;
var
    MatrixStacks : array[0..1] of TMatrixStack;
    CurMatrix: integer;

procedure MatrixLoadIdentity(out Result: TMatrix4x4f);
begin
    Result[0,0]:= 1.0; Result[1,0]:=0.0; Result[2,0]:=0.0; Result[3,0]:=0.0;
    Result[0,1]:= 0.0; Result[1,1]:=1.0; Result[2,1]:=0.0; Result[3,1]:=0.0;
    Result[0,2]:= 0.0; Result[1,2]:=0.0; Result[2,2]:=1.0; Result[3,2]:=0.0;
    Result[0,3]:= 0.0; Result[1,3]:=0.0; Result[2,3]:=0.0; Result[3,3]:=1.0;
end;

procedure hglMatrixMode(t: Integer);
begin
    CurMatrix := t;
end;

procedure hglLoadIdentity();
begin
    MatrixLoadIdentity(MatrixStacks[CurMatrix].stack[MatrixStacks[CurMatrix].top]);
end;

procedure hglScalef(x: GLfloat; y: GLfloat; z: GLfloat);
var
    m:TMatrix4x4f;
    t:TMatrix4x4f;
begin
    m[0,0]:=x;m[1,0]:=0;m[2,0]:=0;m[3,0]:=0;
    m[0,1]:=0;m[1,1]:=y;m[2,1]:=0;m[3,1]:=0;
    m[0,2]:=0;m[1,2]:=0;m[2,2]:=z;m[3,2]:=0;
    m[0,3]:=0;m[1,3]:=0;m[2,3]:=0;m[3,3]:=1;

    MatrixMultiply(t, MatrixStacks[CurMatrix].stack[MatrixStacks[CurMatrix].top], m);
    MatrixStacks[CurMatrix].stack[MatrixStacks[CurMatrix].top] := t;
end;

procedure hglTranslatef(x: GLfloat; y: GLfloat; z: GLfloat);
var
    m:TMatrix4x4f;
    t:TMatrix4x4f;
begin
    m[0,0]:=1;m[1,0]:=0;m[2,0]:=0;m[3,0]:=x;
    m[0,1]:=0;m[1,1]:=1;m[2,1]:=0;m[3,1]:=y;
    m[0,2]:=0;m[1,2]:=0;m[2,2]:=1;m[3,2]:=z;
    m[0,3]:=0;m[1,3]:=0;m[2,3]:=0;m[3,3]:=1;

    MatrixMultiply(t, MatrixStacks[CurMatrix].stack[MatrixStacks[CurMatrix].top], m);
    MatrixStacks[CurMatrix].stack[MatrixStacks[CurMatrix].top] := t;
end;

procedure hglRotatef(a:GLfloat; x:GLfloat; y:GLfloat; z:GLfloat);
var
    m:TMatrix4x4f;
    t:TMatrix4x4f;
    c:GLfloat;
    s:GLfloat;
    xn, yn, zn:GLfloat;
    l:GLfloat;
begin
    a:=a * 3.14159265368 / 180;
    c:=cos(a);
    s:=sin(a);

    l := 1.0 / sqrt(x * x + y * y + z * z);
    xn := x * l;
    yn := y * l;
    zn := z * l;

    m[0,0]:=c + xn * xn * (1 - c);
    m[1,0]:=xn * yn * (1 - c) - zn * s;
    m[2,0]:=xn * zn * (1 - c) + yn * s;
    m[3,0]:=0;


    m[0,1]:=yn * xn * (1 - c) + zn * s;
    m[1,1]:=c + yn * yn * (1 - c);
    m[2,1]:=yn * zn * (1 - c) - xn * s;
    m[3,1]:=0;

    m[0,2]:=zn * xn * (1 - c) - yn * s;
    m[1,2]:=zn * yn * (1 - c) + xn * s;
    m[2,2]:=c + zn * zn * (1 - c);
    m[3,2]:=0;

    m[0,3]:=0;m[1,3]:=0;m[2,3]:=0;m[3,3]:=1;

    MatrixMultiply(t, MatrixStacks[CurMatrix].stack[MatrixStacks[CurMatrix].top], m);
    MatrixStacks[CurMatrix].stack[MatrixStacks[CurMatrix].top] := t;
end;

procedure hglMVP(var res: TMatrix4x4f);
begin
    MatrixMultiply(res,
                   MatrixStacks[MATRIX_PROJECTION].stack[MatrixStacks[MATRIX_PROJECTION].top],
                   MatrixStacks[MATRIX_MODELVIEW].stack[MatrixStacks[MATRIX_MODELVIEW].top]);
end;

procedure hglPushMatrix();
var
    t: Integer;
begin
    t := MatrixStacks[CurMatrix].top;
    MatrixStacks[CurMatrix].stack[t + 1] := MatrixStacks[CurMatrix].stack[t];
    inc(t);
    MatrixStacks[CurMatrix].top := t;
end;

procedure hglPopMatrix();
var
    t: Integer;
begin
    t := MatrixStacks[CurMatrix].top;
    dec(t);
    MatrixStacks[CurMatrix].top := t;
end;

procedure initModule();
begin
    MatrixStacks[MATRIX_MODELVIEW].top := 0;
    MatrixStacks[MATRIX_Projection].top := 0;
    MatrixLoadIdentity(MatrixStacks[MATRIX_MODELVIEW].stack[0]);
    MatrixLoadIdentity(MatrixStacks[MATRIX_PROJECTION].stack[0]);
end;

procedure freeModule();
begin
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

    {$IFNDEF PAS2C}
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
        checkFails(false, 'Error in matrix multiplication?!', true);
    end;
    {$ENDIF}

end;


end.
