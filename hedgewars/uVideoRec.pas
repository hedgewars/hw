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

uses uVariables, uUtils, GLunit, SDLh, SysUtils;

{$IFDEF WIN32}
const AVWrapperLibName = 'libavwrapper.dll';
{$ENDIF}

type TAddFileLogRaw = procedure (s: pchar); cdecl;

{$IFDEF WIN32}
procedure AVWrapper_Init(
              AddLog: TAddFileLogRaw;
              filename, soundFile, format, vcodec, acodec, preset: PChar;
              width, height, framerateNum, framerateDen, frequency, channels, vquality, aquality: LongInt); cdecl; external AVWrapperLibName;
procedure AVWrapper_Close; cdecl; external AVWrapperLibName;
procedure AVWrapper_WriteFrame( pY, pCb, pCr: PByte ); cdecl; external AVWrapperLibName;
{$ELSE}
procedure AVWrapper_Init(
              AddLog: TAddFileLogRaw;
              filename, soundFile, format, vcodec, acodec, preset: PChar;
              width, height, framerateNum, framerateDen, frequency, channels, vquality, aquality: LongInt); cdecl; external;
procedure AVWrapper_Close; cdecl; external;
procedure AVWrapper_WriteFrame( pY, pCb, pCr: PByte ); cdecl; external;
{$ENDIF}

var YCbCr_Planes: array[0..2] of PByte;
    RGB_Buffer: PByte;

    frequency, channels: LongInt;

    cameraFile: TextFile;
    audioFile: File;
    
    numPixels: LongInt;

    firstTick, nframes: Int64;
    
    cameraFilePath, soundFilePath: shortstring;

function BeginVideoRecording: Boolean;
var filename: shortstring;
begin
    AddFileLog('BeginVideoRecording');

    numPixels:= cScreenWidth*cScreenHeight;

{$IOCHECKS OFF}
    // open file with prerecorded camera positions
    cameraFilePath:= UserPathPrefix + '/Videos/' + cRecPrefix + '.txtin';
    Assign(cameraFile, cameraFilePath);
    Reset(cameraFile);
    if IOResult <> 0 then
    begin
        AddFileLog('Error: Could not read from ' + cameraFilePath);
        exit(false);
    end;

    ReadLn(cameraFile, frequency, channels);
{$IOCHECKS ON}

    filename:= UserPathPrefix + '/Videos/' + cRecPrefix + #0;
    soundFilePath:= UserPathPrefix + '/Videos/' + cRecPrefix + '.hwsound' + #0;
    cAVFormat+= #0;
    cAudioCodec+= #0;
    cVideoCodec+= #0;
    cVideoPreset+= #0;
    AVWrapper_Init(@AddFileLogRaw, @filename[1], @soundFilePath[1], @cAVFormat[1], @cVideoCodec[1], @cAudioCodec[1], @cVideoPreset[1],
                   cScreenWidth, cScreenHeight, cVideoFramerateNum, cVideoFramerateDen, frequency, channels, cAudioQuality, cVideoQuality);

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
end;

function pixel(x, y, color: LongInt): LongInt;
begin
    pixel:= RGB_Buffer[(cScreenHeight-y-1)*cScreenWidth*4 + x*4 + color];
end;

procedure EncodeFrame;
var x, y, r, g, b: LongInt;
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
end;

function LoadNextCameraPosition: LongInt;
var NextTime: LongInt;
    NextZoom: LongInt;
    NextWorldDx, NextWorldDy: LongInt;
begin
{$IOCHECKS OFF}
    if eof(cameraFile) then
        exit(-1);
    ReadLn(cameraFile, NextTime, NextWorldDx, NextWorldDy, NextZoom);
{$IOCHECKS ON}
    if NextTime = 0 then
        exit(-1);
    WorldDx:= NextWorldDx;
    WorldDy:= NextWorldDy;
    zoom:= NextZoom/10000;
    ZoomValue:= NextZoom/10000;
    LoadNextCameraPosition:= NextTime;
end;

// this procedure may be called from different thread
procedure RecordPostMix(udata: pointer; stream: PByte; len: LongInt); cdecl;
begin
    udata:= udata;
{$IOCHECKS OFF}
    BlockWrite(audioFile, stream^, len);
{$IOCHECKS ON}
end;

procedure BeginPreRecording;
var format: word;
    filePrefix, filename: shortstring;
begin
    AddFileLog('BeginPreRecording');
    
    nframes:= 0;
    firstTick:= SDL_GetTicks();

    filePrefix:= FormatDateTime('YYYY-MM-DD_HH-mm-ss', Now());

    Mix_QuerySpec(@frequency, @format, @channels);
    if format <> $8010 then
    begin
        // TODO: support any audio format
        AddFileLog('Error: Unexpected audio format ' + IntToStr(format));
        exit;
    end;

{$IOCHECKS OFF}
    filename:= UserPathPrefix + '/Videos/' + filePrefix + '.hwsound';
    Assign(audioFile, filename);
    Rewrite(audioFile, 1);
    if IOResult <> 0 then
    begin
        AddFileLog('Error: Could not write to ' + filename);
        exit;
    end;

    filename:= UserPathPrefix + '/Videos/' + filePrefix + '.txtout';
    Assign(cameraFile, filename);
    Rewrite(cameraFile);
    if IOResult <> 0 then
    begin
        AddFileLog('Error: Could not write to ' + filename);
        exit;
    end;
{$IOCHECKS ON}
    WriteLn(cameraFile, inttostr(frequency) + ' ' + inttostr(channels));

    // register callback for actual audio recording
    Mix_SetPostMix(@RecordPostMix, nil);

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
end;

procedure SaveCameraPosition;
var Ticks: LongInt;
begin
    Ticks:= SDL_GetTicks();
    while (Ticks - firstTick)*cVideoFramerateNum > nframes*cVideoFramerateDen*1000 do
    begin
        WriteLn(cameraFile, inttostr(GameTicks) + ' ' + inttostr(WorldDx) + ' ' + inttostr(WorldDy) + ' ' + inttostr(Round(zoom*10000)));
        inc(nframes);
    end;
end;

procedure freeModule;
begin
    if flagPrerecording then
        StopPreRecording();
end;

end.
