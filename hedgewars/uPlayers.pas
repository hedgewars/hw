(*
 * Hedgewars, a worms-like game
 * Copyright (c) 2004, 2005 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uPlayers;
interface
uses windows, WinSock;
type PPlayer = ^TPlayer;
     PTeam = ^TTeam;
     TTeam = record
             hhs: array[0..7] of TPoint;
             hhCount: LongWord;
             end;
     TPlayer = record
               socket: TSocket;
               NextPlayer, PrevPlayer: PPlayer;
               Name: string[31];
               inbuf: string;
               isme: boolean;
               CurrTeam: LongWord;
               TeamCount: LongWord;
               Teams: array[0..3] of TTeam
               end;

function AddPlayer(sock: TSocket): PPlayer;
procedure DeletePlayer(Player: PPlayer);
function FindPlayerbySock(sock: TSocket): PPlayer;
procedure SendAll(s: shortstring);
procedure SendAllButOne(Player: PPlayer; s: shortstring);
procedure SelectFirstCFGTeam;
procedure SelectNextCFGTeam;
function GetTeamCount: Longword;
procedure ConfCurrTeam(s: shortstring);
procedure SendConfig(player: PPlayer);

var CurrCFGPlayer: PPlayer;

implementation
uses uServerMisc, uNet, SysUtils;
var PlayersList: PPlayer = nil;

function AddPlayer(sock: TSocket): PPlayer;
begin
New(Result);
TryDo(Result <> nil, 'Error adding player!');
FillChar(Result^, sizeof(TPlayer), 0);
Result.socket:= sock;
Result.TeamCount:= 2;
if PlayersList = nil then begin PlayersList:= Result; result.isme:= true end
                     else begin
                     PlayersList.PrevPlayer:= Result;
                     Result.NextPlayer:= PlayersList;
                     PlayersList:= Result
                     end
end;

procedure DeletePlayer(Player: PPlayer);
begin
if Player = nil then OutError('Trying remove nil player!', false);
if Player.NextPlayer <> nil then Player.NextPlayer.PrevPlayer:= Player.PrevPlayer;
if Player.PrevPlayer <> nil then Player.PrevPlayer.NextPlayer:= Player.NextPlayer
                        else begin
                        PlayersList:= Player^.NextPlayer;
                        if PlayersList <> nil then PlayersList.PrevPlayer:= nil
                        end;
Dispose(Player)
end;

function FindPlayerbySock(sock: TSocket): PPlayer;
begin
Result:= PlayersList;
while (Result<>nil)and(Result.socket<>sock) do
      Result:= Result.NextPlayer
end;

procedure SendAll(s: shortstring);
var p: PPlayer;
begin
p:= PlayersList;
while p <> nil do
      begin
      SendSock(p.socket, s);
      p:= p.NextPlayer
      end;
end;

procedure SendAllButOne(Player: PPlayer; s: shortstring);
var p: PPlayer;
begin
p:= Player.NextPlayer;
while p <> nil do
      begin
      SendSock(p.socket, s);
      p:= p.NextPlayer
      end;
p:= PlayersList;
while p <> Player do
      begin
      SendSock(p.socket, s);
      p:= p.NextPlayer
      end;
end;

function GetTeamCount: Longword;
var p: PPlayer;
begin
p:= PlayersList;
Result:= 0;
while p <> nil do
      begin
      inc(Result, p.TeamCount);
      p:= p.NextPlayer
      end;
end;

procedure SelectFirstCFGTeam;
begin
CurrCFGPlayer:= PlayersList
end;

procedure SelectNextCFGTeam;
begin
if CurrCFGPlayer = nil then OutError('Trying select next on nil current', true);
if Succ(CurrCFGPlayer.CurrTeam) < CurrCFGPlayer.TeamCount then inc(CurrCFGPlayer.CurrTeam)
                                                          else CurrCFGPlayer:= CurrCFGPlayer.NextPlayer
end;

procedure ConfCurrTeam(s: shortstring);
begin
if CurrCFGPlayer = nil then OutError('Trying select next on nil current', true);
case s[1] of
     'h': with CurrCFGPlayer.Teams[CurrCFGPlayer.CurrTeam] do
               begin
               hhs[hhCount].X:= PLongWord(@s[2])^;
               hhs[hhCount].Y:= PLongWord(@s[6])^;
               inc(hhCount);
               end;
     end;
end;

procedure SendConfig(player: PPlayer);
var p: PPlayer;
    i, t: integer;
begin
p:= PlayersList;
while p <> nil do
      begin
      for t:= 0 to Pred(player.TeamCount) do
          begin
          SendSock(player.socket, 'eaddteam');
          if p = player then SendSock(player.socket, '@')
                        else SendSock(player.socket, 'erdriven');
          for i:= 0 to Pred(player.Teams[t].hhCount) do
              SendSock(player.socket, Format('eadd hh%d %d %d %d',[i, p.Teams[t].hhs[i].X, p.Teams[t].hhs[i].Y, 0]));
          Sendsock(player.socket, Format('ecolor %d',[random($A0A0A0)+$5F5F5F]))
          end;
      p:= p.NextPlayer
      end
end;


end.
