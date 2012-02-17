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

unit uCaptions;

interface
uses uTypes;

procedure AddCaption(s: shortstring; Color: Longword; Group: TCapGroup);
procedure DrawCaptions;
procedure ReloadCaptions(unload: boolean);

procedure initModule;
procedure freeModule;

implementation
uses uTextures, uRenderUtils, uVariables, uRender;

type TCaptionStr = record
    Tex: PTexture;
    EndTime: LongWord;
    Text: shortstring;
    Color: Longword
    end;
var
    Captions: array[TCapGroup] of TCaptionStr;

procedure AddCaption(s: shortstring; Color: Longword; Group: TCapGroup);
begin
    if Captions[Group].Text <> s then
        begin
        FreeTexture(Captions[Group].Tex);
        Captions[Group].Tex:= nil
        end;
    
    if Captions[Group].Tex = nil then
        begin
        Captions[Group].Color:= Color;
        Captions[Group].Text:= s;
        Captions[Group].Tex:= RenderStringTex(s, Color, fntBig)
        end;

    case Group of
        capgrpGameState: Captions[Group].EndTime:= RealTicks + 2200
    else
        Captions[Group].EndTime:= RealTicks + 1400 + LongWord(Captions[Group].Tex^.w) * 3;
    end;
end;

// For uStore texture recreation
procedure ReloadCaptions(unload: boolean);
var Group: TCapGroup;
begin
for Group:= Low(TCapGroup) to High(TCapGroup) do
    if unload then
        FreeTexture(Captions[Group].Tex)
    else if Captions[Group].Text <> '' then
        Captions[Group].Tex:= RenderStringTex(Captions[Group].Text, Captions[Group].Color, fntBig)
end;

procedure DrawCaptions;
var
    grp: TCapGroup;
    offset: LongInt;
begin
{$IFDEF USE_TOUCH_INTERFACE}
    offset:= 48;
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
                    Text:= '';
                    EndTime:= 0
                    end;
                end;
end;

procedure initModule;
begin
    FillChar(Captions, sizeof(Captions), 0)
end;

procedure freeModule;
var group: TCapGroup;
begin
    for group:= Low(TCapGroup) to High(TCapGroup) do
        begin
        FreeTexture(Captions[group].Tex);
        Captions[group].Tex:= nil
        end
end;

end.
