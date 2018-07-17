(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2015 Andrey Korotaev <unC0Rr@gmail.com>
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
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *)


{$INCLUDE "options.inc"}

unit uVideoRec;

{$IFNDEF USE_VIDEO_RECORDING}
interface
implementation
end.
{$ELSE}

{$IFNDEF WIN32}
    {$linklib avwrapper}
{$ENDIF}

interface

var flagPrerecording: boolean = false;

function BeginVideoRecording: Boolean;
function LoadNextCameraPosition(out newRealTicks, newGameTicks: LongInt): Boolean;
procedure EncodeFrame;
procedure StopVideoRecording;

procedure BeginPreRecording;
procedure StopPreRecording;
procedure SaveCameraPosition;

procedure initModule;
procedure freeModule;

implementation
uses uVariables, GLunit, SDLh, SysUtils, uUtils, uIO, uMisc, uConsts, uTypes, uDebug;

type TAddFileLogRaw = procedure (s: pchar); cdecl;
const AvwrapperLibName = 'libavwrapper';

function AVWrapper_Init(
              AddLog: TAddFileLogRaw;
              filename, desc, soundFile, format, vcodec, acodec: PChar;
              width, height, framerateNum, framerateDen, vquality: LongInt): LongInt; cdecl; external AvwrapperLibName;
function AVWrapper_Close: LongInt; cdecl; external AvwrapperLibName;
function AVWrapper_WriteFrame(rgb: PByte): LongInt; cdecl; external AvwrapperLibName;

type TFrame = record
                  realTicks: LongWord;
                  gameTicks: LongWord;
                  CamX, CamY: LongInt;
                  zoom: single;
              end;

var RGB_Buffer: PByte;
    cameraFile: File of TFrame;
    audioFile: File;
    numPixels: LongWord;
    startTime, numFrames, curTime, progress, maxProgress: LongWord;
    soundFilePath: shortstring;
    thumbnailSaved: boolean;
    recordAudio: boolean;

function BeginVideoRecording: Boolean;
var filename, desc: shortstring;
begin
    AddFileLog('BeginVideoRecording');

{$IOCHECKS OFF}
    // open file with prerecorded camera positions
    filename:= UserPathPrefix + '/VideoTemp/' + RecPrefix + '.txtin';
    Assign(cameraFile, filename);
    Reset(cameraFile);
    maxProgress:= FileSize(cameraFile);
    if IOResult <> 0 then
    begin
        AddFileLog('Error: Could not read from ' + filename);
        exit(false);
    end;
{$IOCHECKS ON}

    { Store some description in output file.
    The comment must follow a particular format and must be in English.
    This will be parsed by the frontend.
    The frontend will parse lines of this format:
        Key: Value
    The key names will be localized in the frontend.
    If you add a key/value pair, don't forget to add a localization
    in the frontend! }
    desc:= '';
    if UserNick <> '' then
        desc:= desc + 'Player: ' + UserNick + #10;
    if recordFileName <> '' then
        desc:= desc + 'Record: ' + recordFileName + #10;
    if cMapName <> '' then
        desc:= desc + 'Map: ' + cMapName + #10;
    if Theme <> '' then
        desc:= desc + 'Theme: ' + Theme + #10;
    desc:= desc + 'prefix[' + RecPrefix + ']prefix';

    filename:= UserPathPrefix + '/VideoTemp/' + RecPrefix;

    recordAudio:= (cAudioCodec <> 'no');
    if recordAudio then
        soundFilePath:= UserPathPrefix + '/VideoTemp/' + RecPrefix + '.sw'
    else
        soundFilePath:= '';

    if checkFails(AVWrapper_Init(@AddFileLogRaw
        , PChar(ansistring(filename))
        , PChar(ansistring(desc))
        , PChar(ansistring(soundFilePath))
        , PChar(ansistring(cAVFormat))
        , PChar(ansistring(cVideoCodec))
        , PChar(ansistring(cAudioCodec))
        , cScreenWidth, cScreenHeight, cVideoFramerateNum, cVideoFramerateDen, cVideoQuality) >= 0,
        'AVWrapper_Init failed',
        true) then exit(false);

    numPixels:= cScreenWidth*cScreenHeight;

    RGB_Buffer:= GetMem(4*numPixels);
    if RGB_Buffer = nil then
    begin
        AddFileLog('Error: Could not allocate memory for video recording (RGB buffer).');
        exit(false);
    end;

    curTime:= 0;
    numFrames:= 0;
    progress:= 0;
    BeginVideoRecording:= true;
