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

unit fConsts;
interface

const cAppName  = '†Hedge Wars Logon†';
      cAppTitle = 'HEDGEWARS';
      cOptionsName  = 'Team Options';
      cOptionsTitle = 'Team Options';
      cGFXPath  = 'Data\front\';

      cLocalGameBtn = 1001;
      cNetGameBtn   = 1002;
      cDemoBtn      = 1003;
      cSettingsBtn  = 1004;
      cExitGameBtn  = 1005;

      cNetIpEdit    = 1021;
      cNetIpStatic  = 1022;
      cNetNameEdit  = 1023;
      cNetNameStatic= 1024;
      cNetConnStatic= 1024;
      cNetJoinBtn   = 1025;
      cNetBeginBtn  = 1026;
      cNetBackBtn   = 1027;

      cDemoList     = 1031;
      cDemoBeginBtn = 1032;
      cDemoBackBtn  = 1033;
      cDemoAllBtn   = 1034;

      cSetResEdit   = 1041;
      cSetFScrCheck = 1042;
      cSetDemoCheck = 1043;
      cSetSndCheck  = 1044;
      cSetSaveBtn   = 1045;
      cSetBackBtn   = 1046;
      cSetShowTeamOptions = 1047;

      cBGStatic     = 1199;
      cOptBGStatic  = 1198;

      cOptTeamName  = 1201;
      cOptHedgeName : array[0..7] of integer = (1202,1203,1204,1205,1206,1207,1208,1209); 

      cDemoSeedSeparator = #10;


implementation

end.
