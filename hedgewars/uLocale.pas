(*
 * Hedgewars, a worms-like game
 * Copyright (c) 2006 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uLocale;
interface
type TAmmoStrId = (sidGrenade, sidClusterBomb, sidBazooka, sidUFO, sidShotgun,
                   sidPickHammer, sidSkip, sidRope, sidMine, sidDEagle,
                   sidDynamite, sidBaseballBat, sidFirePunch);
     TMsgStrId = (sidStartFight, sidSeconds);
var trammo: array[TAmmoStrId] of shortstring;
    trmsg: array[TMsgStrId] of shortstring;

procedure LoadLocale(FileName: string);

implementation
uses uMisc;

procedure LoadLocale(FileName: string);
var s: shortstring;
    f: textfile;
    a, b, c: integer;
begin
{$I-}
assignfile(f, FileName);
reset(f);
TryDo(IOResult = 0, 'Cannot load locale "' + FileName + '"', true);
while not eof(f) do
      begin
      readln(f, s);
      if Length(s) = 0 then continue;
      if s[1] = ';' then continue;
      TryDo(Length(s) > 6, 'Load locale: empty string', true);
      val(s[1]+s[2], a, c);
      TryDo(c = 0, 'Load locale: numbers should be two-digit', true);
      TryDo(s[3] = ':', 'Load locale: ":" expected', true);
      val(s[4]+s[5], b, c);
      TryDo(c = 0, 'Load locale: numbers should be two-digit', true);
      TryDo(s[6] = '=', 'Load locale: "=" expected', true);
      Delete(s, 1, 6);
      case a of
           0: if (b >=0) and (b <= ord(High(TAmmoStrId))) then trammo[TAmmoStrId(b)]:= s;
           1: if (b >=0) and (b <= ord(High(TMsgStrId))) then trmsg[TMsgStrId(b)]:= s;
           end;
      end;
closefile(f)
{$I+}
end;

end.
