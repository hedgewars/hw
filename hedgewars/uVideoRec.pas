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

unit uVideoRec;

{$IFNDEF USE_VIDEO_RECORDING}
interface
implementation
end.
{$ELSE}

{$IFDEF UNIX}
    {$LINKLIB avwrapper}
    {$LINKLIB avutil}
    {$LINKLIB avcodec}
    {$LINKLIB avformat}
{$ENDIF}

interface

var flagPrerecording: boolean = false;

function BeginVideoRecording: Boolean;
function LoadNextCameraPosition: LongInt;
procedure EncodeFrame;
procedure StopVideoRecording;

procedure BeginPreRecording;
procedure StopPreRecording;
procedure SaveCameraPosition;

procedure freeModule;

implementation

uses uVariables, uUtils, GLunit, SDLh, SysUtils, uIO, uMisc, uTypes;

{$IFDEF WIN32}
const AVWrapperLibName = 'libavwrapper.dll';
{$ENDIF}

type TAddFileLogRaw = procedure (s: pchar); cdecl;

{$IFDEF WIN32}
procedure AVWrapper_Init(
              AddLog: TAddFileLogRaw;
              filename, desc, soundFile, format, vcodec, acodec: PChar;
              width, height, framerateNum, framerateDen, vquality: LongInt); cdecl; external AVWrapperLibName;
procedure AVWrapper_Close; cdecl; external AVWrapperLibName;
procedure AVWrapper_WriteFrame( pY, pCb, pCr: PByte ); cdecl; external AVWrapperLibName;
{$ELSE}
procedure AVWrapper_Init(
              AddLog: TAddFileLogRaw;
              filename, desc, soundFile, format, vcodec, acodec: PChar;
              width, height, framerateNum, framerateDen, vquality: LongInt); cdecl; external;
procedure AVWrapper_Close; cdecl; external;
procedure AVWrapper_WriteFrame( pY, pCb, pCr: PByte ); cdecl; external;
{$ENDIF}

type TFrame = record
                  realTicks: LongWord;
                  gameTicks: LongWord;
                  CamX, CamY: LongInt;
                  zoom: single;
              end;

var YCbCr_Planes: array[0..2] of PByte;
    RGB_Buffer: PByte;
    cameraFile: File of TFrame;
    audioFile: File;
    numPixels: LongWord;
    startTime, numFrames, curTime, progress, maxProgress: LongWord;
    cameraFilePath, soundFilePath: shortstring;
    thumbnailSaved : Boolean;

function BeginVideoRecording: Boolean;
var filename, desc: shortstring;
begin
    AddFileLog('BeginVideoRecording');

{$IOCHECKS OFF}
    // open file with prerecorded camera positions
    cameraFilePath:= UserPathPrefix + '/VideoTemp/' + RecPrefix + '.txtin';
    Assign(cameraFile, cameraFilePath);
    Reset(cameraFile);
    maxProgress:= FileSize(cameraFile);
    if IOResult <> 0 then
    begin
        AddFileLog('Error: Could not read from ' + cameraFilePath);
        exit(false);
    end;
{$IOCHECKS ON}

    // store some description in output file
    desc:= '';
    if UserNick <> '' then
        desc+= 'Player: ' + UserNick + #10;
    if recordFileName <> '' then
        desc+= 'Record: ' + recordFileName + #10;
    if cMapName <> '' then
        desc+= 'Map: ' + cMapName + #10;
    if Theme <> '' then
        desc+= 'Theme: ' + Theme + #10;
    desc+= 'prefix[' + RecPrefix + ']prefix';
    desc+= #0;

    filename:= UserPathPrefix + '/VideoTemp/' + RecPrefix + #0;
    soundFilePath:= UserPathPrefix + '/VideoTemp/' + RecPrefix + '.sw' + #0;
    cAVFormat+= #0;
    cAudioCodec+= #0;
    cVideoCodec+= #0;
    AVWrapper_Init(@AddFileLogRaw, @filename[1], @desc[1], @soundFilePath[1], @cAVFormat[1], @cVideoCodec[1], @cAudioCodec[1],
                   cScreenWidth, cScreenHeight, cVideoFramerateNum, cVideoFramerateDen, cVideoQuality);

    numPixels:= cScreenWidth*cScreenHeight;
    YCbCr_Planes[0]:= GetMem(numPixels);
    YCbCr_Planes[1]:= GetMem(numPixels div 4);
    YCbCr_Planes[2]:= GetMem(numPixels div 4);

    if (YCbCr_Planes[0] = nil) or (YCbCr_Planes[1] = nil) or (YCbCr_Planes[2] = nil) then
    begin
        AddFileLog('Error: Could not allocate memory for video recording (YCbCr buffer).');
        exit(false);
    end;

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
    FreeMem(YCbCr_Planes[0], numPixels);
    FreeMem(YCbCr_Planes[1], numPixels div 4);
    FreeMem(YCbCr_Planes[2], numPixels div 4);
    FreeMem(RGB_Buffer, 4*numPixels);
    Close(cameraFile);
    AVWrapper_Close();
    DeleteFile(cameraFilePath);
    DeleteFile(soundFilePath);
    SendIPC(_S'v'); // inform frontend that we finished
