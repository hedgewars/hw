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

unit uSound;
interface
uses SDLh, uConsts;
{$INCLUDE options.inc}

type PVoicepack = ^TVoicepack;
	TVoicepack = record
		name: shortstring;
		chunks: array [TSound] of PMixChunk;
		end;

procedure InitSound;
procedure ReleaseSound;
procedure SoundLoad;
procedure PlaySound(snd: TSound; infinite: boolean);
procedure PlayMusic;
procedure StopSound(snd: TSound);
function  ChangeVolume(voldelta: LongInt): LongInt;
function  AskForVoicepack(name: shortstring): Pointer;

var MusicFN: shortstring = '';

implementation
uses uMisc, uConsole;

const chanTPU = 12;
var Mus: PMixMusic = nil;
	Volume: LongInt;
	lastChan: array [TSound] of LongInt;
	voicepacks: array[0..cMaxTeams] of TVoicepack;

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
begin
if not isSoundEnabled then exit;
WriteToConsole('Init sound...');
isSoundEnabled:= SDL_Init(SDL_INIT_AUDIO) >= 0;
if isSoundEnabled then
   isSoundEnabled:= Mix_OpenAudio(22050, $8010, 2, 512) = 0;
if isSoundEnabled then WriteLnToConsole(msgOK)
                  else WriteLnToConsole(msgFailed);
Mix_AllocateChannels(Succ(chanTPU));
if isMusicEnabled then Mix_VolumeMusic(50);

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
AskForVoicepack('Default');

for i:= Low(TSound) to High(TSound) do
	begin
	s:= Pathz[Soundz[i].Path] + '/' + Soundz[i].FileName;
	WriteToConsole(msgLoading + s + ' ');
	Soundz[i].id:= Mix_LoadWAV_RW(SDL_RWFromFile(Str2PChar(s), 'rb'), 1);
	TryDo(Soundz[i].id <> nil, msgFailed, true);
	WriteLnToConsole(msgOK);
	end;
end;

procedure PlaySound(snd: TSound; infinite: boolean);
var loops: LongInt;
begin
if (not isSoundEnabled) or fastUntilLag then exit;
if infinite then loops:= -1 else loops:= 0;
lastChan[snd]:= Mix_PlayChannelTimed(-1, Soundz[snd].id, loops, -1)
end;

procedure StopSound(snd: TSound);
begin
if not isSoundEnabled then exit;
if Mix_Playing(lastChan[snd]) <> 0 then
	Mix_HaltChannel(lastChan[snd])
end;

procedure PlayMusic;
var s: string;
begin
if (not isSoundEnabled)
	or (MusicFN = '')
	or (not isMusicEnabled)then exit;

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

end.
