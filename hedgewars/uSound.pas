(*
 * Hedgewars, a worms-like game
 * Copyright (c) 2005 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uSound;
interface
uses SDLh, uConsts;
{$INCLUDE options.inc}

procedure InitSound;
procedure ReleaseSound;
procedure SoundLoad;
procedure PlaySound(snd: TSound; infinite: boolean);
procedure PlayMusic;
procedure StopSound(snd: TSound);
function  ChangeVolume(voldelta: integer): integer;

implementation
uses uMisc, uConsole;
const chanTPU = 12;
var Mus: PMixMusic;
    Volume: integer;

procedure InitSound;
begin
if not isSoundEnabled then exit;
WriteToConsole('Init sound...');
isSoundEnabled:= SDL_Init(SDL_INIT_AUDIO) >= 0;
if isSoundEnabled then
   isSoundEnabled:= Mix_OpenAudio(22050, $8010, 2, 512) = 0;
if isSoundEnabled then WriteLnToConsole(msgOK)
                  else WriteLnToConsole(msgFailed);
Mix_AllocateChannels(Succ(chanTPU));
Mix_VolumeMusic(48);

Volume:= cInitVolume;
if Volume < 0 then Volume:= 0;
Volume:= Mix_Volume(-1, Volume)
end;

procedure ReleaseSound;
var i: TSound;
begin
for i:= Low(TSound) to High(TSound) do
    Mix_FreeChunk(Soundz[i].id);
Mix_FreeMusic(Mus);
Mix_CloseAudio
end;

procedure SoundLoad;
var i: TSound;
    s: shortstring;
begin
if not isSoundEnabled then exit;
for i:= Low(TSound) to High(TSound) do
    begin
    s:= Pathz[Soundz[i].Path] + '/' + Soundz[i].FileName;
    WriteToConsole(msgLoading + s + ' ');
    Soundz[i].id:= Mix_LoadWAV_RW(SDL_RWFromFile(Str2PChar(s), 'rb'), 1);
    TryDo(Soundz[i].id <> nil, msgFailed, true);
    WriteLnToConsole(msgOK);
    end;

s:= PathPrefix + '/Music/kahvi140a_alexander_chereshnev-illusion.ogg';
WriteToConsole(msgLoading + string(s) + ' ');
Mus:= Mix_LoadMUS(@s);
TryDo(Mus <> nil, msgFailed, false);
WriteLnToConsole(msgOK)
end;

procedure PlaySound(snd: TSound; infinite: boolean);
var loops: integer;
begin
if not isSoundEnabled then exit;
if infinite then loops:= -1 else loops:= 0;
Soundz[snd].lastChan:= Mix_PlayChannelTimed(-1, Soundz[snd].id, loops, -1)
end;

procedure StopSound(snd: TSound);
begin
if not isSoundEnabled then exit;
if Mix_Playing(Soundz[snd].lastChan) <> 0 then
   Mix_HaltChannel(Soundz[snd].lastChan)
end;

procedure PlayMusic;
begin
if not isSoundEnabled then exit;
if Mix_PlayingMusic = 0 then
   Mix_PlayMusic(Mus, -1)
end;

function ChangeVolume(voldelta: integer): integer;
begin
if not isSoundEnabled then
   exit(0);

inc(Volume, voldelta);
if Volume < 0 then Volume:= 0;
Mix_Volume(-1, Volume);
Volume:= Mix_Volume(-1, -1);
Mix_VolumeMusic(Volume * 3 div 8);
ChangeVolume:= Volume * 100 div MIX_MAX_VOLUME
end;

end.
