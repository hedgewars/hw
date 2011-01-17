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
begin
end;

end.
