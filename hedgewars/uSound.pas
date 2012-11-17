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

unit uSound;
(*
 * This unit controls the sounds and music of the game.
 * Doesn't really do anything if isSoundEnabled = false.
 *
 * There are three basic types of sound controls:
 *    Music        - The background music of the game:
 *                   * will only be played if isMusicEnabled = true
 *                   * can be started, changed, paused and resumed
 *    Sound        - Can be started and stopped
 *    Looped Sound - Subtype of sound: plays in a loop using a
 *                   "channel", of which the id is returned on start.
 *                   The channel id can be used to stop a specific sound loop.
 *)
interface
uses SDLh, uConsts, uTypes, SysUtils;

procedure preInitModule;
procedure initModule;
procedure freeModule;

procedure InitSound;                            // Initiates sound-system if isSoundEnabled.
procedure ReleaseSound(complete: boolean);      // Releases sound-system and used resources.
procedure ResetSound;                           // Reset sound state to the previous state.
procedure SetSound(enabled: boolean);           // Enable/disable sound-system and backup status.

// MUSIC

// Obvious music commands for music track
procedure SetMusic(enabled: boolean);           // Enable/disable music.
procedure SetMusicName(musicname: shortstring); // Set name of the file to play.
procedure PlayMusic;                            // Play music from the start.
procedure PauseMusic;                           // Pause music.
procedure ResumeMusic;                          // Resume music from pause point.
procedure ChangeMusic(musicname: shortstring);  // Replaces music track with musicname and plays it.
procedure StopMusic;                            // Stops and releases the current track.


// SOUNDS

// Plays the sound snd [from a given voicepack],
// if keepPlaying is given and true,
// then the sound's playback won't be interrupted if asked to play again.
procedure PlaySound(snd: TSound);
procedure PlaySound(snd: TSound; keepPlaying: boolean);
procedure PlaySoundV(snd: TSound; voicepack: PVoicepack);
procedure PlaySoundV(snd: TSound; voicepack: PVoicepack; keepPlaying: boolean);

// Plays sound snd [of voicepack] in a loop, but starts with fadems milliseconds of fade-in.
// Returns sound channel of the looped sound.
function  LoopSound(snd: TSound): LongInt;
function  LoopSound(snd: TSound; fadems: LongInt): LongInt;
function  LoopSoundV(snd: TSound; voicepack: PVoicepack): LongInt; // WTF?
function  LoopSoundV(snd: TSound; voicepack: PVoicepack; fadems: LongInt): LongInt;

// Stops the normal/looped sound of the given type/in the given channel
// [with a fade-out effect for fadems milliseconds].
procedure StopSound(snd: TSound);
procedure StopSoundChan(chn: LongInt);
procedure StopSoundChan(chn, fadems: LongInt);

procedure AddVoice(snd: TSound; voicepack: PVoicepack);
procedure PlayNextVoice;


// GLOBAL FUNCTIONS

// Drastically lower the volume when we lose focus (and restore the previous value).
procedure DampenAudio;
procedure UndampenAudio;

// Mute/Unmute audio
procedure MuteAudio;


// MISC

// Set the initial volume
procedure SetVolume(vol: LongInt);

// Modifies the sound volume of the game by voldelta and returns the new volume level.
function  ChangeVolume(voldelta: LongInt): LongInt;

// Returns a pointer to the voicepack with the given name.
function  AskForVoicepack(name: shortstring): Pointer;


implementation
uses uVariables, uConsole, uUtils, uCommands, uDebug, uPhysFSLayer;

const chanTPU = 32;
var Volume: LongInt;
    cInitVolume: LongInt;
    previousVolume: LongInt; // cached volume value
    lastChan: array [TSound] of LongInt;
    voicepacks: array[0..cMaxTeams] of TVoicepack;
    defVoicepack: PVoicepack;
    Mus: PMixMusic; // music pointer
    MusicFN: shortstring; // music file name
    isMusicEnabled: boolean;
    isSoundEnabled: boolean;
    isSEBackup: boolean;


function  AskForVoicepack(name: shortstring): Pointer;
var i: Longword;
    locName, path: shortstring;
begin
i:= 0;
    // First, attempt to locate a localised version of the voice
    if cLocale <> 'en' then
        begin
        locName:= name+'_'+cLocale;
        path:= cPathz[ptVoices] + '/' + locName;
        if DirectoryExists(path) then
            name:= locName
        else
            if Length(cLocale) > 3 then
                begin
                locName:= name+'_'+Copy(cLocale,1,2);
                path:= cPathz[ptVoices] + '/' + locName;
                if DirectoryExists(path) then
                    name:= locName
                end
        end;

    // If that fails, use the unmodified one
    while (voicepacks[i].name <> name) and (voicepacks[i].name <> '') do
        begin
        inc(i);
        TryDo(i <= cMaxTeams, 'Engine bug: AskForVoicepack i > cMaxTeams', true)
        end;

    voicepacks[i].name:= name;
    AskForVoicepack:= @voicepacks[i]
