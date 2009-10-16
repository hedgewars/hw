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

function ChangeVolume(voldelta: LongInt): LongInt;
function AskForVoicepack(name: shortstring): PVoicepack;
function soundFadeOut(snd: TSound; qt: LongInt; voicepack: PVoicepack): LongInt;


procedure oalb_close; cdecl; external OpenALBridge;
function oalb_init		(const app: PChar; const usehardware: Byte): Byte; cdecl; external OpenALBridge;
function oalb_loadfile		(const filename: PChar): LongInt; cdecl; external OpenALBridge;
procedure oalb_playsound	(const idx: LongInt; const loop: Byte); cdecl; external OpenALBridge;
procedure oalb_stopsound	(const idx: LongInt); cdecl; external OpenALBridge;
procedure oalb_pausesound	(const idx: LongInt); cdecl; external OpenALBridge;
procedure oalb_continuesound	(const idx: LongInt); cdecl; external OpenALBridge;
procedure oalb_setvolume	(const idx: LongInt; const percentage: Byte); cdecl; external OpenALBridge;
procedure oalb_setglobalvolume	(const percentage: Byte); cdecl; external OpenALBridge;
procedure oalb_fadein		(const idx: LongInt; quantity: Integer); cdecl; external OpenALBridge;
procedure oalb_fadeout		(const idx: LongInt; quantity: Integer); cdecl; external OpenALBridge;


var MusicFN: shortstring = '';

implementation

uses uMisc, uConsole;

const chanTPU = 12;
var	Volume: LongInt;
	lastChan: array [TSound] of LongInt;
	voicepacks: array[0..cMaxTeams] of TVoicepack;
	defVoicepack: PVoicepack;
	Mus: LongInt = 0;

function  AskForVoicepack(name: shortstring): PVoicepack;
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
{*sound works in ipodtouch only if LAND_WIDTH  = 1024;   LAND_HEIGHT = 512; 
or if ogg are loaded in stream or if sound is loaded by demand*}
WriteToConsole('Init OpenAL sound...');

isSoundEnabled:= oalb_init(str2PChar(ParamStr(0)), Byte(isSoundHardware)) = 1;
if isSoundEnabled then WriteLnToConsole(msgOK)
                  else WriteLnToConsole(msgFailed);

Volume:=0;
ChangeVolume(cInitVolume);
end;

procedure ReleaseSound;
begin
if isMusicEnabled then oalb_fadeout(Mus, 30);
oalb_close();
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
		defVoicepack^.chunks[i]:= oalb_loadfile(Str2PChar(s));
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
				voicepacks[t].chunks[i]:= oalb_loadfile(Str2PChar(s));
				if voicepacks[t].chunks[i] < 0 then
					WriteLnToConsole(msgFailed)
				else
					WriteLnToConsole(msgOK)
				end;
end;

function soundFadeOut(snd: TSound; qt: LongInt; voicepack: PVoicepack): LongInt;
begin
if not isSoundEnabled then exit(0);
if (voicepack <> nil) and (voicepack^.chunks[snd] >= 0) then oalb_fadeout(defVoicepack^.chunks[snd], qt)
else if (defVoicepack^.chunks[snd] >= 0) then oalb_fadeout(defVoicepack^.chunks[snd], qt);
end;

procedure PlaySound(snd: TSound; infinite: boolean; voicepack: PVoicepack);
begin
if (not isSoundEnabled) or fastUntilLag then exit;

if voicepack = nil then voicepack:= defVoicepack;

if voicepack^.chunks[snd] >= 0 then
	begin
	oalb_playsound(voicepack^.chunks[snd], Byte(infinite));
	lastChan[snd]:=voicepack^.chunks[snd];
	end
end;

procedure StopSound(snd: TSound);
begin
if isSoundEnabled then
	oalb_stopsound(lastChan[snd])
end;

procedure PlayMusic;
var s: string;
begin
if (not isSoundEnabled)
	or (MusicFN = '')
	or (not isMusicEnabled) then exit;

s:= PathPrefix + '/Music/' + MusicFN;
WriteToConsole(msgLoading + s + ' ');

Mus:= oalb_loadfile(Str2PChar(s));
TryDo(Mus >= 0, msgFailed, false);
WriteLnToConsole(msgOK);

oalb_playsound(Mus, 1);
oalb_fadein(Mus, 50);
end;

function ChangeVolume(voldelta: LongInt): LongInt;
begin
if not isSoundEnabled then exit(0);

inc(Volume, voldelta);
if Volume < 0 then Volume:= 0;
if Volume > 100 then Volume:= 100;

oalb_setglobalvolume(Volume);
if isMusicEnabled then oalb_setvolume(Mus, Volume shr 1);
ChangeVolume:= Volume;
end;

procedure PauseMusic;
begin
if (MusicFN = '') or (not isMusicEnabled) then exit;
oalb_stopsound(Mus)
end;

procedure ResumeMusic;
begin
if (MusicFN = '') or (not isMusicEnabled) then exit;
oalb_playsound(Mus, 0)
end;


var i: LongInt;
	c: TSound;

initialization
for i:= 0 to cMaxTeams do
	for c:= Low(TSound) to High(TSound) do
		voicepacks[i].chunks[c]:= -1


end.
