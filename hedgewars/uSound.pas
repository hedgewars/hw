(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2005, 2007, 2009 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uSound;
interface
uses SDLh, uConsts, uTypes;

var MusicFN: shortstring;

procedure initModule;
procedure freeModule;

procedure InitSound;
procedure ReleaseSound;
procedure SoundLoad;
procedure PlaySound(snd: TSound);
procedure PlaySound(snd: TSound; keepPlaying: boolean);
procedure PlaySound(snd: TSound; voicepack: PVoicepack);
procedure PlaySound(snd: TSound; voicepack: PVoicepack; keepPlaying: boolean);
function  LoopSound(snd: TSound): LongInt;
function  LoopSound(snd: TSound; voicepack: PVoicepack): LongInt;
procedure PlayMusic;
procedure PauseMusic;
procedure ResumeMusic;
procedure StopSound(snd: TSound);
procedure StopSound(chn: LongInt);
function  ChangeVolume(voldelta: LongInt): LongInt;
function  AskForVoicepack(name: shortstring): Pointer;


implementation
uses uVariables, uConsole, uUtils, uCommands, uDebug;

const chanTPU = 32;
var Volume: LongInt;
    lastChan: array [TSound] of LongInt;
    voicepacks: array[0..cMaxTeams] of TVoicepack;
    defVoicepack: PVoicepack;
    Mus: PMixMusic = nil;

function  AskForVoicepack(name: shortstring): Pointer;
var i: Longword;
begin
i:= 0;
    while (voicepacks[i].name <> name) and (voicepacks[i].name <> '') do
    begin
        inc(i);
        TryDo(i <= cMaxTeams, 'Engine bug: AskForVoicepack i > cMaxTeams', true)
    end;

    voicepacks[i].name:= name;
    AskForVoicepack:= @voicepacks[i]
end;

procedure InitSound;
var i: TSound;
    channels: LongInt;
begin
    if not isSoundEnabled then exit;
    WriteToConsole('Init sound...');
    isSoundEnabled:= SDL_InitSubSystem(SDL_INIT_AUDIO) >= 0;

{$IFDEF IPHONEOS}
    channels:= 1;
{$ELSE}
    channels:= 2;
{$ENDIF}

    if isSoundEnabled then
        isSoundEnabled:= Mix_OpenAudio(44100, $8010, channels, 1024) = 0;

{$IFDEF SDL_MIXER_NEWER}
    WriteToConsole('Init SDL_mixer... ');
    SDLTry(Mix_Init(MIX_INIT_OGG) <> 0, true);
    WriteLnToConsole(msgOK);
{$ENDIF}

    if isSoundEnabled then
        WriteLnToConsole(msgOK)
    else
        WriteLnToConsole(msgFailed);

    Mix_AllocateChannels(Succ(chanTPU));
    if isMusicEnabled then
        Mix_VolumeMusic(50);
    for i:= Low(TSound) to High(TSound) do
        lastChan[i]:= -1;

    Volume:= 0;
    ChangeVolume(cInitVolume)
end;

procedure ReleaseSound;
var i: TSound;
    t: Longword;
begin
    for t:= 0 to cMaxTeams do
        if voicepacks[t].name <> '' then
            for i:= Low(TSound) to High(TSound) do
                if voicepacks[t].chunks[i] <> nil then
                    Mix_FreeChunk(voicepacks[t].chunks[i]);

    if Mus <> nil then
        Mix_FreeMusic(Mus);

{$IFDEF SDL_MIXER_NEWER}
    // make sure all instances of sdl_mixer are unloaded before continuing
    while Mix_Init(0) <> 0 do
        Mix_Quit();
{$ENDIF}

    Mix_CloseAudio();
end;

procedure SoundLoad;
var i: TSound;
    t: Longword;
    s:shortstring;
begin
    if not isSoundEnabled then exit;

    defVoicepack:= AskForVoicepack('Default');

    for t:= 0 to cMaxTeams do
        if voicepacks[t].name <> '' then
            for i:= Low(TSound) to High(TSound) do
                voicepacks[t].chunks[i]:= nil;

    for i:= Low(TSound) to High(TSound) do
    begin
        defVoicepack^.chunks[i]:= nil;
        // preload all the big sound files (>32k) that would otherwise lockup the game
        if (i in [sndBeeWater, sndBee, sndCake, sndHellishImpact1, sndHellish, sndHomerun, sndMolotov, sndMortar, sndRideOfTheValkyries, sndYoohoo])
            and (Soundz[i].Path <> ptVoices) and (Soundz[i].FileName <> '') then
        begin
            s:= Pathz[Soundz[i].Path] + '/' + Soundz[i].FileName;
            WriteToConsole(msgLoading + s + ' ');
            defVoicepack^.chunks[i]:= Mix_LoadWAV_RW(SDL_RWFromFile(Str2PChar(s), 'rb'), 1);
            TryDo(defVoicepack^.chunks[i] <> nil, msgFailed, true);
            WriteLnToConsole(msgOK);
        end;
    end;

end;

procedure PlaySound(snd: TSound);
begin
    PlaySound(snd, nil, false);
end;

procedure PlaySound(snd: TSound; keepPlaying: boolean);
begin
    PlaySound(snd, nil, keepPlaying);
end;

procedure PlaySound(snd: TSound; voicepack: PVoicepack);
begin
    PlaySound(snd, voicepack, false);
end;

procedure PlaySound(snd: TSound; voicepack: PVoicepack; keepPlaying: boolean);
var s:shortstring;
begin
    if (not isSoundEnabled) or fastUntilLag then
        exit;

    if keepPlaying and (lastChan[snd] <> -1) and (Mix_Playing(lastChan[snd]) <> 0) then
        exit;

    if (voicepack <> nil) then
    begin
        if (voicepack^.chunks[snd] = nil) and (Soundz[snd].Path = ptVoices) and (Soundz[snd].FileName <> '') then
        begin
            s:= Pathz[Soundz[snd].Path] + '/' + voicepack^.name + '/' + Soundz[snd].FileName;
            WriteToConsole(msgLoading + s + ' ');
            voicepack^.chunks[snd]:= Mix_LoadWAV_RW(SDL_RWFromFile(Str2PChar(s), 'rb'), 1);
            if voicepack^.chunks[snd] = nil then
                WriteLnToConsole(msgFailed)
            else
                WriteLnToConsole(msgOK)
        end;
        lastChan[snd]:= Mix_PlayChannelTimed(-1, voicepack^.chunks[snd], 0, -1)
    end
    else
    begin
        if (defVoicepack^.chunks[snd] = nil) and (Soundz[snd].Path <> ptVoices) and (Soundz[snd].FileName <> '') then
        begin
            s:= Pathz[Soundz[snd].Path] + '/' + Soundz[snd].FileName;
            WriteToConsole(msgLoading + s + ' ');
            defVoicepack^.chunks[snd]:= Mix_LoadWAV_RW(SDL_RWFromFile(Str2PChar(s), 'rb'), 1);
            TryDo(defVoicepack^.chunks[snd] <> nil, msgFailed, true);
            WriteLnToConsole(msgOK);
        end;
        lastChan[snd]:= Mix_PlayChannelTimed(-1, defVoicepack^.chunks[snd], 0, -1)
    end;
end;

function LoopSound(snd: TSound): LongInt;
begin
    LoopSound:= LoopSound(snd, nil)
end;

function LoopSound(snd: TSound; voicepack: PVoicepack): LongInt;
var s: shortstring;
begin
    if (not isSoundEnabled) or fastUntilLag then
    begin
        LoopSound:= -1;
        exit
    end;

    if (voicepack <> nil) then
    begin
        if (voicepack^.chunks[snd] = nil) and (Soundz[snd].Path = ptVoices) and (Soundz[snd].FileName <> '') then
        begin
            s:= Pathz[Soundz[snd].Path] + '/' + voicepack^.name + '/' + Soundz[snd].FileName;
            WriteToConsole(msgLoading + s + ' ');
            voicepack^.chunks[snd]:= Mix_LoadWAV_RW(SDL_RWFromFile(Str2PChar(s), 'rb'), 1);
            if voicepack^.chunks[snd] = nil then
                WriteLnToConsole(msgFailed)
            else
                WriteLnToConsole(msgOK)
        end;
        LoopSound:= Mix_PlayChannelTimed(-1, voicepack^.chunks[snd], -1, -1)
    end
    else
    begin
        if (defVoicepack^.chunks[snd] = nil) and (Soundz[snd].Path <> ptVoices) and (Soundz[snd].FileName <> '') then
        begin
            s:= Pathz[Soundz[snd].Path] + '/' + Soundz[snd].FileName;
            WriteToConsole(msgLoading + s + ' ');
            defVoicepack^.chunks[snd]:= Mix_LoadWAV_RW(SDL_RWFromFile(Str2PChar(s), 'rb'), 1);
            TryDo(defVoicepack^.chunks[snd] <> nil, msgFailed, true);
            WriteLnToConsole(msgOK);
        end;
        LoopSound:= Mix_PlayChannelTimed(-1, defVoicepack^.chunks[snd], -1, -1);
    end;
end;

procedure StopSound(snd: TSound);
begin
    if not isSoundEnabled then exit;
    if (lastChan[snd] <> -1) and (Mix_Playing(lastChan[snd]) <> 0) then
    begin
        Mix_HaltChannel(lastChan[snd]);
        lastChan[snd]:= -1;
    end;
end;

procedure StopSound(chn: LongInt);
begin
    if not isSoundEnabled then exit;

    if (chn <> -1) and (Mix_Playing(chn) <> 0) then
        Mix_HaltChannel(chn);
end;

procedure PlayMusic;
var s: shortstring;
begin
    if (not isSoundEnabled) or (MusicFN = '') or (not isMusicEnabled) then
        exit;

    s:= PathPrefix + '/Music/' + MusicFN;
    WriteToConsole(msgLoading + s + ' ');

    Mus:= Mix_LoadMUS(Str2PChar(s));
    TryDo(Mus <> nil, msgFailed, false);
    WriteLnToConsole(msgOK);

    SDLTry(Mix_FadeInMusic(Mus, -1, 3000) <> -1, false)
end;

function ChangeVolume(voldelta: LongInt): LongInt;
begin
    if not isSoundEnabled then
        exit(0);

    inc(Volume, voldelta);
    if Volume < 0 then Volume:= 0;
    Mix_Volume(-1, Volume);
    Volume:= Mix_Volume(-1, -1);
    if isMusicEnabled then Mix_VolumeMusic(Volume * 4 div 8);
    ChangeVolume:= Volume * 100 div MIX_MAX_VOLUME
end;

procedure PauseMusic;
begin
    if (MusicFN = '') or (not isMusicEnabled) then
        exit;

    Mix_PauseMusic(Mus);
end;

procedure ResumeMusic;
begin
    if (MusicFN = '') or (not isMusicEnabled) then
        exit;

    Mix_ResumeMusic(Mus);
end;

procedure chVoicepack(var s: shortstring);
begin
    if CurrentTeam = nil then OutError(errmsgIncorrectUse + ' "/voicepack"', true);
    if s[1]='"' then Delete(s, 1, 1);
    if s[byte(s[0])]='"' then Delete(s, byte(s[0]), 1);
    CurrentTeam^.voicepack:= AskForVoicepack(s)
end;

procedure initModule;
begin
    RegisterVariable('voicepack', vtCommand, @chVoicepack, false);
    MusicFN:='';
end;

procedure freeModule;
begin
    if isSoundEnabled then
        ReleaseSound();
end;

end.