end;

procedure InitSound;
const channels: LongInt = {$IFDEF MOBILE}1{$ELSE}2{$ENDIF};
begin
    if not isSoundEnabled then
        exit;
    WriteToConsole('Init sound...');
    isSoundEnabled:= SDL_InitSubSystem(SDL_INIT_AUDIO) >= 0;

    if isSoundEnabled then
        isSoundEnabled:= Mix_OpenAudio(44100, $8010, channels, 1024) = 0;

    if isSoundEnabled then
        WriteLnToConsole(msgOK)
    else
        WriteLnToConsole(msgFailed);

    WriteToConsole('Init SDL_mixer... ');
    SDLTry(Mix_Init(MIX_INIT_OGG) <> 0, true);
    WriteLnToConsole(msgOK);

    Mix_AllocateChannels(Succ(chanTPU));
    ChangeVolume(cInitVolume);	
end;

procedure ResetSound;
begin
    isSoundEnabled:= isSEBackup;
end;

procedure SetSound(enabled: boolean);
begin
    isSEBackup:= isSoundEnabled;
    isSoundEnabled:= enabled;
end;

// when complete is false, this procedure just releases some of the chucks on inactive channels
// in this way music is not stopped, nor are chucks currently being played
procedure ReleaseSound(complete: boolean);
var i: TSound;
    t: Longword;
begin
    // release and nil all sounds
    for t:= 0 to cMaxTeams do
        if voicepacks[t].name <> '' then
            for i:= Low(TSound) to High(TSound) do
                if voicepacks[t].chunks[i] <> nil then
                    if complete or (Mix_Playing(lastChan[i]) = 0) then
                        begin
                        Mix_HaltChannel(lastChan[i]);
                        lastChan[i]:= -1;
                        Mix_FreeChunk(voicepacks[t].chunks[i]);
                        voicepacks[t].chunks[i]:= nil;
                        end;

    // stop music
    if complete then
        begin
        if Mus <> nil then
            begin
            Mix_HaltMusic();
            Mix_FreeMusic(Mus);
            Mus:= nil;
            end;

        // make sure all instances of sdl_mixer are unloaded before continuing
        while Mix_Init(0) <> 0 do
            Mix_Quit();

        Mix_CloseAudio();
        end;
end;

procedure PlaySound(snd: TSound);
begin
    PlaySoundV(snd, nil, false);
end;

procedure PlaySound(snd: TSound; keepPlaying: boolean);
begin
    PlaySoundV(snd, nil, keepPlaying);
end;

procedure PlaySoundV(snd: TSound; voicepack: PVoicepack);
begin
    PlaySoundV(snd, voicepack, false);
end;

procedure PlaySoundV(snd: TSound; voicepack: PVoicepack; keepPlaying: boolean);
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
            s:= cPathz[Soundz[snd].Path] + '/' + voicepack^.name + '/' + Soundz[snd].FileName;
            if (not FileExists(s)) and (snd in [sndFirePunch2, sndFirePunch3, sndFirePunch4, sndFirePunch5, sndFirePunch6]) then
                s:= cPathz[Soundz[sndFirePunch1].Path] + '/' + voicepack^.name + '/' + Soundz[snd].FileName;
            WriteToConsole(msgLoading + s + ' ');
            voicepack^.chunks[snd]:= Mix_LoadWAV_RW(rwopsOpenRead(s), 1);
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
            s:= cPathz[Soundz[snd].Path] + '/' + Soundz[snd].FileName;
            WriteToConsole(msgLoading + s + ' ');
            defVoicepack^.chunks[snd]:= Mix_LoadWAV_RW(rwopsOpenRead(s), 1);
            SDLTry(defVoicepack^.chunks[snd] <> nil, true);
            WriteLnToConsole(msgOK);
            end;
        lastChan[snd]:= Mix_PlayChannelTimed(-1, defVoicepack^.chunks[snd], 0, -1)
        end;
end;

procedure AddVoice(snd: TSound; voicepack: PVoicepack);
var i : LongInt;
begin
    if (not isSoundEnabled) or fastUntilLag or ((LastVoice.snd = snd) and  (LastVoice.voicepack = voicepack)) then
        exit;
    if (snd = sndVictory) or (snd = sndFlawless) then
        begin
        Mix_FadeOutChannel(-1, 800);
        for i:= 0 to 7 do
            VoiceList[i].snd:= sndNone;
        LastVoice.snd:= sndNone;
        end;

    i:= 0;
    while (i<8) and (VoiceList[i].snd <> sndNone) do
        inc(i);

    // skip playing same sound for same hog twice
    if (i>0) and (VoiceList[i-1].snd = snd) and (VoiceList[i-1].voicepack = voicepack) then
        exit;
    VoiceList[i].snd:= snd;
    VoiceList[i].voicepack:= voicepack;
