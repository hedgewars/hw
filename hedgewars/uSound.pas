(*
 * Hedgewars, a worms-like game
 * Copyright (c) 2005 Andrey Korotaev <unC0Rr@gmail.com>
 *
 * Distributed under the terms of the BSD-modified licence:
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * with the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *)

unit uSound;
interface
uses SDLh, uConsts;
{$INCLUDE options.inc}

procedure InitSound;
procedure ReleaseSound;
procedure SoundLoad;
procedure PlaySound(snd: TSound);
procedure PlayMusic;
procedure StopTPUSound;

implementation
uses uMisc, uConsole;
const chanTPU = 12;
var Mus: PMixMusic;

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
Mix_VolumeMusic(48)
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
    s: string;
begin
if not isSoundEnabled then exit;
for i:= Low(TSound) to High(TSound) do
    begin
    s:= Pathz[Soundz[i].Path] + '/' + Soundz[i].FileName;
    WriteToConsole(msgLoading + s + ' ');
    Soundz[i].id:= Mix_LoadWAV_RW(SDL_RWFromFile(PChar(s), 'rb'), 1);
    TryDo(Soundz[i].id <> nil, msgFailed, true);
    WriteLnToConsole(msgOK);
    end;

s:= 'Data/Music/kahvi140a_alexander_chereshnev-illusion.ogg';
WriteToConsole(msgLoading + s + ' ');
Mus:= Mix_LoadMUS(PChar(s));
TryDo(Mus <> nil, msgFailed, false);
WriteLnToConsole(msgOK)
end;

procedure PlaySound(snd: TSound);
begin
if not isSoundEnabled then exit;
if snd <> sndThrowPowerUp then Mix_PlayChannelTimed(-1, Soundz[snd].id, 0, -1)
                          else Mix_PlayChannelTimed(chanTPU, Soundz[snd].id, 0, -1)
end;

procedure StopTPUSound;
begin
if not isSoundEnabled then exit;
if Mix_Playing(chanTPU) <> 0 then
   Mix_HaltChannel(chanTPU)
end;

procedure PlayMusic;
begin
if not isSoundEnabled then exit;
if Mix_PlayingMusic = 0 then
   Mix_PlayMusic(Mus, -1)
end;

end.