end;

function pixel(x, y, color: LongInt): LongInt;
begin
    pixel:= RGB_Buffer[(cScreenHeight-y-1)*cScreenWidth*4 + x*4 + color];
end;

procedure EncodeFrame;
var x, y, r, g, b: LongInt;
    s: shortstring;
begin
    // read pixels from OpenGL
    glReadPixels(0, 0, cScreenWidth, cScreenHeight, GL_RGBA, GL_UNSIGNED_BYTE, RGB_Buffer);

    // convert to YCbCr 4:2:0 format
    // Y
    for y := 0 to cScreenHeight-1 do
        for x := 0 to cScreenWidth-1 do
            YCbCr_Planes[0][y*cScreenWidth + x]:= Byte(16 + ((16828*pixel(x,y,0) + 33038*pixel(x,y,1) + 6416*pixel(x,y,2)) shr 16));

    // Cb and Cr
    for y := 0 to cScreenHeight div 2 - 1 do
        for x := 0 to cScreenWidth div 2 - 1 do
        begin
            r:= pixel(2*x,2*y,0) + pixel(2*x+1,2*y,0) + pixel(2*x,2*y+1,0) + pixel(2*x+1,2*y+1,0);
            g:= pixel(2*x,2*y,1) + pixel(2*x+1,2*y,1) + pixel(2*x,2*y+1,1) + pixel(2*x+1,2*y+1,1);
            b:= pixel(2*x,2*y,2) + pixel(2*x+1,2*y,2) + pixel(2*x,2*y+1,2) + pixel(2*x+1,2*y+1,2);
            YCbCr_Planes[1][y*(cScreenWidth div 2) + x]:= Byte(128 + ((-2428*r - 4768*g + 7196*b) shr 16));
            YCbCr_Planes[2][y*(cScreenWidth div 2) + x]:= Byte(128 + (( 7196*r - 6026*g - 1170*b) shr 16));
        end;

    AVWrapper_WriteFrame(YCbCr_Planes[0], YCbCr_Planes[1], YCbCr_Planes[2]);

    // inform frontend that we have encoded new frame
    s[0]:= #3;
    s[1]:= 'p'; // p for progress
    SDLNet_Write16(progress*10000 div maxProgress, @s[2]);
    SendIPC(s);
    inc(numFrames);
end;

// returns new game ticks
function LoadNextCameraPosition: LongInt;
var frame: TFrame;
begin
    LoadNextCameraPosition:= GameTicks;
    // we need to skip or duplicate frames to match target framerate
    while Int64(curTime)*cVideoFramerateNum <= Int64(numFrames)*cVideoFramerateDen*1000 do
    begin
    {$IOCHECKS OFF}
        if eof(cameraFile) then
            exit(-1);
        BlockRead(cameraFile, frame, 1);
    {$IOCHECKS ON}
        curTime:= frame.realTicks;
        WorldDx:= frame.CamX;
        WorldDy:= frame.CamY + cScreenHeight div 2;
        zoom:= frame.zoom*cScreenWidth;
        ZoomValue:= zoom;
        inc(progress);
        LoadNextCameraPosition:= frame.gameTicks;
    end;
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
    MakeScreenshot(thumbpath, k);
    thumbnailSaved:= true;
end;

procedure BeginPreRecording;
var format: word;
    filename: shortstring;
    frequency, channels: LongInt;
begin
    AddFileLog('BeginPreRecording');

    thumbnailSaved:= false;
    RecPrefix:= 'hw-' + FormatDateTime('YYYY-MM-DD_HH-mm-ss-z', Now());

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

    // create file with camera positions
    filename:= UserPathPrefix + '/VideoTemp/' + RecPrefix + '.txtout';
    Assign(cameraFile, filename);
    Rewrite(cameraFile);
    if IOResult <> 0 then
    begin
        AddFileLog('Error: Could not write to ' + filename);
        exit;
    end;

    // save audio parameters in sound file
    BlockWrite(audioFile, frequency, 4);
    BlockWrite(audioFile, channels, 4);
{$IOCHECKS ON}

    // register callback for actual audio recording
    Mix_SetPostMix(@RecordPostMix, nil);

    startTime:= SDL_GetTicks();
    flagPrerecording:= true;
end;

procedure StopPreRecording;
begin
    AddFileLog('StopPreRecording');
    flagPrerecording:= false;

    // call SDL_LockAudio because RecordPostMix may be executing right now
    SDL_LockAudio();
    Close(audioFile);
    Close(cameraFile);
    Mix_SetPostMix(nil, nil);
    SDL_UnlockAudio();

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

procedure freeModule;
begin
    if flagPrerecording then
        StopPreRecording();
end;

end.

{$ENDIF} // USE_VIDEO_RECORDING
