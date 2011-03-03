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

unit uCaptions;

interface
uses uTypes;

procedure AddCaption(s: shortstring; Color: Longword; Group: TCapGroup);
procedure DrawCaptions;

procedure initModule;
procedure freeModule;

implementation
uses uTextures, uRenderUtils, uVariables, uRender;

type TCaptionStr = record
                   Tex: PTexture;
                   EndTime: LongWord;
                   end;
var
    Captions: array[TCapGroup] of TCaptionStr;

procedure AddCaption(s: shortstring; Color: Longword; Group: TCapGroup);
begin
    if Captions[Group].Tex <> nil then
        FreeTexture(Captions[Group].Tex);
    Captions[Group].Tex:= nil;

    Captions[Group].Tex:= RenderStringTex(s, Color, fntBig);

    case Group of
        capgrpGameState: Captions[Group].EndTime:= RealTicks + 2200
    else
        Captions[Group].EndTime:= RealTicks + 1400 + LongWord(Captions[Group].Tex^.w) * 3;
    end;
end;

procedure DrawCaptions;
var
    grp: TCapGroup;
    offset: LongInt;
begin
{$IFDEF IPHONEOS}
    offset:= 40;
{$ELSE}
    offset:= 8;
{$ENDIF}

    for grp:= Low(TCapGroup) to High(TCapGroup) do
        with Captions[grp] do
            if Tex <> nil then
            begin
                DrawCentered(0, offset, Tex);
                inc(offset, Tex^.h + 2);
                if EndTime <= RealTicks then
                begin
                    FreeTexture(Tex);
                    Tex:= nil;
                    EndTime:= 0
                end;
            end;
end;

procedure initModule;
begin
    FillChar(Captions, sizeof(Captions), 0)
end;

procedure freeModule;
var
    group: TCapGroup;
begin
    for group:= Low(TCapGroup) to High(TCapGroup) do
    begin
        FreeTexture(Captions[group].Tex);
    end;
end;

end.