end;

procedure StopVideoRecording;
begin
    AddFileLog('StopVideoRecording');
    FreeMem(RGB_Buffer, 4*numPixels);
    Close(cameraFile);
    if AVWrapper_Close() < 0 then
        begin
        AddFileLog('AVWrapper_Close() has failed.');
        halt(HaltVideoRec);
        end;
    Erase(cameraFile);
    if recordAudio then
        DeleteFile(soundFilePath);
    SendIPC(_S'v'); // inform frontend that we finished
end;

procedure EncodeFrame;
var s: shortstring;
begin
    // read pixels from OpenGL
    glReadPixels(0, 0, cScreenWidth, cScreenHeight, GL_RGBA, GL_UNSIGNED_BYTE, RGB_Buffer);

    if AVWrapper_WriteFrame(RGB_Buffer) < 0 then
        begin
        AddFileLog('AVWrapper_WriteFrame(RGB_Buffer) has failed.');
        halt(HaltVideoRec);
        end;

    // inform frontend that we have encoded new frame
    s[0]:= #3;
    s[1]:= 'p'; // p for progress
    SDLNet_Write16(progress*10000 div maxProgress, @s[2]);
    SendIPC(s);
    inc(numFrames);
end;

function LoadNextCameraPosition(out newRealTicks, newGameTicks: LongInt): Boolean;
var frame: TFrame = (realTicks: 0; gameTicks: 0; CamX: 0; CamY: 0; zoom: 0);
begin
    // we need to skip or duplicate frames to match target framerate
    while Int64(curTime)*cVideoFramerateNum <= Int64(numFrames)*cVideoFramerateDen*1000 do
    begin
    {$IOCHECKS OFF}
        if eof(cameraFile) then
            exit(false);
        BlockRead(cameraFile, frame, 1);
    {$IOCHECKS ON}
        curTime:= frame.realTicks;
        WorldDx:= frame.CamX;
        WorldDy:= frame.CamY + cScreenHeight div 2;
        zoom:= frame.zoom*cScreenWidth;
        ZoomValue:= zoom;
        inc(progress);
        newRealTicks:= frame.realTicks;
        newGameTicks:= frame.gameTicks;
    end;
    LoadNextCameraPosition:= true;
end;

// Callback which records sound.
// This procedure may be called from different thread.
procedure RecordPostMix(udata: pointer; stream: PByte; len: LongInt); cdecl;
begin
    udata:= udata; // avoid warning
{$IOCHECKS OFF}
    BlockWrite(audioFile, stream^, len);
{$IOCHECKS ON}
end;

procedure SaveThumbnail;
var thumbpath: shortstring;
    k: LongInt;
begin
    thumbpath:= '/VideoTemp/' + RecPrefix;
    AddFileLog('Saving thumbnail ' + thumbpath);
    k:= max(max(cScreenWidth, cScreenHeight) div 400, 1); // here 400 is minimum size of thumbnail
    MakeScreenshot(thumbpath, k, 0);
    thumbnailSaved:= true;
end;

// copy file (free pascal doesn't have copy file function)
procedure CopyFile(src, dest: shortstring);
var inF, outF: file;
    buffer: array[0..1023] of byte;
    result: LongInt;
    i: integer;