end;

procedure PlayNextVoice;
var i : LongInt;
begin
    if (not isSoundEnabled) or fastUntilLag or ((LastVoice.snd <> sndNone) and (lastChan[LastVoice.snd] <> -1) and (Mix_Playing(lastChan[LastVoice.snd]) <> 0)) then
        exit;
    i:= 0;
    while (i<8) and (VoiceList[i].snd = sndNone) do
        inc(i);
    
    if (VoiceList[i].snd <> sndNone) then
        begin
        LastVoice.snd:= VoiceList[i].snd;
        LastVoice.voicepack:= VoiceList[i].voicepack;
        VoiceList[i].snd:= sndNone;
        PlaySoundV(LastVoice.snd, LastVoice.voicepack)
        end
    else LastVoice.snd:= sndNone;
end;

function LoopSound(snd: TSound): LongInt;
begin
    LoopSound:= LoopSoundV(snd, nil)
end;

function LoopSound(snd: TSound; fadems: LongInt): LongInt;
begin
    LoopSound:= LoopSoundV(snd, nil, fadems)
end;

function LoopSoundV(snd: TSound; voicepack: PVoicepack): LongInt;
begin
    voicepack:= voicepack;    // avoid compiler hint
    LoopSoundV:= LoopSoundV(snd, nil, 0)
end;

function LoopSoundV(snd: TSound; voicepack: PVoicepack; fadems: LongInt): LongInt;
var s: shortstring;
begin
    if (not isSoundEnabled) or fastUntilLag then
        begin
        LoopSoundV:= -1;
        exit
        end;

    if (voicepack <> nil) then
        begin
        if (voicepack^.chunks[snd] = nil) and (Soundz[snd].Path = ptVoices) and (Soundz[snd].FileName <> '') then
           begin
            s:= cPathz[Soundz[snd].Path] + '/' + voicepack^.name + '/' + Soundz[snd].FileName;
            WriteToConsole(msgLoading + s + ' ');
            voicepack^.chunks[snd]:= Mix_LoadWAV_RW(rwopsOpenRead(s), 1);
            if voicepack^.chunks[snd] = nil then
                WriteLnToConsole(msgFailed)
            else
                WriteLnToConsole(msgOK)
            end;
        LoopSoundV:= Mix_PlayChannelTimed(-1, voicepack^.chunks[snd], -1, -1)
        end
    else
        begin
        if (defVoicepack^.chunks[snd] = nil) and (Soundz[snd].Path <> ptVoices) and (Soundz[snd].FileName <> '') then
            begin
            s:= cPathz[Soundz[snd].Path] + '/' + Soundz[snd].FileName;
            WriteToConsole(msgLoading + s + ' ');
            defVoicepack^.chunks[snd]:= Mix_LoadWAV_RW(rwopsOpenRead(s), 1);
            SDLTry(defVoicepack^.chunks[snd] <> nil, true);
            WriteLnToConsole(msgOK);
            end;
        if fadems > 0 then
            LoopSoundV:= Mix_FadeInChannelTimed(-1, defVoicepack^.chunks[snd], -1, fadems, -1)
        else
            LoopSoundV:= Mix_PlayChannelTimed(-1, defVoicepack^.chunks[snd], -1, -1);
        end;
end;

procedure StopSound(snd: TSound);
begin
    if not isSoundEnabled then
        exit;

    if (lastChan[snd] <> -1) and (Mix_Playing(lastChan[snd]) <> 0) then
        begin
        Mix_HaltChannel(lastChan[snd]);
        lastChan[snd]:= -1;
        end;
end;

procedure StopSoundChan(chn: LongInt);
begin
    if not isSoundEnabled then
        exit;

    if (chn <> -1) and (Mix_Playing(chn) <> 0) then
        Mix_HaltChannel(chn);
end;

procedure StopSoundChan(chn, fadems: LongInt);
begin
    if not isSoundEnabled then
        exit;

    if (chn <> -1) and (Mix_Playing(chn) <> 0) then
        Mix_FadeOutChannel(chn, fadems);
end;

