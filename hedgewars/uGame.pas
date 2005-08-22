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

unit uGame;
interface
uses SDLh;
{$INCLUDE options.inc}

procedure DoGameTick(Lag: integer);

////////////////////
   implementation
////////////////////
uses uMisc, uConsts, uWorld, uKeys, uTeams, uIO, uAI, uGears;

procedure DoGameTick(Lag: integer);
const SendEmptyPacketTicks: LongWord = 0;
var i: integer;
begin
if CurrentTeam.ExtDriven then
   begin
   if (GameType = gmtDemo) then
      ProcessKbdDemo;
   end
   else begin
   NetGetNextCmd; // на случай, если что-то сказано
   if SendEmptyPacketTicks >= cSendEmptyPacketTime then
      begin
      SendIPC('+');
      SendEmptyPacketTicks:= 0
      end;
   inc(SendEmptyPacketTicks, Lag)
   end;

// если тачка слабая, то Lag с каждым кадром стремится в бесконечность
if Lag > 100 then Lag:= 100;

for i:= 0 to Lag do
    if not CurrentTeam.ExtDriven then
       begin
       with CurrentTeam^ do
           if Hedgehogs[CurrHedgehog].BotLevel <> 0 then ProcessBot;
       ProcessGears
       end else
       begin
       NetGetNextCmd;
       if isInLag then
          case GameType of
               gmtNet: break;
               gmtDemo: begin
                        SendIPC('q');
                        GameState:= gsExit;
                        exit
                        end
               end
          else ProcessGears
       end;
if not CurrentTeam.ExtDriven then isInLag:= false;

MoveWorld
end;

end.