begin
{$IOCHECKS OFF}
    result:= 0; // avoid compiler hint and warning
    for i:= 0 to 1023 do
        buffer[i]:= 0;

    Assign(inF, src);
    Reset(inF, 1);
    if IOResult <> 0 then
    begin
        AddFileLog('Error: Could not read from ' + src);
        exit;
    end;

    Assign(outF, dest);
    Rewrite(outF, 1);
    if IOResult <> 0 then
    begin
        AddFileLog('Error: Could not write to ' + dest);
        exit;
    end;

    repeat
        BlockRead(inF, buffer, 1024, result);
        BlockWrite(outF, buffer, result);
    until result < 1024;
{$IOCHECKS ON}
end;

procedure BeginPreRecording;
var format: word;
    filename: shortstring;
    frequency, channels: LongInt;
begin
    AddFileLog('BeginPreRecording');

    thumbnailSaved:= false;
    RecPrefix:= 'hw-' + FormatDateTime('YYYY-MM-DD_HH-mm-ss-z', Now());

    // If this video is recorded from demo executed directly (without frontend)
    // then we need to copy demo so that frontend will be able to find it later.
    if recordFileName <> '' then
    begin
        if GameType <> gmtDemo then // this is save and game demo is not recording, abort
            exit;
        CopyFile(recordFileName, UserPathPrefix + '/VideoTemp/' + RecPrefix + '.hwd');
    end;

    if cIsSoundEnabled then
        begin
        Mix_QuerySpec(@frequency, @format, @channels);
        AddFileLog('sound: frequency = ' + IntToStr(frequency) + ', format = ' + IntToStr(format) + ', channels = ' + IntToStr(channels));
        if format <> $8010 then
            begin
            // TODO: support any audio format
            AddFileLog('Error: Unexpected audio format ' + IntToStr(format));
            exit;
            end;

{$IOCHECKS OFF}
        // create sound file
        filename:= UserPathPrefix + '/VideoTemp/' + RecPrefix + '.sw';
        Assign(audioFile, filename);
        Rewrite(audioFile, 1);
        if IOResult <> 0 then
            begin
            AddFileLog('Error: Could not write to ' + filename);
            exit;
            end;
        end;

    // create file with camera positions
    filename:= UserPathPrefix + '/VideoTemp/' + RecPrefix + '.txtout';
    Assign(cameraFile, filename);
    Rewrite(cameraFile);
    if IOResult <> 0 then
        begin
        AddFileLog('Error: Could not write to ' + filename);
        exit;
        end;

    if cIsSoundEnabled then
        begin
        // save audio parameters in sound file
        BlockWrite(audioFile, frequency, 4);
        BlockWrite(audioFile, channels, 4);
{$IOCHECKS ON}

        // register callback for actual audio recording
        Mix_SetPostMix(@RecordPostMix, nil);
        end;

    startTime:= SDL_GetTicks();
    flagPrerecording:= true;
end;

procedure StopPreRecording;
begin
    AddFileLog('StopPreRecording');
    flagPrerecording:= false;

    if cIsSoundEnabled then
        begin
        // call SDL_LockAudio because RecordPostMix may be executing right now
        SDL_LockAudio();
        Close(audioFile);
        end;
    Close(cameraFile);
    if cIsSoundEnabled then
        begin
        Mix_SetPostMix(nil, nil);
        SDL_UnlockAudio();
        end;

    if not thumbnailSaved then
        SaveThumbnail();
end;

procedure SaveCameraPosition;
var frame: TFrame;
begin
    if (not thumbnailSaved) and (ScreenFade = sfNone) then
        SaveThumbnail();

    frame.realTicks:= SDL_GetTicks() - startTime;
    frame.gameTicks:= GameTicks;
    frame.CamX:= WorldDx;
    frame.CamY:= WorldDy - cScreenHeight div 2;
    frame.zoom:= zoom/cScreenWidth;
    BlockWrite(cameraFile, frame, 1);
end;

procedure initModule;
begin
    // we need to make sure these variables are initialized before the main loop
    // or the wrapper will keep the default values of preinit
    cScreenWidth:= max(cWindowedWidth, 640);
    cScreenHeight:= max(cWindowedHeight, 480);
end;

procedure freeModule;
begin
    if flagPrerecording then
        StopPreRecording();
end;

end.

{$ENDIF} // USE_VIDEO_RECORDING
