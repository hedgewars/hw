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


{$IFDEF DARWIN}
	{$linklib openalbridge}
	{$linkframework OpenAL}
	{$linkframework Ogg}
	{$linkframework Vorbis}
{$ELSE}
{$IFNDEF WIN32}
    {$linklib openal}
    {$linklib ogg}
    {$linklib vorbis}
    {$linklib vorbisfile}
{$ENDIF}
{$ENDIF}

uses uConsts;
{$INCLUDE options.inc}

type PVoicepack = ^TVoicepack;
	TVoicepack = record
		name: shortstring;
		chunks: array [TSound] of LongInt;
		end;

const OpenALBridge = 'libopenalbridge';

procedure InitSound;
procedure ReleaseSound;
procedure SoundLoad;
procedure PlaySound(snd: TSound; infinite: boolean; voicepack: PVoicepack);
procedure PlayMusic;
procedure PauseMusic;
procedure ResumeMusic;
procedure StopSound(snd: TSound);
function  ChangeVolume(voldelta: LongInt): LongInt;
function  AskForVoicepack(name: shortstring): Pointer;
function  soundFadeOut(snd: TSound; qt: LongInt; voicepack: PVoicepack): LongInt;


{*remember: LongInt = 32bit; integer = 16bit; byte = 8bit*}
function openal_init		(memsize: LongInt)                      : boolean; cdecl; external OpenALBridge;
function openal_close							: boolean; cdecl; external OpenALBridge;
function openal_loadfile	(const filename: PChar)			: LongInt; cdecl; external OpenALBridge;
function openal_toggleloop	(index: LongInt)			: boolean; cdecl; external OpenALBridge;
function openal_setvolume	(index: LongInt; percentage: byte)	: boolean; cdecl; external OpenALBridge;
function openal_setglobalvolume	(percentage: byte)			: boolean; cdecl; external OpenALBridge;
function openal_fadeout		(index: LongInt; quantity: integer)	: boolean; cdecl; external OpenALBridge;
function openal_fadein		(index: LongInt; quantity: integer)	: boolean; cdecl; external OpenALBridge;
function openal_fade		(index: LongInt; quantity: integer; direction: boolean)	: boolean; cdecl; external OpenALBridge;
function openal_playsound	(index: LongInt)			: boolean; cdecl; external OpenALBridge;
function openal_pausesound	(index: LongInt)			: boolean; cdecl; external OpenALBridge;
function openal_stopsound	(index: LongInt)			: boolean; cdecl; external OpenALBridge;

var MusicFN: shortstring = '';

implementation

uses uMisc, uConsole;

const chanTPU = 12;
var	Volume: LongInt;
	lastChan: array [TSound] of LongInt;
	voicepacks: array[0..cMaxTeams] of TVoicepack;
	defVoicepack: PVoicepack;
	Mus: LongInt = 0;

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
const numSounds = 80;
begin
if not isSoundEnabled then exit;
WriteToConsole('Init OpenAL sound...');
isSoundEnabled:= openal_init(numSounds);
if isSoundEnabled then WriteLnToConsole(msgOK)
                  else WriteLnToConsole(msgFailed);

Volume:=0;
ChangeVolume(cInitVolume);
end;

procedure ReleaseSound;
begin
if isMusicEnabled then openal_fadeout(Mus, 30);
openal_close();
end;

procedure SoundLoad;
var i: TSound;
	s: shortstring;
	t: Longword;
begin
if not isSoundEnabled then exit;

defVoicepack:= AskForVoicepack('Default');

for i:= Low(TSound) to High(TSound) do
	if Soundz[i].Path <> ptVoices then
		begin
		s:= Pathz[Soundz[i].Path] + '/' + Soundz[i].FileName;
		WriteToConsole(msgLoading + s + ' ');
		defVoicepack^.chunks[i]:= openal_loadfile (Str2PChar(s));
		TryDo(defVoicepack^.chunks[i] >= 0, msgFailed, true);
		WriteLnToConsole(msgOK);
		end;

for t:= 0 to cMaxTeams do
	if voicepacks[t].name <> '' then
		for i:= Low(TSound) to High(TSound) do
			if Soundz[i].Path = ptVoices then
				begin
				s:= Pathz[Soundz[i].Path] + '/' + voicepacks[t].name + '/' + Soundz[i].FileName;
				WriteToConsole(msgLoading + s + ' ');
				voicepacks[t].chunks[i]:= openal_loadfile (Str2PChar(s));
				if voicepacks[t].chunks[i] < 0 then
					WriteLnToConsole(msgFailed)
				else
					WriteLnToConsole(msgOK)
				end;
end;

function soundFadeOut(snd: TSound; qt: LongInt; voicepack: PVoicepack): LongInt;
begin
if not isSoundEnabled then exit(0);
if (voicepack <> nil) and (voicepack^.chunks[snd] >= 0) then openal_fadeout(defVoicepack^.chunks[snd], qt)
else if (defVoicepack^.chunks[snd] >= 0) then openal_fadeout(defVoicepack^.chunks[snd], qt);
end;

procedure PlaySound(snd: TSound; infinite: boolean; voicepack: PVoicepack);
begin
if (not isSoundEnabled) or fastUntilLag then exit;

if (voicepack <> nil) then
begin
if voicepack^.chunks[snd] >= 0 then
	begin
	if infinite then openal_toggleloop(voicepack^.chunks[snd]);
	openal_playsound(voicepack^.chunks[snd]);
	lastChan[snd]:=voicepack^.chunks[snd];
	end
end
else
begin
if (defVoicepack^.chunks[snd] >= 0) then
	begin
	if infinite then openal_toggleloop(defVoicepack^.chunks[snd]);
	openal_playsound(defVoicepack^.chunks[snd]);
	lastChan[snd]:=defVoicepack^.chunks[snd];
	end
end
end;

procedure StopSound(snd: TSound);
begin
if not isSoundEnabled then exit;
	openal_stopsound(lastChan[snd])
end;

procedure PlayMusic;
var s: string;
begin
if (not isSoundEnabled)
	or (MusicFN = '')
	or (not isMusicEnabled) then exit;

s:= PathPrefix + '/Music/' + MusicFN;
WriteToConsole(msgLoading + s + ' ');

Mus:= openal_loadfile(Str2PChar(s));
TryDo(Mus >= 0, msgFailed, false);
WriteLnToConsole(msgOK);

openal_fadein(Mus, 20);
openal_toggleloop(Mus);
end;

function ChangeVolume(voldelta: LongInt): LongInt;
begin
if not isSoundEnabled then exit(0);

inc(Volume, voldelta);
if Volume < 0 then Volume:= 0;
if Volume > 100 then Volume:= 100;

openal_setglobalvolume(Volume);
if isMusicEnabled then openal_setvolume(Mus, Volume shr 1);
ChangeVolume:= Volume;
end;

procedure PauseMusic;
begin
if (MusicFN = '') or (not isMusicEnabled) then exit;
openal_pausesound(Mus);
end;

procedure ResumeMusic;
begin
if (MusicFN = '') or (not isMusicEnabled) then exit;
openal_playsound(Mus);
end;


var i: LongInt;
	c: TSound;

initialization
for i:= 0 to cMaxTeams do
	for c:= Low(TSound) to High(TSound) do
		voicepacks[i].chunks[c]:= -1


end.