procedure PlayMusic;
var s: shortstring;
begin
    if (not isSoundEnabled) or (MusicFN = '') or (not isMusicEnabled) then
        exit;

    s:= '/Music/' + MusicFN;
    WriteToConsole(msgLoading + s + ' ');

    Mus:= Mix_LoadMUS_RW(rwopsOpenRead(s));
    SDLTry(Mus <> nil, false);
    WriteLnToConsole(msgOK);

    SDLTry(Mix_FadeInMusic(Mus, -1, 3000) <> -1, false)
end;

procedure SetVolume(vol: LongInt);
begin
    cInitVolume:= vol;
end;

function ChangeVolume(voldelta: LongInt): LongInt;
begin
    ChangeVolume:= 0;
    if (not isSoundEnabled) or ((voldelta = 0) and (not (cInitVolume = 0))) then
        exit;

    inc(Volume, voldelta);
    if Volume < 0 then
        Volume:= 0;
    // apply Volume to all channels
    Mix_Volume(-1, Volume);
    // get assigned Volume
    Volume:= Mix_Volume(-1, -1);
    if isMusicEnabled then
        Mix_VolumeMusic(Volume * 4 div 8);
    ChangeVolume:= Volume * 100 div MIX_MAX_VOLUME;

    if (isMusicEnabled) then
        if (Volume = 0) then
            PauseMusic
            else
            ResumeMusic;

    isAudioMuted:= (Volume = 0);
end;

procedure DampenAudio;
begin
    if (isAudioMuted) then
        exit;
    previousVolume:= Volume;
    ChangeVolume(-Volume * 7 div 9);
end;

procedure UndampenAudio;
begin
     if (isAudioMuted) then
        exit;
    ChangeVolume(previousVolume - Volume);
end;

procedure MuteAudio;
begin
    if not isSoundEnabled then
        exit;

    if (isAudioMuted) then
    begin
        ResumeMusic;
        ChangeVolume(previousVolume);
    end
    else
    begin
        PauseMusic;
        previousVolume:= Volume;
        ChangeVolume(-Volume);
    end;

    // isAudioMuted is updated in ChangeVolume
end;

procedure SetMusic(enabled: boolean);
begin
    isMusicEnabled:= enabled;
end;

procedure SetMusicName(musicname: shortstring);
begin
    MusicFN:= musicname;
end;

procedure PauseMusic;
begin
    if (MusicFN = '') or (not isMusicEnabled) then
        exit;

    if Mus <> nil then
        Mix_PauseMusic(Mus);
end;

procedure ResumeMusic;
begin
    if (MusicFN = '') or (not isMusicEnabled) then
        exit;

    if Mus <> nil then
        Mix_ResumeMusic(Mus);
end;

procedure ChangeMusic(musicname: shortstring);
begin
    MusicFN:= musicname;
    if (MusicFN = '') or (not isMusicEnabled) then
        exit;

    StopMusic;
    PlayMusic;
end;

procedure StopMusic;
begin
    if (MusicFN = '') or (not isMusicEnabled) then
        exit;

    if Mus <> nil then
        begin
        Mix_FreeMusic(Mus);
        Mus:= nil;
        end
end;

procedure chVoicepack(var s: shortstring);
begin
    if CurrentTeam = nil then
        OutError(errmsgIncorrectUse + ' "/voicepack"', true);
    if s[1]='"' then Delete(s, 1, 1);
    if s[byte(s[0])]='"' then
        Delete(s, byte(s[0]), 1);
    CurrentTeam^.voicepack:= AskForVoicepack(s)
end;

procedure chMute(var s: shortstring);
begin
    s:= s; // avoid compiler hint
    MuteAudio;
end;

procedure preInitModule;
begin
    isMusicEnabled:= true;
    isSoundEnabled:= true;
    cInitVolume:= 100;
end;

procedure initModule;
var t: LongInt;
    i: TSound;
begin
    RegisterVariable('voicepack', @chVoicepack, false);
    RegisterVariable('mute'     , @chMute     , true );

    MusicFN:='';
    Mus:= nil;
    isAudioMuted:= false;
    isSEBackup:= isSoundEnabled;
    Volume:= 0;
    defVoicepack:= AskForVoicepack('Default');

    for i:= Low(TSound) to High(TSound) do
        lastChan[i]:= -1;

    // initialize all voices to nil so that they can be loaded lazily
    for t:= 0 to cMaxTeams do
        if voicepacks[t].name <> '' then
            for i:= Low(TSound) to High(TSound) do
                voicepacks[t].chunks[i]:= nil;

    (* on MOBILE SDL_mixer has to be compiled against Tremor (USE_OGG_TREMOR)
       or sound files bigger than 32k will lockup the game *)
    for i:= Low(TSound) to High(TSound) do
        defVoicepack^.chunks[i]:= nil;

end;

procedure freeModule;
begin
    if isSoundEnabled then
        ReleaseSound(true);
end;

end.

